#############################################
# WAF Web ACL
#############################################

resource "aws_wafv2_web_acl" "webapp" {
  name        = "webapp-waf"
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

  # Rule 1 — Common AWS managed rules
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2 — Known bad inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "bad-inputs"
      sampled_requests_enabled   = true
    }
  }
}

#############################################
# Associate WAF + ALB
#############################################

resource "aws_wafv2_web_acl_association" "webapp" {
  resource_arn = aws_lb.webapp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.webapp.arn
}
