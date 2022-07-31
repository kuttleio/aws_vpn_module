## aws_ec2_pritunl_vpn

This module will create Highly Available Pritunl VPN Access Server with ElasticIP and ASG `min1/max1` with auto Backup and Restore of configuration from S3.
 
### Usage example:
 ```bash
 module "aws_pritunl_ha" {
   source             = ""
   region             = var.region
   name               = var.name
   tags               = var.tags
   subnet_id          = data.terraform_remote_state.vpc.public_subnet_ids
   key_name           = aws_key_pair.aws_key_pair.key_name
   allowed_cidr       = var.allowed_cidr
   backup_bucket_name = var.backup_bucket_name
 }
```
