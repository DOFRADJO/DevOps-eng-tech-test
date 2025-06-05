# DevOps Engineer Technical Test - proposed solution DONALD

This repository contains the solution for the DevOps Engineer Technical Test. The test assesses skills in infrastructure as code (Terraform), CI/CD pipeline development (GitHub Actions), and Bash scripting. The project involves deploying a PHP-FPM application with Nginx within the context of Cloud SQL, Cloud Run, a static file bucket, and a Cloud Load Balancer.

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Project Setup](#project-setup)
   - [Google Cloud Setup](#google-cloud-setup)
   - [GitHub Setup](#github-setup)
   - [Terraform Environment Variables](#terraform-environment-variables)
5. [Deployment Instructions](#deployment-instructions)
   - [Infrastructure Deployment (Terraform)](#infrastructure-deployment-terraform)
   - [Application Deployment (CI/CD)](#application-deployment-cicd)
6. [Retrieving Public IP (Bash Script)](#retrieving-public-ip-bash-script)
7. [Troubleshooting Potential Issues](#troubleshooting-potential-issues)
8. [Challenges Encountered & Solutions](#challenges-encountered--solutions)
9. [Future Improvements (Production Ready)](#future-improvements-production-ready)

## Project Overview

This project focuses on deploying a simple PHP-FPM web application, served by Nginx, to Google Cloud Run. Key components include:

* **Infrastructure as Code (IaC)**: Terraform is used to create and manage all necessary Google Cloud resource
* **CI/CD Pipeline**: GitHub Actions automate the build, push, and deployment process. Environment variables for sensitive information are managed using GitHub secrets.
* **Bash Scripting**: A Bash script is provided to retrieve the public IP address of the deployed Cloud Run services. It includes error handling, argument parsing for adaptability, and logging capabilities.

## Architecture

The solution deploys the following Google Cloud resources:

* **Google Cloud SQL (MySQL)**: A managed MySQL database instance servers as the backend for the PHP aplication.
* **Google Cloud Storage**: A bucket designated for serving static files.
* **Google Cloud Run**

A high-level flow of requests would be:
`User Request` -> `Cloud Run Service` -> `Cloud SQL` (for database interactions).

## Prerequisites

Before setting up and deploye this project, ensure that you have the following installed and configured:

* **Google Cloud SDK (gcloud CLI)**: [Installation Guide](https://cloud.google.com/sdk/docs/install)
* **Terraform**: [Installation Guide](https://developer.hashicorp.com/terraform/downloads)
* **Docker Desktop (or Docker Engine)**: [Installation Guide](https://www.docker.com/products/docker-desktop)
* A **Google Cloud Project** with billing enabled.
* A **GitHub account** and a new **public GitHub repository** for this project.

## Project Setup
### GitHub Setup

1.  **Create a new public GitHub repository**.
2.  Navigate to your repository's `Settings` -> `Secrets and variables` -> `Actions`.
3.  Add the following **repository secrets**:
    * `GCP_CREDENTIALS`: **entire JSON content** of your iam that you have gave role o GCP ID (e.g., `my-php-app-12345`).
    * `GCP_REGION`: The region where your Google Cloud Project located
    * `DB_PASSWORD`: The password you want to set for your Cloud SQL database user

### Terraform Environment Variables
for local Terraform execution, you should define your variable. You can do this by:
 **Using a `terraform.tfvars` file (less secure for sensitive data, but convenient for non-sensitive variables)**:
    Create a file named `terraform.tfvars` in your Terraform root directory:
    ```terraform
    project_id        = "your id project"
    region            = "region"
    db_password       = "password"
    bucket_name       = "${var.project_id}_static_file_bucket"
    sql_instance_name = "${var.project_id}_sql_instance"
    database_name     = "${var.project_id}_db"
    ```
    **Remember to add `terraform.tfvars` to your `.gitignore` if it contains sensitive information.**

## Deployment Instructions

### Infrastructure Deployment (Terraform)

1.  **Navigate to the Terraform root directory** (where your `main.tf` and `modules/` folders is).
2.  **Initialize Terraform**: This prepares your working directory, downloads provider plugins, and configures the remote backend for state management.
    ```bash
    terraform init
    ```
3. **Review the deployment plan**: 
    ```bash
    terraform plan
    ```
4.  **Apply the configuration**: This will provision all the Google Cloud infrastructure.
    ```bash
    terraform apply
    ```
    Type `yes` when prompted to confirm the execution.
    This step will deploy the Cloud SQL instance, Cloud Storage bucket, the Cloud Run service

### Application Deployment (CI/CD)

The application code (PHP script, Nginx config, Dockerfile) is deployed automatically via GitHub Actions upon a push to the `main` branch.

1.  **Push your code** to the `main` branch of your GitHub repository. This includes:
    * `app/index.php`
    * `app/nginx.conf` (Nginx configuration)
    * `app/Dockerfile` (for building the application image)
    * `.github/workflows/main.yml` (your CI/CD workflow definition)
2.  **Monitor the workflow**: Go to the `Actions` tab in your GitHub repository. You should see a workflow run triggered by your push.
3.  The workflow will perform the following steps:
    * Check out the code.
    * Authenticate to Google Cloud using the provided service account key secret.
    * Build the Docker image based on your `Dockerfile`.
    * Push the built image to Google Container Registry (GCR).
    * Deploy the `latest` tagged image to your Google Cloud Run service, injecting necessary environment variables like database credentials from GitHub secrets.

## Retrieving Public IP (Bash Script)

A Bash script `get-pip-cloudrun.sh` is provided to programmatically retrieve the public endpoint of your deployed application. It will attempt to get the Load Balancer IP first, falling back to the Cloud Run service URL if the Load Balancer IP is not found.

1.  **Make the script executable**:
    ```bash
    chmod +x scripts/get-pip-cloudrun.sh
    ```
2. **Run the script**:
    ```bash
    cd scripts
    .scripts/get-pip-cloudrun.sh 
    ```
## Troubleshooting Potential Issues

Here are some common issues you might encounter and tips for debugging:

* **Terraform Apply Failures**:
    * **Authentication/Permissions**: Ensure `gcloud auth application-default login` is active 
    * **API Not Enabled**: Verify that all required GCP APIs are enabled in your project.
* **GitHub Actions Workflow Failures**:
    * **Service Account Permissions**: This is the most frequent cause. Double-check that the `github-actions-sa` has *all* the required IAM roles (`roles/run.admin`, `roles/storage.admin`, `roles/iam.serviceAccountUser`, `roles/cloudsql.client`, etc.). Refer to the "Google Cloud Setup" section.
    * **Docker Build Errors**: Review the logs for any error during the `docker build` step
* **Bash Script Issues**:
    * **Permissions**: Ensure the script is executable (`chmod +x get-pip-cloudrun.sh`).

## Challenges Encountered & Solutions

* **Challenge 1: no billing account**
    * _Description:_ Without billing acount that are link to my project, not possibilty to run the cloud tird party of challenges
    * _Solution:_ nothing

* **Challenge 2: unable t create load balancer**
    * _Description:_ No possibilty to create ressource load balancer directly with terraform
    * _Solution:_ implement policies rulle member allow to all users

## Future Improvement

For a production-ready environment, the folowing features and best practices would be considered:

* **Monitoring and Alerting**: Implement comprehensive monitoring using Google Cloud Monitoringand set up alerts for application performance, errors, and resource utilisation.
* **Enhanced Security**:
    * Implement more granular IAM roles with the principle of least privilege.
    * Integrate Google Secret Manager for truly secure storage and retrieval of sensitive data like database credentials, rather than passing them directly as environment variables in the workflow
* **Cost Optimization**: Implement autoscaling policies, rightsizing of Cloud SQL instance.
