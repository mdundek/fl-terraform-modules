output "bucket_arn" {
    value = aws_s3_bucket.main.arn
}
output "bucket_name" {
    value = aws_s3_bucket.main.bucket
}
output "iam_access_key_id" {
    value = aws_iam_access_key.s3_user_key.id
    sensitive = true
}
output "iam_secret_access_key" {
    value = aws_iam_access_key.s3_user_key.secret
    sensitive = true
}
output "s3_user_name" {
    value = aws_iam_user.s3_user.name
}