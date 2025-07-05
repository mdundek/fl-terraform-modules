variable "provider_config" { type = string }
variable "tenant_name" { type = string }
variable "db_name" { type = string }
variable "instances" { type = number }
variable "master_username" { type = string }
variable "master_password" { type = string }
variable "instance_class" { type = string }
variable "engine_version" { type = string }
variable "region" { type = string }

provider "aws" {
    shared_credentials_files = ["${path.module}/aws-creds.ini"]
    region = "${var.region}"
    default_tags {
        tags = {
            Tenant = "${var.tenant_name}"
            Region = "${var.region}"
        }
    }
}

# 1. Aurora Cluster (with IAM DB Auth enabled)
resource "aws_rds_cluster" "aurora" {
    cluster_identifier       = var.db_name
    engine                   = "aurora-mysql"
    engine_version           = var.engine_version
    database_name            = var.db_name
    master_username          = var.master_username
    master_password          = var.master_password
    iam_database_authentication_enabled = true
    skip_final_snapshot      = true
    tags = {
        Name   = "${var.db_name}-cluster"
    }
}
# 2. Aurora Cluster Instance
resource "aws_rds_cluster_instance" "aurora_instance" {
    count                  = var.instances
    identifier             = "${var.db_name}-instance-1"
    cluster_identifier     = aws_rds_cluster.aurora.id
    instance_class         = var.instance_class
    engine                 = "aurora-mysql"
    engine_version         = var.engine_version
    tags = {
        Name   = "${var.db_name}-instance-${count.index + 1}"
    }
}

# 3. IAM User for RDS IAM DB Authentication
resource "aws_iam_user" "aurora_app" {
    name = "${var.db_name}-appuser"
    tags = {
        Name   = "${var.db_name}-appuser"
    }
}
resource "aws_iam_access_key" "aurora_key" {
    user = aws_iam_user.aurora_app.name
}

# 6. Least-privilege IAM Policy: Allow only RDS IAM DB connect to this cluster
data "aws_iam_policy_document" "aurora_sa_policy" {
    statement {
        effect = "Allow"
        actions = [
            "rds-db:connect",
            "rds:DescribeDBClusters",
            "rds:DescribeDBInstances",
            "rds:DescribeDBClusterEndpoints",
            "rds:DescribeDBClusterParameters"
        ]
        resources = concat(
            [
                aws_rds_cluster.aurora.arn,
                "${aws_rds_cluster.aurora.arn}/*",
            ],
            aws_rds_cluster_instance.aurora_instance[*].arn
        )
    }
}
resource "aws_iam_policy" "aurora_sa_policy" {
    name   = "${var.db_name}-sa-policy"
    policy = data.aws_iam_policy_document.aurora_sa_policy.json
    tags = {
        Name   = "${var.db_name}-sa-policy"
    }
}
resource "aws_iam_user_policy_attachment" "attach" {
    user       = aws_iam_user.aurora_app.name
    policy_arn = aws_iam_policy.aurora_sa_policy.arn
}

output "db_endpoint" {
    value = aws_rds_cluster.aurora.endpoint
}
output "db_reader_endpoint" {
    value = aws_rds_cluster.aurora.reader_endpoint
}
output "db_port" {
    value = 3306
}
output "db_username" {
    value = var.master_username
}
output "db_password" {
    value     = var.master_password
    sensitive = true
}
output "db_name" {
    value = var.db_name
}
output "aws_access_key_id" {
    value     = aws_iam_access_key.aurora_key.id
    sensitive = true
}
output "aws_secret_access_key" {
    value     = aws_iam_access_key.aurora_key.secret
    sensitive = true
}
output "aws_iam_username" {
    value = aws_iam_user.aurora_app.name
}