# Trade.InsertDividend

> Inserts a single dividend event into Trade.IndexDividends for a validated index/ETF/ETF-type instrument, providing buy-side and sell-side payment amounts in USD.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT, @DividendDate DATE |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertDividend is the **legacy single-dividend insert entrypoint** for index and ETF instruments. It accepts the instrument, dividend ex-date, and per-unit payment amounts for buy and sell positions, validates that the instrument is eligible for dividends (InstrumentTypeID 4, 5, or 6), then inserts a single row into `Trade.IndexDividends`.

This SP was created in 2015 (FB 25519) to support dividend payments for index instruments, with ETF support added in 2016 (FB 33349). It is called by the `IndexDividend` service account, suggesting a dedicated application or integration that manages dividend data entry. For more complex scenarios (multiple dividends, position-type splits, correction handling), the newer `Trade.InsertIndexDividend` and `Trade.InsertMultipleIndexDividends` SPs are used instead.

Data flow: the calling service provides instrument and payment details; the SP validates the instrument type, then inserts. `Trade.IndexDividends` table defaults set `Status=0` (Pending) and other operational fields. The dividend then follows the standard lifecycle: Status=0 (Pending) -> Status=1 (In Progress, when PaymentDate passes) -> Status=2 (Completed, after payment processing).

---

## 2. Business Logic

### 2.1 Instrument Type Validation

**What**: Restricts dividend insertion to instruments capable of paying dividends.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.GetInstrument.InstrumentTypeID`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Trade.GetInstrument WHERE InstrumentID=@InstrumentID AND InstrumentTypeID IN (4,5,6))`
  - RAISERROR('The Instrument does not exist in the database or it has the wrong type', 16, 1)
- Valid InstrumentTypeIDs:
  - 4 = Index (original supported type, 2015)
  - 5 = Instruments that can have dividends (added FB 25519, 2015)
  - 6 = ETF (added FB 33349, 2016)
- Other instrument types (e.g., Crypto=10, Stocks=1, Currencies=2) are blocked

### 2.2 Dividend Row Insert

**What**: Inserts a single dividend event row with buy and sell payment amounts.

**Columns/Parameters Involved**: `@InstrumentID`, `@DividendDate`, `@BuyPaymentInDollars`, `@SellPaymentInDollars`

**Rules**:
- `INSERT INTO Trade.IndexDividends(InstrumentID, DividendDate, BuyPaymentInDollars, SellPaymentInDollars) VALUES (...)`
- `DividendDate` represents the ex-date - the date on which a position holder qualifies to receive the dividend
- `BuyPaymentInDollars` = per-unit payment for LONG (buy) positions
- `SellPaymentInDollars` = per-unit payment for SHORT (sell) positions (negative, representing a charge to short holders)
- Table defaults: Status=0, PaymentDate derived, DividendID auto-generated (IDENTITY)
- TRY/CATCH with THROW: exceptions propagate to caller (no silent failure)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument for which a dividend event is being created. Must exist in Trade.GetInstrument with InstrumentTypeID 4 (Index), 5 (dividend-eligible instruments), or 6 (ETF). SP raises an error for any other instrument type. |
| 2 | @DividendDate | DATE | NO | - | CODE-BACKED | The ex-dividend date - the date on which position holders are evaluated for dividend eligibility. Position holders on this date receive the dividend payment. Stored as DividendDate in Trade.IndexDividends. |
| 3 | @BuyPaymentInDollars | MONEY | NO | - | CODE-BACKED | Per-unit dividend payment in USD for LONG (buy) positions. Positive value credited to long position holders on the dividend payment date. |
| 4 | @SellPaymentInDollars | MONEY | NO | - | CODE-BACKED | Per-unit dividend adjustment in USD for SHORT (sell) positions. Typically negative (a charge) since short holders do not receive dividends but must compensate for them. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (validates via) | Trade.GetInstrument | READER | Validates @InstrumentID exists with InstrumentTypeID IN (4,5,6) |
| (inserts into) | Trade.IndexDividends | WRITER | Inserts one dividend event row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| IndexDividend service account | EXEC Trade.InsertDividend | Caller | SQL login 'IndexDividend' has GRANT EXECUTE - called by dividend management service/application |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertDividend (procedure)
|- Trade.GetInstrument (view/table, validation)
`-- Trade.IndexDividends (table, write target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View/Table | Validates instrument exists with correct InstrumentTypeID |
| Trade.IndexDividends | Table | Insert destination for dividend event |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| IndexDividend service account | External Application | Calls this SP to insert dividend records |
| Trade.InsertIndexDividend | Procedure | Newer sibling SP with extended parameters (PositionTypeID, Status, etc.) |
| Trade.InsertMultipleIndexDividends | Procedure | Batch variant for multiple dividends |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentTypeID check | Pre-check | RAISERROR if instrument not found or not type 4/5/6 |
| TRY/CATCH THROW | Error propagation | Exceptions propagate to caller |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Insert a dividend for an index instrument

```sql
EXEC Trade.InsertDividend
    @InstrumentID = 1001,
    @DividendDate = '2026-03-20',
    @BuyPaymentInDollars = 0.42,
    @SellPaymentInDollars = -0.42
```

### 8.2 Verify the inserted dividend

```sql
SELECT TOP 5 DividendID, InstrumentID, DividendDate, BuyPaymentInDollars, SellPaymentInDollars, Status
FROM Trade.IndexDividends WITH (NOLOCK)
WHERE InstrumentID = 1001
ORDER BY DividendID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. No dedicated Confluence page or Jira ticket found in the TRAD space.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 permissions file analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertDividend | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertDividend.sql*
