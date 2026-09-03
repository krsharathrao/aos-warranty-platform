#!/usr/bin/env bash
set -euo pipefail
SQL_FILE="$1"; OUTPUT_LOCATION="$2"
QUERY_ID=$(aws athena start-query-execution --query-string "$(cat "$SQL_FILE")" --result-configuration "OutputLocation=$OUTPUT_LOCATION" --query QueryExecutionId --output text)
while true; do
  STATE=$(aws athena get-query-execution --query-execution-id "$QUERY_ID" --query 'QueryExecution.Status.State' --output text)
  case "$STATE" in SUCCEEDED) echo "Athena succeeded: $QUERY_ID"; exit 0 ;; FAILED|CANCELLED) aws athena get-query-execution --query-execution-id "$QUERY_ID" --query 'QueryExecution.Status' --output json; exit 1 ;; esac
  sleep 3
done
