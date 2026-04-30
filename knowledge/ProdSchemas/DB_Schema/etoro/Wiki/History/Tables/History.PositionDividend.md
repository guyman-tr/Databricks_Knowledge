# History.PositionDividend

> Archive of paid stock position dividends. When Stocks.PayDividends processes a dividend payment, it atomically moves the paid record from Stocks.PositionDividend to this table via DELETE...OUTPUT INTO. Each row represents a single dividend payment made to a customer for a specific stock position.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionDividendID (int, IDENTITY PK) |
| **Partition** | No - CLUSTERED PK on [PRIMARY] |
| **Indexes** | 1 (CLUSTERED PK on PositionDividendID) |

---

## 1. Business Meaning

This table is the historical archive for stock (equity) position dividend payments. When a customer holds a stock position (Leverage=1) on a dividend record date, the system calculates their entitlement via `Stocks.CalcDividends` (writing to the live `Stocks.PositionDividend` queue). When the payment date arrives, `Stocks.PayDividends` credits the customer's balance, updates `History.Position_Extra.Dividend`, then archives the paid record here via DELETE...OUTPUT INTO.

The table has 0 rows in the current (clone) environment - dividend payments may not occur in this environment or records were not migrated. In production this table would contain the full history of all stock dividend payments made to position holders.

**Related table**: `Stocks.PositionDividend` is the live/pending queue. `History.Dividends` archives the stock dividend declarations. `History.Position_Extra` accumulates total dividend amounts per position.

**Key distinction**: The `IsHistory` and `IsProcessed` flags from `Stocks.PositionDividend` are NOT carried over to this archive - only the payment-relevant columns are preserved.

---

## 2. Business Logic

### 2.1 Delete-Output-Into Archive Pattern

**What**: Paid dividend records are archived atomically from the live queue to this table.

**Columns/Parameters Involved**: `PositionDividendID`, `Occurred`, `DividendID`, `CID`, `PositionID`, `Amount`, `PaymentDate`

**Rules**:
```sql
-- Stocks.PayDividends (after paying all customers and updating IsProcessed=1):
DELETE FROM Stocks.PositionDividend
OUTPUT DELETED.Occurred,
       DELETED.DividendID,
       DELETED.CID,
       DELETED.PositionID,
       DELETED.Amount,
       DELETED.PaymentDate
INTO History.PositionDividend
WHERE IsProcessed = 1
```
- Only `IsProcessed = 1` records are archived (unprocessed pending dividends remain in `Stocks.PositionDividend`)
- `IsHistory` (was position open or closed at dividend time) is dropped on archive - not stored in history
- `PositionDividendID` is an IDENTITY column on this table (new ID assigned at archive time, not preserved from Stocks.PositionDividend)

### 2.2 Dividend Calculation and Payment Flow

**What**: Two-step process: calculate entitlement, then pay and archive.

**Step 1 - Stocks.CalcDividends** (called when a dividend record date arrives):
```sql
-- Inserts into Stocks.PositionDividend (live queue):
INSERT INTO Stocks.PositionDividend (DividendID, CID, PositionID, IsHistory, Amount, PaymentDate, IsProcessed)
SELECT DividendID, CID, PositionID,
    CASE WHEN IsOpened = 1 THEN 0 ELSE 1 END AS IsHistory,  -- 0=open position, 1=closed position
    AmountInUnitsDecimal * AmountPerShare * ISNULL(c.DollarValue, 1),  -- in USD
    PaymentDate, 0
FROM Trade.GetPositionData a
    JOIN Stocks.Dividends b ON a.InstrumentID = b.InstrumentID AND ...
    JOIN @ConversionRates c ON a.InstrumentID = c.InstrumentID
WHERE a.Leverage = 1  -- stock positions only (not leveraged CFDs)
  AND RecordDate <= GETUTCDATE()
```

**Step 2 - Stocks.PayDividends** (called when payment date arrives):
1. For each pending dividend: calls `Customer.SetBalance` to credit customer (CreditTypeID=6, CompensationReasonID=45)
2. Updates `History.Position_Extra.Dividend` (cumulative dividend total for the position)
3. Sets `Stocks.PositionDividend.IsProcessed = 1`
4. After cursor loop: archives all processed records to this table via DELETE...OUTPUT INTO
5. Archives dividend declarations to `History.Dividends`

### 2.3 Amount Currency and Precision

**What**: The Amount stored here is in USD, calculated from per-share amount and unit count.

**Rules**:
- `Amount = AmountInUnitsDecimal * AmountPerShare * DollarValue` (conversion to USD via @ConversionRates)
- Stored as `decimal(18,4)` in this table (vs `money` in Stocks.PositionDividend - type coercion on INSERT)
- Paid to customer in full dollar amount (`Customer.SetBalance @Payment = @Amount`)
- Also written to `History.Position_Extra.Dividend` in cents (`@Payment = convert(int, @Amount * 100)`)

---

## 3. Data Overview

Table has 0 rows in the current (clone) environment. In production, expected columns:

| PositionDividendID | DividendID | CID | PositionID | Amount | Occurred | PaymentDate |
|-------------------|-----------|-----|-----------|--------|----------|-------------|
| (IDENTITY - new ID at archive time) | (FK to Stocks.Dividends at time of calc) | (copier CID) | (position bigint) | (USD amount, decimal 4dp) | (when calculated) | (scheduled payment date) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionDividendID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-generated archive ID. New IDENTITY value assigned at archive time (not preserved from Stocks.PositionDividend). PK. |
| 2 | Occurred | datetime | NO | - | CODE-BACKED | When the dividend entitlement was calculated (the record date processing time). Populated from Stocks.PositionDividend.Occurred at archive time. |
| 3 | DividendID | int | NO | - | CODE-BACKED | References the dividend declaration (Stocks.Dividends at calculation time, History.Dividends after archive). Identifies which corporate dividend event this payment relates to. |
| 4 | CID | int | NO | - | CODE-BACKED | The customer who received this dividend payment. Must have held a stock position (Leverage=1) on the dividend record date. |
| 5 | PositionID | bigint | NO | - | CODE-BACKED | The stock position that generated this dividend entitlement. bigint (changed from int in Nov 2021 for large position IDs per Stocks.PayDividends comment). |
| 6 | Amount | decimal(18,4) | NO | - | CODE-BACKED | The dividend amount paid in USD. Calculated as AmountInUnitsDecimal * AmountPerShare * DollarValue. Stored as decimal(18,4) here vs money in the live queue (type coercion on archive). |
| 7 | PaymentDate | datetime | NO | - | CODE-BACKED | The scheduled dividend payment date (from the dividend declaration). The date when Stocks.PayDividends was triggered to credit the customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Customer.Customer | CID | Implicit FK (no constraint) | The customer who received the dividend. |
| History.Position_Active / Trade.PositionTbl | PositionID | Implicit FK (no constraint) | The stock position that generated the entitlement. bigint FK. |
| History.Dividends | DividendID | Implicit FK (no constraint) | The dividend declaration (archived concurrently by Stocks.PayDividends). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Stocks.PayDividends | PositionDividendID | Writer (archive-on-delete) | Deletes from Stocks.PositionDividend and outputs into this table for all IsProcessed=1 records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionDividend (table)
- Written by: Stocks.PayDividends
  - DELETE Stocks.PositionDividend OUTPUT INTO History.PositionDividend WHERE IsProcessed = 1
  - Called on each dividend PaymentDate
- Upstream population: Stocks.CalcDividends
  - Inserts into Stocks.PositionDividend (live queue) on each dividend RecordDate
  - Reads from Trade.GetPositionData, Stocks.Dividends, @ConversionRates
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependencies: Customer.Customer (CID), History.Position_Active (PositionID), History.Dividends (DividendID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none identified in SSDT) | - | Archive table - no downstream dependents found in SSDT |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dividend | CLUSTERED | PositionDividendID ASC | - | - | Active (no compression specified, PRIMARY filegroup) |

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_Dividend | PRIMARY KEY | PositionDividendID ASC - clustered |

Note: No DEFAULTs on this table. Stocks.PositionDividend has DEFAULT Occurred=getutcdate() but that is consumed before archival.

---

## 8. Sample Queries

### 8.1 Dividend payment history for a customer

```sql
SELECT
    h.PositionDividendID,
    h.DividendID,
    h.PositionID,
    h.Amount,
    h.Occurred,
    h.PaymentDate
FROM History.PositionDividend h WITH (NOLOCK)
WHERE h.CID = @CID
ORDER BY h.PaymentDate DESC;
```

### 8.2 All dividends paid for a specific position

```sql
SELECT
    h.PositionDividendID,
    h.DividendID,
    h.Amount,
    h.Occurred,
    h.PaymentDate
FROM History.PositionDividend h WITH (NOLOCK)
WHERE h.PositionID = @PositionID
ORDER BY h.PaymentDate DESC;
```

### 8.3 Total dividends paid per customer

```sql
SELECT
    h.CID,
    COUNT(*) AS PaymentCount,
    SUM(h.Amount) AS TotalDividendUSD
FROM History.PositionDividend h WITH (NOLOCK)
GROUP BY h.CID
ORDER BY TotalDividendUSD DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Stocks.CalcDividends, Stocks.PayDividends) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionDividend | Type: Table | Source: etoro/etoro/History/Tables/History.PositionDividend.sql*
