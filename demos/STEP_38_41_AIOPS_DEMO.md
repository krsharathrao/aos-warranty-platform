# Steps 38-41 - AIOps demonstration

Use the V3 PDF as the authoritative procedure.

1. Verify Lambda environment/model configuration for `aos-aiops-rca`.
2. Record the existing inbound RDS rule: TCP/5432 from `aos-glue-sg`.
3. Temporarily remove only that rule.
4. Run Glue job `aos-ingest-raw` manually.
5. Wait for FAILED and capture its JobRun ID/ErrorMessage.
6. Open CloudWatch log group `/aws/lambda/aos-aiops-rca`.
7. Confirm EventBridge invoked Lambda and that the Lambda logged a Bedrock advisory RCA (or a clear Bedrock access/model error).
8. Restore TCP/5432 from `aos-glue-sg` immediately.
9. Run `aos-ingest-raw` again and prove SUCCEEDED.

CLI job start/check:

```bash
RUN_ID=$(aws glue start-job-run \
  --job-name aos-ingest-raw \
  --query JobRunId \
  --output text)

echo "$RUN_ID"

aws glue get-job-run \
  --job-name aos-ingest-raw \
  --run-id "$RUN_ID" \
  --query 'JobRun.{State:JobRunState,Error:ErrorMessage}' \
  --output json
```

If Lambda does not run:

```bash
aws events describe-rule --name aos-glue-failure
aws events list-targets-by-rule --rule aos-glue-failure
aws lambda get-policy --function-name aos-aiops-rca
```
