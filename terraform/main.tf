terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "terraform-user"
  region  = "us-east-1"
}

# Registers a device (Thing) in Core IoT
resource "aws_iot_thing" "MKR_1010_ENV_THING" {
  name = "${var.thing_name}"
}

# Creates a certificate from the certificate request generated from
# the MKR 1010
resource "aws_iot_certificate" "mkr_1010_cert" {
  csr    = file("../mkr_1010_env/secret/cert.csr")
  active = true
}

# Creates a policy that will be attached to the certificate for the device
resource "aws_iot_policy" "mkr_1010_policy" {
  name = "${var.project_name}_mkr_1010_policy"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = [
          "iot:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attaches a policy to the certificate for the device
resource "aws_iot_policy_attachment" "attach_policy" {
  policy = aws_iot_policy.mkr_1010_policy.name
  target = aws_iot_certificate.mkr_1010_cert.arn
}

# Attaches a principal to and AWS IoT Thing (device)
resource "aws_iot_thing_principal_attachment" "attach_certificate" {
  principal = aws_iot_certificate.mkr_1010_cert.arn
  thing     = aws_iot_thing.MKR_1010_ENV_THING.name
}

# Creates a role in AWS
resource "aws_iam_role" "iot_role" {
  name = "${var.project_name}_iot_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          "Service" : "iot.amazonaws.com"
        }
      },
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          "Service" : "firehose.amazonaws.com"
        }
      },
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          "Service" : "kinesis.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "allow_access_to_s3_and_kinesis"

    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = [
            "s3:*",
            "s3-object-lambda:*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = [
            "kinesis:*"
          ]
          Effect   = "Allow"
          Resource = "*"
        }

      ]
    })
  }

  tags = local.tags
}

# Creates an S3 bucket where the telemetry data from the device will be stored.
resource "aws_s3_bucket" "telemetry_bucket" {
  bucket = "${replace(var.project_name, "_","-")}-telemetry-bucket"

  tags = local.tags

  force_destroy = true
}

# Applies an acl to the S3 Bucket
resource "aws_s3_bucket_acl" "telemetry_bucket_acl" {
  bucket = aws_s3_bucket.telemetry_bucket.id
  acl    = "private"
}

# Creates a Kinesis stream to be used as a source for the Kinesis Firehose
resource "aws_kinesis_stream" "telemetry_stream" {
  name             = "${var.project_name}_telemetry_stream"
  retention_period = 24
  shard_count      = 1

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = local.tags
}

# Creates a Kinesis Firehose
resource "aws_kinesis_firehose_delivery_stream" "telemetry_delivery_stream" {
  name        = "${var.project_name}_telemetry_to_s3_delivery_stream"
  destination = "s3"

  s3_configuration {
    role_arn        = "${aws_iam_role.iot_role.arn}"
    bucket_arn      = "${aws_s3_bucket.telemetry_bucket.arn}"
    buffer_size     = 10
    buffer_interval = 60
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.telemetry_stream.arn
    role_arn           = aws_iam_role.iot_role.arn
  }

  tags = local.tags
}

# Creates an IoT rule that queries attributes from the incoming
# MQTT messages and sends them to a Kinesis stream
resource "aws_iot_topic_rule" "mqtt_to_kinesis" {
  name        = "${var.project_name}_telemetry_to_kinesis_rule"
  description = "Pipes incoming MQTT messages to Kinesis"
  enabled     = true
  sql         = "SELECT temperature as temp, humidity as humid, pressure as press, illuminance as lux FROM '${var.iot_topic}'"
  sql_version = "2015-10-08"

  kinesis {
    role_arn      = "${aws_iam_role.iot_role.arn}"
    stream_name   = "${aws_kinesis_stream.telemetry_stream.name}"
    partition_key = "$${newuuid()}"
  }

  tags = local.tags

  depends_on = [aws_iam_role.iot_role]
}

output "s3_bucket_name" {
  value = aws_s3_bucket.telemetry_bucket.bucket
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.telemetry_stream.name
}

output "kinesis_delivery_stream_name" {
  value = aws_kinesis_firehose_delivery_stream.telemetry_delivery_stream.name
}

output "device_name" {
  value = aws_iot_thing.MKR_1010_ENV_THING.name
}

