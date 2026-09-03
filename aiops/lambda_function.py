import json
import os
import boto3

REGION = os.environ.get("AWS_REGION_NAME", os.environ.get("AWS_REGION", "ap-south-1"))
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "apac.amazon.nova-micro-v1:0")

glue = boto3.client("glue", region_name=REGION)
bedrock = boto3.client("bedrock-runtime", region_name=REGION)


def lambda_handler(event, context):
    detail = event.get("detail", {})
    job_name = detail.get("jobName", "unknown")
    run_id = detail.get("jobRunId", "")
    state = detail.get("state", "unknown")
    error_message = detail.get("message", "")

    if job_name != "unknown" and run_id:
        try:
            r = glue.get_job_run(
                JobName=job_name,
                RunId=run_id,
                PredecessorsIncluded=False,
            )
            error_message = r["JobRun"].get("ErrorMessage") or error_message
        except Exception as exc:
            error_message = f"{error_message} | GetJobRun failed: {exc}"

    prompt = (
        "You are an AWS operations assistant analyzing a lab Glue failure.\n"
        f"Job: {job_name}\n"
        f"Run ID: {run_id}\n"
        f"State: {state}\n"
        f"Error: {error_message}\n"
        "Return concise JSON with probable_root_cause, confidence, affected_layer, "
        "first_3_checks, safe_remediation, rollback_recommended. "
        "Do not propose destructive or autonomous remediation."
    )

    try:
        response = bedrock.converse(
            modelId=MODEL_ID,
            messages=[{"role": "user", "content": [{"text": prompt}]}],
            inferenceConfig={"maxTokens": 500, "temperature": 0.2},
        )
        answer = response["output"]["message"]["content"][0]["text"]
    except Exception as exc:
        answer = json.dumps(
            {
                "aiops_status": "bedrock_call_failed",
                "job": job_name,
                "state": state,
                "raw_error": error_message,
                "bedrock_error": str(exc),
            }
        )

    print(answer)
    return {"statusCode": 200, "body": answer}
