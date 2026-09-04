# AOS Warranty Platform - V3 Master Fresh-Build GitOps Package

**Use together with:** `docs/AOS_Warranty_Fresh_Build_GitOps_Complete_45_Step_Guide_v3.pdf`

This package assumes the previous AWS lab is gone. It builds a new disposable environment from Git/Terraform after a small one-time backend/OIDC bootstrap.

## First-run order

1. Install/authenticate Git, AWS CLI, Terraform and `gh`.
2. Create GitHub repo `aos-warranty-platform`.
3. Push this repository.
4. Create GitHub environment `dev`.
5. Run `bootstrap/bootstrap.sh`.
6. Verify the real `TF_STATE_BUCKET`; never use the literal placeholder `YOUR_TF_STATE_BUCKET`.
7. Run workflow `01 - OIDC Test`.
8. Create a feature branch and PR; pass `02 - PR CI DevSecOps`.
9. Merge.
10. Run `03 - Fresh Lab Bootstrap` once.
11. After it succeeds, set GitHub repository variable `LAB_BOOTSTRAPPED=true`.
12. Normal future merges run `04 - Deploy Data Platform`.

## What Terraform creates

- VPC 10.20.0.0/16 and two private subnets
- Glue/RDS/VPC-endpoint security groups
- STS, Secrets Manager and Glue interface endpoints
- S3 gateway endpoint
- private encrypted S3 data-lake bucket
- private RDS PostgreSQL `aosdb` with RDS-managed master secret
- Glue runtime role and NETWORK connection
- Glue 5.0 jobs: seed, Raw ingestion and Silver transform
- Glue Data Catalog databases and Raw/Silver crawlers
- EventBridge Glue failure rule
- AIOps Lambda + Bedrock advisory RCA

## Steps 36-42 demonstrations

Do not hand-edit from memory. Use the files under `demos/` plus the V3 PDF.

### Step 36-37 DataOps

```bash
cp demos/step36_ingest_raw_bad_release.py glue/ingest_raw.py
```

Commit that only on the deliberate bad-release branch. After proving the gate, restore with:

```bash
cp demos/step37_ingest_raw_clean.py glue/ingest_raw.py
```

### Steps 38-41 AIOps

Follow `demos/STEP_38_41_AIOPS_DEMO.md`. The failure is created only by temporarily removing RDS inbound PostgreSQL/5432 from the Glue SG and must be restored immediately.

### Step 42 Drift

Follow `demos/STEP_42_DRIFT_DEMO.md`. Use a harmless manual S3 tag such as `DriftDemo=true`, then run workflow `05 - Terraform Drift`.

## Cost/cleanup

- `06 - RDS Cost Control` -> START/STOP RDS.
- `07 - Destroy Lab` -> full Terraform-managed lab destroy after typing `DESTROY`.
- Interface VPC endpoints incur hourly charges while they exist.
- The Terraform state bucket is intentionally kept outside the Terraform-managed disposable stack.

## Safety baseline

- No long-lived AWS access keys in GitHub.
- No database password committed to Git; Glue retrieves the RDS-managed secret from Secrets Manager.
- DataOps failure blocks Gold promotion.
- AIOps is advisory only and has no network-remediation permissions.
# GitOps validation
