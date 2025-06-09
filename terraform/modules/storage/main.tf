# Cloud Storage Buckets

# Content Storage - for EPUB files, images, etc.
resource "google_storage_bucket" "content" {
  name          = "${var.project_id}-content-${var.name_suffix}"
  location      = var.storage_location
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = var.labels
}

# Audio Storage - for TTS generated audio files
resource "google_storage_bucket" "audio" {
  name          = "${var.project_id}-audio-${var.name_suffix}"
  location      = var.storage_location
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 7
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = var.labels
}

# Backup Storage - for database backups and other backups
resource "google_storage_bucket" "backup" {
  name          = "${var.project_id}-backup-${var.name_suffix}"
  location      = var.storage_location
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 90
      matches_storage_class = ["NEARLINE"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = var.labels
}

# Pub/Sub Topics and Subscriptions

# Topic for real-time events
resource "google_pubsub_topic" "events" {
  name    = "${var.project_id}-events-${var.name_suffix}"
  project = var.project_id

  message_retention_duration = "604800s" # 7 days

  labels = var.labels
}

resource "google_pubsub_subscription" "events_subscription" {
  name    = "${var.project_id}-events-sub-${var.name_suffix}"
  topic   = google_pubsub_topic.events.name
  project = var.project_id

  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false
  ack_deadline_seconds       = 20

  expiration_policy {
    ttl = "2678400s" # 31 days
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = var.labels
}

# Topic for analytics events
resource "google_pubsub_topic" "analytics" {
  name    = "${var.project_id}-analytics-${var.name_suffix}"
  project = var.project_id

  message_retention_duration = "604800s" # 7 days

  labels = var.labels
}

resource "google_pubsub_subscription" "analytics_subscription" {
  name    = "${var.project_id}-analytics-sub-${var.name_suffix}"
  topic   = google_pubsub_topic.analytics.name
  project = var.project_id

  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false
  ack_deadline_seconds       = 60

  expiration_policy {
    ttl = "2678400s" # 31 days
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = var.labels
}

# Topic for recommendation model training
resource "google_pubsub_topic" "ml_training" {
  name    = "${var.project_id}-ml-training-${var.name_suffix}"
  project = var.project_id

  message_retention_duration = "604800s" # 7 days

  labels = var.labels
}

resource "google_pubsub_subscription" "ml_training_subscription" {
  name    = "${var.project_id}-ml-training-sub-${var.name_suffix}"
  topic   = google_pubsub_topic.ml_training.name
  project = var.project_id

  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false
  ack_deadline_seconds       = 300

  expiration_policy {
    ttl = "2678400s" # 31 days
  }

  retry_policy {
    minimum_backoff = "30s"
    maximum_backoff = "600s"
  }

  labels = var.labels
}

# Cloud Tasks Queue for async jobs
resource "google_cloud_tasks_queue" "async_jobs" {
  name     = "${var.project_id}-async-jobs-${var.name_suffix}"
  location = var.region
  project  = var.project_id

  rate_limits {
    max_concurrent_dispatches = 10
    max_dispatches_per_second = 100
  }

  retry_config {
    max_attempts       = 5
    max_retry_duration = "3600s"
    max_backoff        = "3600s"
    min_backoff        = "5s"
    max_doublings      = 5
  }
}