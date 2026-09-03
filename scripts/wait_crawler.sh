#!/usr/bin/env bash
set -euo pipefail
CRAWLER="$1"
STATE=$(aws glue get-crawler --name "$CRAWLER" --query 'Crawler.State' --output text)
[[ "$STATE" == "READY" ]] && aws glue start-crawler --name "$CRAWLER"
while true; do
  STATE=$(aws glue get-crawler --name "$CRAWLER" --query 'Crawler.State' --output text)
  echo "$CRAWLER => $STATE"
  [[ "$STATE" == "READY" ]] && break
  sleep 15
done
STATUS=$(aws glue get-crawler --name "$CRAWLER" --query 'Crawler.LastCrawl.Status' --output text)
echo "Last crawl => $STATUS"
[[ "$STATUS" == "SUCCEEDED" ]]
