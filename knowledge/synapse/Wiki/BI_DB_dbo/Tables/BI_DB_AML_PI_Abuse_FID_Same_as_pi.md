# BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_as_pi

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents a **computed FID cross-match score for a PI against copiers of other PIs** — specifically, a measure of how many times copiers of other PIs used the same FundingIDs as this PI. Non-zero values indicate PI payment methods that are also used by copiers belonging to different PI networks, a potential cross-network coordination signal.

- **Row count**: 431 (as of 2026-04-22) — 352 distinct PIs; some PIs have multiple rows
- **Distinct PIs (ParentCID)**: 352
- **SameFID_AS_PI range**: 0–170 | **Avg**: 2.90
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
| 1 | ParentCID | int | T2 | `#PI_FID.ParentCID` | The Popular Investor's customer ID. (Tier 2 — SP-derived via #PI_FID JOIN #Copy_FID GROUP BY) |
| 2 | SameFID_AS_PI | int | T2 | `#PI_FID JOIN #Copy_FID.FundingID` | `COUNT(*) - COUNT(DISTINCT pf.FundingID)` over (#PI_FID JOIN #Copy_FID ON FundingID) grouped by (PI, copier). Measures how many non-unique PI FundingID entries are attributed to cross-PI copier FID matches. 0 = exactly one shared FundingID per copier-PI pair; higher values indicate multiple shared FundingIDs. NOT NULL in DDL. (Tier 2 — SP-computed) |
| 3 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. NOT NULL in DDL. (Propagation) |

**Tier summary**: 2 T2 | 1 Propagation

---

## 3. Business Context

This table answers: *"Do this PI's payment methods appear in copier FundingID records belonging to other PIs?"* Unlike `FID_Same_Copy` (which measures within-PI copier sharing), this table measures **cross-PI** FID matches — a PI's payment methods showing up in a completely different PI's copier network.

### Formula Semantics

`SameFID_AS_PI = COUNT(*) - COUNT(DISTINCT pf.FundingID)` computed over `#PI_FID JOIN #Copy_FID ON FundingID`, grouped by `(pf.ParentCID, cf.CID)`, then `SELECT DISTINCT (ParentCID, SameFID_AS_PI)`.

**Critical design note**: The JOIN between #PI_FID and #Copy_FID is on FundingID only — there is **no restriction that the copier belongs to this PI**. This means the join matches a PI's FundingIDs against ALL copiers of ALL PIs who used the same FundingID. A non-zero SameFID_AS_PI indicates the PI's FundingID appears in a copier's deposit history for a different PI's network.

### Why Multiple Rows per PI

Because the aggregation is per `(pf.ParentCID, cf.CID)` pair and then SELECT DISTINCT on `(ParentCID, SameFID_AS_PI)`, a PI can produce multiple distinct (ParentCID, SameFID_AS_PI) values if different copier groupings yield different formula results. This is why 352 distinct PIs produce 431 rows.

### Relationship to Main Table

This metric corresponds to `FID_Same_Copy AS SameFID_AS_PI` column in the main `BI_DB_AML_PI_Abuse` table. The main table's SameFID_AS_PI column was noted as unreliable (see Known Issues).

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 431 (2026-04-22) |
| Distinct PIs (ParentCID) | 352 |
| Min SameFID_AS_PI | 0 |
| Max SameFID_AS_PI | 170 |
| Avg SameFID_AS_PI | 2.90 |
| Snapshot | 2026-04-22 (single-day full refresh) |

Only 352 of 3,854 PIs (≈9%) appear in this table — PIs with zero cross-network FID matches are absent. The max of 170 for one PI indicates significant cross-PI payment method overlap. Multiple rows per PI (431 rows / 352 PIs ≈ 1.22 rows/PI on avg) reflect distinct formula results for different copier groupings.

---

## 5. Usage Notes

### Find PIs with Cross-Network FID Matches

```sql
SELECT ParentCID, MAX(SameFID_AS_PI) AS MaxScore
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_as_pi
WHERE SameFID_AS_PI > 0
GROUP BY ParentCID
ORDER BY MaxScore DESC
```

### Note on Multi-Row PIs

When joining this table to a PI-level fact table, use MAX or aggregate to avoid fan-out:

```sql
SELECT a.ParentCID, MAX(s.SameFID_AS_PI) AS SameFID_Score
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse a
LEFT JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_as_pi s
  ON a.ParentCID = s.ParentCID
GROUP BY a.ParentCID
```

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `#PI_FID` | Temp Table | PI's own FundingIDs — DISTINCT (FundingID, ParentCID) from Fact_BillingDeposit for PI deposits |
| 2 | `#Copy_FID` | Temp Table | Copier FundingIDs — DISTINCT (FundingID, CID, ParentCID) from Fact_BillingDeposit for copier deposits |
| 3 | `DWH_dbo.Fact_BillingDeposit` | Fact Table | Upstream source of both PI and copier FundingIDs |

---

## 7. Known Issues

1. **Cross-PI join (no ParentCID restriction)**: The JOIN on FundingID only — not restricted to the PI's own copiers — means this table measures cross-network PI-copier FID overlap, not within-PI copier overlap. This is a subtle but important distinction from `FID_Same_Copy`.

2. **Multiple rows per PI**: 352 PIs produce 431 rows. Aggregation (MAX or DISTINCT) is required when joining to PI-level tables to avoid row multiplication.

3. **Formula produces 0 for most shared FundingIDs**: A value of 0 means exactly one PI FundingID was matched per copier group — the copier used exactly one of this PI's FundingIDs. Non-zero values are rarer and indicate multiple shared FundingIDs per copier.

4. **Only 9% of PIs appear**: The 3,503 PIs absent from this table have zero cross-PI FID matches and are not represented (not even with a zero row). LEFT JOIN against `BI_DB_AML_PI_Abuse` will produce NULLs for these PIs.

5. **Historical deposits only**: FundingIDs come from all historical `Fact_BillingDeposit` records (no date filter).

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
| Rows | 431 (2026-04-22) |
| Distinct PIs | 352 (≈9% of PI population) |
| PII | LOW |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 48 |
| Generated | 2026-04-22 |
