# Review Needed — eMoney_dbo.eMoney_Panel_FirstDates

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 9.0/10

---

## Tier 1 Columns

| Column | Upstream Source | Verified |
|--------|----------------|---------|
| AccountID | eMoney_Dim_Account wiki → dbo.FiatAccount | ✓ Copy-verified |
| GCID | eMoney_Dim_Account wiki → dbo.FiatAccount | ✓ Copy-verified |
| CID | eMoney_Dim_Account wiki → Customer.CustomerStatic | ✓ Copy-verified |

---

## Open Questions

1. **2 duplicate CID rows**: As of 2026-04-12 there are 2,031,884 rows but only 2,031,882 distinct CIDs. Which two accounts share a CID, and is this an expected anomaly or a data quality issue? JOINs to Dim_Customer on CID will produce unexpected duplicates for those accounts.
2. **GCID_Unique_Count=1 filter scope**: The grain filter (added 2026-01-12 by Shachar Rubin) excludes accounts where one GCID maps to multiple eMoney accounts. How many accounts are excluded by this filter? Should they be tracked in a separate table or report?
3. **Seniority columns staleness**: Seniority_FMI/FMO/LastTXDate are computed at INSERT time from the daily SP run date. Documentation warns to recompute DATEDIFF directly for real-time use. Is this SP-computed seniority still used directly by downstream reports, or have consumers migrated to live computation?
4. **FMO_MOP DirectDebit=12**: Only 12 accounts have TxTypeID=13 as their first money-out. This is unexpectedly low. Are these legitimate DirectDebit transactions or data anomalies? Worth confirming TxTypeID=13 is still in active use.
5. **UC format is parquet, not delta**: Unlike most eMoney_dbo Gold exports (delta format), this table exports as parquet. Is this intentional (e.g., consumer tooling requirement) or an oversight that should be migrated to delta?
6. **FMI_Source/FMO_Target gap**: TxTypeID 6 maps to FMO_Target='TP' but is also included in IBAN rail definitions (TxTypeID IN [5,6,7,8]). TxTypeID 5 maps to FMI_Source='TP'. Confirm the naming: TxTypeID=5 is "TransferReceived" (money IN from eToro user) and TxTypeID=6 is "Transfer" (money OUT to eToro user)?

---

## No Structural Issues

All 65 elements present. T1 assignments confirmed (AccountID, GCID, CID verbatim from eMoney_Dim_Account wiki). Column naming verified against live INFORMATION_SCHEMA query. Grain filter documented.
