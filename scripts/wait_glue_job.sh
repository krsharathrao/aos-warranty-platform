#!/usr/bin/env bash
set -euo pipefail
JOB_NAME="$1"; RUN_ID="$2"
while true; do
  STATE=$(aws glue get-job-run --job-name "$JOB_NAME" --run-id "$RUN_ID" --query 'JobRun.JobRunState' --output text)
  echo "$JOB_NAME / $RUN_ID => $STATE"
  case "$STATE" in
    SUCCEEDED) exit 0 ;;
    FAILED|ERROR|TIMEOUT|STOPPED)
      aws glue get-job-run --job-name "$JOB_NAME" --run-id "$RUN_ID" --query 'JobRun.{State:JobRunState,Error:ErrorMessage}' --output json || true
      exit 1 ;;
  esac
  sleep 20
done
