terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  credentials = file("~/terraform-key.json")  
  project     = "domina-entrega-total"
  region      = "us-central1"
  zone        = "us-central1-a"
}

# ---------------- VPC ----------------
resource "google_compute_network" "web_app_vpc" {
  name                    = "web-app-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "web_app_subnet" {
  name          = "web-app-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.web_app_vpc.id
}

# Firewall SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.web_app_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-server"]
}

# Firewall HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.web_app_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# ---------------- VM (Free Tier) ----------------
resource "google_compute_instance" "web_server" {
  name         = "web-server-1"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web_app_subnet.id
    access_config {}  # IP pública
  }

  tags = ["http-server", "ssh-server"]
}

# Artifact Registry (Docker)
resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = "det"                  
  format        = "DOCKER"
  location      = "us-central1"
  description   = "Repositorio de Docker para Cloud Run"

  labels = {
    environment = "dev"
  }
}

# ---------------- IAM Custom Role para Cloud Run ----------------
resource "google_project_iam_custom_role" "cloudrun_admin" {
  role_id     = "cloudrunAdminCustom"
  title       = "Cloud Run Admin Custom"
  description = "Permite solo administrar servicios de Cloud Run"
  project     = "domina-entrega-total"

  permissions = [
    "run.services.create",
    "run.services.update",
    "run.services.get",
    "run.services.delete",
    "run.services.list"
  ]
}
