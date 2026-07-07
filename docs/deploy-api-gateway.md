# Deploy API Gateway HTTP API

This creates an Amazon API Gateway HTTP API in front of the internal ALB created
by the EKS Ingress.

Traffic path:

```text
public HTTP API endpoint -> API Gateway VPC Link -> internal ALB -> reghub-web
```

## Installed Values

```text
AWS_ACCOUNT_ID=818916267011
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=java-reghub-dev
VPC_ID=vpc-04b5af3d5d94287ae
PRIVATE_SUBNETS=subnet-0711f89f50e07d6fe,subnet-0eeba65c131583de3
ALB_NAME=k8s-reghub-reghubwe-146da59bb5
INTERNAL_ALB_DNS=internal-k8s-reghub-reghubwe-146da59bb5-209527896.us-east-1.elb.amazonaws.com
API_NAME=java-reghub-dev-http-api
VPC_LINK_NAME=java-reghub-dev-vpc-link
```

## Deploy

From the repository root:

```bash
chmod +x infra/api-gateway/deploy.sh infra/api-gateway/destroy.sh
infra/api-gateway/deploy.sh
```

The script is idempotent. It creates or reuses:

- A security group for API Gateway VPC Link ENIs.
- An API Gateway VPC Link in the private EKS subnets.
- An HTTP API.
- An `HTTP_PROXY` integration pointing at the internal ALB HTTP listener ARN.
- Routes for `ANY /` and `ANY /{proxy+}`.
- The `$default` stage with auto-deploy enabled.

The script writes the current IDs and endpoint to:

```text
infra/api-gateway/outputs.env
```

## Verify

Load the endpoint from the generated outputs:

```bash
source infra/api-gateway/outputs.env
curl -i "$API_ENDPOINT/"
curl -i "$API_ENDPOINT/actuator/health/readiness"
```

Expected readiness response:

```json
{"status":"UP"}
```

Useful AWS checks:

```bash
aws apigatewayv2 get-apis --region us-east-1
aws apigatewayv2 get-vpc-links --region us-east-1
aws apigatewayv2 get-routes --region us-east-1 --api-id "$API_ID"
aws apigatewayv2 get-integrations --region us-east-1 --api-id "$API_ID"
```

## Remove

For dev cleanup:

```bash
infra/api-gateway/destroy.sh
```

The VPC Link can take a few minutes to finish deleting. Delete the generated
security group after the VPC Link is gone if AWS still reports it as attached.

## Notes

- API Gateway HTTP API private integrations use the ALB listener ARN, not the
  ALB DNS name.
- The current Kubernetes Ingress rule is path-only (`/*`), so no Host header
  override is required.
- The internal ALB remains private. Only the API Gateway endpoint is public.
- Add a custom domain and TLS certificate later for a production-style URL.
