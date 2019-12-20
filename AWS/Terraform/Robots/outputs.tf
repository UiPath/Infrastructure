output "bastion_public_ip" {
  description = "BastionHost public IP."
  value = "${aws_instance.bastion.public_ip}"
}
