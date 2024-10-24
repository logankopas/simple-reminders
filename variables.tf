variable "gcp_region" {
    type = string
    description = "The GCP region where this service will be hosted"
    default = "us-west1"
}

variable "gcp_project" {
    type = string
    description = "the GCP project to authenticate with"
    default = "tensile-walker-438002-j0"
}

variable "fn_name" {
    type = string
    description = "The name this service will be deployed as"
    default = "simple-reminders"
}

variable "twilio_auth_token_secret_id" {
    type = string
    description = "The identifier of the secret in GCP for the TWILIO_AUTH_TOKEN"
}

variable "twilio_account_sid" {
    type = string
    description = "The Twilio account SID that will be used"
}

variable "twilio_outbound_number" {
    type = string
    description = "The Twilio number used to send and receive SMS messages"
}

variable "testing_number" {
    # temporary, numbers will go in firestore later
    type = string
}