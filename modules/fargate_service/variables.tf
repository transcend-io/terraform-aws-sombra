variable name {
  description = "The name of the service. Used as a prefix for other resource names"
}

variable cluster_id {
  description = <<EOF
  The id of the ECS cluster this service belongs to.

  Having multiple related services in one service can decrease cost
  by more efficiently using a shared pool of resources.
  EOF
}

variable desired_count {
  type        = number
  description = "The number of tasks to keep alive at all times"
}

variable vpc_id {
  description = "ID of the VPC the alb is in"
}

variable subnet_ids {
  type        = list(string)
  description = "List of subnets tasks can be run in."
}

variable load_balancers {
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = string
  }))

  description = <<EOF
  When using ECS services, the service will ensure that at least
  {@variable desired_count} tasks are running at all times. Because
  there can be multiple tasks running at once, we set up a load
  balancer to ditribute traffic.

  `target_group_arn` is the arn of the target group on that alb that will
  be set to watch over the tasks managed by this service.
  EOF
}

variable tags {
  type        = map(string)
  description = "Tags to set on all resources that support them"
}

variable cpu {
  default     = 512
  description = "How much CPU should be allocated to each app instance?"
}

variable memory {
  default     = 1024
  description = "How much memory should be allocated to each app instance?"
}

variable container_definitions {
  type        = string
  description = "JSON encoded list of container definitions"
}

variable additional_task_policy_arns {
  type        = list(string)
  description = "IAM Policy arns to be added to the tasks"
}

variable additional_task_policy_arns_count {
  type        = number
  description = "The number of items in var.additional_task_policy_arns. Terraform is not quite smart enough to figure this out on its own."
}

variable alb_security_group_ids {
  type        = list(string)
  description = "The ids of all security groups set on the ALB. We require that the tasks can only talk to the ALB"
}

variable deploy_env {
  type        = string
  description = "The environment resources are to be created in. Usually dev, staging, or prod"
}

variable aws_region {
  type        = string
  description = "The AWS region to create resources in."
  default     = "eu-west-1"
}
