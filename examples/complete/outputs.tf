output "this_alb_instance_id" {
  description = "The instance ID of ALB."
  value       = module.example.this_alb_instance_id
}

output "this_alb_server_group_id" {
  description = "The ID of ALB server group."
  value       = module.example.this_alb_server_group_id
}

output "this_alb_listener" {
  description = "The ID of ALB http listener."
  value       = module.example.this_alb_listener
}
