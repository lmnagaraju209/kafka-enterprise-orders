###############################
# EXISTING ALB LOOKUP
###############################

data "aws_lb" "webapp_alb" {
  arn = var.existing_alb_arn
}

###############################
# CREATE WAF
###############################

resource "aws_wafv2_web_acl" "webapp" {
  name        = "${var.project_name}-waf"
  description = "WAF for webapp"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webapp-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }
}

###############################
# WAF ASSOCIATION TO EXISTING ALB
###############################

resource "aws_wafv2_web_acl_association" "webapp" {
  resource_arn = data.aws_lb.webapp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.webapp.arn
}
