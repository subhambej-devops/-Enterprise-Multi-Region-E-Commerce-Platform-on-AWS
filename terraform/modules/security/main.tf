data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = var.tags
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for repo in var.github_repositories : "repo:${repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${var.name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_ecr_push" {
  statement {
    sid = "EcrLogin"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid = "EcrPushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [
      "arn:aws:ecr:*:*:repository/${var.name}/*"
    ]
  }
}

resource "aws_iam_policy" "github_ecr_push" {
  name        = "${var.name}-github-ecr-push"
  description = "Allow GitHub Actions to publish immutable service images to ECR."
  policy      = data.aws_iam_policy_document.github_ecr_push.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "github_ecr_push" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}

resource "aws_iam_role_policy_attachment" "github_deploy" {
  for_each   = toset(var.deploy_policy_arns)
  role       = aws_iam_role.github_deploy.name
  policy_arn = each.value
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for ${var.name} application secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret" "application" {
  name        = "${var.name}/application"
  description = "Application bootstrap secret placeholder managed outside source control"
  kms_key_id  = aws_kms_key.secrets.arn
  tags        = var.tags
}
