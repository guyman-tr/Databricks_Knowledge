---
object: Dealing_CIDs_CommissionsAndFails
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pii_present
  - top20_sampling_bias
quality_score: 8.5
---

## Review Flags

### FLAG 1 — PII PRESENT (HIGH)
**Severity**: High
**Description**: Columns `CID` and `UserName` are present. Any query or BI report using this table must comply with data classification and access control policies for PII.
**Action**: Confirm row-level security or view-based masking is applied for BI consumers. Document data retention policy.

### FLAG 2 — TOP 20 SAMPLING BIAS (MEDIUM)
**Severity**: Medium
**Description**: This table captures only the top 20 CIDs by TotalCommission per day. It is NOT representative of the full customer base. Analysis using this table will be skewed toward high-frequency/high-volume traders. The fail rate (Ratio) for the top 20 may be higher or lower than the overall population fail rate.
**Action**: Document clearly in any BI report or dashboard that this is a "top 20 by commission" view. For population-level fail rate analysis, use `Dealing_dbo.Dealing_FailReasons` or the full `Dealing_Failures` tables.

### FLAG 3 — Count_Fails NULL AMBIGUITY (LOW)
**Severity**: Low
**Description**: When a top-20 CID has no fails, `Count_Fails` is NULL (FULL OUTER JOIN with fails data returns NULL). A NULL in this column means 0 fails, not unknown. Ratio is calculated as 0 when Success_Positions=0, but Count_Fails=NULL+Success_Positions produces NULL Ratio.
**Action**: Consider COALESCE(Count_Fails, 0) in any downstream aggregations.
