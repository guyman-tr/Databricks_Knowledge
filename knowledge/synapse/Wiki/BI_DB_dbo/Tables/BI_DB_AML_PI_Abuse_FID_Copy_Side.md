# BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **unique (payment instrument, copier) combination for copiers of a given PI**, after excluding generic/internal payment methods (FundingID 1–7). The table enumerates every distinct funding method each copier has ever deposited with — forming the copier-side inventory for cross-referencing against PI payment methods to detect shared payment infrastructure.

- **Row count**: 1,344,091 (as of 2026-04-22)
- **Distinct FundingIDs**: 563,967 | **Distinct Copiers (CID)**: 215,326 | **Distinct PIs (ParentCID)**: 3,849
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains funding method IDs, copier CID, and PI CID only

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | FundingID | int | T1 | `DWH_dbo.Fact_BillingDeposit.FundingID` | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. FundingID NOT IN (1,2,3,4,5,6,7) — generic and internal methods excluded from abuse analysis. (Tier 1 — Billing.Deposit via Fact_BillingDeposit) |
| 2 | CID | int | T2 | `DWH_dbo.Fact_BillingDeposit.CID` | The copier's customer ID — the person who copied the PI. (Tier 2 — SP-derived via copier deposit join) |
| 3 | ParentCID | int | T2 | `general.etoroGeneral_History_GuruCopiers.ParentCID` | The Popular Investor's customer ID — the PI being copied at @DateTime. Links copier FundingID records to their PI. (Tier 2 — SP-derived via History_GuruCopiers join) |
| 4 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. (Propagation) |

**Tier summary**: 1 T1 | 2 T2 | 1 Propagation

---

## 3. Business Context

This table answers: *"What payment methods (FundingIDs) has each copier of each PI ever deposited with?"* It is one half of the PI-abuse FID cross-reference pair — the copier's payment method inventory. The other half is `BI_DB_AML_PI_Abuse_FID_PI_Side` (PIs' payment methods).

By comparing this table against the PI-side table, investigators can identify PIs and copiers who share payment infrastructure — a strong indicator of coordinated account networks (e.g., a copier depositing via the same credit card as their PI).

### Grain

One row per (FundingID, CID, ParentCID) unique combination. A copier with 5 distinct payment methods who copies 2 PIs appears as up to 10 rows (one per funding method per PI relationship). There is no aggregation — this is a raw enumeration of (PI, copier, FundingID) triples.

### Exclusion Logic

FundingID values 1–7 are excluded from both PI and copier FID tables because they represent generic or internal payment methods that appear across millions of accounts and have no discriminatory value for abuse detection.

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 1,344,091 (2026-04-22) |
| Distinct FundingIDs | 563,967 |
| Distinct Copiers (CID) | 215,326 |
| Distinct PIs (ParentCID) | 3,849 |
| Avg FundingIDs per copier | 6.24 |
| Max FundingIDs per copier | 2,185 |
| Min FundingIDs per copier | 1 |
| Snapshot | 2026-04-22 (single-day full refresh) |

The table is significantly larger than `FID_PI_Side` (1.3M vs 18K rows) because it covers all copiers (215K) across all PIs (3.8K), not just the PIs themselves. Most FundingIDs are unique to a single copier; cross-copier FundingID sharing within a PI's follower base is captured by `FID_Same_Copy`.

---

## 5. Usage Notes

### Identify Copiers Sharing a Payment Method with Their PI

```sql
SELECT c.ParentCID, c.CID AS CopierCID, c.FundingID
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side c
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side p
  ON c.FundingID = p.FundingID
  AND c.ParentCID = p.ParentCID
ORDER BY c.ParentCID
```

### Count Distinct Copiers Per PI Who Share a FundingID with the PI

```sql
SELECT c.ParentCID, COUNT(DISTINCT c.CID) AS CopierCount
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side c
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side p
  ON c.FundingID = p.FundingID
  AND c.ParentCID = p.ParentCID
GROUP BY c.ParentCID
ORDER BY CopierCount DESC
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | Copier deposit history (CID=copier, FundingID) |
| 2 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Links copier CID to PI (ParentCID) at @DateTime |
| 3 | `#pis` | Temp Table | PI gate filter (GuruStatusID>=2, IsValidCustomer=1, VL3, Depositor) |

---

## 7. Known Issues

1. **FundingID 1–7 excluded**: These are internal/generic methods. Shared FundingID analysis only applies to non-generic payment instruments.

2. **Historical deposits, not date-scoped**: FID data uses all historical `Fact_BillingDeposit` records — a copier's FundingIDs include payment methods used years ago, not just recent activity.

3. **One row per unique (FundingID, CID, ParentCID)**: If a copier deposited with the same FundingID 1,000 times across multiple copy relationships, each (copier, PI, FundingID) triple still appears as one row — volume and recency are not captured here.

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
| Columns | 4 (1 T1, 2 T2, 1 Propagation) |
| Rows | 1,344,091 (2026-04-22) |
| Distinct PIs | 3,849 |
| Distinct Copiers | 215,326 |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 48 |
| Generated | 2026-04-22 |
