# Trade.PositionOpenForFork

> Opens a new position on behalf of a customer as part of an instrument fork operation, handling negative balance compensation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @PositionID - the newly created position |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new position when an instrument is forked (split into two instruments). Customers who held the old instrument receive equivalent positions on the new instrument. The procedure handles the edge case where a customer has negative balance: it temporarily adds compensation so the position can be opened, then deducts the excess after the position is created.

Without this procedure, Trade.ForkByDB could not create positions for individual customers during a fork. The procedure ensures leverage is 1, IsBuy is 1, and uses a standard "Opened by Fork" description for auditability.

Data flows when Trade.ForkByDB iterates over eligible customers and calls this procedure for each. The procedure reads BackOffice.Customer for ManagerID, Customer.CustomerMoney for credit, calls Customer.SetBalanceCompensation when needed, and delegates position creation to Trade.PositionOpen.

---

## 2. Business Logic

### 2.1 Negative Balance Compensation

**What**: Customers with negative credit cannot open positions. The procedure adds compensation equal to position amount plus absolute credit, then opens the position, then deducts the extra compensation.

**Columns/Parameters Involved**: `@CustomerCredit`, `@Amount`, `@SetBalancePayment`, `Customer.SetBalanceCompensation`

**Rules**:
- SetBalancePayment = IIF(Credit >= 0, Amount, Amount + ABS(Credit))
- First SetBalanceCompensation: adds SetBalancePayment with Description 'Fork'
- After PositionOpen: if CustomerCredit < 0, second SetBalanceCompensation with Payment = CustomerCredit and Description 'Fork - User had negetive balance.'

### 2.2 Fork Position Defaults

**What**: Fork positions use fixed values for certain attributes.

**Columns/Parameters Involved**: `IsBuy`, `Leverage`, `CurrencyID`, `ProviderID`, `Description`

**Rules**:
- IsBuy = 1 (always buy for fork)
- Leverage = 1
- CurrencyID = 1
- ProviderID = 1
- Description = 'Opened by Fork'

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | OUTPUT | - | CODE-BACKED | Returns the newly created position ID from Trade.PositionOpen |
| 2 | @pCID | int | NO | - | CODE-BACKED | Customer ID. Customer who receives the forked position. |
| 3 | @pInstrumentID | int | NO | - | CODE-BACKED | New instrument ID (post-fork). |
| 4 | @pAmountInUnitsDecimal | decimal(16,6) | NO | - | CODE-BACKED | Amount in units for the new position. |
| 5 | @pAmount | money | NO | - | CODE-BACKED | Position amount. Converted to cents (Amount * 100) internally. |
| 6 | @pInitForexRate | dtPrice | NO | - | CODE-BACKED | Initial forex rate for the new instrument. |
| 7 | @pUnitMargin | dtPrice | NO | - | CODE-BACKED | Unit margin for the new instrument. |
| 8 | @pLimitRate | dtPrice | NO | - | CODE-BACKED | Take-profit rate. |
| 9 | @pStopRate | dtPrice | NO | - | CODE-BACKED | Stop-loss rate. |
| 10 | @pHedgeServerID | int | NO | - | CODE-BACKED | Hedge server ID. |
| 11 | @pReason | int | NO | - | CODE-BACKED | Compensation reason ID passed to SetBalanceCompensation. |
| 12 | @pUnits | int | NO | - | CODE-BACKED | Number of units. Used to derive LotCountDecimal. |
| 13 | @InitForexPriceRateID | bigint | NO | - | CODE-BACKED | Initial forex price rate ID. |
| 14 | @LastOpConversionRate | dtPrice | NO | - | CODE-BACKED | Last operation conversion rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | BackOffice.Customer | Implicit | ManagerID for SetBalanceCompensation |
| SELECT | Customer.CustomerMoney | Implicit | Credit for negative balance check |
| EXEC | Customer.SetBalanceCompensation | Procedure call | Add/deduct compensation |
| EXEC | Trade.PositionOpen | Procedure call | Create the forked position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ForkByDB | EXEC | Procedure call | Invokes for each eligible customer during fork |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionOpenForFork (procedure)
├── BackOffice.Customer (table)
├── Customer.CustomerMoney (table)
├── Customer.SetBalanceCompensation (procedure)
└── Trade.PositionOpen (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | SELECT ManagerID by CID |
| Customer.CustomerMoney | Table | SELECT Credit for negative balance logic |
| Customer.SetBalanceCompensation | Procedure | EXEC for compensation add/deduct |
| Trade.PositionOpen | Procedure | EXEC to create position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ForkByDB | Procedure | Calls for each CID during instrument fork |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Uses SET XACT_ABORT ON and TRY/CATCH with transaction management.

---

## 8. Sample Queries

### 8.1 Call procedure to open a fork position
```sql
DECLARE @PositionID BIGINT;
EXEC Trade.PositionOpenForFork
    @PositionID = @PositionID OUTPUT,
    @pCID = 1000,
    @pInstrumentID = 500,
    @pAmountInUnitsDecimal = 10.5,
    @pAmount = 1000.00,
    @pInitForexRate = 50000.0,
    @pUnitMargin = 5000.0,
    @pLimitRate = 55000.0,
    @pStopRate = 45000.0,
    @pHedgeServerID = 1,
    @pReason = 1,
    @pUnits = 10,
    @InitForexPriceRateID = 12345,
    @LastOpConversionRate = 1.0;
```

### 8.2 Verify new position after fork
```sql
SELECT PositionID, CID, InstrumentID, Amount, AmountInUnitsDecimal, Leverage, IsBuy
FROM Trade.Position WITH (NOLOCK)
WHERE PositionID = @PositionID;
```

### 8.3 Check customer credit before fork (negative balance scenario)
```sql
SELECT CID, Credit, RealizedEquity
FROM Customer.CustomerMoney WITH (NOLOCK)
WHERE CID = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionOpenForFork | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionOpenForFork.sql*
