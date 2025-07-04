variable "db_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }
variable "instance_class" { type = string }
variable "engine_version" { type = string }
variable "region" { type = string }

resource "null_resource" "clean-k8s-resources" {
    triggers = {
        vpc_id = aws_vpc.main.id
    }
    provisioner "local-exec" {
        when    = "destroy"
        command = "./bin/delete_sgs ${self.triggers.vpc_id}"
    }
}

# 1. VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = { Name = "${var.db_name}-vpc" }
    depends_on = [null_resource.clean-k8s-resources]
}

# 2. Subnets in separate AZs
data "aws_availability_zones" "available" {}
resource "aws_subnet" "aurora_subnet1" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = false
    tags = { Name = "${var.db_name}-subnet1" }
}
resource "aws_subnet" "aurora_subnet2" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = false
    tags = { Name = "${var.db_name}-subnet2" }
}
# Aurora Subnet Group
resource "aws_db_subnet_group" "aurora" {
    name       = "${var.db_name}-subnet-group"
    subnet_ids = [
        aws_subnet.aurora_subnet1.id,
        aws_subnet.aurora_subnet2.id,
    ]
}

# 3. Security Group permitting only VPC-local access
resource "aws_security_group" "aurora_sg" {
    name        = "${var.db_name}-aurora-sg"
    description = "Aurora access"
    vpc_id      = aws_vpc.main.id
    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# 4. Aurora Cluster (with IAM DB Auth enabled)
resource "aws_rds_cluster" "aurora" {
    cluster_identifier        = var.db_name
    engine                   = "aurora-mysql"
    engine_version           = var.engine_version
    database_name            = var.db_name
    master_username          = var.master_username
    master_password          = var.master_password
    db_subnet_group_name     = aws_db_subnet_group.aurora.name
    vpc_security_group_ids   = [aws_security_group.aurora_sg.id]
    iam_database_authentication_enabled = true
    skip_final_snapshot      = true
}
resource "aws_rds_cluster_instance" "aurora_instance" {
    identifier             = "${var.db_name}-instance-1"
    cluster_identifier     = aws_rds_cluster.aurora.id
    instance_class         = var.instance_class
    engine                 = "aurora-mysql"
    engine_version         = var.engine_version
}

# 5. IAM User for RDS IAM DB Authentication
resource "aws_iam_user" "aurora_app" {
    name = "${var.db_name}-appuser"
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
        resources = [
            aws_rds_cluster.aurora.arn,
            "${aws_rds_cluster.aurora.arn}/*",
            aws_rds_cluster_instance.aurora_instance.arn
        ]
    }
}
resource "aws_iam_policy" "aurora_sa_policy" {
    name   = "${var.db_name}-sa-policy"
    policy = data.aws_iam_policy_document.aurora_sa_policy.json
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