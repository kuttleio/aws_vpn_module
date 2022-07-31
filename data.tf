data "template_file" "pritunlvpn_user_data" {
  template = "${file("${path.module}/user_data.sh.tpl")}"

  vars = {
    host               = var.pritunlvpn_host != "" ? var.pritunlvpn_host : aws_eip.pritunlvpn_eip.public_ip
    eip_allocation_id  = aws_eip.pritunlvpn_eip.id
    backup_bucket_name = aws_s3_bucket.pritunlvpn_backup.bucket
    backup_file_name   = var.backup_file_name
  }
}

data "aws_subnet" "vpc_lookup" {
  id = var.subnet_id
}
