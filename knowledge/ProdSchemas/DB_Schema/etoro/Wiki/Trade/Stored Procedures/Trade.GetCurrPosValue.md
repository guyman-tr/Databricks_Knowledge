# Trade.GetCurrPosValue

> Calculates the current profit value (in dollars, divided by 100) for a set of open positions specified via XML, using the Internal.GetNetProfit function.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns PositionID and current profit for specified positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure calculates the current unrealized profit for a list of positions. It accepts position IDs as XML, queries the Trade.Position view for open positions, and uses the Internal.GetNetProfit function to compute the real-time P&L based on current market prices. The result is divided by 100, converting from cents to dollars (the function stores values in cents).

This is used when a service or admin tool needs to know the current value of specific positions without calculating the full portfolio.

Data flow: Caller provides position IDs as XML -> procedure parses XML to temp table -> joins to Trade.Position view -> calls Internal.GetNetProfit for each position -> returns PositionID + Profit (in dollars).

---

## 2. Business Logic

### 2.1 Cents-to-Dollars Conversion

**What**: Internal.GetNetProfit returns values in cents; this procedure divides by 100 for dollar display.

**Columns/Parameters Involved**: `Internal.GetNetProfit`, result

**Rules**:
- Internal.GetNetProfit calculates real-time PnL based on current market rates
- Division by 100 converts from internal cents representation to dollar display value
- Only open positions (from Trade.Position view, which filters StatusID=1) are included

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionIDs | XML | NO | - | CODE-BACKED | XML containing position IDs to evaluate. Format: `<Root><PositionID>123</PositionID><PositionID>456</PositionID></Root>`. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Position identifier. |
| 2 | Profit | MONEY | - | - | CODE-BACKED | Current unrealized profit in dollars. Computed: Internal.GetNetProfit(PositionID) / 100. Positive = profit, negative = loss. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | JOIN | Filters to open positions matching the XML input |
| PositionID | Internal.GetNetProfit | Function call | Calculates real-time PnL for each position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin/Portfolio Tools | EXEC | Caller | Ad-hoc position value lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrPosValue (procedure)
├── Trade.Position (view)
│   └── Trade.PositionTbl (table)
└── Internal.GetNetProfit (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Source of open positions |
| Internal.GetNetProfit | Function | Real-time PnL calculation per position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin/Portfolio Tools | External | Position value lookup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- XML parsing may be slow for large position lists
- Internal.GetNetProfit is called per-row (scalar function) - may cause performance issues for many positions
- No SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 Execute for specific positions

```sql
DECLARE @xml XML = '<Root><PositionID>123456789</PositionID><PositionID>987654321</PositionID></Root>';
EXEC Trade.GetCurrPosValue @PositionIDs = @xml;
```

### 8.2 Get current value of a single position

```sql
SELECT PositionID, Internal.GetNetProfit(PositionID) / 100 AS Profit
FROM Trade.Position WITH (NOLOCK)
WHERE PositionID = 123456789;
```

### 8.3 Find most profitable open positions

```sql
SELECT TOP 10 PositionID, Internal.GetNetProfit(PositionID) / 100 AS Profit
FROM Trade.Position WITH (NOLOCK)
ORDER BY Internal.GetNetProfit(PositionID) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrPosValue | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCurrPosValue.sql*
