output "asg_arn" {
  value = aws_autoscaling_group.clients.arn
}

output "asg_id" {
  value = aws_autoscaling_group.clients.id
}

output "asg_name" {
  value = aws_autoscaling_group.clients.name
}
