# Trade.ExposuresForAllHedgeServers_Log

> Discrepancy log capturing differences found between the precomputed exposure table and live position data during periodic consistency checks.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | DateChecked + CID + ProviderID + InstrumentID + HedgeServerID (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table stores the results of periodic exposure consistency checks performed by `Trade.ExposuresForAllHedgeServers_Check`. When the check procedure recalculates expected exposure values from live positions (Trade.Position WHERE IsComputeForHedge=1) and finds discrepancies against the precomputed values in Trade.ExposuresForAllHedgeServers, those differences are logged here with both the stored value and the recalculated query value.

The table exists for operational monitoring and debugging. If the incremental exposure updates (via ExposuresForAllHedgeServers_Update) get out of sync with reality - due to edge cases, race conditions, or bugs - this log provides evidence of what went wrong and when. Operations teams can review the ErrorDescription to understand the type of discrepancy.

Rows are inserted exclusively by `Trade.ExposuresForAllHedgeServers_Check`, which runs periodically. Three types of discrepancies are logged: "Records With Differences" (both sources have the row but values disagree), "Records in New Table and Not Old View" (row exists in the precomputed table but not in positions), and "Records in Old View and not New Table" (positions exist but no precomputed row).

---

## 2. Business Logic

### 2.1 Discrepancy Classification

**What**: Three categories of exposure drift are detected and logged separately.

**Columns/Parameters Involved**: `ErrorDescription`, `OpenedBuy`, `OpenedBuyQuery`, `OpenedSell`, `OpenedSellQuery`

**Rules**:
- "Records With Differences": Both the exposure table and the position-based calculation have a row, but OpenedBuy or OpenedSell values differ. OpenedBuy/OpenedSell = table values, OpenedBuyQuery/OpenedSellQuery = recalculated from positions
- "Records in New Table and Not Old View": The exposure table has a row with non-zero values but no matching positions exist. OpenedBuyQuery/OpenedSellQuery will be NULL
- "Records in Old View and not New Table": Positions exist that would produce exposure but no row exists in the exposure table. OpenedBuy/OpenedSell will be NULL

**Diagram**:
```
ExposuresForAllHedgeServers_Check runs:

1. Recalculate from Trade.Position (IsComputeForHedge=1)
2. Compare with Trade.ExposuresForAllHedgeServers
   |
   +-- Values differ --> Log "Records With Differences"
   |
   +-- Row in table, not in positions --> Log "In New Table and Not Old View"
   |
   +-- Row in positions, not in table --> Log "In Old View and not New Table"
3. Fix the table to match recalculated values
```

---

## 3. Data Overview

The table is currently empty (0 rows), indicating no discrepancies have been logged recently (or the check job may not be actively running in this environment).

| DateChecked | ErrorDescription | CID | InstrumentID | OpenedBuy | OpenedBuyQuery | Meaning |
|------------|-----------------|-----|-------------|-----------|---------------|---------|
| *(empty)* | *(empty)* | - | - | - | - | No discrepancies logged |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | Auto-increment | CODE-BACKED | Surrogate identity key for the log entry. |
| 2 | DateChecked | datetime | NO | - | CODE-BACKED | Timestamp when the consistency check ran (set to GETDATE() at the start of the check procedure). Part of the composite PK - groups all discrepancies from the same check run. |
| 3 | ErrorDescription | varchar(100) | NO | - | VERIFIED | Category of discrepancy detected. Known values: "Records With Differences" (value mismatch), "Records in New Table and Not Old View" (orphaned table row), "Records in Old View and not New Table" (missing table row). |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID with the exposure discrepancy. References Customer.Customer. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider for the discrepant exposure row. References Trade.Provider. |
| 6 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument for the discrepant exposure row. References Trade.Instrument. |
| 7 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server for the discrepant exposure row. References Trade.HedgeServer. |
| 8 | OpenedBuy | decimal(38,6) | YES | - | VERIFIED | Buy exposure value stored in Trade.ExposuresForAllHedgeServers at time of check. NULL when the row exists only in the position-based recalculation (error type "In Old View and not New Table"). |
| 9 | OpenedBuyQuery | decimal(38,6) | YES | - | VERIFIED | Buy exposure value recalculated from Trade.Position (SUM of LotCountDecimal WHERE IsBuy=1 AND IsComputeForHedge=1). NULL when the exposure table row has no matching positions (error type "In New Table and Not Old View"). |
| 10 | OpenedSell | decimal(38,6) | YES | - | VERIFIED | Sell exposure value stored in Trade.ExposuresForAllHedgeServers at time of check. NULL when the row exists only in the position-based recalculation. |
| 11 | OpenedSellQuery | decimal(38,6) | YES | - | VERIFIED | Sell exposure value recalculated from Trade.Position (SUM of LotCountDecimal WHERE IsBuy=0 AND IsComputeForHedge=1). NULL when no matching positions exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer with discrepant exposure |
| ProviderID | Trade.Provider | Implicit | Liquidity provider context |
| InstrumentID | Trade.Instrument | Implicit | Financial instrument context |
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server context |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExposuresForAllHedgeServers_Check | - | Writer | Inserts discrepancy rows during consistency check |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers_Check | Stored Procedure | Writes discrepancy records during exposure reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExposuresForAllHedgeServers_Log | CLUSTERED PK | DateChecked, CID, ProviderID, InstrumentID, HedgeServerID | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExposuresForAllHedgeServers_Log | PRIMARY KEY | Groups discrepancy rows by check run and exposure combination |

---

## 8. Sample Queries

### 8.1 Find recent discrepancies
```sql
SELECT TOP 20 DateChecked, ErrorDescription, CID, InstrumentID,
       OpenedBuy, OpenedBuyQuery,
       OpenedSell, OpenedSellQuery
FROM   Trade.ExposuresForAllHedgeServers_Log WITH (NOLOCK)
ORDER BY DateChecked DESC
```

### 8.2 Count discrepancies by type
```sql
SELECT ErrorDescription, COUNT(*) AS DiscrepancyCount
FROM   Trade.ExposuresForAllHedgeServers_Log WITH (NOLOCK)
GROUP BY ErrorDescription
```

### 8.3 Find largest exposure drift for a specific check run
```sql
SELECT CID, InstrumentID,
       ABS(ISNULL(OpenedBuy,0) - ISNULL(OpenedBuyQuery,0)) AS BuyDrift,
       ABS(ISNULL(OpenedSell,0) - ISNULL(OpenedSellQuery,0)) AS SellDrift
FROM   Trade.ExposuresForAllHedgeServers_Log WITH (NOLOCK)
WHERE  DateChecked = @CheckDate
       AND ErrorDescription = 'Records With Differences'
ORDER BY ABS(ISNULL(OpenedBuy,0) - ISNULL(OpenedBuyQuery,0)) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposuresForAllHedgeServers_Log | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ExposuresForAllHedgeServers_Log.sql*
