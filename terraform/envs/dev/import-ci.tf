data "aws_caller_identity" "current" {}

import {
  to = aws_ecr_repository.container_security_lab
  id = "container-security-lab"
}

import {
  to = aws_ecr_registry_scanning_configuration.this
  id = data.aws_caller_identity.current.account_id
}

import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

import {
  to = aws_iam_role.github_actions
  id = "github-actions-container-security-lab"
}

import {
  to = aws_iam_role_policy.github_actions_ecr
  id = "github-actions-container-security-lab:ecr-push"
}
