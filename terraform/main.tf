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

resource "aws_iot_thing" "MKR_1010_ENV_THING" {
  name = "MKR_1010_ENV_THING"

}

# Creates a certificate from the certificate request generated from
# the MKR 1010
resource "aws_iot_certificate" "mkr_1010_cert" {
  csr    = file("../mkr_1010_env/secret/certificate.pem.crt")
  active = true
}

resource "aws_iot_policy" "mkr_1010_policy" {
  name        = "MKR_1010_Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iot_policy_attachment" "attach_policy" {
  policy = aws_iot_policy.mkr_1010_policy.name
  target = aws_iot_certificate.mkr_1010_cert.arn
}

resource "aws_iot_thing_principal_attachment" "attach_certificate" {
  principal = aws_iot_certificate.mkr_1010_cert.arn
  thing     = aws_iot_thing.MKR_1010_ENV_THING.name
}
