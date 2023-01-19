terraform {
  backend "s3" {
    bucket = "dtoki-tf-backend-bucket"
    key    = "tf-interview.tfstate"
    region = "us-west-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_event_rule" "trigger_rule" {
  name = "trigger_rule"
  event_pattern = "{\"source\":[\"custom.event.trigger\"]}"
}

# FIXME: looks like the eventbridge is not a compatible source for lambda event source mapping
# resource "aws_lambda_event_source_mapping" "example_mapping" {
#   event_source_arn = aws_cloudwatch_event_bus.hello_world_bus.arn
#   function_name = aws_lambda_function.hello_world_lambda.arn
#   starting_position = "LATEST"
# }

resource "aws_cloudwatch_event_target" "example_target" {
  rule = aws_cloudwatch_event_rule.trigger_rule.name
  arn = aws_lambda_function.hello_world_lambda.arn
  target_id = "example_target"
}

resource "aws_lambda_function" "hello_world_lambda" {
    filename = "lambda.zip"
    function_name = "example_function"
    role = aws_iam_role.lambda_role.arn
    handler = "index.handler"
    # if i was using an image, i would use this line instead of the runtime and source code zip line
    # runtime = "provided"
    # image_uri = "${var.image_uri}"
    # if i was using a zip file, i would use this line instead of the runtime and image uri line
    runtime = "nodejs12.x"
    source_code_hash = "${filebase64("lambda.zip")}"
    publish = true
    timeout = 15
}


