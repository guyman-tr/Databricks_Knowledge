# dbo.TradeComparasionView

> Trade comparison view that FULL OUTER JOINs reconciliation results with Apex trade activity data and eToro trade data, computing break values and reconciliation status. Powers the SOD Reconciliation UI's trade comparison display.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Returns** | Trade comparison result set with break values and reconciliation status |
| **SET Options** | ANSI_NULLS ON, QUOTED_IDENTIFIER ON |

---

## 1. Business Meaning

This view provides a consolidated trade comparison across three data sources: the reconciliation results (recon.TradeReconciliation), Apex Clearing's raw trade activity data (apex.EXT872_TradeActivity), and eToro's internal trade data (tmp.EtoroTrades). It is a key component of the SOD Reconciliation UI, providing the data behind the trade comparison screen.

Per the Confluence "Design and flows" page, the reconciliation UI displays position and trade comparisons. This view powers the trade comparison portion of that UI, presenting operations teams with a unified view of trades from both Apex and eToro alongside computed break values and directional information (buy/sell).

The view uses a FULL OUTER JOIN between the reconciliation table and Apex trade data to ensure that trades appearing in only one system are still visible (unmatched trades). A LEFT JOIN to eToro's temporary trade data enriches the result with eToro-specific fields (IsBuy direction).

Note: The view name contains a typo ("Comparasion" instead of "Comparison") which is preserved from the original DDL.

---

## 2. Business Logic

### 2.1 Break Value Calculation

**What**: Computes the monetary discrepancy between Apex and eToro trade values.

**Columns/Parameters Involved**: `BreakValue`, `R.ApexTradeQuantity`, `R.ApexTradePrice`, `R.EtoroTradeQuantity`, `R.EtoroTradePrice`

**Rules**:
- Formula: `ABS(ABS(ApexTradeQuantity * ApexTradePrice) - ABS(EtoroTradeQuantity * EtoroTradePrice))`
- Uses each side's own price for its value computation (unlike PositionComparasionView which uses a single price)
- ISNULL defaults the entire product to 0 if NULL
- Result is always non-negative (double ABS)
- BreakValue = 0 means Apex and eToro agree on trade value
- BreakValue > 0 indicates a discrepancy requiring investigation

### 2.2 Reconciliation Status

**What**: Determines whether a trade row is matched or unmatched.

**Columns/Parameters Involved**: `ReconStatus`, `R.Id`

**Rules**:
- ReconStatus = 1 (Unmatched): When R.Id IS NULL -- the trade exists in Apex (EXT872) but has no reconciliation record
- ReconStatus = 2 (Matched): When R.Id IS NOT NULL -- a reconciliation record exists for this trade
- This status reflects whether matching was attempted, not whether the values actually agree

### 2.3 Buy/Sell Direction Resolution

**What**: Determines the trade direction from multiple sources.

**Columns/Parameters Involved**: `IsBuy`, `R.IsBuy`, `A.Quantity`, `EtoroDirection`

**Rules**:
- IsBuy: Coalesced from recon record first; if NULL, derived from Apex Quantity sign (positive = buy/1, negative = sell/0, NULL = NULL)
- EtoroDirection: IsBuy flag directly from eToro trade data (tmp.EtoroTrades)
- ApexBuySellCode: Buy/sell code from Apex EXT872 raw data (separate from the derived IsBuy)

### 2.4 Cross-System Trade Matching (eToro Enrichment)

**What**: LEFT JOINs eToro trade data for enrichment.

**Columns/Parameters Involved**: `tmp.EtoroTrades`, `SodFileId`, `OrderId/PositionIdApexFormat`, `AccountNumber`

**Rules**:
- Matches on SodFileId (from either Apex or recon side)
- AND on OrderId matching to eToro's PositionIdApexFormat
- AND on AccountNumber (from either Apex or recon side)
- Adds EtoroDirection (IsBuy) from eToro data

---

## 3. Data Overview

N/A - View returns data dynamically from underlying tables.

---

## 4. Elements

| # | Element | Source | Type | Confidence | Description |
|---|---------|--------|------|------------|-------------|
| 1 | ReconId | R.Id | uniqueidentifier | CODE-BACKED | ID from recon.TradeReconciliation. NULL if the trade exists only in Apex (unmatched). |
| 2 | TradeId | A.Id | uniqueidentifier | CODE-BACKED | ID from apex.EXT872_TradeActivity. NULL if the trade exists only in reconciliation. |
| 3 | ReconFileId | R.SodFileId | uniqueidentifier | CODE-BACKED | SodFileId from the reconciliation record. |
| 4 | ReconAccountNumber | R.AccountNumber | varchar | CODE-BACKED | Account number from the reconciliation record. |
| 5 | ApexFileId | A.SodFileId | uniqueidentifier | CODE-BACKED | SodFileId from the Apex EXT872 trade data. |
| 6 | ApexAccountNumber | A.AccountNumber | varchar | CODE-BACKED | Account number from the Apex trade data. |
| 7 | AccountNumber | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced account number: takes recon value first, falls back to Apex value. |
| 8 | OrderId | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced order identifier: takes recon value first, falls back to Apex value. |
| 9 | CUSIP | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced CUSIP: takes recon value first, falls back to Apex value. |
| 10 | Symbol | ISNULL(R, A) | varchar | CODE-BACKED | Coalesced ticker symbol: takes recon value first, falls back to Apex value. |
| 11 | BreakValue | Computed | decimal | CODE-BACKED | Monetary discrepancy: ABS(ABS(ApexQty * ApexPrice) - ABS(EtoroQty * EtoroPrice)). 0 = no break. |
| 12 | ApexBuySellCode | A.BuySellCode | varchar | CODE-BACKED | Buy/sell code from Apex EXT872 raw data. |
| 13 | ApexTradeQuantity | R.ApexTradeQuantity | decimal | CODE-BACKED | Trade quantity as reported by Apex (from the reconciliation record). |
| 14 | ApexTradePrice | R.ApexTradePrice | decimal | CODE-BACKED | Trade price as reported by Apex (from the reconciliation record). |
| 15 | ApexExecutionDate | R.ApexTradeDate | datetime | CODE-BACKED | Apex trade execution date (aliased from ApexTradeDate). |
| 16 | EtoroTradeQuantity | R.EtoroTradeQuantity | decimal | CODE-BACKED | Trade quantity as reported by eToro (from the reconciliation record). |
| 17 | EtoroTradePrice | R.EtoroTradePrice | decimal | CODE-BACKED | Trade price as reported by eToro (from the reconciliation record). |
| 18 | EtoroExecutionDate | R.EtoroTradeDate | datetime | CODE-BACKED | eToro trade execution date (aliased from EtoroTradeDate). |
| 19 | Quantity | A.Quantity | decimal | CODE-BACKED | Raw trade quantity from the Apex EXT872 trade data. |
| 20 | Price | A.Price | decimal | CODE-BACKED | Raw trade price from the Apex EXT872 trade data. |
| 21 | TradeDate | A.TradeDate | datetime | CODE-BACKED | Trade date from the Apex EXT872 trade data. |
| 22 | ReconStatus | Computed | int | CODE-BACKED | 1 = Unmatched (no recon record), 2 = Matched (recon record exists). |
| 23 | IsBuy | Computed | bit | CODE-BACKED | Coalesced buy direction: recon IsBuy first, then derived from Apex Quantity sign (>0=buy, <0=sell). |
| 24 | EtoroDirection | tmp.IsBuy | bit | CODE-BACKED | Buy/sell direction from eToro trade data. NULL if no eToro match found. |
| 25 | ApexTag | A.TradeNumber | varchar | CODE-BACKED | Apex trade number, used as an external reference tag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| R.* | recon.TradeReconciliation | FULL OUTER JOIN | Reconciliation results -- the "left" side of the comparison |
| A.* | apex.EXT872_TradeActivity | FULL OUTER JOIN | Apex raw trade data -- the "right" side of the comparison |
| tmp.* | tmp.EtoroTrades | LEFT JOIN | eToro trade data enrichment (IsBuy direction) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Relationship Type | Description |
|--------------|-------------------|-------------|
| SOD Reconciliation UI | Read | Powers the trade comparison display per Confluence "Design and flows" |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.TradeComparasionView (view)
├── recon.TradeReconciliation (table)
│   ├── apex.SodFiles (table)
│   └── apex.EXT872_TradeActivity (table)
├── apex.EXT872_TradeActivity (table)
│   └── apex.SodFiles (table)
└── tmp.EtoroTrades (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| recon.TradeReconciliation | Table | FULL OUTER JOIN -- reconciliation results |
| apex.EXT872_TradeActivity | Table | FULL OUTER JOIN -- Apex trade data |
| tmp.EtoroTrades | Table | LEFT JOIN -- eToro enrichment data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SOD Reconciliation UI | External | Reads view for trade comparison display |

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
| R <-> A | FULL OUTER JOIN | A.Id = R.TradeActivityId | Ensures trades from either system appear even without a match in the other |
| (R,A) -> tmp | LEFT JOIN | SodFileId + OrderId/PositionIdApexFormat + AccountNumber | Enriches with eToro data; matches on the Apex-format position ID used as order reference |

### 7.3 Performance Notes

- FULL OUTER JOIN can be expensive on large datasets -- no filtering by date or SodFileId is built into the view
- Callers should filter by SodFileId or date in their WHERE clause for acceptable performance
- The LEFT JOIN to tmp.EtoroTrades uses OR conditions for SodFileId and AccountNumber from both sides

---

## 8. Sample Queries

### 8.1 Trade breaks for a specific date

```sql
SELECT v.AccountNumber, v.Symbol, v.CUSIP, v.OrderId,
       v.ApexTradeQuantity, v.ApexTradePrice,
       v.EtoroTradeQuantity, v.EtoroTradePrice,
       v.BreakValue, v.ReconStatus
FROM dbo.TradeComparasionView v WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON v.ApexFileId = f.Id
WHERE f.ProcessDate = '2026-04-10' AND v.BreakValue > 0
ORDER BY v.BreakValue DESC;
```

### 8.2 Unmatched trades (Apex-only, no reconciliation record)

```sql
SELECT ApexAccountNumber, Symbol, CUSIP, Quantity, Price, TradeDate
FROM dbo.TradeComparasionView WITH (NOLOCK)
WHERE ReconStatus = 1
ORDER BY ApexFileId DESC;
```

### 8.3 Compare buy/sell direction across systems

```sql
SELECT AccountNumber, Symbol, OrderId,
       ApexBuySellCode, IsBuy, EtoroDirection,
       BreakValue
FROM dbo.TradeComparasionView WITH (NOLOCK)
WHERE ReconFileId = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
ORDER BY BreakValue DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | The reconciliation UI displays position and trade comparisons. This view powers the trade comparison portion of the UI. |

---

*Generated: 2026-04-11 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TradeComparasionView | Type: View | Source: Sodreconciliation/Sodreconciliation/dbo/Views/dbo.TradeComparasionView.sql*
