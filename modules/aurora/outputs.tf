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
