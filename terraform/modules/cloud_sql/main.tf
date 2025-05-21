#resource for creating the instance where we will store our database of the app
resource "google_sql_database_instance" "default" {
  name             = "my-sql-instance"
  database_version = "MYSQL_8_0" #version of mysql database
  region           = var.region

  settings {
    tier = "db-f1-micro" #machine type which is low cost
  }
}

#resource for creating the user "root" who would be able to cnnect to the database
resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.default.name #refer to the instance name
  password_wo = var.db_password
}

#resource for creating the database of our application
resource "google_sql_database" "app_db" {
  name     = "app_database"
  instance = google_sql_database_instance.default.name
}
