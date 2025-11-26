########################################
# WAF Web ACL
########################################

resource "aws_wafv2_web_acl" "webapp_acl" {
  name        = "${var.project_name}-waf"
  description = "WAF for webapp"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSCommon"
    priority = 1

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
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "awsCommon"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webACL"
    sampled_requests_enabled   = true
  }
}

########################################
# ASSOCIATE WAF WITH ALB
########################################

resource "aws_wafv2_web_acl_association" "webapp" {
  resource_arn = aws_lb.webapp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.webapp_acl.arn
}
