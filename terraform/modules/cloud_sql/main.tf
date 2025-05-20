resource "google_sql_database_instance" "default" {
  name             = "my-sql-instance"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.default.name
  password_wo = var.db_password
}

resource "google_sql_database" "app_db" {
  name     = "app_database"
  instance = google_sql_database_instance.default.name
}