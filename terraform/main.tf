provider "google" {
 project = var.project_id
 region  = var.region
}

module "cloud_sql" {
 source        = "./modules/cloud_sql"
 instance_name = var.sql_instance_name
 region        = var.region
 database_name = var.database_name
 db_password   = var.db_password
}

resource "google_storage_bucket" "static_file" {
  name          = var.bucket_name
  location      = var.region
}

resource "google_cloud_run_service" "php_app" {
  name     = "php-app"
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
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