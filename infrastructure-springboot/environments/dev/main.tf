module "infrastructure" {
  source = "../../"

  aws_region      = var.aws_region
  environment     = "dev"
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
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
  db_instance_class = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  allowed_ip_cidr = var.allowed_ip_cidr
 
  tags = merge(
    var.tags,
    {
      Environment = "dev"
    }
  )
}

