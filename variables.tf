variable "gcp_region" {
    type = string
    default = "us-west1"
}

variable "gcp_project" {
    type = string
    default = "tensile-walker-438002-j0"
}

variable "twilio_auth_token_secret_id" {
    type = string
    description = "The identifier of the secret in GCP for the TWILIO_AUTH_TOKEN"
}

variable "twilio_account_sid" {
    type = string
}

variable "twilio_outbound_number" {
    type = string
}



variable "testing_number" {
    # temporary, numbers will go in firestore later
    type = string
}