 # Terrakube on Amazon EKS — DevSecOps Technical Assignment

## Objectives Covered
1. Provision EKS Cluster in a dedicated VPC using Terraform.
2. Deploy Terrakube using official Helm Chart.
3. Applied DevSecOps Best Practices (IRSA, Secrets Handling, Scanning).
4. Execute sample Terraform Plan using Terrakube Workspace.

---

 Prerequisites
- AWS Account (Free Tier eligible)
- AWS CLI configured with IAM user (least-privilege access)
- Terraform v1.6+
- kubectl & Helm installed
- GitHub Actions (for CI/CD Workflow)

---

##  Setup Instructions

### 1. Clone the Repo
``
git clone https://github.com/ASHISH1452/terrakube-sample-project.git
cd terrakube-sample-project

2. ##Initialize & Apply Terraform

terraform init
terraform apply -auto-approve

3. ## Update Kubeconfig

aws eks update-kubeconfig --name terrakube-eks --region us-east-1

4. Run Validation Script

bash test.sh

 5. Teardown Instructions

terraform destroy -auto-approve


Step-by-Step Commands for Terrakube Deployment on EKS


6. Configure AWS CLI (One-Time)

aws configure


2. Initialize Terraform & Apply Infrastructure (EKS + VPC)

terraform init
terraform plan
terraform apply -auto-approve
3. Update Kubeconfig to Access EKS Cluster

aws eks update-kubeconfig --region us-east-1 --name terrakube-eks
4. Verify Cluster Connection

kubectl get nodes
5. Create Namespace for Terrakube

kubectl create namespace terrakube
6. Add Terrakube Helm Repo & Update

helm repo add terrakube https://releasehub.github.io/terrakube-helm-chart/
helm repo update
7. Create LoadBalancer Service for Terrakube UI
(This is only if Helm chart didn’t create LB by default. You manually created it)


# terrakube-ui-lb.yaml
apiVersion: v1
kind: Service
metadata:
  name: terrakube-ui-lb
  namespace: terrakube
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: terrakube-ui
  ports:
    - port: 80
      targetPort: 80


kubectl apply -f terrakube-ui-lb.yaml
8. Install Terrakube via Helm

helm install terrakube terrakube/terrakube -n terrakube --values terrakube-values.yaml
9. Wait for Pods to be Ready


kubectl get pods -n terrakube
kubectl wait --for=condition=Ready pods --all -n terrakube --timeout=300s
10. Get LoadBalancer URL (Terrakube UI)

kubectl get svc terrakube-ui-lb -n terrakube
# Copy EXTERNAL-IP and open in browser.
11. Access Terrakube UI
Open the EXTERNAL-IP in browser.

Register a Workspace.

Execute Terraform Plan from UI.

12. Verify Terrakube Backend (API Service)

kubectl get svc terrakube-api -n terrakube
(Optional) Port-Forward for Local Testing

kubectl port-forward svc/terrakube-api 8080:80 -n terrakube
kubectl port-forward svc/terrakube-ui 3000:80 -n terrakube
Clean-up Commands (Teardown)

terraform destroy -auto-approve
helm uninstall terrakube -n terrakube
kubectl delete namespace terrakube
