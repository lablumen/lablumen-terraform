# ---- Cognito user pool ----

resource "aws_cognito_user_pool" "this" {
  name                     = var.user_pool_name
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = var.tags
}

# ---- Web app client (SPA — no client secret) ----

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project}-web"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = false
  explicit_auth_flows                  = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
}

# ---- Role groups ----

resource "aws_cognito_user_group" "roles" {
  for_each = toset(["PATIENT", "LAB_STAFF", "LAB_ADMIN"])

  name         = each.value
  user_pool_id = aws_cognito_user_pool.this.id
}
