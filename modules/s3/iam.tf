resource "aws_iam_user" "s3_user" {
    name = "${var.bucket_name}-service-account"
}
data "aws_iam_policy_document" "s3_user_policy" {
    statement {
        actions   = ["s3:*"]
        resources = [
            aws_s3_bucket.main.arn,
            "${aws_s3_bucket.main.arn}/*"
        ]
    }
}
resource "aws_iam_policy" "s3_user_policy" {
    name   = "${var.bucket_name}-s3-user-policy"
    policy = data.aws_iam_policy_document.s3_user_policy.json
}
resource "aws_iam_user_policy_attachment" "attach" {
    user       = aws_iam_user.s3_user.name
    policy_arn = aws_iam_policy.s3_user_policy.arn
}
resource "aws_iam_access_key" "s3_user_key" {
    user = aws_iam_user.s3_user.name
}