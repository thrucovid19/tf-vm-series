output eip {
    value = aws_eip.management.public_ip
}

output instance_name {
    value = aws_instance.this.id
}

