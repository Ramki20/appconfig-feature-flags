variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (derived from Git branch name)"
  type        = string
}

variable "config_file_name" {
  description = "Configuration file name without extension"
  type        = string
}

variable "config_content" {
  description = "JSON content of the configuration file"
  type        = string
}

variable "config_version" {
  description = "Version of the configuration"
  type        = string
}