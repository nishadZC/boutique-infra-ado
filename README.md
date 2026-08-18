# Infrastructure as Code (IaC) Guide

This directory contains the automated provisioning scripts for the cloud architecture backing the Boutique application.

## Directory Structure

```text
Infrastructure/
└── azure/
    ├── environments/        # Environment-specific deployments (dev, prod, shared)
    └── modules/             # Reusable Terraform modules (AKS, VNet, Postgres)
```

## Terraform Methodology

This project utilizes a **Modular Terraform Architecture**:
- **Modules:** Abstract away complex configurations (e.g., an AKS cluster with AGIC, or a Postgres Flexible server). They are stateless and environment-agnostic.
- **Environments:** Concrete implementations of modules. We separate environments (`dev`, `prod`) to ensure isolation. The `shared` environment holds global resources like Container Registries and centralized tooling (SonarQube).

### State Management
Terraform state is managed securely using **Terraform Cloud**. Each environment connects to a specific Terraform Cloud Workspace (e.g., `boutique-azure-dev`) to execute runs remotely and protect sensitive state data.

## VM Configuration

While Terraform provisions the raw infrastructure, Virtual Machine configuration (like installing the **SonarQube** server) is handled automatically via cloud-init scripts passed to the VM's `custom_data` attribute.

1. Terraform provisions an Ubuntu VM in Azure.
2. It base64 encodes the `setup.sh` script and passes it to the VM.
3. The VM executes the script as root on startup to install Java, PostgreSQL, and SonarQube automatically.
