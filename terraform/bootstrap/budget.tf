# Monthly cost budget. Created by hand in the console in Sept 2026,
# imported into Terraform in Nov 2026 (see import.tf).
resource "aws_budgets_budget" "monthly" {
  name              = "billing-Budget"
  budget_type       = "COST"
  limit_amount      = "20.0"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-09-01_00:00"
  metrics           = ["UnblendedCost"]

  # Credits and refunds must not hide real spending
  filter_expression {
    not {
      dimensions {
        key           = "RECORD_TYPE"
        match_options = []
        values        = ["Credit", "Refund"]
      }
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 85
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_alert_emails
  }

  lifecycle {
    prevent_destroy = true
  }
}
