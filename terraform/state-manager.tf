resource "aws_ssm_document" "create_local_admin_doc" {
  name          = "create_local_admin_account"
  document_type = "Command"
  content = file("${path.module}/admin.account.doc.json")
}

resource "aws_ssm_association" "state_management_association" {
  name = aws_ssm_document.create_local_admin_doc.name
  schedule_expression = "rate(1 day)"
  targets {
    key    = "tag:Name"
    values = ["windows-host"]
  }
}