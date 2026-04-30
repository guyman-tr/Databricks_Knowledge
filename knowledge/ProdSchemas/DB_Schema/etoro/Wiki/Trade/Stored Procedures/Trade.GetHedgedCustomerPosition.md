# Trade.GetHedgedCustomerPosition

> Returns open positions for an instrument that are NOT hedged by a specific hedge server - identifies unhedged customer exposure.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies customer positions on a given instrument that are NOT currently hedged by a specific hedge server. It returns position details including customer info, amounts (converted from cents to dollars), and a signed DEAL column showing net exposure direction. This is used by the dealing/risk team to understand unhedged exposure.

The procedure exists to support risk management and hedging analysis. When a hedge server handles certain customers, the dealing team needs to know which positions on a given instrument are NOT covered by that server - these represent unhedged risk. The NOT EXISTS filter excludes customers already mapped to the specified hedge server.

Data flow: caller passes @HedgeServerID and @InstrumentID. The SP first populates a table variable with the customer-to-hedge-server mapping via Internal.GetCustomerToHedgeServer. It then joins Trade.GetPosition (open positions), Trade.GetPositionInfo (position details), and Customer.Customer, filtering to the instrument and excluding customers already mapped to the given hedge server.

---

## 2. Business Logic

### 2.1 Unhedged Position Identification

**What**: Finds positions NOT covered by a specific hedge server by excluding mapped customers.

**Columns/Parameters Involved**: `@HedgeServerID`, `@InstrumentID`, `CID`, `@Map`

**Rules**:
- Internal.GetCustomerToHedgeServer returns the full CID-to-HedgeServer mapping
- Positions are excluded (NOT EXISTS) when the customer IS mapped to the specified hedge server
- Only open positions on the specified instrument are considered
- Result shows the "gap" - positions that need hedging coverage

### 2.2 Amount Conversion and Directional DEAL

**What**: Converts internal cents representation to dollars and signs the lot count by direction.

**Columns/Parameters Involved**: `Amount`, `NetProfit`, `IsBuy`, `LotCountDecimal`, `DEAL`

**Rules**:
- Amount and NetProfit are stored in cents internally; divided by 100.0 and cast to MONEY for display
- IsBuy is translated to 'Buy'/'Sell' text label in the Action column
- DEAL = positive LotCountDecimal for Buy, negative for Sell - representing net directional exposure

**Diagram**:
```
@Map = EXEC Internal.GetCustomerToHedgeServer
  [HedgeServerID, CID] - all customer-server mappings

Trade.GetPosition (open positions)
  JOIN Trade.GetPositionInfo (detail)
  JOIN Customer.Customer (username)
  WHERE InstrumentID = @InstrumentID
    AND NOT EXISTS (@Map WHERE CID matches AND HedgeServerID = @HedgeServerID)

Result: Positions on this instrument NOT hedged by this server
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server to check against. Positions for customers mapped to this server are EXCLUDED from results. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument to filter positions. FK to Trade.Instrument. |
| 3 | CID (output) | INT | NO | - | CODE-BACKED | Customer ID of the position owner. From Customer.Customer. |
| 4 | UserName (output) | VARCHAR | NO | - | CODE-BACKED | Customer's username. From Customer.Customer. |
| 5 | TradeID (output) | BIGINT | - | - | CODE-BACKED | Trade identifier. From Trade.GetPositionInfo. |
| 6 | PositionID (output) | BIGINT | NO | - | CODE-BACKED | Position identifier. Joined between GetPosition and GetPositionInfo. |
| 7 | Leverage (output) | INT | - | - | CODE-BACKED | Leverage multiplier for the position. From Trade.GetPosition. |
| 8 | Amount (output) | MONEY | - | - | CODE-BACKED | Position amount in dollars. Computed: CAST(Amount/100.0 AS MONEY) - converted from cents storage. |
| 9 | NetProfit (output) | MONEY | - | - | CODE-BACKED | Net profit/loss in dollars. Computed: CAST(NetProfit/100.0 AS MONEY) - converted from cents storage. |
| 10 | LotCountDecimal (output) | DECIMAL | - | - | CODE-BACKED | Decimal lot count from Trade.GetPositionInfo. |
| 11 | InstrumentName (output) | VARCHAR | - | - | CODE-BACKED | Instrument display name. From Trade.GetPositionInfo. |
| 12 | Action (output) | VARCHAR | - | - | CODE-BACKED | Direction label: 'Buy' when IsBuy=1, 'Sell' when IsBuy=0. Derived via CASE expression. |
| 13 | DEAL (output) | DECIMAL | - | - | CODE-BACKED | Signed lot count representing directional exposure: positive for Buy, negative for Sell. Used to calculate net unhedged exposure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetPosition | FROM | Open positions - filtered by InstrumentID |
| (body) | Trade.GetPositionInfo | FROM (JOIN) | Position detail including TradeID, LotCountDecimal, InstrumentName |
| (body) | Customer.Customer | FROM (JOIN) | Customer info - CID and UserName |
| @Map | Internal.GetCustomerToHedgeServer | EXEC (INSERT...EXEC) | Populates CID-to-HedgeServer mapping table variable |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin access for reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgedCustomerPosition (procedure)
+-- Trade.GetPosition (view)
+-- Trade.GetPositionInfo (view)
+-- Customer.Customer (table)
+-- Internal.GetCustomerToHedgeServer (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPosition | View | FROM - open positions filtered by InstrumentID |
| Trade.GetPositionInfo | View | FROM (JOIN) - position detail joined on PositionID |
| Customer.Customer | Table | FROM (JOIN) - customer CID and UserName |
| Internal.GetCustomerToHedgeServer | Procedure | EXEC - populates @Map table variable for NOT EXISTS filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a specific hedge server and instrument

```sql
EXEC Trade.GetHedgedCustomerPosition
    @HedgeServerID = 5,
    @InstrumentID = 1001;
```

### 8.2 Sum unhedged exposure by direction

```sql
DECLARE @Results TABLE (
    CID INT, UserName VARCHAR(20), TradeID BIGINT, PositionID BIGINT,
    Leverage INT, Amount MONEY, NetProfit MONEY, LotCountDecimal DECIMAL(18,8),
    InstrumentName VARCHAR(100), Action VARCHAR(4), DEAL DECIMAL(18,8)
);

INSERT INTO @Results
EXEC Trade.GetHedgedCustomerPosition @HedgeServerID = 5, @InstrumentID = 1001;

SELECT  SUM(CASE WHEN DEAL > 0 THEN DEAL ELSE 0 END) AS TotalBuyLots,
        SUM(CASE WHEN DEAL < 0 THEN DEAL ELSE 0 END) AS TotalSellLots,
        SUM(DEAL) AS NetExposure,
        SUM(Amount) AS TotalAmount
FROM    @Results;
```

### 8.3 Check specific customer's unhedged positions

```sql
DECLARE @Results TABLE (
    CID INT, UserName VARCHAR(20), TradeID BIGINT, PositionID BIGINT,
    Leverage INT, Amount MONEY, NetProfit MONEY, LotCountDecimal DECIMAL(18,8),
    InstrumentName VARCHAR(100), Action VARCHAR(4), DEAL DECIMAL(18,8)
);

INSERT INTO @Results
EXEC Trade.GetHedgedCustomerPosition @HedgeServerID = 5, @InstrumentID = 1001;

SELECT  *
FROM    @Results
WHERE   CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgedCustomerPosition | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetHedgedCustomerPosition.sql*
