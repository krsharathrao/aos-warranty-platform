#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_OWNER:?Set GITHUB_OWNER}"
: "${GITHUB_REPO:?Set GITHUB_REPO}"
AWS_REGION="${AWS_REGION:-ap-south-1}"

command -v aws >/dev/null || { echo "AWS CLI is required"; exit 1; }
command -v gh >/dev/null || { echo "GitHub CLI (gh) is required"; exit 1; }

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OWNER_ID=$(gh api "repos/${GITHUB_OWNER}/${GITHUB_REPO}" --jq '.owner.id')
REPO_ID=$(gh api "repos/${GITHUB_OWNER}/${GITHUB_REPO}" --jq '.id')
STATE_BUCKET="aos-tfstate-${ACCOUNT_ID}-${AWS_REGION}"

echo "AWS account : ${ACCOUNT_ID}"
echo "GitHub repo : ${GITHUB_OWNER}@${OWNER_ID}/${GITHUB_REPO}@${REPO_ID}"
echo "State bucket: ${STATE_BUCKET}"

if ! aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
  aws s3api create-bucket --bucket "${STATE_BUCKET}" --region "${AWS_REGION}" \
    --create-bucket-configuration "LocationConstraint=${AWS_REGION}"
  aws s3api put-bucket-versioning --bucket "${STATE_BUCKET}" --versioning-configuration Status=Enabled
  aws s3api put-public-access-block --bucket "${STATE_BUCKET}" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-encryption --bucket "${STATE_BUCKET}" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
fi

OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_ARN}" >/dev/null 2>&1; then
  aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --client-id-list "sts.amazonaws.com"
fi

cat > /tmp/aos-github-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "${OIDC_ARN}"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:${GITHUB_OWNER}@${OWNER_ID}/${GITHUB_REPO}@${REPO_ID}:*"}
    }
  }]
}
EOF

ROLE_NAME="AOSGitHubDeployRole"
if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  aws iam update-assume-role-policy --role-name "${ROLE_NAME}" --policy-document file:///tmp/aos-github-trust.json
else
  aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file:///tmp/aos-github-trust.json
fi

# LAB FAST PATH ONLY - tighten after the simulation works.
aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

gh variable set AWS_REGION --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --body "${AWS_REGION}"
gh variable set AWS_ACCOUNT_ID --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --body "${ACCOUNT_ID}"
gh variable set AWS_DEPLOY_ROLE_ARN --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --body "${ROLE_ARN}"
gh variable set TF_STATE_BUCKET --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --body "${STATE_BUCKET}"
gh variable set LAB_BOOTSTRAPPED --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --body "false"

echo "Bootstrap completed. Run workflow 01 - OIDC Test."
echo "After workflow 03 succeeds, set LAB_BOOTSTRAPPED=true."
