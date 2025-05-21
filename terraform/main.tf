
# Configure the Google Cloud provider
# This tell terraform to use the Google provider and set the active project and region
provider "google" {
  project = var.project_id  # The GCP project ID is supplied via a variable
  region  = var.region      # The GCP region, also from a variables
}


# Cloud SQL Module
# we use a reusable module for Cloud SQL (MySQL) configuration.
#the module is located in ./modules/cloud_sql
module "cloud_sql" {
  source        = "./modules/cloud_sql"         # path to the module
  instance_name = var.sql_instance_name         # Name of the SQL instance
  region        = var.region                    # region where the SQL instance is deployed
  database_name = var.database_name             # name of the MySQL database
  db_password   = var.db_password               # Password for the root user (sensitive)
}


# Cloud Storage Bucket
# This resource creates a GCS (Google Cloud Storage) bucket to store static file
resource "google_storage_bucket" "static_file" {
  name     = var.bucket_name  # Bucket name passed from a variables
  location = var.region       # region where the buket will be created
}


# Cloud Run Service
# This resource deploy a containerised application (PHP-FPM with Nginx) to Cloud Run
resource "google_cloud_run_service" "php_app" {
  name     = "php-app"      # Name of the Cloud Run service
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image       # Container image stored in Container Registry or artifact registry
        ports {
          container_port = 8080           # Exposes port 8080 inside the container (default for HTTP apps)
        }
      }
    }
  }

  traffic {
    percent         = 100                 # Routes 100% of traffic to the latest revision
    latest_revision = true                # to insure traffic goes to the most recent deployment
  }
}

#this resources is for the questions of load balancer (the alternative)
#because it's difficult to create a load balencer directly from GCP to cloud run using only
#teraform
resource "google_cloud_run_service_iam_member" "invoker" {
  service    = google_cloud_run_service.php_app.name
  location   = var.region
  role       = "roles/run.invoker"
  member     = "allUsers"
}

#but with more times, we can use and combine NEG, Url map, backend associate to NEG.... for this situation
