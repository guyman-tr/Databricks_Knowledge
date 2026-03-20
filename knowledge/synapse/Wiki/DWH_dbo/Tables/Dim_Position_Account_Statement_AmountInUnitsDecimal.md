# DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal

> Data quality reconciliation table: 34,258 positions compared between DWH-computed AmountInUnitsDecimal and an independent history snapshot; 34,089 rows (99.5%) show discrepancies, indicating a systematic calculation divergence rather than isolated data errors.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown - no writer SP in SSDT repo |
| **Refresh** | Unknown - likely ad-hoc investigation script |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (PositionID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Position_Account_Statement_AmountInUnitsDecimal` is a data quality reconciliation artifact that stores the per-position comparison between two independent computations of `AmountInUnitsDecimal` (the position size in instrument units, as a decimal value): the DWH's own calculation (`_dwh`) versus a historical snapshot or alternative computation (`_history`). The `diff` column is `_dwh - _history`.

This table is NOT a true business dimension. Despite the "Dim_" prefix, it contains no lookup data - it is an audit/investigation artifact. The 99.5% mismatch rate (34,089 of 34,258 rows) indicates a systematic computational difference between the two sources, not random data quality issues.

**This table has no known writer SP in the SSDT repo.** It was almost certainly populated by a one-off investigation or external script outside of the standard ETL pipeline. Its presence in the DWH schema alongside production tables is a naming artifact.

---

## 2. Business Logic

### 2.1 Reconciliation Structure

**What**: Each row represents one PositionID where the DWH and history calculations of `AmountInUnitsDecimal` were compared. Rows with `diff = 0` are matches; all others are mismatches.

**Columns Involved**: `PositionID`, `AmountInUnitsDecimal_dwh`, `AmountInUnitsDecimal_history`, `diff`

**Rules**:
- `diff = AmountInUnitsDecimal_dwh - AmountInUnitsDecimal_history` (computed at population time)
- Population coverage: 34,258 positions out of the full Fact_Positions universe
- Match rate: 169/34,258 = 0.49% (nearly all rows are mismatches)
- Diff range: -374.01 to +23,332.50 (non-trivial dollar magnitudes)

**Diagram**:
```
Investigation source A (DWH calc)    -> AmountInUnitsDecimal_dwh
Investigation source B (history snap) -> AmountInUnitsDecimal_history
diff = _dwh - _history               -> stored for analysis
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table uses HASH(PositionID). JOINs to Fact_Positions or Dim_Position (if they also hash on PositionID) will be co-located. However, since this is an ad-hoc reconciliation table, production queries should not depend on it.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this will be a small 34K-row Delta table. No partitioning needed. HASH distribution will not apply in Databricks (all tables are Delta with Z-ordering as the equivalent).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find largest discrepancies | `ORDER BY ABS(diff) DESC` |
| Find only matching positions | `WHERE diff = 0` |
| Find DWH-higher discrepancies | `WHERE diff > 0` |
| Find history-higher discrepancies | `WHERE diff < 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_Positions (presumed) | `ON Fact_Positions.PositionID = Dim_Position_Account_Statement_AmountInUnitsDecimal.PositionID` | Cross-reference discrepancies to live position data (no enforced FK) |

### 3.4 Gotchas

- **NOT a live ETL table** - no writer SP exists in SSDT. Do not treat as a refreshed dimension.
- **99.5% mismatch rate** - this is expected given the purpose; do not interpret as poor data quality in the underlying system.
- **Subset coverage** - this table only contains positions that were part of the investigation. It does not cover all positions.
- **`diff` direction** - positive diff means DWH value is higher than history; negative means history is higher.
- **Naming confusion** - the "Dim_" prefix is misleading. This is not a dimension in the Kimball sense.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★ | Tier 2 | Synapse code (DDL) |
| ★★ | Tier 3 | Live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | Unique position identifier. Foreign key (unenforced) to the positions universe - identifies which position's AmountInUnitsDecimal values were compared. Range from live data matches Fact_Positions scale (bigint). (Tier 2 - DDL structure) |
| 2 | AmountInUnitsDecimal_dwh | money | NO | The DWH-computed value of AmountInUnitsDecimal for this position. Represents the position size in instrument-native units as computed by the DWH ETL pipeline. (Tier 3 - live data sampling) |
| 3 | AmountInUnitsDecimal_history | money | NO | The independently-computed or snapshotted value of AmountInUnitsDecimal for this position, from a history source. Used as the comparison baseline. (Tier 3 - live data sampling) |
| 4 | diff | money | NO | Computed difference: AmountInUnitsDecimal_dwh - AmountInUnitsDecimal_history. Zero = match; non-zero = discrepancy. Range observed: -374.01 to +23,332.50. (Tier 3 - live data sampling) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PositionID | Unknown (ad-hoc script) | PositionID | passthrough |
| AmountInUnitsDecimal_dwh | DWH ETL computation | AmountInUnitsDecimal | passthrough |
| AmountInUnitsDecimal_history | History snapshot source | AmountInUnitsDecimal | passthrough |
| diff | Computed at load time | _dwh - _history | computed |

No writer SP found in SSDT. Source is an unknown ad-hoc investigation script.

### 5.2 ETL Pipeline

```
DWH ETL (AmountInUnitsDecimal calc)   -|
                                        +-> [unknown ad-hoc script] -> Dim_Position_Account_Statement_AmountInUnitsDecimal
History snapshot (AmountInUnitsDecimal) -|
```

| Step | Object | Description |
|------|--------|-------------|
| Source A | DWH ETL pipeline | DWH-computed AmountInUnitsDecimal values |
| Source B | History/snapshot source | Alternative AmountInUnitsDecimal computation |
| Target | DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal | Reconciliation artifact, no active refresh |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo positions universe | Unenforced FK to position records |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (none found in SSDT) | — | No stored procedures or views reference this table in the SSDT repo |

---

## 7. Sample Queries

### 7.1 Top discrepancies by magnitude
```sql
SELECT TOP 20
    PositionID,
    AmountInUnitsDecimal_dwh,
    AmountInUnitsDecimal_history,
    diff
FROM [DWH_dbo].[Dim_Position_Account_Statement_AmountInUnitsDecimal]
ORDER BY ABS(diff) DESC;
```

### 7.2 Match vs mismatch summary
```sql
SELECT
    CASE WHEN diff = 0 THEN 'Match' ELSE 'Mismatch' END AS ReconciliationStatus,
    COUNT(*) AS PositionCount,
    MIN(diff) AS MinDiff,
    MAX(diff) AS MaxDiff
FROM [DWH_dbo].[Dim_Position_Account_Statement_AmountInUnitsDecimal]
GROUP BY CASE WHEN diff = 0 THEN 'Match' ELSE 'Mismatch' END;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Account Statement Closed Positions](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/11670225092/Account+Statement+Closed+Positions) | Confluence | Maps `AmountInUnitsDecimal`, units, and position fields for account statement / DWH staging |
| [Account Statement Fields](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/12188353681/Account+Statement+Fields) | Confluence | Account statement fields; notes DWH-sourced unrealized values |
| [Account Statement (CS)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137345178/Account+Statement) | Confluence | Client-facing account statement and Amount / Units semantics |

---

*Generated: 2026-03-19 | Quality: 6.9/10 (★★★☆☆) | Phases: 11/14*
*Tiers: 0 T1, 1 T2, 3 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 4/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal | Type: Table | Production Source: Unknown (ad-hoc reconciliation)*
