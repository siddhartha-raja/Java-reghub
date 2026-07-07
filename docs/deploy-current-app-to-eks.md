# Deploy the Current App to EKS

This deploys the current Spring Boot application and MySQL into the
`java-reghub-dev` EKS cluster.

## 1. Confirm Cluster Access

```bash
aws eks update-kubeconfig --region us-east-1 --name java-reghub-dev
kubectl get nodes
```

## 2. Build and Push the App Image

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login \
      --username AWS \
      --password-stdin 818916267011.dkr.ecr.us-east-1.amazonaws.com

docker build -t redis-db-demo:dev .

docker tag \
  redis-db-demo:dev \
  818916267011.dkr.ecr.us-east-1.amazonaws.com/redis-db-demo:dev

docker push 818916267011.dkr.ecr.us-east-1.amazonaws.com/redis-db-demo:dev
```

## 3. Confirm EBS Storage

The MySQL manifest uses the `gp2` StorageClass created with the dev EKS cluster.

```bash
kubectl get storageclass
```

If the MySQL PVC stays Pending later, install the EBS CSI add-on:

```bash
eksctl create addon \
  --cluster java-reghub-dev \
  --region us-east-1 \
  --name aws-ebs-csi-driver \
  --force
```

After installing the add-on, check the PVC again:

```bash
kubectl -n reghub get pvc mysql-data
```

## 4. Create the App Secret

For this first dev deployment, create the secret manually. Replace the AWS
values with credentials that can access the configured S3 bucket.

```bash
kubectl apply -f k8s/base/namespace.yaml

kubectl create secret generic reghub-secret \
  --namespace reghub \
  --from-literal=SPRING_DATASOURCE_PASSWORD='reghub_password' \
  --from-literal=AWS_ACCESS_KEY_ID='replace-me' \
  --from-literal=AWS_SECRET_ACCESS_KEY='replace-me' \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -
```

Later we should replace static AWS keys with IRSA.

## 5. Deploy MySQL and the App

```bash
kubectl apply -k k8s/overlays/dev
```

Watch rollout:

```bash
kubectl -n reghub get pods -w
```

Check status:

```bash
kubectl -n reghub get deploy,svc,pvc
kubectl -n reghub rollout status deploy/mysql
kubectl -n reghub rollout status deploy/reghub-web
```

## 6. Test with Port Forwarding

```bash
kubectl -n reghub port-forward svc/reghub-web 8080:80
```

Open:

```text
http://localhost:8080
```

## 7. Useful Debug Commands

```bash
kubectl -n reghub logs deploy/reghub-web
kubectl -n reghub logs deploy/mysql
kubectl -n reghub describe pod -l app=reghub-web
kubectl -n reghub describe pod -l app=mysql
```

## 8. Remove the App Stack

```bash
kubectl delete -k k8s/overlays/dev
```

This removes the app manifests, including the MySQL PVC. Do not run this if you
want to keep the dev database data.
