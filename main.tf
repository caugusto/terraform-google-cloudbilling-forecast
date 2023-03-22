module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "13.0.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "datacatalog.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "eventarc.googleapis.com",
    "iam.googleapis.com",
    "metastore.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com"
  ]
}

resource "time_sleep" "wait_after_apis_activate" {
  depends_on      = [module.project-services]
  create_duration = "30s"
}
resource "time_sleep" "wait_after_adding_eventarc_svc_agent" {
  depends_on = [time_sleep.wait_after_apis_activate,
    google_project_iam_member.eventarc_svg_agent
  ]
  #actually waits 180 seconds
  create_duration = "60s"
}

#random id
resource "random_id" "id" {
  byte_length = 4
}


#get service acct IDs
resource "google_project_service_identity" "eventarc" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "eventarc.googleapis.com"
  depends_on = [time_sleep.wait_after_apis_activate]
}

resource "google_project_service_identity" "pubsub" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "pubsub.googleapis.com"
  depends_on = [time_sleep.wait_after_apis_activate]
}

resource "google_project_service_identity" "workflows" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "workflows.googleapis.com"
  depends_on = [time_sleep.wait_after_apis_activate]
}
resource "google_project_service_identity" "dataplex_sa" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "dataplex.googleapis.com"
  depends_on = [time_sleep.wait_after_adding_eventarc_svc_agent]
}

#eventarc svg agent permissions 
resource "google_project_iam_member" "eventarc_svg_agent" {
  project = module.project-services.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.eventarc.email}"

  depends_on = [
    google_project_service_identity.eventarc
  ]
}