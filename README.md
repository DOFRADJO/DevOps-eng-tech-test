# DevOps Engineer Technical Test - PHP-FPM on Cloud Run

This repository contains the solution for the DevOps Engineer Technical Test. The test assesses skills in infrastructure as code (Terraform), CI/CD pipeline development (GitHub Actions), and Bash scripting[cite: 1]. The project involves deploying a PHP-FPM application with Nginx within the context of Cloud SQL, Cloud Run, a static file bucket, and a Cloud Load Balancer[cite: 1].

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
6. [Accessing the Application](#accessing-the-application)
7. [Retrieving Public IP (Bash Script)](#retrieving-public-ip-bash-script)
8. [Troubleshooting Potential Issues](#troubleshooting-potential-issues)
9. [Challenges Encountered & Solutions](#challenges-encountered--solutions)
10. [Future Improvements (Production Ready)](#future-improvements-production-ready)
11. [Additional Notes](#additional-notes)

## 1. Project Overview

This project focuses on deploying a simple PHP-FPM web application, served by Nginx, to Google Cloud Run. Key components include:

* **Infrastructure as Code (IaC)**: Terraform is used to create and manage all necessary Google Cloud resources[cite: 1]. This includes a Cloud SQL instance (MySQL), a Cloud Storage bucket for static files, the Cloud Run service itself, and a Cloud Load Balancer to route traffic to Cloud Run[cite: 1].
* **CI/CD Pipeline**: GitHub Actions automate the build, push, and deployment process[cite: 1]. Upon code push, the pipeline builds the Docker image, pushes it to Google Container Registry, and deploys the application to Cloud Run[cite: 1]. Environment variables for sensitive information are managed using GitHub secrets[cite: 1].
* **Bash Scripting**: A Bash script is provided to retrieve the public IP address of the deployed Cloud Run service[cite: 1]. It includes error handling, argument parsing for adaptability, and logging capabilities[cite: 1].

The goal is to demonstrate a well-documented and well-commented solution, prioritizing quality over quantity within the given time limit[cite: 1].

## 2. Architecture

The solution deploys the following Google Cloud resources:

* **Google Cloud SQL (MySQL)**: A managed MySQL database instance serves as the backend for the PHP application[cite: 1].
* **Google Cloud Storage**: A bucket designated for serving static files[cite: 1].
* **Google Cloud Run**: A fully managed compute platform that automatically scales your stateless containers. The application runs here, with Nginx proxying requests to PHP-FPM[cite: 1].
* **Google Cloud Load Balancing (HTTP(S))**: A global load balancer routes external traffic to the Cloud Run service, enabling custom domains and SSL termination if needed[cite: 1].

A high-level flow of requests would be:
`User Request` -> `Cloud Load Balancer` -> `Cloud Run Service` (Nginx serves static content or proxies PHP requests to PHP-FPM) -> `Cloud SQL` (for database interactions).

## 3. Prerequisites

Before setting up and deploying this project, ensure you have the following installed and configured:

* **Google Cloud SDK (gcloud CLI)**: [Installation Guide](https://cloud.google.com/sdk/docs/install)
* **Terraform**: [Installation Guide](https://developer.hashicorp.com/terraform/downloads)
* **Docker Desktop (or Docker Engine)**: [Installation Guide](https://www.docker.com/products/docker-desktop)
* A **Google Cloud Project** with [billing enabled](https://cloud.google.com/billing/docs/how-to/enable-billing).
* A **GitHub account** and a new **public GitHub repository** for this project[cite: 1].

## 4. Project Setup

### Google Cloud Setup

1.  **Authenticate `gcloud` and set project**:
    ```bash
    gcloud auth login
    gcloud config set project YOUR_GCP_PROJECT_ID
    gcloud auth application-default login # For Terraform to authenticate to GCP
    ```
    Replace `YOUR_GCP_PROJECT_ID` with your actual Google Cloud Project ID.

2.  **Enable necessary APIs**:
    ```bash
    gcloud services enable \
      run.googleapis.com \
      sqladmin.googleapis.com \
      compute.googleapis.com \
      containerregistry.googleapis.com \
      iam.googleapis.com \
      servicenetworking.googleapis.com # Required if you plan to use VPC Access Connector for private IP connectivity to Cloud SQL
    ```

3.  **Create a Service Account for GitHub Actions**:
    This service account will be used by the GitHub Actions workflow to deploy resources.
    ```bash
    # Create the service account
    gcloud iam service-accounts create github-actions-sa \
      --display-name "GitHub Actions Service Account for DevOps Test" \
      --project YOUR_GCP_PROJECT_ID

    # Grant necessary IAM roles to the service account
    gcloud projects add-iam-policy-binding YOUR_GCP_PROJECT_ID \
      --member="serviceAccount:github-actions-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com" \
      --role="roles/run.admin" # Allows deploying and managing Cloud Run services
    gcloud projects add-iam-policy-binding YOUR_GCP_PROJECT_ID \
      --member="serviceAccount:github-actions-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com" \
      --role="roles/storage.admin" # Allows pushing Docker images to Container Registry (GCR)
    gcloud projects add-iam-policy-binding YOUR_GCP_PROJECT_ID \
      --member="serviceAccount:github-actions-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com" \
      --role="roles/iam.serviceAccountUser" # Allows the SA to act as other service accounts (e.g., Cloud Run service identity)
    gcloud projects add-iam-policy-binding YOUR_GCP_PROJECT_ID \
      --member="serviceAccount:github-actions-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com" \
      --role="roles/cloudsql.client" # Allows connecting to Cloud SQL instances
    # If using VPC Access Connector for private Cloud SQL connection, add:
    # gcloud projects add-iam-policy-binding YOUR_GCP_PROJECT_ID \
    #   --member="serviceAccount:github-actions-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com" \
    #   --role="roles/compute.networkUser"
    
    # Create and download the JSON key for the service account
    # IMPORTANT: Save this file securely and NEVER commit it to your repository!
    gcloud iam service-accounts keys create ./github-actions-sa-key.json \
      --iam-account=github-actions-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com \
      --project YOUR_GCP_PROJECT_ID
    ```
    The content of `github-actions-sa-key.json` will be used for your `GCP_SA_KEY` GitHub Secret.

### GitHub Setup

1.  **Create a new public GitHub repository**.
2.  Navigate to your repository's `Settings` -> `Secrets and variables` -> `Actions`.
3.  Add the following **repository secrets**:
    * `GCP_PROJECT_ID`: Your Google Cloud Project ID (e.g., `my-php-app-12345`).
    * `GCP_SA_KEY`: The **entire JSON content** (starting from `{` and ending with `}`) of the `github-actions-sa-key.json` file you downloaded.
    * `DB_PASSWORD`: The password you want to set for your Cloud SQL database user. This will be securely injected into the Cloud Run environment.

### Terraform Environment Variables

For local Terraform execution, you should define your variables. You can do this by:

1.  **Setting environment variables (recommended for sensitive data)**:
    ```bash
    export TF_VAR_gcp_project_id="YOUR_GCP_PROJECT_ID"
    export TF_VAR_cloud_sql_user_password="YOUR_DB_PASSWORD" # This will be overridden by GitHub Secrets in CI/CD
    export TF_VAR_gcp_region="us-central1" # Or your chosen region
    export TF_VAR_cloud_sql_instance_name="my-php-app-sql"
    export TF_VAR_cloud_sql_database_name="phpappdb"
    export TF_VAR_cloud_sql_user_name="phpappuser"
    export TF_VAR_static_bucket_name="my-php-app-static-bucket"
    export TF_VAR_cloud_run_service_name="my-php-app-service"
    ```
2.  **Using a `terraform.tfvars` file (less secure for sensitive data, but convenient for non-sensitive variables)**:
    Create a file named `terraform.tfvars` in your Terraform root directory:
    ```terraform
    gcp_project_id          = "YOUR_GCP_PROJECT_ID"
    cloud_sql_user_password = "YOUR_DB_PASSWORD"
    gcp_region              = "us-central1"
    cloud_sql_instance_name = "my-php-app-sql"
    cloud_sql_database_name = "phpappdb"
    cloud_sql_user_name     = "phpappuser"
    static_bucket_name      = "my-php-app-static-bucket"
    cloud_run_service_name  = "my-php-app-service"
    ```
    **Remember to add `terraform.tfvars` to your `.gitignore` if it contains sensitive information.**

## 5. Deployment Instructions

### Infrastructure Deployment (Terraform)

1.  **Navigate to the Terraform root directory** (where your `main.tf` and `modules/` folders are).
2.  **Initialize Terraform**: This prepares your working directory, downloads provider plugins, and configures the remote backend for state management.
    ```bash
    terraform init
    ```
    Ensure you have set up a GCS bucket for Terraform state management (e.g., `gs://your-terraform-state-bucket`) and updated your `backend "gcs"` configuration in `main.tf`.
3.  **Review the deployment plan**: This command shows you what resources Terraform will create, modify, or destroy.
    ```bash
    terraform plan
    ```
4.  **Apply the configuration**: This will provision all the Google Cloud infrastructure.
    ```bash
    terraform apply
    ```
    Type `yes` when prompted to confirm the execution.
    This step will deploy the Cloud SQL instance, Cloud Storage bucket, the Cloud Run service (as a placeholder initially, the actual image will be deployed by CI/CD), and the Cloud Load Balancer.

### Application Deployment (CI/CD)

The application code (PHP script, Nginx config, Dockerfile) is deployed automatically via GitHub Actions upon a push to the `main` branch[cite: 1].

1.  **Push your code** to the `main` branch of your GitHub repository. This includes:
    * `src/index.php` (your simple PHP application)
    * `nginx/default.conf` (Nginx configuration)
    * `Dockerfile` (for building the application image)
    * `.github/workflows/main.yml` (your CI/CD workflow definition)
2.  **Monitor the workflow**: Go to the `Actions` tab in your GitHub repository. You should see a workflow run triggered by your push.
3.  The workflow will perform the following steps:
    * Check out the code[cite: 1].
    * Authenticate to Google Cloud using the provided service account key secret.
    * Build the Docker image based on your `Dockerfile`[cite: 1].
    * Push the built image to Google Container Registry (GCR)[cite: 1].
    * Deploy the `latest` tagged image to your Google Cloud Run service, injecting necessary environment variables like database credentials from GitHub secrets[cite: 1].

## 6. Accessing the Application

Once both the Terraform infrastructure and the GitHub Actions application deployment are complete:

1.  **Via Load Balancer IP**:
    The public IP address of the HTTP(S) Load Balancer will be displayed as a Terraform output. After `terraform apply`, look for the `load_balancer_ip` output. You can access your application by navigating to `http://<LOAD_BALANCER_IP>` in your web browser.

2.  **Via Cloud Run URL (Direct Access)**:
    The direct URL of the Cloud Run service will also be available as a Terraform output. Look for the `cloud_run_url` output. You can access your application directly via this URL.

## 7. Retrieving Public IP (Bash Script)

A Bash script `get-cloudrun-ip.sh` is provided to programmatically retrieve the public endpoint of your deployed application. It will attempt to get the Load Balancer IP first, falling back to the Cloud Run service URL if the Load Balancer IP is not found.

1.  **Make the script executable**:
    ```bash
    chmod +x get-cloudrun-ip.sh
    ```
2.  **Run the script**:
    You can run the script with default values (if configured in the script) or provide arguments:
    ```bash
    # Using default values (make sure they are set in the script or via env vars)
    ./get-cloudrun-ip.sh

    # Providing arguments for project, service name, and region
    ./get-cloudrun-ip.sh --project YOUR_GCP_PROJECT_ID --service my-php-app-service --region us-central1
    ```
    Replace `YOUR_GCP_PROJECT_ID`, `my-php-app-service`, and `us-central1` with your actual configuration details. The script includes error handling and logs execution details[cite: 1].

## 8. Troubleshooting Potential Issues

Here are some common issues you might encounter and tips for debugging:

* **Terraform Apply Failures**:
    * **Authentication/Permissions**: Ensure `gcloud auth application-default login` is active and your user/service account has the necessary IAM roles (`Owner`, `Project Editor`, or specific resource roles) on the GCP project.
    * **Resource Naming**: Google Cloud resources like bucket names often need to be globally unique. Check for naming conflicts.
    * **API Not Enabled**: Verify that all required GCP APIs are enabled in your project (e.g., Cloud Run API, Cloud SQL Admin API, Compute Engine API).
    * **State Locking Issues**: If `terraform init` or `terraform apply` fails due to state locking, ensure your GCS backend is correctly configured and you have write permissions to the bucket.
* **GitHub Actions Workflow Failures**:
    * **Service Account Permissions**: This is the most frequent cause. Double-check that the `github-actions-sa` has *all* the required IAM roles (`roles/run.admin`, `roles/storage.admin`, `roles/iam.serviceAccountUser`, `roles/cloudsql.client`, etc.). Refer to the "Google Cloud Setup" section.
    * **Docker Build Errors**: Review the workflow logs carefully for any errors during the `docker build` step. This could indicate issues in your `Dockerfile` or source code.
    * **`gcloud` Command Errors**: Ensure the `gcloud run deploy` command has the correct service name, region, and image path. Check that environment variables are correctly passed.
    * **GitHub Secrets**: Confirm that your `GCP_PROJECT_ID`, `GCP_SA_KEY`, and `DB_PASSWORD` secrets are correctly configured in GitHub and are not empty or malformed.
* **Application Not Accessible / Not Responding**:
    * **Cloud Run Logs**: Access the logs for your Cloud Run service in the Google Cloud Console (`Cloud Run` -> `Services` -> `Your Service` -> `Logs`). Look for application errors from Nginx or PHP-FPM, or database connection issues.
    * **Nginx Configuration**: Verify that your `nginx/default.conf` file is listening on `port 8080` and is correctly configured to proxy requests to PHP-FPM (typically `127.0.0.1:9000`).
    * **Cloud SQL Connectivity**:
        * Check if the `run.googleapis.com/cloudsql-instances` annotation is correctly set on your Cloud Run service with the proper Cloud SQL instance connection name.
        * Ensure your Cloud SQL instance is configured to allow connections from your Cloud Run service (either via Cloud SQL proxy or private IP with VPC Access Connector).
        * Verify database credentials (DB_USER, DB_PASS, DB_NAME) in Cloud Run environment variables.
* **Bash Script Issues**:
    * **Permissions**: Ensure the script is executable (`chmod +x get-cloudrun-ip.sh`).
    * **`gcloud` Availability**: Verify that `gcloud CLI` is installed and authenticated in the environment where you're running the script.
    * **Correct Resource Names**: Double-check that the project ID, service name, and region provided to the script match your deployed resources.

## 9. Challenges Encountered & Solutions

* **Challenge 1: [Describe a specific problem you faced]**
    * _Description:_ Briefly explain the issue (e.g., "Initially, I had trouble with PHP-FPM not starting correctly within the Docker container alongside Nginx.")
    * _Solution:_ Explain how you debugged and resolved it (e.g., "I debugged this by examining the Docker container logs and adjusting the `CMD` command in the Dockerfile to ensure both PHP-FPM and Nginx start correctly and that Nginx could properly proxy to PHP-FPM on `127.0.0.1:9000`.")

* **Challenge 2: [Describe another challenge]**
    * _Description:_ (e.g., "Integrating the Cloud SQL database connectivity with Cloud Run required careful configuration of the `cloudsql-instances` annotation and ensuring the correct database host was used.")
    * _Solution:_ (e.g., "I ensured the Cloud Run service used the Cloud SQL connection name (`projects/<PROJECT_ID>/locations/<REGION>/instances/<INSTANCE_NAME>`) for `DB_HOST` via environment variables, leveraging the built-in Cloud SQL Proxy feature of Cloud Run.")

* **Challenge 3: [Any other challenge]**
    * _Description:_
    * _Solution:_

## 10. Future Improvements (Production Ready)

For a production-ready environment, the following features and best practices would be considered:

* **Monitoring and Alerting**: Implement comprehensive monitoring using Google Cloud Monitoring (Stackdriver) and set up alerts for application performance, errors, and resource utilization.
* **Enhanced Security**: [cite: 1]
    * Implement more granular IAM roles with the principle of least privilege.
    * Integrate Google Secret Manager for truly secure storage and retrieval of sensitive data like database credentials, rather than passing them directly as environment variables in the workflow (though GitHub secrets are better than plain text).
    * Utilize container image vulnerability scanning (e.g., Cloud Build's built-in scanning or third-party tools like Trivy).
    * Consider VPC Service Controls for data exfiltration prevention.
* **Disaster Recovery (DR) Strategy**: [cite: 1]
    * Develop a formal disaster recovery plan, possibly involving multi-region deployments for high availability and resilience.
    * Implement robust database backup and restore procedures, including point-in-time recovery.
    * Define clear Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO).
    * (Further details would be documented in a separate `dr.md` file.)
* **Continuous Delivery (CD) Automation**: [cite: 1]
    * Explore using Terraform Cloud or similar tools for continuous deployment of infrastructure changes, integrating directly with VCS.
    * Integrate Cloud Build into the CI/CD pipeline for container image building for more GCP-native approach[cite: 1].
* **Cost Optimization**: Implement autoscaling policies, rightsizing of Cloud SQL instances, and leveraging committed use discounts where applicable.
* **Infrastructure Testing**: Incorporate more advanced testing for Terraform configurations, such as static analysis (`terraform validate`, `terraform fmt`), and potentially integration tests with tools like `Terratest` or `InSpec`.
* **Custom Domain and SSL**: Configure a custom domain for the application and manage SSL certificates through the Load Balancer using Google-managed certificates.
* **Environment Management**: Utilize separate Terraform workspaces or dedicated GCP projects/folders for `development`, `staging`, and `production` environments to manage configurations and deployments distinctly.

## 11. Additional Notes

(Use this section or an `extra.md` file to add anything else interesting you'd like to showcase, such as specific design choices, alternative approaches considered, or any minor optimizations/features you implemented.)
