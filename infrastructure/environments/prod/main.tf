module "infrastructure" {
  source = "../../"

  aws_region      = var.aws_region
  environment     = "prod"
  app_name        = var.app_name
  container_port  = var.container_port
  container_cpu   = var.container_cpu
  container_memory = var.container_memory
  desired_count   = var.desired_count
  min_capacity    = var.min_capacity
  max_capacity    = var.max_capacity
  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn
  vpc_cidr        = var.vpc_cidr
  availability_zones = var.availability_zones

  tags = merge(
    var.tags,
    {
      Environment = "prod"
    }
  )
}

