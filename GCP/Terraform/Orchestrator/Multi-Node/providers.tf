// Configure the Google Cloud provider
provider "google" {
  # credentials = "${file("account.json")}"
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.region}-b"
}

provider "google-beta" {
  # credentials = "${file("account.json")}"
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.region}-b"
}

