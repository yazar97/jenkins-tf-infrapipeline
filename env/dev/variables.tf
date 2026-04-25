variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
}
/*
variable "env" {
  description = "Environment name (dev/test/prod)"
  type        = string
}
*/
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}
/*
variable "subnets" {
  description = "Map of subnets with name, cidr, and region"
  type = map(object({
    name   = string
    cidr   = string
    region = string
  }))
}

*/