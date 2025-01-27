variable "region" {
  type        = string
}

variable "key_name" {
  type        = string
}

variable "public_key" {
  type        = string
}

variable "instance_type" {
  type        = string
}

variable "ami" {
  type        = string
}

variable "security_group" {
  type        = string
}

variable "description_sg" {
  type        = string
}

variable "auto_scaling_group_name" {
  type        = string
}

variable "max_size" {
  type        = number
}

variable "min_size" {
  type        = number
}

variable "production" {
  type        = bool
}