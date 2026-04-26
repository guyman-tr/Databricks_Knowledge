# BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **unique payment instrument (FundingID) used by a Popular Investor (PI) in their own deposit history**, after excluding generic/internal payment methods (FundingID 1–7). The table enumerates every distinct funding method a PI has ever deposited with — forming the PI-side inventory for cross-referencing against copier payment methods to detect shared payment infrastructure.

- **Row count**: 17,814 (as of 2026-04-12)
- **Distinct PIs (ParentCID)**: 3,854 | **Distinct FundingIDs**: 17,807
- **Avg FundingIDs per PI**: 4.62 | **Max**: 114 | **Min**: 1
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains funding method IDs and PI CID only

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | FundingID | int | T1 | `DWH_dbo.Fact_BillingDeposit.FundingID` | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. FundingID NOT IN (1,2,3,4,5,6,7) — generic and internal methods excluded from abuse analysis. (Tier 1 — Billing.Deposit via Fact_BillingDeposit) |
| 2 | ParentCID | int | T1 | `DWH_dbo.Fact_BillingDeposit.CID` (where CID=PI) | The Popular Investor's customer ID. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. NULL in DDL but always populated by the SP. (Propagation) |

**Tier summary**: 2 T1 | 1 Propagation

---

## 3. Business Context

This table answers: *"What payment methods (FundingIDs) has each PI ever deposited with?"* It is one half of the PI-abuse FID cross-reference pair — the PI's payment method inventory. The other half is `BI_DB_AML_PI_Abuse_FID_Copy_Side` (copiers' payment methods).

By comparing this table against the copy-side table, investigators can identify PIs and copiers who share payment infrastructure — a strong indicator of coordinated account networks (e.g., a PI depositing via the same credit card as their copier).

### Exclusion Logic

FundingID values 1–7 are excluded from both PI and copier FID tables because they represent generic or internal payment methods (cash deposits, system credits, etc.) that appear across millions of accounts and have no discriminatory value for abuse detection.

### Grain

One row per (FundingID, ParentCID) unique combination. A PI with 4 distinct payment methods appears as 4 rows. There is no aggregation — this is a raw enumeration of (PI, FundingID) pairs.

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 17,814 (2026-04-12) |
| Distinct PIs (ParentCID) | 3,854 |
| Distinct FundingIDs | 17,807 (nearly unique — few FundingIDs shared across PIs) |
| Avg FundingIDs per PI | 4.62 |
| Max FundingIDs per PI | 114 |
| Min FundingIDs per PI | 1 |
| Snapshot | 2026-04-12 (single-day full refresh) |

Nearly all FundingIDs (17,807 of 17,814) are distinct — most payment instruments belong to a single PI. The few shared FundingIDs represent cases where multiple PIs have deposited via the same payment method — the key abuse signal this suite is designed to detect.

---

## 5. Usage Notes

### Identify PIs Sharing a Payment Method with Any Copier

```sql
SELECT p.ParentCID, c.CID AS CopierCID, p.FundingID
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side p
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side c
  ON p.FundingID = c.FundingID
  AND p.ParentCID = c.ParentCID   -- copier copies THIS PI
ORDER BY p.ParentCID
```

### Count Shared FundingIDs per PI (Correct Approach)

```sql
SELECT p.ParentCID, COUNT(DISTINCT p.FundingID) AS SharedFIDCount
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side p
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side c
  ON p.FundingID = c.FundingID
  AND p.ParentCID = c.ParentCID
GROUP BY p.ParentCID
ORDER BY SharedFIDCount DESC
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | PI deposit history (CID=PI, FundingID) |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Validates PI membership at @DateTime |
| 3 | `#pis` | Temp Table | PI gate filter (GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor) |

---

## 7. Known Issues

1. **FundingID 1–7 excluded**: These are internal/generic methods. Shared FundingID analysis only applies to non-generic payment instruments.

2. **Historical deposits, not date-scoped**: Unlike device data (DateID>=20240101), FID data uses all historical Fact_BillingDeposit records — a PI's FundingIDs include payment methods used years ago, not just recent activity.

3. **One row per unique (PI, FundingID)**: If a PI deposited with the same FundingID 1,000 times, it still appears as one row — volume is not captured here.

---

## 8. Metadata

| Field | Value |
|-------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Writer SP | SP_AML_PI_Abuse |
| ETL Pattern | TRUNCATE + INSERT (daily full refresh) |
| OpsDB Priority | 0 |
| UC Status | Not Migrated |
| Columns | 3 (2 T1, 1 Propagation) |
| Rows | 17,814 (2026-04-12) |
| Distinct PIs | 3,854 |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 48 |
| Generated | 2026-04-22 |
