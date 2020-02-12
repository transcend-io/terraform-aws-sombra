variable name {
  type        = string
  description = <<EOF
  The name of a container. Up to 255 letters (uppercase and lowercase), numbers, hyphens,
  and underscores are allowed. If you are linking multiple containers together in a task
  definition, the name of one container can be entered in the links of another container
  to connect the containers.
  EOF
}

variable image {
  type        = string
  description = <<EOF
  The image used to start a container. This string is passed directly to the Docker daemon.
  Images in the Docker Hub registry are available by default. You can also specify other
  repositories with either repository-url/image:tag or repository-url/image@digest. Up to 255
  letters (uppercase and lowercase), numbers, hyphens, underscores, colons, periods, forward
  slashes, and number signs are allowed.
  EOF
}

variable cpu {
  type        = number
  default     = 512
  description = <<EOF
  The number of cpu units the Amazon ECS container agent will reserve for the container.
  EOF
}

variable memory {
  type        = number
  default     = 1024
  description = <<EOF
  The amount (in MiB) of memory to present to the container. If your container attempts to
  exceed the memory specified here, the container is killed. The total amount of memory reserved
  for all containers within a task must be lower than the task memory value, if one is specified.
  EOF
}

variable containerPorts {
  type        = list(number)
  default     = []
  description = <<EOF
  Port mappings allow containers to access ports on the host container instance to send or receive traffic.
  Each port number given will be mapped from the container to the host over the tcp protocol.
  EOF
}

variable environment {
  type        = map(string)
  default     = {}
  description = <<EOF
  The non-secret environment variables to pass to a container.

  Usage would be something like:
  environment = {
    SOME_ENV_VAR = "123"
    SOME_OTHER_ENV_VAR = "nice"
  }
  EOF
}

variable secret_environment {
  type        = map(string)
  default     = {}
  description = <<EOF
  The secret environment variables to pass to a container.

  Usage would be something like:
  environment = {
    SOME_ENV_VAR = "123"
    SOME_OTHER_ENV_VAR = "nice"
  }

  These will be made into SSM SecureString parameters, which
  will be dynamically fetched and set as env vars on boot.
  EOF
}

variable tags {
  type        = map(string)
  description = "Tags to apply to all resources that support them"
}

variable ssm_prefix {
  type        = string
  description = "Prefix to put in front of all ssm parameter keys"
  default     = "ssm"
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

variable use_cloudwatch_logs {
  type        = bool
  description = "If true, a cloudwatch group will be created and written to."
  default     = true
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable log_configuration {
  type = object({
    logDriver = string
    options   = map(string)
  })
  description = <<EOF
  Log configuration options to send to a custom log driver for the container.
  For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html

  This parameter is ignored if use_cloudwatch_logs is true, and a log group will be automatically
  written to.

  Use log_secrets to set extra options here that should be secret, such as API keys for third party loggers.
  EOF
  default     = null
}

variable log_secrets {
  type        = map(string)
  default     = {}
  description = "Used to add extra options to log_configuration.options that should be secret, such as third party API keys"
}
