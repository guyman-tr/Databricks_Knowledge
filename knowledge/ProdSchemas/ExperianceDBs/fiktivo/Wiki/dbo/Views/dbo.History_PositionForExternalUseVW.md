# dbo.History_PositionForExternalUseVW

> Enrichment view over historical closed position data that adds two PNL-inclusive commission columns (CommissionOnOpenPNL and CommissionOnClosePNL) by folding open and close taxes and fees into the base commission figures.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base: dbo.SYN_History_PositionForExternalUse (synonym) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.History_PositionForExternalUseVW enriches the historical closed position dataset -- sourced via a synonym to an external trading database -- with two computed columns that combine the raw commission with the full cost burden of taxes and fees. This gives affiliate commission calculations a complete picture of what the customer actually paid at each stage of the position lifecycle.

The view was created 2024-02-29 as part of PART-2485 to replace dbo.SYN_History_Position_Active_ForAffiliateAggregatedData for PNL-based affiliate commission calculations. The replacement was necessary to correctly account for taxes and fees in commission aggregation, which the prior synonym did not expose in a pre-computed form.

The "History" prefix denotes that this view covers closed (completed) positions only. Its companion view dbo.Trade_PositionForExternalUseVW covers live/active positions using the same enrichment pattern but with only the open-side PNL column (since active positions have no close-side costs yet).

---

## 2. Business Logic

### 2.1 CommissionOnOpenPNL Computation

**What**: Calculates the total cost at position open, including the base commission and all opening-side taxes and fees.

**Columns/Parameters Involved**: `Commission`, `OpenTotalTaxes`, `OpenTotalFees`

**Formula**: `Commission + OpenTotalTaxes + OpenTotalFees AS CommissionOnOpenPNL`

**Rules**:
- Represents the full cost burden at the time the position was opened
- Used in affiliate PNL calculations that attribute cost to the open event
- NULL propagation: if any component is NULL, the result is NULL

### 2.2 CommissionOnClosePNL Computation

**What**: Calculates the total cost across the complete position lifecycle -- open and close sides -- including the commission on close plus all accumulated taxes and fees from both events.

**Columns/Parameters Involved**: `CommissionOnClose`, `CloseTotalTaxes`, `CloseTotalFees`, `OpenTotalTaxes`, `OpenTotalFees`

**Formula**: `CommissionOnClose + CloseTotalTaxes + CloseTotalFees + OpenTotalTaxes + OpenTotalFees AS CommissionOnClosePNL`

**Rules**:
- Represents the complete, all-in cost of the position from open to close
- The correct column to use when computing affiliate commission based on full position PNL
- Replaces the prior approach (SYN_History_Position_Active_ForAffiliateAggregatedData) which did not include all cost components
- NULL propagation: if any component is NULL, the result is NULL

### 2.3 Pass-Through Columns

**What**: All other columns are selected directly from the synonym without transformation.

**Columns/Parameters Involved**: `PositionID`, `CID`, `Commission`, `CommissionOnClose`, `InitDateTime`, `CloseOccurred`, `CloseTotalTaxes`, `CloseTotalFees`, `OpenTotalTaxes`, `OpenTotalFees`

**Rules**:
- No filtering is applied; all rows from the synonym are returned
- No aggregation; this is a row-level enrichment view

---

## 3. Data Overview

One row per historical closed position. Volume is proportional to total closed position history in the external trading database. The synonym routes to the external DB, so query performance depends on the linked server connection and the indexes on the remote source table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | int | NO | - | VERIFIED | Unique position identifier. Primary key from the external trading database. |
| 2 | CID | int | YES | - | VERIFIED | Customer ID. Links the position to a customer who may be affiliate-attributed. |
| 3 | Commission | float | YES | - | VERIFIED | Base commission charged at position open. One of the inputs to CommissionOnOpenPNL. |
| 4 | CommissionOnClose | float | YES | - | VERIFIED | Base commission charged at position close. One of the inputs to CommissionOnClosePNL. |
| 5 | InitDateTime | datetime | YES | - | VERIFIED | Timestamp when the position was opened. Used for time-windowed affiliate aggregation. |
| 6 | CloseOccurred | datetime | YES | - | VERIFIED | Timestamp when the position was closed. Confirms this is a completed (historical) position. |
| 7 | CloseTotalTaxes | float | YES | - | VERIFIED | Total taxes applied at position close. Included in CommissionOnClosePNL. |
| 8 | CloseTotalFees | float | YES | - | VERIFIED | Total fees applied at position close. Included in CommissionOnClosePNL. |
| 9 | OpenTotalTaxes | float | YES | - | VERIFIED | Total taxes applied at position open. Included in both CommissionOnOpenPNL and CommissionOnClosePNL. |
| 10 | OpenTotalFees | float | YES | - | VERIFIED | Total fees applied at position open. Included in both CommissionOnOpenPNL and CommissionOnClosePNL. |
| 11 | CommissionOnOpenPNL | float | YES | - | VERIFIED | Computed: Commission + OpenTotalTaxes + OpenTotalFees. Full cost burden at position open for PNL-based affiliate commission calculations. |
| 12 | CommissionOnClosePNL | float | YES | - | VERIFIED | Computed: CommissionOnClose + CloseTotalTaxes + CloseTotalFees + OpenTotalTaxes + OpenTotalFees. All-in cost across the complete position lifecycle. The primary column for affiliate PNL commission aggregation on closed positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | dbo.SYN_History_PositionForExternalUse | Base synonym | Source of all position data; synonym routes to external trading DB |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate PNL commission aggregation routines | FROM | Consumer | Replaced SYN_History_Position_Active_ForAffiliateAggregatedData (PART-2485) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.History_PositionForExternalUseVW (view)
  +-- dbo.SYN_History_PositionForExternalUse (synonym -> external DB table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SYN_History_PositionForExternalUse | Synonym | Base data source; synonym to historical closed position table in external trading database |

### 6.2 Objects That Depend On This

No dependents registered in SSDT. Consumed by affiliate commission aggregation routines at runtime (introduced by PART-2485 as a replacement for prior synonym-based access).

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Query performance depends on the remote table indexes accessible via the synonym's linked server connection.

### 7.2 Constraints

N/A for view.

### 7.3 External Dependency Note

All data flows through dbo.SYN_History_PositionForExternalUse, which is a synonym to a table in an external trading database. If the linked server or the remote database is unavailable, this view will fail entirely. Consumers should handle linked server connectivity errors accordingly.

---

## 8. Sample Queries

### 8.1 Closed positions for a customer with full PNL cost breakdown
```sql
SELECT PositionID, CID, InitDateTime, CloseOccurred,
       Commission, CommissionOnOpenPNL,
       CommissionOnClose, CommissionOnClosePNL
FROM dbo.History_PositionForExternalUseVW WITH (NOLOCK)
WHERE CID = @CustomerID
ORDER BY CloseOccurred DESC
```

### 8.2 Aggregate PNL-inclusive commission by customer for affiliate attribution
```sql
SELECT CID,
       COUNT(PositionID)          AS ClosedPositions,
       SUM(CommissionOnClosePNL)  AS TotalPNLCommission
FROM dbo.History_PositionForExternalUseVW WITH (NOLOCK)
WHERE InitDateTime >= @WindowStart
  AND InitDateTime <  @WindowEnd
GROUP BY CID
ORDER BY TotalPNLCommission DESC
```

### 8.3 Positions where close-side costs exceed open-side costs
```sql
SELECT TOP 100 PositionID, CID, InitDateTime, CloseOccurred,
       CommissionOnOpenPNL, CommissionOnClosePNL,
       CommissionOnClosePNL - CommissionOnOpenPNL AS AdditionalCloseCost
FROM dbo.History_PositionForExternalUseVW WITH (NOLOCK)
WHERE CommissionOnClosePNL > CommissionOnOpenPNL
ORDER BY AdditionalCloseCost DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2485](https://etoro-jira.atlassian.net/browse/PART-2485) | Jira | Created 2024-02-29 to replace SYN_History_Position_Active_ForAffiliateAggregatedData; adds CommissionOnOpenPNL and CommissionOnClosePNL to correctly include taxes and fees in affiliate PNL commission calculations for historical closed positions |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 12 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.History_PositionForExternalUseVW | Type: View | Source: fiktivo/dbo/Views/dbo.History_PositionForExternalUseVW.sql*
