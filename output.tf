output "public_ip" {
  value = aws_eip.pritunlvpn_eip.public_ip
}

output "security_group_id" {
  value = aws_security_group.pritunlvpn.id
}
