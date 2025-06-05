# Locally lunch a PHP analysis tool
This first version of the branch is to lunch locally analysis tool for PHP (PHPStan)
## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Setup](#setup)
3. [Troubleshooting Potential Issues](#troubleshooting-potential-issues)

## Prerequisites

Before setting up this project, ensure that you have the following installed and configured:

* **PHP version >=8.3.0**: [Installation Guide](https://www.php.net/downloads.php)

## Setup
### GitHub Setup
Clone this repo an switch to the right branch.
```bash
git clone https://github.com/bw-gaming/bluewindow-hosting-php.git
cd bluewindow-hosting-php
git checkout feature/NEX-13214
```


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
