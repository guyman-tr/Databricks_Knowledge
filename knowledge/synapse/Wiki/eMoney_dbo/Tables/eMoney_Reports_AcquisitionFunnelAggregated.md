# eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated

> 1,863-row daily aggregation of the eToro Money acquisition funnel — pivoting `eMoney_Reports_AcquisitionFunnel`'s customer-grain boolean flags into country+club-level counts across 9 funnel stages. Refreshed daily by `SP_eMoney_Reports_Daily`; each row represents one (FunnelStage, Country, Club) combination with the count of customers at that stage.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | eMoney_Reports_AcquisitionFunnel (via SP_eMoney_Reports_Daily intermediate temp table #funnel) |
| **Refresh** | Daily — TRUNCATE + INSERT full refresh via SP_eMoney_Reports_Daily (Steps 5–6) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override strategy, daily) |

---

## 1. Business Meaning

`eMoney_Reports_AcquisitionFunnelAggregated` is the pre-aggregated, dashboard-ready companion to `eMoney_Reports_AcquisitionFunnel`. Rather than one row per customer, it provides one row per (FunnelStage, Country, Club) combination — making it efficient for reporting queries that would otherwise require GROUP BY on the 3.67M-row customer table. As of 2026-04-12 there are **1,863 rows** = 9 funnel stages × 207 distinct Country+Club combinations. All 9 stages and their total counts mirror the customer-grain table exactly (e.g., VerifiedFTD total = 3,672,801 matching the row count of the customer table).

This table is generated in the same SP run as `eMoney_Reports_AcquisitionFunnel` using a shared intermediate `#funnel` temp table, so both are always consistent with each other.

---

## 2. Business Logic

### 2.1 Funnel Stage Enumeration

**What**: The FunnelStage column encodes which acquisition milestone the FunnelCount represents.
**Columns Involved**: FunnelStage, FunnelCount
**Rules**:
- SP uses 9 UNION ALL blocks, one per stage, with hardcoded stage label strings
- FunnelCount = SUM(ISNULL(boolean_flag, 0)) for that stage's flag across all customers in the Country+Club group
- 9 values (descending by total count, as of 2026-04-12):
  - `VerifiedFTD` = 3,672,801 (all eligible customers)
  - `IsVerifiedFTDPlus2Weeks` = 3,659,851 (99.6%)
  - `IseMoneyAccount` = 1,726,054 (47.0%)
  - `IsFMI` = 1,201,484 (32.7%)
  - `IsFMO` = 1,160,237 (31.6%)
  - `IsActiveMIMO` = 449,123 (12.2%)
  - `IsCardCreated` = 89,823 (2.4%)
  - `IsCardActivated` = 26,079 (0.7%)
  - `IsCardFirstTx` = 23,690 (0.6%)

### 2.2 Granularity

**What**: Each row is a (FunnelStage, Country, Club) triplet — the finest aggregation level.
**Columns Involved**: FunnelStage, Country, Club, FunnelCount
**Rules**:
- 207 distinct (Country, Club) combinations exist across all stages
- Country reflects the eMoney registered country (same logic as AcquisitionFunnel.Country)
- Club reflects the customer's current eToro loyalty tier (same logic as AcquisitionFunnel.Club)
- To get national totals: GROUP BY FunnelStage, Country → SUM(FunnelCount)
- To get overall totals: GROUP BY FunnelStage → SUM(FunnelCount) (should match AcquisitionFunnel stage sums exactly)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution is optimal — the table has only 1,863 rows. Any JOIN to this table will have zero data movement. HEAP is appropriate for a small, full-refresh analytical summary.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Overall funnel conversion rates | `SELECT FunnelStage, SUM(FunnelCount) AS total FROM ... GROUP BY FunnelStage ORDER BY total DESC` |
| Country-level funnel breakdown | `SELECT Country, FunnelStage, FunnelCount FROM ... WHERE Club = 'Bronze' ORDER BY Country, FunnelCount DESC` |
| Cross-stage funnel by club | `PIVOT on FunnelStage, GROUP BY Club` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Reports_AcquisitionFunnel | `Country, Club` | Cross-validate aggregated vs customer-grain counts |
| eMoney_Dim_Country_Rollout | `CountryName = Country` | Enrich with Region, Desk, RolloutDate |

### 3.4 Gotchas

- **FunnelStage strings match AcquisitionFunnel column names exactly**: `IsFMI`, `IsFMO`, etc. — useful for dynamic pivot queries.
- **Country/Club grain only**: No date dimension — this is a snapshot of the current state. For time-series, use the customer-grain table joined to historical data.
- **VerifiedFTD is the denominator**: All other stages are subsets of VerifiedFTD. For conversion rates, divide other FunnelCounts by the matching VerifiedFTD FunnelCount for the same Country+Club.
- **Consistent with AcquisitionFunnel**: Because both tables come from the same `#funnel` temp table in the same SP run, their totals always agree. If SUM(FunnelCount) for VerifiedFTD ≠ COUNT(*) from AcquisitionFunnel, something is wrong.
- **Changed from DELETE to TRUNCATE**: As of 2022-07-22 (MaorTu change), uses TRUNCATE for performance.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived or computed by ETL SP — aggregation or hardcoded label |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FunnelStage | varchar(50) | YES | Acquisition funnel milestone label. 9 values: VerifiedFTD (3,672,801), IsVerifiedFTDPlus2Weeks (3,659,851), IseMoneyAccount (1,726,054), IsFMI (1,201,484), IsFMO (1,160,237), IsActiveMIMO (449,123), IsCardCreated (89,823), IsCardActivated (26,079), IsCardFirstTx (23,690). Hardcoded strings in SP_eMoney_Reports_Daily. Names match corresponding boolean column names in eMoney_Reports_AcquisitionFunnel. (Tier 2 — SP_eMoney_Reports_Daily) |
| 2 | Country | varchar(50) | YES | Customer's eMoney-registered country name. Same derivation as eMoney_Reports_AcquisitionFunnel.Country — ISNULL(RegCountry, rollout CountryName). GROUP BY key for aggregation. (Tier 2 — SP_eMoney_Reports_Daily) |
| 3 | Club | varchar(50) | YES | Customer's current eToro loyalty club tier at time of refresh. Same derivation as eMoney_Reports_AcquisitionFunnel.Club. GROUP BY key for aggregation. 6 values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_eMoney_Reports_Daily) |
| 4 | FunnelCount | int | YES | Count of customers in the given (FunnelStage, Country, Club) group. Computed as SUM(ISNULL(boolean_flag, 0)) from the #funnel intermediate table in SP_eMoney_Reports_Daily. For VerifiedFTD, total across all groups equals the full row count of eMoney_Reports_AcquisitionFunnel. (Tier 2 — SP_eMoney_Reports_Daily) |
| 5 | UpdateDate | datetime | YES | Timestamp of the most recent SP refresh. Set to GETDATE() at insert time; all rows share the same value per daily refresh. Last observed: 2026-04-12 06:50:03. (Tier 2 — SP_eMoney_Reports_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| FunnelStage | SP_eMoney_Reports_Daily | — | Hardcoded string (9 UNION ALL blocks) |
| Country | #funnel (temp table) | Country | GROUP BY passthrough |
| Club | #funnel (temp table) | Club | GROUP BY passthrough |
| FunnelCount | #funnel (temp table) | Boolean flag columns | SUM(ISNULL(flag, 0)) |
| UpdateDate | SP_eMoney_Reports_Daily | — | GETDATE() |

### 5.2 ETL Pipeline

```
eMoney_Reports_AcquisitionFunnel [logical source]
  ≡ #funnel temp table (shared with AcquisitionFunnel in same SP run)
  → 9 UNION ALL blocks, each GROUP BY Country, Club with SUM of one boolean flag
    |-- SP_eMoney_Reports_Daily Steps 5-6 (TRUNCATE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated (1,863 rows, REPLICATE HEAP)
    |-- Generic Pipeline (Override, delta, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | eMoney_Reports_AcquisitionFunnel | Same Country column derivation |
| Club | eMoney_Reports_AcquisitionFunnel | Same Club column derivation |
| (data source) | eMoney_Reports_AcquisitionFunnel | Aggregated summary of customer-grain funnel table |

### 6.2 Referenced By

No downstream objects documented referencing this table directly.

---

## 7. Sample Queries

### Funnel conversion waterfall (national totals)

```sql
SELECT FunnelStage,
       SUM(FunnelCount) AS total_customers
FROM [eMoney_dbo].[eMoney_Reports_AcquisitionFunnelAggregated]
GROUP BY FunnelStage
ORDER BY total_customers DESC;
```

### Country-level acquisition funnel for UK

```sql
SELECT FunnelStage, SUM(FunnelCount) AS count
FROM [eMoney_dbo].[eMoney_Reports_AcquisitionFunnelAggregated]
WHERE Country = 'United Kingdom'
GROUP BY FunnelStage
ORDER BY count DESC;
```

### Club-level card adoption

```sql
SELECT Club,
       MAX(CASE WHEN FunnelStage = 'IsCardCreated' THEN FunnelCount END) AS card_created,
       MAX(CASE WHEN FunnelStage = 'IsCardActivated' THEN FunnelCount END) AS card_activated,
       MAX(CASE WHEN FunnelStage = 'IsCardFirstTx' THEN FunnelCount END) AS card_tx
FROM [eMoney_dbo].[eMoney_Reports_AcquisitionFunnelAggregated]
GROUP BY Club
ORDER BY card_created DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 9/10, Completeness: 9/10*
*Object: eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated | Type: Table | Production Source: eMoney_Reports_AcquisitionFunnel (SP_eMoney_Reports_Daily)*
