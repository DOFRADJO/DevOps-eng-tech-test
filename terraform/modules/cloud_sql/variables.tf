variable "instance_name" {
 type        = string
 description = "name of the instance where we will initialized database"
}

variable "region" {
 type        = string
 description = "region where the instance should be located"
 default     = "europe-west1"
}

variable "database_name" {
 type        = string
 description = "the name of the sql database"
}

variable "db_password" {
 type = string
 description = "the pass of the database that the root user will use to connect"
}