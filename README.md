# 🚀 Amazon EKS + Kubernetes Ingress + Route 53 + ExternalDNS

This project demonstrates how to deploy applications on **Amazon Elastic Kubernetes Service (EKS)** and expose them to the internet using **Kubernetes Ingress**, **AWS Load Balancer**, **Amazon Route 53**, and **ExternalDNS**.

The project focuses on building a complete AWS-native Kubernetes networking setup where DNS records are automatically managed through Route 53.

---

## 📌 Project Overview

In this project:

1. Applications are deployed inside an **Amazon EKS cluster**.
2. Kubernetes **Ingress** manages HTTP/HTTPS routing.
3. AWS Load Balancer exposes the applications to the internet.
4. **ExternalDNS** automatically creates and manages DNS records in Route 53.
5. Users can access applications using a custom domain instead of the AWS Load Balancer hostname.

### Architecture

```text
                         Internet
                            │
                            │
                    app.example.com
                            │
                            ▼
                    Amazon Route 53
                            │
                     DNS Resolution
                            │
                            ▼
                 AWS Load Balancer
                            │
                            ▼
                Kubernetes Ingress
                            │
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
          Application 1          Application 2
          Kubernetes Service     Kubernetes Service
                 │                     │
                 ▼                     ▼
              Pods                  Pods
                 │                     │
                 └──────────┬──────────┘
                            │
                       Amazon EKS
```

---

# 🛠️ Technologies Used

| Technology         | Purpose                                |
| ------------------ | -------------------------------------- |
| AWS EKS            | Managed Kubernetes cluster             |
| Kubernetes         | Container orchestration                |
| Kubernetes Ingress | HTTP/HTTPS traffic routing             |
| AWS Load Balancer  | Internet-facing application endpoint   |
| Route 53           | DNS management                         |
| ExternalDNS        | Automatically manages Route 53 records |
| kubectl            | Kubernetes CLI                         |
| AWS CLI            | AWS resource management                |
| Docker             | Containerization                       |
| Linux              | Deployment environment                 |

---

# ☁️ AWS Architecture

The major AWS components used in this project are:

### Amazon EKS

Amazon EKS provides the managed Kubernetes control plane.

The cluster runs:

* Kubernetes Pods
* Deployments
* Services
* Ingress
* ExternalDNS

---

### AWS Load Balancer

The Kubernetes Ingress is used to expose applications externally.

Depending on the Ingress Controller configuration, AWS can provision an internet-facing Load Balancer.

Traffic follows:

```text
Client
   ↓
Route 53
   ↓
AWS Load Balancer
   ↓
Kubernetes Ingress
   ↓
Kubernetes Service
   ↓
Pod
```

---

### Amazon Route 53

Route 53 provides DNS resolution for the application.

For example:

```text
app.navaneethkrishna.me
```

instead of accessing the application using a long AWS Load Balancer hostname.

---

### ExternalDNS

ExternalDNS automatically synchronizes Kubernetes DNS resources with Route 53.

For example, an Ingress can contain:

```yaml
annotations:
  external-dns.alpha.kubernetes.io/hostname: app.navaneethkrishna.me
```

ExternalDNS detects this configuration and creates the required Route 53 record.

This eliminates the need to manually create DNS records every time an application is deployed.

---

# 📂 Project Structure

A typical project structure is:

```text
EKS-Ingress-route53-Demo/
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
├── scripts/
│   └── deploy.sh
│
├── README.md
└── .gitignore
```

> File names may vary depending on the deployment configuration used in the repository.

---

# 🔐 Prerequisites

Before starting, install and configure the following:

### AWS CLI

Check installation:

```bash
aws --version
```

Configure AWS:

```bash
aws configure
```

Verify your AWS identity:

```bash
aws sts get-caller-identity
```

---

### kubectl

Check:

```bash
kubectl version --client
```

---

### eksctl

Check:

```bash
eksctl version
```

---

# 🔑 AWS IAM Permissions

The deployment environment needs appropriate permissions.

Depending on the setup, permissions may be required for:

* EKS
* EC2
* IAM
* Elastic Load Balancing
* Route 53
* CloudFormation
* VPC

For ExternalDNS, the IAM identity used by ExternalDNS should have only the required Route 53 permissions.

A typical permission set includes:

```text
route53:ChangeResourceRecordSets
route53:ListHostedZones
route53:ListResourceRecordSets
```

### ⚠️ Security Recommendation

Never hard-code AWS credentials inside:

```text
deploy.sh
```

or Kubernetes YAML files.

Do NOT commit:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

to GitHub.

Use:

* IAM Roles
* IAM Roles for Service Accounts
* EKS Pod Identity
* AWS credential providers

instead.

---

# 🚀 Step 1 — Create the EKS Cluster

Example:

```bash
eksctl create cluster \
  --name eks-ingress-demo \
  --region us-east-1 \
  --nodes 2 \
  --node-type t3.medium
```

Verify the cluster:

```bash
aws eks list-clusters --region us-east-1
```

---

# 🔗 Step 2 — Connect kubectl to EKS

Run:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-ingress-demo
```

Verify:

```bash
kubectl get nodes
```

Expected output:

```text
NAME                         STATUS   ROLES    AGE
ip-xxx-xxx-xxx-xxx          Ready    <none>   ...
ip-xxx-xxx-xxx-xxx          Ready    <none>   ...
```

---

# 📦 Step 3 — Deploy the Application

Apply the Kubernetes resources:

```bash
kubectl apply -f k8s/
```

Check deployments:

```bash
kubectl get deployments
```

Check Pods:

```bash
kubectl get pods
```

Check Services:

```bash
kubectl get svc
```

---

# 🌐 Step 4 — Configure Ingress

The Ingress resource defines how incoming HTTP traffic should be routed.

Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    external-dns.alpha.kubernetes.io/hostname: app.navaneethkrishna.me
spec:
  ingressClassName: alb

  rules:
    - host: app.navaneethkrishna.me
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: demo-service
                port:
                  number: 80
```

The important components are:

```text
Ingress
 ├── Host
 ├── Path
 ├── Service
 └── ExternalDNS hostname
```

---

# ⚖️ Step 5 — AWS Load Balancer Controller

For AWS Application Load Balancer based Ingress, the **AWS Load Balancer Controller** should be installed in the EKS cluster.

Check whether it is running:

```bash
kubectl get pods -n kube-system
```

Look for:

```text
aws-load-balancer-controller
```

Check:

```bash
kubectl get deployment \
  -n kube-system \
  aws-load-balancer-controller
```

---

# 🌍 Step 6 — Configure Route 53

Make sure you already have a Route 53 hosted zone for your domain.

Example:

```text
navaneethkrishna.me
```

The hosted zone should contain the appropriate NS records registered with your domain registrar.

Verify hosted zones:

```bash
aws route53 list-hosted-zones
```

---

# 🔄 Step 7 — Install ExternalDNS

ExternalDNS watches Kubernetes resources and creates DNS records automatically.

Check ExternalDNS:

```bash
kubectl get pods -n external-dns
```

Or:

```bash
kubectl get pods -A | grep external-dns
```

Check logs:

```bash
kubectl logs -n external-dns \
  deployment/external-dns
```

You should see messages similar to:

```text
Desired change: CREATE ...
```

This indicates ExternalDNS has detected a DNS change.

---

# 🧩 How ExternalDNS Works

Suppose the Ingress contains:

```yaml
external-dns.alpha.kubernetes.io/hostname: app.navaneethkrishna.me
```

ExternalDNS performs approximately this workflow:

```text
Kubernetes Ingress
        │
        ▼
    ExternalDNS
        │
        ▼
   Route 53 API
        │
        ▼
DNS Record Created
        │
        ▼
app.navaneethkrishna.me
```

After the record is created:

```text
Browser
   │
   ▼
app.navaneethkrishna.me
   │
   ▼
Route 53
   │
   ▼
AWS Load Balancer
   │
   ▼
Ingress
   │
   ▼
Service
   │
   ▼
Pod
```

---

# 🔍 Step 8 — Verify Ingress

Run:

```bash
kubectl get ingress
```

Example:

```text
NAME           CLASS   HOSTS                     ADDRESS
demo-ingress   alb     app.navaneethkrishna.me   xxx.elb.amazonaws.com
```

The `ADDRESS` field should eventually contain the AWS Load Balancer DNS name.

For detailed information:

```bash
kubectl describe ingress demo-ingress
```

---

# 🔎 Step 9 — Verify Route 53

Use:

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID>
```

You should see the DNS record for your application.

Example:

```text
app.navaneethkrishna.me
```

---

# 🌐 Step 10 — Test the Application

Once DNS propagation is complete:

```bash
curl http://app.navaneethkrishna.me
```

Or open:

```text
http://app.navaneethkrishna.me
```

in a browser.

You can also verify DNS:

```bash
nslookup app.navaneethkrishna.me
```

or:

```bash
dig app.navaneethkrishna.me
```

---

# 🧪 Useful Kubernetes Commands

### View Pods

```bash
kubectl get pods
```

### View all resources

```bash
kubectl get all
```

### View Services

```bash
kubectl get svc
```

### View Ingress

```bash
kubectl get ingress
```

### Describe Ingress

```bash
kubectl describe ingress demo-ingress
```

### View Pod logs

```bash
kubectl logs <pod-name>
```

### Follow logs

```bash
kubectl logs -f <pod-name>
```

### Restart deployment

```bash
kubectl rollout restart deployment <deployment-name>
```

### Check rollout status

```bash
kubectl rollout status deployment <deployment-name>
```

---

# 🔧 Troubleshooting

## 1. Ingress has no ADDRESS

Check:

```bash
kubectl get ingress
```

Then:

```bash
kubectl describe ingress demo-ingress
```

Check the AWS Load Balancer Controller:

```bash
kubectl get pods -n kube-system | grep aws-load-balancer
```

View controller logs:

```bash
kubectl logs -n kube-system \
  deployment/aws-load-balancer-controller
```

---

## 2. DNS record is not created

Check ExternalDNS:

```bash
kubectl get pods -A | grep external-dns
```

Then:

```bash
kubectl logs -n external-dns deployment/external-dns
```

Look for messages such as:

```text
Desired change
CREATE
UPSERT
DELETE
```

---

## 3. Application is not reachable

Check:

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

Then inspect the Ingress:

```bash
kubectl describe ingress demo-ingress
```

Check service endpoints:

```bash
kubectl get endpoints
```

If using EndpointSlices:

```bash
kubectl get endpointslices
```

---

## 4. Pod is not running

Check:

```bash
kubectl get pods
```

Then:

```bash
kubectl describe pod <pod-name>
```

Check logs:

```bash
kubectl logs <pod-name>
```

---

## 5. DNS resolves incorrectly

Check:

```bash
dig app.navaneethkrishna.me
```

and:

```bash
nslookup app.navaneethkrishna.me
```

Then verify the Route 53 record:

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID>
```

---

# 🔐 Security Best Practices

This project involves AWS credentials, Kubernetes and DNS infrastructure, so security is important.

### Never commit AWS credentials

Avoid:

```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

Use IAM roles instead.

### Recommended architecture

```text
EKS
 │
 ├── AWS Load Balancer Controller
 │        │
 │        └── IAM Role
 │
 └── ExternalDNS
          │
          └── IAM Role
                    │
                    ▼
                 Route 53
```

This follows the principle of least privilege.

---

# 🛡️ Recommended `.gitignore`

Create a `.gitignore` file:

```gitignore
# AWS
.aws/
*.pem
*.key
credentials
config

# Environment files
.env
.env.*
!.env.example

# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json

# Kubernetes secrets
secret.yaml
secrets.yaml

# Logs
*.log

# OS files
.DS_Store
Thumbs.db
```

> `.gitignore` prevents future accidental commits. It does not remove secrets that were already committed to Git history.

---

# 🧹 Deployment Cleanup

When you are finished with the project, remove Kubernetes resources:

```bash
kubectl delete -f k8s/
```

If you created the cluster specifically for this project:

```bash
eksctl delete cluster \
  --name eks-ingress-demo \
  --region us-east-1
```

Also verify that AWS resources such as Load Balancers and Route 53 records are no longer required.

---

# 📊 Request Flow

The complete request flow is:

```text
                    USER
                     │
                     │
                     ▼
          app.navaneethkrishna.me
                     │
                     ▼
               Route 53
                     │
                     │ DNS
                     ▼
           AWS Load Balancer
                     │
                     ▼
        AWS Load Balancer Controller
                     │
                     ▼
          Kubernetes Ingress
                     │
                     ▼
             Kubernetes Service
                     │
                     ▼
                  Pod
                     │
                     ▼
               Application
```

---

# 💡 What This Project Demonstrates

This project demonstrates practical knowledge of:

* Amazon EKS
* Kubernetes
* Kubernetes Ingress
* AWS Load Balancer
* AWS Load Balancer Controller
* Route 53
* ExternalDNS
* DNS automation
* Kubernetes Services
* Kubernetes Deployments
* IAM
* AWS CLI
* kubectl
* Cloud networking
* Infrastructure automation

---

# 🎯 DevOps Concepts Demonstrated

The project is useful for understanding how multiple DevOps components work together:

```text
                    AWS
                     │
              ┌──────┴──────┐
              │             │
           Route 53        EKS
              │             │
              │       ┌─────┴─────┐
              │       │           │
              │    Ingress      Services
              │       │           │
              │       └─────┬─────┘
              │             │
              └─────── Load Balancer
                            │
                           Pods
```

This provides a foundation for more advanced deployments involving:

* HTTPS/TLS
* AWS Certificate Manager
* CI/CD
* Jenkins
* Argo CD
* Helm
* Prometheus
* Grafana
* GitOps
* Blue/Green deployments
* Canary deployments

---

# 👨‍💻 Author

**Navaneeth Krishna**

GitHub:

`https://github.com/Navaneethkrishna-coder`

Portfolio:

`https://navaneethkrishna.me`

---

# ⭐ Project

If this project helped you understand **EKS, Ingress, Route 53 and ExternalDNS**, consider giving the repository a ⭐.

**GitHub Repository:**

`https://github.com/Navaneethkrishna-coder/EKS-Ingress-route53-Demo`
