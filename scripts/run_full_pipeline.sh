#!/usr/bin/env bash
set -euo pipefail
SEED_SOURCE="${1:-false}"
SEED_JOB=$(terraform -chdir=terraform output -raw seed_job_name)
INGEST_JOB=$(terraform -chdir=terraform output -raw ingest_job_name)
SILVER_JOB=$(terraform -chdir=terraform output -raw silver_job_name)
RAW_CRAWLER=$(terraform -chdir=terraform output -raw raw_crawler_name)
SILVER_CRAWLER=$(terraform -chdir=terraform output -raw silver_crawler_name)
ATHENA_RESULTS=$(terraform -chdir=terraform output -raw athena_results_s3)
if [[ "$SEED_SOURCE" == "true" ]]; then
  RUN_ID=$(aws glue start-job-run --job-name "$SEED_JOB" --query JobRunId --output text)
  bash scripts/wait_glue_job.sh "$SEED_JOB" "$RUN_ID"
fi
RUN_ID=$(aws glue start-job-run --job-name "$INGEST_JOB" --query JobRunId --output text)
bash scripts/wait_glue_job.sh "$INGEST_JOB" "$RUN_ID"
bash scripts/wait_crawler.sh "$RAW_CRAWLER"
RUN_ID=$(aws glue start-job-run --job-name "$SILVER_JOB" --query JobRunId --output text)
bash scripts/wait_glue_job.sh "$SILVER_JOB" "$RUN_ID"
bash scripts/wait_crawler.sh "$SILVER_CRAWLER"
for test in tests/*.sql; do bash scripts/run_athena_count_test.sh "$test" "$ATHENA_RESULTS"; done
SHORT_SHA="${GITHUB_SHA:-manual}"; SHORT_SHA="${SHORT_SHA:0:7}"; VERSION="warranty_v_${SHORT_SHA//-/_}"
sed "s/__VERSION__/${VERSION}/g" sql/version_view.sql.tmpl > /tmp/version.sql
sed "s/__VERSION__/${VERSION}/g" sql/smoke_test.sql.tmpl > /tmp/smoke.sql
sed "s/__VERSION__/${VERSION}/g" sql/promote.sql.tmpl > /tmp/promote.sql
bash scripts/run_athena_sql.sh /tmp/version.sql "$ATHENA_RESULTS"
bash scripts/run_athena_sql.sh /tmp/smoke.sql "$ATHENA_RESULTS"
bash scripts/run_athena_sql.sh /tmp/promote.sql "$ATHENA_RESULTS"
echo "Promoted warranty_public -> $VERSION"
