# Review Needed: eMoney_dbo.eMoney_Reports_ClubUpgrade

**Generated**: 2026-04-21 | **Batch**: 13 | **Reviewer**: TBD

## Tier 4 Items (Require Verification)

None — all columns resolved to Tier 1 or Tier 2 with code-level confirmation.

## Tier 2 Items Requiring Business Context Confirmation

| Column | Question |
|--------|----------|
| Is_eTM | Flag reflects current account status at SP run time, not at upgrade event time. Confirm this is intentional and acceptable for downstream analysis. |
| UK/EU | 'EU' encompasses non-UK eToro Money rollout countries including Norway, Denmark, Australia. Confirm analysts are aware this is NOT an EU regulatory segmentation. |
| Club_Upgrade_Date | Derived from Fact_SnapshotCustomer.FromDateID (start of snapshot period), not the exact moment the tier changed. May have day-level imprecision. Confirm acceptable. |

## Known Flags / Anomalies

- **Historical window**: SP hardcodes `WHERE dr.FromDateID >= 20230101`. Upgrades before 2023-01-01 are NOT captured — this is by design, not a data quality issue.
- **Previous_ClubID=0**: Valid sentinel for first-ever club assignment. Do not treat as missing data.
- **AccountProgram/AccountSubProgram NULL for Is_eTM=0**: Expected behavior, not a data gap.
- **1,178,170 rows** as of 2026-04-12 — rapidly growing daily.

## Reviewer Checklist

- [ ] Confirm Is_eTM point-in-time behavior is intended (current state, not historical)
- [ ] Confirm UK/EU definition aligns with analyst expectations
- [ ] Confirm Club_Upgrade_Date precision (snapshot-period start vs exact event date)
- [ ] Validate Club_ID → Dim_PlayerLevel mapping (0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond)
- [ ] Confirm UC target: bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade
