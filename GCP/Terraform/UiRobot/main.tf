// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("terraform-245706-bba73b77aff6.json")}"
  project     = "terraform-245706"
  region      = "${var.region}"
}

