#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
API_NAME="${API_NAME:-java-reghub-dev-http-api}"
VPC_LINK_NAME="${VPC_LINK_NAME:-java-reghub-dev-vpc-link}"
VPC_LINK_SG_NAME="${VPC_LINK_SG_NAME:-java-reghub-dev-apigw-vpc-link}"
VPC_ID="${VPC_ID:-vpc-04b5af3d5d94287ae}"

api_id="$(aws apigatewayv2 get-apis \
  --region "$AWS_REGION" \
  --query "Items[?Name=='$API_NAME'].ApiId | [0]" \
  --output text)"

if [[ -n "$api_id" && "$api_id" != "None" ]]; then
  echo "Deleting HTTP API: $API_NAME ($api_id)"
  aws apigatewayv2 delete-api --region "$AWS_REGION" --api-id "$api_id"
else
  echo "HTTP API not found: $API_NAME"
fi

vpc_link_id="$(aws apigatewayv2 get-vpc-links \
  --region "$AWS_REGION" \
  --query "Items[?Name=='$VPC_LINK_NAME' && VpcLinkStatus!='DELETING'].VpcLinkId | [0]" \
  --output text)"

if [[ -n "$vpc_link_id" && "$vpc_link_id" != "None" ]]; then
  echo "Deleting VPC Link: $VPC_LINK_NAME ($vpc_link_id)"
  aws apigatewayv2 delete-vpc-link --region "$AWS_REGION" --vpc-link-id "$vpc_link_id"
else
  echo "VPC Link not found: $VPC_LINK_NAME"
fi

sg_id="$(aws ec2 describe-security-groups \
  --region "$AWS_REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$VPC_LINK_SG_NAME" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)"

if [[ -n "$sg_id" && "$sg_id" != "None" ]]; then
  echo "Security group $sg_id can be deleted after the VPC Link finishes deleting:"
  echo "aws ec2 delete-security-group --region $AWS_REGION --group-id $sg_id"
fi
