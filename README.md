# Boutique Deployment Runbook

This guide outlines the steps required to completely tear down and rebuild the Boutique application infrastructure and GitOps deployments from scratch. All previous manual workarounds have been automated within the codebase, meaning you no longer need to run any manual Azure CLI commands during provisioning.

## 1. Complete Teardown (Destroy)

If you have an existing deployment, you should run the destroy pipeline to clean up Azure resources.

1. Navigate to **Azure DevOps > Pipelines**.
2. Run the **Destroy Infrastructure** pipeline.
   - It will run a `terraform plan -destroy`.
   - Once it pauses for manual intervention, review the plan and click **Resume** to approve the actual `terraform apply -destroy`.

## 2. Infrastructure Provisioning

Once the environment is clean, you can recreate the infrastructure.

1. Navigate to **Azure DevOps > Pipelines**.
2. Run the **Boutique Infrastructure Pipeline**.
   - This pipeline provisions the AKS cluster, Azure Key Vault, PostgreSQL Flexible Server, and Application Gateway.
   - **Automated Enhancements:** 
     - The Terraform script now automatically grants itself Key Vault access and provisions the `boutique-db-secret` (with your secure database credentials).
     - It no longer requires you to manually inject the secret via the Azure CLI.

## 3. GitOps Synchronization (Argo CD)

After the infrastructure finishes provisioning, Argo CD handles the cluster configuration and application deployments.

1. The infrastructure pipeline automatically deployed Argo CD and connected it to your `boutique-gitops` repository.
2. In the Argo CD dashboard, verify that the `system-apps` Application is syncing correctly.
   - **Automated Enhancements:**
     - The External Secrets Operator now securely authenticates using **ManagedIdentity** instead of WorkloadIdentity. You do not need to hardcode or update Azure Client IDs in the YAML manifests anymore.
     - The connection strings for the microservices are securely constructed using ExternalSecrets templating, so special characters in your database password (like `@` or `#`) are automatically URL-encoded and won't crash the Node.js applications.
3. Wait for the `system-apps` to turn Green (Healthy).
4. Argo CD will then deploy the `boutique-azure-dev` Application containing your microservices.
5. All pods (including `product-service`, `auth`, `orders`, and `gateway`) should start successfully and connect to the database.

## Troubleshooting

- **Database Connection Issues:** If pods fail to start, check the `boutique-secrets` Kubernetes secret in the `boutique-app` namespace to verify that the templating engine successfully generated the `DATABASE_URL`s.
- **Key Vault Access:** If External Secrets fail to sync, ensure the `aks_principal_id` (the AKS Kubelet Identity) was correctly assigned the `Get` and `List` Key Vault Access Policy in Terraform.
