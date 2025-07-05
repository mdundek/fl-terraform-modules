# Aurora Cluster
resource "aws_rds_cluster" "aurora" {
    cluster_identifier                  = var.db_name
    engine                              = var.engine
    engine_version                      = var.engine_version
    database_name                       = var.db_name
    master_username                     = var.master_username
    master_password                     = var.master_password
    iam_database_authentication_enabled = true
    skip_final_snapshot                 = true
    tags = {
        Name   = "${var.db_name}-cluster"
    }
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "aurora_instance" {
    count               = var.instances
    identifier          = "${var.db_name}-instance-${count.index + 1}"
    cluster_identifier  = aws_rds_cluster.aurora.id
    instance_class      = var.instance_class
    engine              = var.engine
    engine_version      = var.engine_version
    tags = {
        Name = "${var.db_name}-instance-${count.index + 1}"
    }
}
