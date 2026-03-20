# DWH_dbo.Dim_Position_Account_Statement_NetProfit

> Data quality reconciliation table: 251,813 positions compared between DWH-computed NetProfit and an independent history snapshot; 100% mismatch rate because all NetProfit_dwh values are 0.0000, indicating the DWH NetProfit calculation was never implemented or was zeroed out before this comparison was captured.

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

`Dim_Position_Account_Statement_NetProfit` is a data quality reconciliation artifact pairing with `Dim_Position_Account_Statement_AmountInUnitsDecimal`. It compares the DWH's computation of `NetProfit` per position (`_dwh`) against an independent history snapshot (`_history`). The `diff` column is `_dwh - _history`.

This table is NOT a true business dimension. The 100% mismatch rate (251,813 of 251,813 rows) combined with all `NetProfit_dwh = 0.0000` is a critical finding: **the DWH did not have a computed NetProfit value for any of the compared positions.** The history source had non-zero NetProfit values (range -29,575 to +39,676), meaning this comparison captured a state where DWH was missing the calculation entirely.

**This table has no known writer SP in the SSDT repo.** Like its sibling table, it was populated by a one-off investigation script external to the standard ETL pipeline.

---

## 2. Business Logic

### 2.1 Reconciliation Structure

**What**: Each row represents one PositionID where the DWH and history NetProfit values were compared. All rows show diff != 0 because DWH had no NetProfit values.

**Columns Involved**: `PositionID`, `NetProfit_dwh`, `NetProfit_history`, `diff`

**Rules**:
- `diff = NetProfit_dwh - NetProfit_history`
- All `NetProfit_dwh = 0.0000` -> diff = -(NetProfit_history) for every row
- Population coverage: 251,813 positions (5.7x more than the AmountInUnitsDecimal sibling)
- Match rate: 0/251,813 = 0%
- Diff range: -29,575.00 to +39,676.00 (direction of diff is `_dwh - _history`; since _dwh=0, diff = negative of history value)

**Diagram**:
```
DWH NetProfit calc (ALL ZERO)          -> NetProfit_dwh = 0
History snapshot NetProfit             -> NetProfit_history (non-zero)
diff = 0 - NetProfit_history           -> negative of history value
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(PositionID) is consistent with the sibling AmountInUnitsDecimal table, allowing co-located JOINs between the two reconciliation tables on PositionID.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this will be a 251K-row Delta table. No partitioning needed. HASH distribution does not apply in Databricks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find positions with largest history NetProfit | `ORDER BY NetProfit_history DESC` |
| Find positions with negative history NetProfit | `WHERE NetProfit_history < 0` |
| Cross-reference with AmountInUnitsDecimal findings | `JOIN Dim_Position_Account_Statement_AmountInUnitsDecimal ON PositionID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal | `ON PositionID` | Cross-reference both reconciliation investigations for the same positions |
| DWH_dbo.Fact_Positions (presumed) | `ON PositionID` | Cross-reference discrepancies to live position data |

### 3.4 Gotchas

- **ALL NetProfit_dwh = 0.0000** - this is the defining characteristic. Do not treat the _dwh column as a usable DWH metric. The DWH had no NetProfit computation for these positions when the snapshot was taken.
- **diff = -NetProfit_history** - since _dwh is always 0, the diff simply negates the history value. diff analysis is therefore equivalent to analyzing NetProfit_history directly.
- **NOT a live ETL table** - no writer SP exists in SSDT.
- **Larger population than AmountInUnitsDecimal** - 251K vs 34K rows. The two sibling tables were not necessarily populated from the same source run.
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
| 1 | PositionID | bigint | NO | Unique position identifier. Foreign key (unenforced) to the positions universe. (Tier 2 - DDL structure) |
| 2 | NetProfit_dwh | money | NO | The DWH-computed value of NetProfit for this position. In live data, ALL values are 0.0000 - the DWH had no NetProfit calculation at the time this table was populated. Do not use as a metric. (Tier 3 - live data sampling) |
| 3 | NetProfit_history | money | NO | The independently-computed or snapshotted value of NetProfit for this position, from a history source. Contains actual non-zero NetProfit values (range observed: -29,575 to +39,676). The only meaningful NetProfit column in this table. (Tier 3 - live data sampling) |
| 4 | diff | money | NO | Computed difference: NetProfit_dwh - NetProfit_history. Because _dwh is always 0, this equals negative of NetProfit_history for every row. Zero rows: 0 of 251,813. (Tier 3 - live data sampling) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PositionID | Unknown (ad-hoc script) | PositionID | passthrough |
| NetProfit_dwh | DWH ETL (missing/zeroed) | NetProfit | passthrough (all zero) |
| NetProfit_history | History snapshot source | NetProfit | passthrough |
| diff | Computed at load time | _dwh - _history | computed |

No writer SP found in SSDT. Source is an unknown ad-hoc investigation script.

### 5.2 ETL Pipeline

```
DWH ETL (NetProfit = 0 for all rows) -|
                                        +-> [unknown ad-hoc script] -> Dim_Position_Account_Statement_NetProfit
History snapshot (NetProfit values)   -|
```

| Step | Object | Description |
|------|--------|-------------|
| Source A | DWH ETL pipeline | DWH-computed NetProfit (all zero at capture time) |
| Source B | History/snapshot source | Actual NetProfit values per position |
| Target | DWH_dbo.Dim_Position_Account_Statement_NetProfit | Reconciliation artifact, no active refresh |

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

### 7.1 Check all DWH values are zero (validation)
```sql
SELECT
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN NetProfit_dwh != 0 THEN 1 END) AS NonZeroDwhCount
FROM [DWH_dbo].[Dim_Position_Account_Statement_NetProfit];
-- Expected: TotalRows=251813, NonZeroDwhCount=0
```

### 7.2 Distribution of history NetProfit values
```sql
SELECT
    MIN(NetProfit_history) AS MinNetProfit,
    MAX(NetProfit_history) AS MaxNetProfit,
    AVG(NetProfit_history) AS AvgNetProfit,
    COUNT(*) AS PositionCount
FROM [DWH_dbo].[Dim_Position_Account_Statement_NetProfit];
```

### 7.3 Cross-reference both reconciliation tables
```sql
SELECT
    a.PositionID,
    a.diff AS AmountDiff,
    n.diff AS NetProfitDiff
FROM [DWH_dbo].[Dim_Position_Account_Statement_AmountInUnitsDecimal] a
JOIN [DWH_dbo].[Dim_Position_Account_Statement_NetProfit] n
    ON a.PositionID = n.PositionID
ORDER BY ABS(a.diff) DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Account Statement Closed Positions](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/11670225092/Account+Statement+Closed+Positions) | Confluence | `History.Position.NetProfit` and closed-position profit mapping for statements |
| [Account Statement (CS)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137345178/Account+Statement) | Confluence | Net profit/loss lines and financial summary on account statements |
| [Profit/Loss calculation](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11877024028/Profit+Loss+calculation) | Confluence | P/L calculation context behind closed-position profit figures |

---

*Generated: 2026-03-19 | Quality: 6.9/10 (★★★☆☆) | Phases: 11/14*
*Tiers: 0 T1, 1 T2, 3 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 4/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Position_Account_Statement_NetProfit | Type: Table | Production Source: Unknown (ad-hoc reconciliation)*
