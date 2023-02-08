
locals {
  # Common tags to group resources
  tags = {
    Project = "${var.project_name}"
  }
}
