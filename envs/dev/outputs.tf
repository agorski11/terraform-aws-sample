output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "site_url" {
  value = module.static_site.url
}

output "site_bucket" {
  value = module.static_site.bucket_name
}

output "media_bucket" {
  value = module.media_pipeline.media_bucket_name
}

output "moderation_results_queue_url" {
  value = module.media_pipeline.results_queue_url
}
