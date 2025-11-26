###############################################
# WAF – Attach to existing ALB
###############################################

resource "aws_wafv2_web_acl" "webapp" {
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "webapp" {
  resource_arn = var.existing_alb_arn
  web_acl_arn  = aws_wafv2_web_acl.webapp.arn
}
