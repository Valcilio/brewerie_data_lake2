resource "aws_cloudwatch_event_rule" "brewery_trigger_rule" {
  name                = "brewery_trigger_rule"
  description         = "At 12:00 AM, only on Friday."
  schedule_expression = "cron(0 0 4 * ? *)"
}

resource "aws_cloudwatch_event_target" "target_to_brewery_etl_lambda" {
  rule = aws_cloudwatch_event_rule.brewery_trigger_rule.name
  arn  = aws_lambda_function.brewery_etl_lambda.arn
  input = jsonencode({
    "KMS_KEY" : "alias/brewery_etl_key",
    "START_PAGE_PARAMETER_NAME" : "brewery_start_page",
    "BRONZE_BUCKET" : "brewery-bronze-layer2",
    "SILVER_BUCKET" : "brewery-silver-layer2",
    "GOLD_BUCKET" : "brewery-gold-layer2",
    "BRONZE_KEY" : "raw/jsons/data",
    "SILVER_KEY" : "processed/parquets/brewery_proc_data",
    "GOLD_KEY" : "brewery_type_loc_view",
    "AWS_REGION" : "us-east-1",
    "AWS_ACCOUNT_ID" : "${var.aws_account_id}",
    "RETRY_NUMBER" : "0",
    "LAMBDA_NAME" : "brewery_etl_lambda"
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_brewery_etl_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.brewery_etl_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.brewery_trigger_rule.arn
}