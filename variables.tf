variable "name" {
  type        = string
  description = "Name of the PritunlVPN Server"
}

variable "region" {
  type        = string
  description = "Region of the PritunlVPN server"
}

variable "tags" {
  type        = map
  description = "Map of tags to apply to supported resources"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "pritunlvpn_ami_map" {
  type        = map
  description = "Map of Centos 8 official AMIs"

  default = {
    us-east-1      = "ami-01ca03df4a6012157",
    us-east-2      = "ami-000e7ce4dd68e7a11",
    us-west-1      = "ami-04179d30492b778ad",
    us-west-2      = "ami-0157b1e4eefd91fd7",
    af-south-1     = "ami-059c85867d88036bf",
    ap-east-1      = "ami-0a5c028e5b48c5b03",
    ap-south-1     = "ami-056940cb2a7bb6d71",
    ap-northeast-1 = "ami-089a156ea4f52a0a3",
    ap-northeast-2 = "ami-09cdc4034bbb65412",
    ap-southeast-1 = "ami-0bfb8f6cdedb56577",
    ap-southeast-2 = "ami-08a0839a09bbc6f20",
    ca-central-1   = "ami-07a182edcd7d04084",
    eu-central-1   = "ami-032025b3afcbb6b34",
    eu-west-1      = "ami-0bfa4fefe067b7946",
    eu-west-2      = "ami-0eee2548cd75b4877",
    eu-west-3      = "ami-05786aa5add3ca7c8",
    eu-south-1     = "ami-00fd0c9036a37a48e",
    eu-north-1     = "ami-0474ce84d449ee66f",
    me-south-1     = "ami-06b01ecfde1a04811",
    sa-east-1      = "ami-005c6439e527f2704"
  }
}

variable "subnet_id" {
  type        = string
  description = "subnet_id to deploy the pritunlvpn server into"
}

variable "key_name" {
  type        = string
  description = "Name of the SSH key to deploy to the PritunlVPN server"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR Allowed to access PritunlVPN"
  default     = "0.0.0.0/0"
}

variable "pritunlvpn_host" {
  type        = string
  description = "DNS/IP Address of the PritunlVPN Server"
  default     = ""
}

variable "backup_bucket_name" {
  type        = string
  description = "S3 Bucket name for pritunl mongodb backups"
  default     = ""
}

variable "backup_file_name" {
  type        = string
  description = "Name of the backup file, for this name date stamp will be added"
  default     = "pritunlmongodb"
}

variable "backup_file_expiration" {
  description = "Days to keep backup config files"
  default     = "90"
}