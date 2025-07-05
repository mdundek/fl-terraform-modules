# IAM User
resource "aws_iam_user" "aurora_app" {
    name = "${var.db_name}-appuser"
    tags = {
        Name = "${var.db_name}-appuser"
    }
}

# IAM Access Key
resource "aws_iam_access_key" "aurora_key" {
    user = aws_iam_user.aurora_app.name
}

# IAM Policy Document
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

# IAM Policy
resource "aws_iam_policy" "aurora_sa_policy" {
    name   = "${var.db_name}-sa-policy"
    policy = data.aws_iam_policy_document.aurora_sa_policy.json
    tags = {
        Name = "${var.db_name}-sa-policy"
    }
}

# Attach IAM Policy
resource "aws_iam_user_policy_attachment" "attach" {
    user       = aws_iam_user.aurora_app.name
    policy_arn = aws_iam_policy.aurora_sa_policy.arn
}
