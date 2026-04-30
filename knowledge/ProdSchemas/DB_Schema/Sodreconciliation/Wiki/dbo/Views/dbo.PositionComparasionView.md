# dbo.PositionComparasionView

> Position comparison view that FULL OUTER JOINs reconciliation results with Apex position data and eToro position data, computing break values and reconciliation status. Powers the SOD Reconciliation UI's position comparison display.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Returns** | Position comparison result set with break values and reconciliation status |
| **SET Options** | ANSI_NULLS ON, QUOTED_IDENTIFIER ON |

---

## 1. Business Meaning

This view provides a consolidated position comparison across three data sources: the reconciliation results (recon.PositionReconciliation), Apex Clearing's raw position data (apex.EXT871_PositionActivity), and eToro's internal position data (tmp.EtoroPositions). It is a key component of the SOD Reconciliation UI, providing the data behind the position comparison screen.

Per the Confluence "Design and flows" page, the reconciliation UI displays position and trade comparisons. This view powers the position comparison portion of that UI, presenting operations teams with a unified view of positions from both Apex and eToro alongside computed break values.

The view uses a FULL OUTER JOIN between the reconciliation table and Apex position data to ensure that positions appearing in only one system are still visible (unmatched positions). A LEFT OUTER JOIN to eToro's temporary position data enriches the result with eToro-specific fields (AverageOpenPrice, InstrumentId).

Note: The view name contains a typo ("Comparasion" instead of "Comparison") which is preserved from the original DDL.

---

## 2. Business Logic

### 2.1 Break Value Calculation

**What**: Computes the monetary discrepancy between Apex and eToro position values.

**Columns/Parameters Involved**: `BreakValue`, `A.ClosingPrice`, `R.ApexTradeQuantity`, `R.EtoroTradeQuantity`

**Rules**:
- Formula: `ABS(ABS(ClosingPrice * ApexTradeQuantity) - ABS(ClosingPrice * EtoroTradeQuantity))`
- Uses Apex's ClosingPrice as the reference price for both sides
- ISNULL defaults to 0 for NULL prices and quantities
- Result is always non-negative (double ABS)
- BreakValue = 0 means Apex and eToro agree on position value
- BreakValue > 0 indicates a discrepancy that needs investigation

### 2.2 Reconciliation Status

**What**: Determines whether a position row is matched or unmatched.

**Columns/Parameters Involved**: `ReconciliationStatus`, `R.Id`

**Rules**:
- ReconciliationStatus = 1 (Unmatched): When R.Id IS NULL -- the position exists in Apex (EXT871) but has no reconciliation record
- ReconciliationStatus = 2 (Matched): When R.Id IS NOT NULL -- a reconciliation record exists for this position
- This status reflects whether matching was attempted, not whether the values actually agree (that is indicated by BreakValue)

### 2.3 Cross-System Position Matching (eToro Enrichment)

**What**: LEFT JOINs eToro position data for enrichment.

**Columns/Parameters Involved**: `tmp.EtoroPositions`, `SodFileId`, `Symbol`, `Cusip`, `AccountNumber`

**Rules**:
- Matches on SodFileId (from either recon or Apex side)
- AND on Symbol or CUSIP (from either recon or Apex side)
- AND on AccountNumber (from either recon or Apex side)
- Filters out eToro rows where both Symbol and Cusip are NULL
- Filters out eToro rows where AccountNumber is NULL
- Adds AverageOpenPrice and InstrumentId from eToro data

---

## 3. Data Overview

N/A - View returns data dynamically from underlying tables.

---

## 4. Elements

| # | Element | Source | Type | Confidence | Description |
|---|---------|--------|------|------------|-------------|
| 1 | ReconId | R.Id | uniqueidentifier | CODE-BACKED | ID from recon.PositionReconciliation. NULL if the position exists only in Apex (unmatched). |
| 2 | ReconFileId | R.SodFileId | uniqueidentifier | CODE-BACKED | SodFileId from the reconciliation record. Links to the file import that triggered reconciliation. |
| 3 | ReconAccountNumber | R.AccountNumber | varchar | CODE-BACKED | Account number from the reconciliation record. |
| 4 | ApexFileId | A.SodFileId | uniqueidentifier | CODE-BACKED | SodFileId from the Apex EXT871 position data. |
| 5 | ApexId | A.Id | uniqueidentifier | CODE-BACKED | ID from apex.EXT871_PositionActivity. NULL if the position exists only in the reconciliation (eToro-only). |
| 6 | ApexAccountNumber | A.AccountNumber | varchar | CODE-BACKED | Account number from the Apex position data. |
| 7 | AccountNumber | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced account number: takes recon value first, falls back to Apex value. |
| 8 | Cusip | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced CUSIP: takes recon value first, falls back to Apex value. |
| 9 | Symbol | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced ticker symbol: takes recon value first, falls back to Apex value. |
| 10 | ApexTradeQuantity | R.ApexTradeQuantity | decimal | CODE-BACKED | Position quantity as reported by Apex (from the reconciliation record). |
| 11 | EtoroTradeQuantity | R.EtoroTradeQuantity | decimal | CODE-BACKED | Position quantity as reported by eToro (from the reconciliation record). |
| 12 | TradeQuantity | A.TradeQuantity | decimal | CODE-BACKED | Raw trade quantity from the Apex EXT871 position data. |
| 13 | BreakValue | Computed | decimal | CODE-BACKED | Monetary discrepancy: ABS(ABS(ClosingPrice * ApexQty) - ABS(ClosingPrice * EtoroQty)). 0 = no break. |
| 14 | ReconciliationStatus | Computed | int | CODE-BACKED | 1 = Unmatched (no recon record), 2 = Matched (recon record exists). |
| 15 | AverageOpenPrice | tmp.AverageOpenPrice | decimal | CODE-BACKED | Average open price from eToro's position data. NULL if no eToro match found. |
| 16 | InstrumentId | tmp.InstrumentId | int | CODE-BACKED | eToro internal instrument identifier. NULL if no eToro match found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| R.* | recon.PositionReconciliation | FULL OUTER JOIN | Reconciliation results -- the "left" side of the comparison |
| A.* | apex.EXT871_PositionActivity | FULL OUTER JOIN | Apex raw position data -- the "right" side of the comparison |
| tmp.* | tmp.EtoroPositions | LEFT OUTER JOIN | eToro position data enrichment (AverageOpenPrice, InstrumentId) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Relationship Type | Description |
|--------------|-------------------|-------------|
| SOD Reconciliation UI | Read | Powers the position comparison display per Confluence "Design and flows" |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PositionComparasionView (view)
├── recon.PositionReconciliation (table)
│   ├── apex.SodFiles (table)
│   └── apex.EXT871_PositionActivity (table)
├── apex.EXT871_PositionActivity (table)
│   └── apex.SodFiles (table)
└── tmp.EtoroPositions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| recon.PositionReconciliation | Table | FULL OUTER JOIN -- reconciliation results |
| apex.EXT871_PositionActivity | Table | FULL OUTER JOIN -- Apex position data |
| tmp.EtoroPositions | Table | LEFT OUTER JOIN -- eToro enrichment data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SOD Reconciliation UI | External | Reads view for position comparison display |

---

## 7. Technical Details

### 7.1 SET Options

| Option | Value | Purpose |
|--------|-------|---------|
| ANSI_NULLS | ON | Standard NULL comparison behavior |
| QUOTED_IDENTIFIER | ON | Allows quoted identifiers |

### 7.2 JOIN Strategy

| Join | Type | Condition | Purpose |
|------|------|-----------|---------|
| R <-> A | FULL OUTER JOIN | A.Id = R.ApexPositionId | Ensures positions from either system appear even without a match in the other |
| (R,A) -> tmp | LEFT OUTER JOIN | SodFileId + (Symbol OR CUSIP) + AccountNumber | Enriches with eToro data; multi-condition OR matching handles cases where only Symbol or only CUSIP is available |

### 7.3 Performance Notes

- FULL OUTER JOIN can be expensive on large datasets -- no filtering by date or SodFileId is built into the view
- The LEFT JOIN to tmp.EtoroPositions uses OR conditions on multiple columns, which may prevent optimal index usage
- Callers should filter by SodFileId or date in their WHERE clause for acceptable performance

---

## 8. Sample Queries

### 8.1 Position breaks for a specific date

```sql
SELECT v.AccountNumber, v.Symbol, v.Cusip,
       v.ApexTradeQuantity, v.EtoroTradeQuantity, v.TradeQuantity,
       v.BreakValue, v.ReconciliationStatus
FROM dbo.PositionComparasionView v WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON v.ApexFileId = f.Id
WHERE f.ProcessDate = '2026-04-10' AND v.BreakValue > 0
ORDER BY v.BreakValue DESC;
```

### 8.2 Unmatched positions (Apex-only, no reconciliation record)

```sql
SELECT ApexAccountNumber, Symbol, Cusip, TradeQuantity
FROM dbo.PositionComparasionView WITH (NOLOCK)
WHERE ReconciliationStatus = 1
ORDER BY ApexFileId DESC;
```

### 8.3 Position comparison with eToro enrichment

```sql
SELECT AccountNumber, Symbol, ApexTradeQuantity, EtoroTradeQuantity,
       BreakValue, AverageOpenPrice, InstrumentId
FROM dbo.PositionComparasionView WITH (NOLOCK)
WHERE ReconFileId = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
ORDER BY BreakValue DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | The reconciliation UI displays position and trade comparisons. This view powers the position comparison portion of the UI. |

---

*Generated: 2026-04-11 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PositionComparasionView | Type: View | Source: Sodreconciliation/Sodreconciliation/dbo/Views/dbo.PositionComparasionView.sql*
