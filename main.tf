terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.7.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
}

# Service Account
resource "google_service_account" "main_service_account" {
  project = var.gcp_project
  account_id = "main-service-account"
  display_name = "Service account for simple-reminders app"
}

# Cloud Storage
resource "google_storage_bucket" "cloud_fn_src_bucket" {
  project = var.gcp_project
  location = var.gcp_region
  name = "simple_reminders_src"
}

resource "google_project_iam_member" "src_access" {
  project = var.gcp_project
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.main_service_account.email}"
}

resource "google_project_iam_member" "log_writer" {
  project = var.gcp_project
  role = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.main_service_account.email}"
}

resource "google_project_iam_member" "artifact_reader" {
  project = var.gcp_project
  role = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.main_service_account.email}"
}

resource "google_project_iam_member" "artifact_writer" {
  project = var.gcp_project
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.main_service_account.email}"
}

data "archive_file" "src_zip" {
  type        = "zip"
  output_path = "/tmp/simple-reminders.zip"
  source_dir  = "src"
}

resource "google_storage_bucket_object" "cloud_fn_src_zips" {
  content_type = "application/zip"
  bucket = google_storage_bucket.cloud_fn_src_bucket.name
  source = data.archive_file.src_zip.output_path # Add path to the zipped function source code
  name = "fn_src_${data.archive_file.src_zip.output_md5}.zip" # Every bucket name must be globally unique
}

# Secrets
resource "google_secret_manager_secret_iam_member" "twilio_auth_token" {
  project = var.gcp_project
  secret_id = var.twilio_auth_token_secret_id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.main_service_account.email}"
}

# Cloud Function
resource "google_cloudfunctions2_function" "default" {
  name        = var.fn_name
  location    = var.gcp_region
  description = "simple SMS based reminders"

  build_config {
    runtime     = "python310"
    entry_point = "root" # Set the entry point
    service_account = google_service_account.main_service_account.id
    source {
      storage_source {
        bucket = google_storage_bucket.cloud_fn_src_bucket.name
        object = google_storage_bucket_object.cloud_fn_src_zips.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    service_account_email = google_service_account.main_service_account.email
    ingress_settings = "ALLOW_ALL"
    environment_variables = {
      TESTING_NUMBER = var.testing_number
      TWILIO_ACCOUNT_SID = var.twilio_account_sid
      TWILIO_OUTBOUND_NUMBER = var.twilio_outbound_number
      FN_NAME = var.fn_name
    }
    secret_environment_variables {
      key = "TWILIO_AUTH_TOKEN"
      project_id = var.gcp_project
      secret = var.twilio_auth_token_secret_id
      version = "latest"
    }
  }
}

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = google_cloudfunctions2_function.default.project
  location       = google_cloudfunctions2_function.default.location
  cloud_function = google_cloudfunctions2_function.default.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.main_service_account.email}"
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project  = google_cloudfunctions2_function.default.project
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"  # allow public http access
}

# Not ready for this yet
#resource "google_cloud_scheduler_job" "invoke_cloud_function" {
#  name        = "invoke-gcf-function"
#  description = "Schedule the HTTPS trigger for cloud function"
#  schedule    = "0 0 * * *" # every day at midnight
#  project     = google_cloudfunctions2_function.function.project
#  region      = google_cloudfunctions2_function.function.location
#
#  http_target {
#    uri         = google_cloudfunctions2_function.function.service_config[0].uri
#    http_method = "POST"
#    oidc_token {
#      audience              = "${google_cloudfunctions2_function.function.service_config[0].uri}/"
#      service_account_email = google_service_account.account.email
#    }
#  }
#}


output "function_uri" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}