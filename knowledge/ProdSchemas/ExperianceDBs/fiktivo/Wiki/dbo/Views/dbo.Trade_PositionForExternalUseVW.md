# dbo.Trade_PositionForExternalUseVW

> Enrichment view over live/active position data that adds a single PNL-inclusive commission column (CommissionOnOpenPNL) by folding opening taxes and fees into the base commission figure.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base: dbo.SYN_Trade_PositionForExternalUse (synonym) |
| **Partition** | PartitionCol (pass-through from source) |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.Trade_PositionForExternalUseVW enriches the live/active position dataset -- sourced via a synonym to an external trading database -- with a single computed column (CommissionOnOpenPNL) that combines the base open-side commission with all opening taxes and fees. This gives affiliate commission calculations an accurate cost figure for positions that are currently open and have not yet been closed.

The view was created 2024-02-29 as part of PART-2485 to replace dbo.SYN_Trade_PositionTbl_ForAffiliateAggregatedData for PNL-based affiliate commission calculations. The replacement was necessary because the prior synonym did not expose taxes and fees in a pre-computed form, causing affiliate aggregation routines to undercount the full cost burden of active positions.

The "Trade" prefix denotes that this view covers live/active (open) positions. Its companion view dbo.History_PositionForExternalUseVW covers closed (historical) positions using the same enrichment pattern and additionally provides a CommissionOnClosePNL column for the completed position lifecycle. Because active positions have no close event yet, Trade_PositionForExternalUseVW exposes only the open-side PNL column.

PartitionCol is passed through from the source to support any downstream partition-aware processing that mirrors the pattern used in dbo.ClosedPositions.

---

## 2. Business Logic

### 2.1 CommissionOnOpenPNL Computation

**What**: Calculates the full cost burden at position open, including the base commission and all opening-side taxes and fees.

**Columns/Parameters Involved**: `Commission`, `OpenTotalTaxes`, `OpenTotalFees`

**Formula**: `Commission + OpenTotalTaxes + OpenTotalFees AS CommissionOnOpenPNL`

**Rules**:
- Represents the all-in cost at the time the position was opened
- The correct column to use when aggregating affiliate commissions for active (not yet closed) positions
- Replaces the prior approach (SYN_Trade_PositionTbl_ForAffiliateAggregatedData) which did not include taxes and fees
- NULL propagation: if any component is NULL, the result is NULL

### 2.2 Pass-Through Columns

**What**: All other columns are selected directly from the synonym without transformation.

**Columns/Parameters Involved**: `PositionID`, `PartitionCol`, `CID`, `Commission`, `InitDateTime`, `OpenTotalTaxes`, `OpenTotalFees`

**Rules**:
- No filtering is applied; all rows from the synonym are returned
- No aggregation; this is a row-level enrichment view
- PartitionCol is passed through to support partition-aware consumers

---

## 3. Data Overview

One row per live (open) position. Volume reflects the current open position book in the external trading database. Because active positions close over time, this population is dynamic and smaller than the historical closed position set served by History_PositionForExternalUseVW.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | int | NO | - | VERIFIED | Unique position identifier. Primary key from the external trading database. |
| 2 | PartitionCol | int | YES | - | VERIFIED | Partition routing column passed through from the source. Supports partition-aware downstream processing (e.g., CID % 10 pattern). |
| 3 | CID | int | YES | - | VERIFIED | Customer ID. Links the position to a customer who may be affiliate-attributed. |
| 4 | Commission | float | YES | - | VERIFIED | Base commission charged at position open. One of the inputs to CommissionOnOpenPNL. |
| 5 | InitDateTime | datetime | YES | - | VERIFIED | Timestamp when the position was opened. Used for time-windowed affiliate aggregation. |
| 6 | OpenTotalTaxes | float | YES | - | VERIFIED | Total taxes applied at position open. Included in CommissionOnOpenPNL. |
| 7 | OpenTotalFees | float | YES | - | VERIFIED | Total fees applied at position open. Included in CommissionOnOpenPNL. |
| 8 | CommissionOnOpenPNL | float | YES | - | VERIFIED | Computed: Commission + OpenTotalTaxes + OpenTotalFees. Full cost burden at position open for PNL-based affiliate commission calculations on active positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | dbo.SYN_Trade_PositionForExternalUse | Base synonym | Source of all active position data; synonym routes to external trading DB |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate PNL commission aggregation routines | FROM | Consumer | Replaced SYN_Trade_PositionTbl_ForAffiliateAggregatedData (PART-2485) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Trade_PositionForExternalUseVW (view)
  +-- dbo.SYN_Trade_PositionForExternalUse (synonym -> external DB table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SYN_Trade_PositionForExternalUse | Synonym | Base data source; synonym to active/live position table in external trading database |

### 6.2 Objects That Depend On This

No dependents registered in SSDT. Consumed by affiliate commission aggregation routines at runtime (introduced by PART-2485 as a replacement for prior synonym-based access).

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Query performance depends on the remote table indexes accessible via the synonym's linked server connection.

### 7.2 Constraints

N/A for view.

### 7.3 External Dependency Note

All data flows through dbo.SYN_Trade_PositionForExternalUse, which is a synonym to a table in an external trading database. If the linked server or the remote database is unavailable, this view will fail entirely. Consumers should handle linked server connectivity errors accordingly.

### 7.4 Relationship to History View

This view covers only open (active) positions and provides one computed PNL column (CommissionOnOpenPNL). Once a position closes and migrates to the history store, it should be queried through dbo.History_PositionForExternalUseVW, which additionally provides CommissionOnClosePNL for the complete lifecycle cost.

---

## 8. Sample Queries

### 8.1 Active positions for a customer with PNL commission
```sql
SELECT PositionID, CID, InitDateTime, Commission,
       OpenTotalTaxes, OpenTotalFees, CommissionOnOpenPNL
FROM dbo.Trade_PositionForExternalUseVW WITH (NOLOCK)
WHERE CID = @CustomerID
ORDER BY InitDateTime DESC
```

### 8.2 Aggregate open-position PNL commission by customer for affiliate attribution
```sql
SELECT CID,
       COUNT(PositionID)         AS OpenPositions,
       SUM(CommissionOnOpenPNL)  AS TotalOpenPNLCommission
FROM dbo.Trade_PositionForExternalUseVW WITH (NOLOCK)
WHERE InitDateTime >= @WindowStart
  AND InitDateTime <  @WindowEnd
GROUP BY CID
ORDER BY TotalOpenPNLCommission DESC
```

### 8.3 Open positions by partition for load distribution review
```sql
SELECT PartitionCol,
       COUNT(PositionID)        AS PositionCount,
       SUM(CommissionOnOpenPNL) AS TotalPNLCommission
FROM dbo.Trade_PositionForExternalUseVW WITH (NOLOCK)
GROUP BY PartitionCol
ORDER BY PartitionCol
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2485](https://etoro-jira.atlassian.net/browse/PART-2485) | Jira | Created 2024-02-29 to replace SYN_Trade_PositionTbl_ForAffiliateAggregatedData; adds CommissionOnOpenPNL to correctly include taxes and fees in affiliate PNL commission calculations for live/active positions |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Trade_PositionForExternalUseVW | Type: View | Source: fiktivo/dbo/Views/dbo.Trade_PositionForExternalUseVW.sql*
