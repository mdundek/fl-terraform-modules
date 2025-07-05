provider "aws" {
    shared_credentials_files = ["${path.module}/aws-creds.ini"]
    region = var.region
    default_tags {
        tags = {
            Tenant = var.tenant_name
            Region = var.region
        }
    }
}
