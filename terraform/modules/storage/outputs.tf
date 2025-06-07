output "content_bucket_name" {
  description = "Name of the content storage bucket"
  value       = google_storage_bucket.content.name
}

output "content_bucket_url" {
  description = "URL of the content storage bucket"
  value       = google_storage_bucket.content.url
}

output "audio_bucket_name" {
  description = "Name of the audio storage bucket"
  value       = google_storage_bucket.audio.name
}

output "audio_bucket_url" {
  description = "URL of the audio storage bucket"
  value       = google_storage_bucket.audio.url
}

output "backup_bucket_name" {
  description = "Name of the backup storage bucket"
  value       = google_storage_bucket.backup.name
}

output "backup_bucket_url" {
  description = "URL of the backup storage bucket"
  value       = google_storage_bucket.backup.url
}

output "pubsub_topics" {
  description = "Created Pub/Sub topics"
  value = {
    events      = google_pubsub_topic.events.name
    analytics   = google_pubsub_topic.analytics.name
    ml_training = google_pubsub_topic.ml_training.name
  }
}

output "pubsub_subscriptions" {
  description = "Created Pub/Sub subscriptions"
  value = {
    events      = google_pubsub_subscription.events_subscription.name
    analytics   = google_pubsub_subscription.analytics_subscription.name
    ml_training = google_pubsub_subscription.ml_training_subscription.name
  }
}

output "cloud_tasks_queue" {
  description = "Cloud Tasks queue for async jobs"
  value       = google_cloud_tasks_queue.async_jobs.name
}