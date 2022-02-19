resource "aws_iam_role" "role" {
  name = "{var.name}-role"
  assume_role_policy = file("{path.module}/policies/assume_role_policy.json")
}

resource "aws_iam_role_policy" "policy" {
  name = "{var.name}-role-policy"
  role = aws_iam_role.role.id
  policy = templatefile("{path.module}/policies/role_policy.json", {
    
  })
}