# BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_Copy

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **PI with a computed score of FundingID convergence across their copier base** — specifically, the number of non-unique (duplicate) FundingID entries across all copiers of that PI. A higher `Same_FID_Copier` value indicates greater payment method sharing within a PI's follower network.

- **Row count**: 3,849 (as of 2026-04-22) — one row per PI, no duplicates
- **Distinct PIs (ParentCID)**: 3,849
- **Same_FID_Copier range**: 0–402 | **Avg**: 0.62
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains PI CID and aggregate score only

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | ParentCID | int | T2 | `#Copy_FID.ParentCID` | The Popular Investor's customer ID — aggregation key grouping all copier FundingID records belonging to this PI. (Tier 2 — SP-derived via #Copy_FID GROUP BY) |
| 2 | Same_FID_Copier | int | T2 | `#Copy_FID.FundingID` | `COUNT(*) - COUNT(DISTINCT FundingID)` over all copier FundingID records for this PI. Measures the number of non-unique (duplicate) payment instrument entries across the PI's copier base. 0 = all copiers have unique FundingIDs; higher values indicate cross-copier FID sharing. NOT NULL in DDL. (Tier 2 — SP-computed) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. NOT NULL in DDL. (Propagation) |

**Tier summary**: 2 T2 | 1 Propagation

---

## 3. Business Context

This table answers: *"How much payment method overlap exists within the copier network of each PI?"* A PI whose copiers all deposit via unique payment instruments scores 0. A PI whose copiers share payment instruments with each other scores higher — indicating potentially coordinated accounts within the same PI's follower group.

### Formula Semantics

`Same_FID_Copier = COUNT(*) - COUNT(DISTINCT FundingID)`

This is computed over the `#Copy_FID` temp table (DISTINCT FundingID, CID, ParentCID records) grouped by ParentCID. Because the source is already DISTINCT per (FundingID, CID) pair, a non-zero result means multiple copiers of the same PI used the same FundingID. Specifically, a value of N means N copier-FundingID rows were "extra" beyond the unique FundingID count — i.e., N cases where a FundingID was shared by 2+ copiers.

### Grain

One row per PI (ParentCID). This table is PI-level aggregation — there is exactly one row per PI in `#pis`.

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 3,849 (2026-04-22) |
| Distinct PIs (ParentCID) | 3,849 (one-to-one) |
| Min Same_FID_Copier | 0 |
| Max Same_FID_Copier | 402 |
| Avg Same_FID_Copier | 0.62 |
| Snapshot | 2026-04-22 (single-day full refresh) |

The average of 0.62 means most PIs have near-zero copier FID overlap. The max of 402 for one PI represents a high-risk signal — that PI's copier base contains 402 "duplicate" FundingID entries, indicating extensive payment method sharing within the copier network.

---

## 5. Usage Notes

### Find High-Risk PIs by Copier FID Convergence

```sql
SELECT ParentCID, Same_FID_Copier
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_Copy
WHERE Same_FID_Copier > 0
ORDER BY Same_FID_Copier DESC
```

### Join with Main PI Abuse Table for Combined Risk Scoring

```sql
SELECT a.ParentCID, a.FID_Same_Copy, a.SameFID_AS_PI, fc.Same_FID_Copier
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse a
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_Copy fc
  ON a.ParentCID = fc.ParentCID
ORDER BY fc.Same_FID_Copier DESC
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `#Copy_FID` | Temp Table | Copier FundingIDs per PI — DISTINCT (FundingID, CID, ParentCID) from Fact_BillingDeposit for active copiers |
| 2 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | Upstream source of copier FundingIDs |

---

## 7. Known Issues

1. **Count formula semantics**: `COUNT(*) - COUNT(DISTINCT FundingID)` measures "extra" rows beyond the unique FundingID count. A value of 1 means exactly 2 copiers shared 1 FundingID; it does not mean 1 distinct shared FundingID. Large values indicate high copier FID convergence but require cross-referencing `FID_Copy_Side` for specifics.

2. **Historical deposits only**: FundingIDs come from all historical `Fact_BillingDeposit` records (no date filter), so old/dormant payment methods are included.

3. **NOT NULL DDL**: Both `Same_FID_Copier` and `UpdateDate` are NOT NULL in the DDL. `FID_PI_Side` and `DeviceID_PI_Side` have NULL columns — this table reflects a later DDL revision.

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
| Columns | 3 (2 T2, 1 Propagation) |
| Rows | 3,849 (2026-04-22) |
| Distinct PIs | 3,849 (one row per PI) |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 48 |
| Generated | 2026-04-22 |
