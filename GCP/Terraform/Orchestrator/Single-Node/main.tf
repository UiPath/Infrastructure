// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("account.json")}"
  project     = "gcp-terraform-us"
  region      = "${var.region}"
}

