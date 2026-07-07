#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
API_NAME="${API_NAME:-java-reghub-dev-http-api}"
VPC_LINK_NAME="${VPC_LINK_NAME:-java-reghub-dev-vpc-link}"
VPC_LINK_SG_NAME="${VPC_LINK_SG_NAME:-java-reghub-dev-apigw-vpc-link}"
VPC_ID="${VPC_ID:-vpc-04b5af3d5d94287ae}"
PRIVATE_SUBNETS="${PRIVATE_SUBNETS:-subnet-0711f89f50e07d6fe,subnet-0eeba65c131583de3}"
ALB_NAME="${ALB_NAME:-k8s-reghub-reghubwe-146da59bb5}"
STAGE_NAME="${STAGE_NAME:-\$default}"
OUTPUT_FILE="${OUTPUT_FILE:-infra/api-gateway/outputs.env}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

tag_specifications() {
  local resource_type="$1"
  printf 'ResourceType=%s,Tags=[{Key=Project,Value=java-reghub},{Key=Environment,Value=dev},{Key=ManagedBy,Value=infra/api-gateway/deploy.sh}]' "$resource_type"
}

require aws
require jq

IFS=',' read -r -a subnet_ids <<< "$PRIVATE_SUBNETS"

echo "Discovering internal ALB: $ALB_NAME"
alb_json="$(aws elbv2 describe-load-balancers \
  --region "$AWS_REGION" \
  --names "$ALB_NAME")"
alb_arn="$(jq -r '.LoadBalancers[0].LoadBalancerArn' <<< "$alb_json")"
alb_dns="$(jq -r '.LoadBalancers[0].DNSName' <<< "$alb_json")"

listener_arn="$(aws elbv2 describe-listeners \
  --region "$AWS_REGION" \
  --load-balancer-arn "$alb_arn" \
  --query 'Listeners[?Protocol==`HTTP` && Port==`80`].ListenerArn | [0]' \
  --output text)"

if [[ -z "$listener_arn" || "$listener_arn" == "None" ]]; then
  echo "No HTTP:80 listener found on $ALB_NAME" >&2
  exit 1
fi

echo "Using listener: $listener_arn"

sg_id="$(aws ec2 describe-security-groups \
  --region "$AWS_REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$VPC_LINK_SG_NAME" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)"

if [[ -z "$sg_id" || "$sg_id" == "None" ]]; then
  echo "Creating VPC Link security group: $VPC_LINK_SG_NAME"
  sg_id="$(aws ec2 create-security-group \
    --region "$AWS_REGION" \
    --group-name "$VPC_LINK_SG_NAME" \
    --description "API Gateway VPC Link egress for Java Reghub dev" \
    --vpc-id "$VPC_ID" \
    --tag-specifications "$(tag_specifications security-group)" \
    --query 'GroupId' \
    --output text)"
else
  echo "Reusing VPC Link security group: $sg_id"
fi

vpc_link_id="$(aws apigatewayv2 get-vpc-links \
  --region "$AWS_REGION" \
  --query "Items[?Name=='$VPC_LINK_NAME' && VpcLinkStatus!='DELETING'].VpcLinkId | [0]" \
  --output text)"

if [[ -z "$vpc_link_id" || "$vpc_link_id" == "None" ]]; then
  echo "Creating VPC Link: $VPC_LINK_NAME"
  vpc_link_id="$(aws apigatewayv2 create-vpc-link \
    --region "$AWS_REGION" \
    --name "$VPC_LINK_NAME" \
    --subnet-ids "${subnet_ids[@]}" \
    --security-group-ids "$sg_id" \
    --tags Project=java-reghub,Environment=dev,ManagedBy=infra/api-gateway/deploy.sh \
    --query 'VpcLinkId' \
    --output text)"
else
  echo "Reusing VPC Link: $vpc_link_id"
fi

echo "Waiting for VPC Link to become AVAILABLE..."
for _ in {1..60}; do
  vpc_link_status="$(aws apigatewayv2 get-vpc-link \
    --region "$AWS_REGION" \
    --vpc-link-id "$vpc_link_id" \
    --query 'VpcLinkStatus' \
    --output text)"
  echo "VPC Link status: $vpc_link_status"
  [[ "$vpc_link_status" == "AVAILABLE" ]] && break
  if [[ "$vpc_link_status" == "FAILED" ]]; then
    aws apigatewayv2 get-vpc-link --region "$AWS_REGION" --vpc-link-id "$vpc_link_id"
    exit 1
  fi
  sleep 10
done

if [[ "$vpc_link_status" != "AVAILABLE" ]]; then
  echo "Timed out waiting for VPC Link $vpc_link_id to become AVAILABLE" >&2
  exit 1
fi

api_id="$(aws apigatewayv2 get-apis \
  --region "$AWS_REGION" \
  --query "Items[?Name=='$API_NAME'].ApiId | [0]" \
  --output text)"

if [[ -z "$api_id" || "$api_id" == "None" ]]; then
  echo "Creating HTTP API: $API_NAME"
  api_id="$(aws apigatewayv2 create-api \
    --region "$AWS_REGION" \
    --name "$API_NAME" \
    --protocol-type HTTP \
    --tags Project=java-reghub,Environment=dev,ManagedBy=infra/api-gateway/deploy.sh \
    --query 'ApiId' \
    --output text)"
else
  echo "Reusing HTTP API: $api_id"
fi

integration_id="$(aws apigatewayv2 get-integrations \
  --region "$AWS_REGION" \
  --api-id "$api_id" \
  --query "Items[?IntegrationUri=='$listener_arn' && ConnectionId=='$vpc_link_id'].IntegrationId | [0]" \
  --output text)"

if [[ -z "$integration_id" || "$integration_id" == "None" ]]; then
  echo "Creating HTTP_PROXY integration to ALB listener"
  integration_id="$(aws apigatewayv2 create-integration \
    --region "$AWS_REGION" \
    --api-id "$api_id" \
    --integration-type HTTP_PROXY \
    --integration-method ANY \
    --connection-type VPC_LINK \
    --connection-id "$vpc_link_id" \
    --integration-uri "$listener_arn" \
    --payload-format-version "1.0" \
    --query 'IntegrationId' \
    --output text)"
else
  echo "Reusing integration: $integration_id"
fi

ensure_route() {
  local route_key="$1"
  local route_id
  route_id="$(aws apigatewayv2 get-routes \
    --region "$AWS_REGION" \
    --api-id "$api_id" \
    --query "Items[?RouteKey=='$route_key'].RouteId | [0]" \
    --output text)"

  if [[ -z "$route_id" || "$route_id" == "None" ]]; then
    echo "Creating route: $route_key"
    aws apigatewayv2 create-route \
      --region "$AWS_REGION" \
      --api-id "$api_id" \
      --route-key "$route_key" \
      --target "integrations/$integration_id" \
      >/dev/null
  else
    echo "Updating route: $route_key"
    aws apigatewayv2 update-route \
      --region "$AWS_REGION" \
      --api-id "$api_id" \
      --route-id "$route_id" \
      --target "integrations/$integration_id" \
      >/dev/null
  fi
}

ensure_route 'ANY /'
ensure_route 'ANY /{proxy+}'

stage_exists="$(aws apigatewayv2 get-stages \
  --region "$AWS_REGION" \
  --api-id "$api_id" \
  --query "Items[?StageName=='$STAGE_NAME'].StageName | [0]" \
  --output text)"

if [[ -z "$stage_exists" || "$stage_exists" == "None" ]]; then
  echo "Creating stage: $STAGE_NAME"
  aws apigatewayv2 create-stage \
    --region "$AWS_REGION" \
    --api-id "$api_id" \
    --stage-name "$STAGE_NAME" \
    --auto-deploy \
    --tags Project=java-reghub,Environment=dev,ManagedBy=infra/api-gateway/deploy.sh \
    >/dev/null
else
  echo "Ensuring auto-deploy is enabled on stage: $STAGE_NAME"
  aws apigatewayv2 update-stage \
    --region "$AWS_REGION" \
    --api-id "$api_id" \
    --stage-name "$STAGE_NAME" \
    --auto-deploy \
    >/dev/null
fi

api_endpoint="$(aws apigatewayv2 get-api \
  --region "$AWS_REGION" \
  --api-id "$api_id" \
  --query 'ApiEndpoint' \
  --output text)"

mkdir -p "$(dirname "$OUTPUT_FILE")"
cat > "$OUTPUT_FILE" <<EOF
AWS_REGION='$AWS_REGION'
API_NAME='$API_NAME'
API_ID='$api_id'
API_ENDPOINT='$api_endpoint'
VPC_LINK_NAME='$VPC_LINK_NAME'
VPC_LINK_ID='$vpc_link_id'
VPC_LINK_SECURITY_GROUP_ID='$sg_id'
ALB_NAME='$ALB_NAME'
ALB_DNS='$alb_dns'
ALB_LISTENER_ARN='$listener_arn'
STAGE_NAME='$STAGE_NAME'
EOF

echo
echo "API Gateway is ready:"
echo "$api_endpoint"
echo
echo "Wrote outputs to $OUTPUT_FILE"
