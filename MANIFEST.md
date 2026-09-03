# V3 Master Package Manifest

This package is synchronized to the V3 45-step PDF.

## Authoritative guide
- `docs/AOS_Warranty_Fresh_Build_GitOps_Complete_45_Step_Guide_v3.pdf`
- Editable copy: `.docx`

## GitHub workflows
- `01-oidc-test.yml` -> Step 10
- `02-pr-ci.yml` -> Steps 11-17
- `03-bootstrap-lab.yml` -> Step 18 / first fresh build
- `04-deploy.yml` -> normal post-bootstrap deployments and Steps 36-37 bad-release demonstration
- `05-drift.yml` -> Step 42
- `06-rds-cost-control.yml` -> Step 43
- `07-destroy.yml` -> Step 44

## Step 36-42 demo assets
- `demos/step36_ingest_raw_bad_release.py`
- `demos/step37_ingest_raw_clean.py`
- `demos/STEP_36_37_DATAOPS_DEMO.md`
- `demos/STEP_38_41_AIOPS_DEMO.md`
- `demos/STEP_42_DRIFT_DEMO.md`

## Important
`glue/ingest_raw.py` is the CLEAN production/lab version. Do not permanently replace it with the Step 36 demo file.
