resource "aws_s3_bucket" "ssm_sessions" {
  bucket_prefix = "ssm-session-data-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ssm_sessions_access_block" {
  bucket = aws_s3_bucket.ssm_sessions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_ownership_controls" "ssm_sessions_ownership" {
  bucket = aws_s3_bucket.ssm_sessions.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_sessions_encryption" {
  bucket = aws_s3_bucket.ssm_sessions.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudwatch_log_group" "ssm_log_group" {
  name              = "/ssm/ssm-session-data"
  kms_key_id        = local.kms_key_arn
  retention_in_days = 1

}

resource "aws_ssm_document" "ssm_preferences" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"
  depends_on = [
    aws_s3_bucket.ssm_sessions
  ]
  content = jsonencode({
    "schemaVersion" : "1.0",
    "description" : "Document to hold regional settings for Session Manager",
    "sessionType" : "Standard_Stream",
    "inputs" : {
      "s3BucketName" : "${aws_s3_bucket.ssm_sessions.bucket}",
      "s3KeyPrefix" : "",
      "s3EncryptionEnabled" : true,
      "cloudWatchLogGroupName" : "${aws_cloudwatch_log_group.ssm_log_group.name}",
      "cloudWatchEncryptionEnabled" : true,
      "cloudWatchStreamingEnabled" : true,
      "kmsKeyId" : "${local.kms_key_arn}",
      "runAsEnabled" : false,
      "runAsDefaultUser" : "",
      "idleSessionTimeout" : "",
      "maxSessionDuration" : "",
      "shellProfile" : {
        "windows" : "date",
        "linux" : "pwd;ls"
      }
    }
  })
}

resource "aws_iam_policy" "ssm_policy" {
  name_prefix = "ssm_policy_"
  path        = "/"
  description = "Enabled SSM and Session Logging"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:UpdateInstanceInformation"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.ssm_sessions.arn}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetEncryptionConfiguration"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : "${local.kms_key_arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : "kms:GenerateDataKey",
        "Resource" : "*"
      }
    ]
  })
}