variable "project_id" {
 type        = string
 description = "Id of GCP project"
}

variable "region" {
 type        = string
 description = "region where our project should be located"
 default     = "europe-west1"
}

variable "container_image" {
 type        = string
 description = "this is for the fuull name off the docker image"
}

variable "db_password" {
 type = string
 description = "the pass of the database that the root user will use to connect"
}

variable "database_name" {
 type        = string
 description = "the name of the sql database"
}

variable "instance_name" {
 type        = string
 description = "name of the instance where we will initialized database"
}