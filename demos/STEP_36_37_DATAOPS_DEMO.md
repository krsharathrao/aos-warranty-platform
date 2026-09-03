# Steps 36-37 - DataOps bad-release demonstration

Use the V3 PDF as the authoritative procedure.

## Inject the bad candidate

```bash
git checkout main
git pull
git checkout -b demo/dataops-bad-release
cp demos/step36_ingest_raw_bad_release.py glue/ingest_raw.py
git add glue/ingest_raw.py
git commit -m "Demo DataOps gate with orphan warranty claim"
git push -u origin demo/dataops-bad-release
```

Open a PR to `main`, let `02 - PR CI DevSecOps` pass, then merge it.

Expected deploy behavior:

```text
Raw/Silver succeeds
orphan_claims.sql => violation_count=1
DATA QUALITY GATE FAILED
Gold candidate creation is skipped
warranty_public remains on last-known-good version
```

Proof queries:

```sql
SELECT *
FROM aos_warranty_raw.warranty_claims
WHERE claim_id='WC999';

SELECT w.claim_id, w.order_id
FROM aos_warranty_raw.warranty_claims w
LEFT JOIN aos_warranty_raw.sales_orders s
  ON w.order_id=s.order_id
WHERE s.order_id IS NULL;

SHOW CREATE VIEW aos_warranty_gold.warranty_public;
```

## Recover

Create a fix branch from the current main and restore the clean file:

```bash
git checkout main
git pull
git checkout -b fix/remove-dataops-demo
cp demos/step37_ingest_raw_clean.py glue/ingest_raw.py
git add glue/ingest_raw.py
git commit -m "Remove DataOps bad-record simulation"
git push -u origin fix/remove-dataops-demo
```

Open/merge the fix PR. The next deployment should return all DQ counts to 0 and promote a new Git-SHA Gold view.
