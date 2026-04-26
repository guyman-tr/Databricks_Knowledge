# BI_DB_AML_PI_Abuse_DeviceID_PI_Side — Review Notes

**Generated**: 2026-04-22
**Batch**: 48
**Reviewer action required**: Yes — extreme outlier requires investigation

---

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|---|---|---|
| Tier fidelity | 9/10 | PI_DeviceID (T1 — verbatim from STS wiki: UUID device identifier); ParentCID (T1 — verbatim: PI customer ID via Fact_SnapshotCustomer); UpdateDate Propagation |
| Completeness | 10/10 | All 3 DDL columns documented; row count, distinct devices/PIs, avg/max/min per PI captured |
| ETL accuracy | 9.5/10 | SP fully read; GCID join (not CID) correctly identified and explained; DateID>=20240101 and null-GUID exclusion both documented |
| Grain clarity | 9/10 | One row per (PI_DeviceID, ParentCID) clearly stated; session frequency not captured noted |
| Quirk capture | 9.5/10 | GCID vs CID join design, date scoping asymmetry vs FID tables, null-GUID exclusion, extreme outlier (457,015 devices) all documented |
| UC accuracy | 10/10 | Not Migrated confirmed |

**Overall**: 9.5/10 — PASS (threshold: 7.5)

---

## Open Questions

**Q1 (High priority)**: One PI has 457,015 distinct device fingerprints — more than the entire table's average (114.1) by a factor of 4,000×. This is likely an automated account, STS fingerprinting issue, or load-testing artifact. Investigate this ParentCID before using device count as an abuse signal.

```sql
SELECT TOP 5 ParentCID, COUNT(*) AS DeviceCount
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side
GROUP BY ParentCID
ORDER BY DeviceCount DESC
```

**Q2 (Low priority)**: DateID >= 20240101 scope is asymmetric with FID tables (which use all historical data). Confirm this is intentional given STS data availability constraints, not an oversight.

---

## Confirmed Behaviors

- TRUNCATE + INSERT daily — no history retained
- Source join is via GCID (`pp.GCID = dh.Gcid`), not CID — required by STS table design
- Null-GUID `00000000-0000-0000-0000-000000000000` excluded by design
- DateID >= 20240101 — STS-scoped, not a bug; asymmetric with FID tables
- Grain: one row per (PI_DeviceID, ParentCID) unique pair
- PII: LOW — PI_DeviceID is a UUID device fingerprint (not personal); ParentCID is CID only
