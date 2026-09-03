# Step 42 - Terraform drift demonstration

Use a harmless manual tag change, not a networking change.

1. In AWS Console, add tag `DriftDemo=true` to the Terraform-managed data-lake S3 bucket.
2. GitHub -> Actions -> `05 - Terraform Drift` -> Run workflow.
3. Expected: Terraform `plan -detailed-exitcode` returns 2 and workflow prints `DRIFT DETECTED`.
4. Reconcile either by removing the manual tag in AWS or by adding the desired tag in Terraform through a PR.
5. Rerun drift; expected exit code 0 / no drift.

Meaning:

```text
0 = no changes/no drift
1 = Terraform error
2 = changes/drift detected
```
