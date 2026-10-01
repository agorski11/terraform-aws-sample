locals {
  name = "${var.project}-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  cidr_block         = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway
}

module "static_site" {
  source = "../../modules/static-site"

  name                = local.name
  domain_name         = var.site_domain_name
  acm_certificate_arn = var.site_acm_certificate_arn
  route53_zone_id     = var.route53_zone_id
}

module "media_pipeline" {
  source = "../../modules/media-pipeline"

  name           = local.name
  min_confidence = var.moderation_min_confidence
}
