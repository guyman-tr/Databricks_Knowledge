# Trade.GetRateInDollarsForDividends

> Converts dividend values from their native currency to USD by resolving the current exchange rate for each dividend's currency, using Trade.GetMoneyConversionsView and Trade.CurrencyPrice.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Dividends [Trade].[DividendTbl] READONLY |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure takes a batch of DividendIDs and returns the USD conversion data needed to pay each dividend. Dividends on eToro are declared in a native currency (the currency of the underlying instrument or exchange), but all payments to users are processed in USD. This procedure bridges that gap by looking up each dividend's currency, then fetching the current bid rate for converting that currency to USD.

The procedure is called by the DividendsApp service (EXECUTE permission granted to DividendsApp DB user) as part of the dividend payment pipeline. For each DividendID passed in, it returns the dividend's value in its native currency plus all the conversion metadata: whether conversion is needed (ShouldConvert), the current exchange rate (Bid), and whether to divide or multiply by that rate (IsReciprocal). The caller then performs the actual multiplication to produce the USD amount.

Data flows: @Dividends (table-valued param) -> JOIN Trade.IndexDividends (get DividendValueInCurrency + DividendCurrencyID) -> JOIN Trade.GetMoneyConversionsView (get ShouldConvert, IsReciprocal, ConversionInstrumentID) -> JOIN curentPrice CTE (Trade.CurrencyPrice UNION sentinel) -> return conversion package. The elegant CTE design means USD dividends (ShouldConvert=0) get the sentinel row (Bid=-1) while non-USD dividends get their actual CurrencyPrice row.

---

## 2. Business Logic

### 2.1 Conditional CurrencyPrice JOIN via CTE

**What**: A CTE pre-unions a sentinel row into CurrencyPrice so that USD dividends (needing no conversion) can be joined without a special NULL/CASE branch.

**Columns/Parameters Involved**: `ShouldConvert`, `Bid`, `ConversionInstrumentID`

**Rules**:
- Real=1 rows come from Trade.CurrencyPrice (actual current market rates).
- Real=0 is the sentinel row (InstrumentID=-1, Bid=-1): used when ShouldConvert=0 (dividend is already in USD).
- JOIN condition: if ShouldConvert=0, match the sentinel (CP.Real=0); if ShouldConvert=1, match CurrencyPrice by ConversionInstrumentID (CP.Real=1 AND MCV.ConversionInstrumentID=CP.InstrumentID).
- This means USD dividends always return Bid=-1 (sentinel), which the caller ignores because ShouldConvert=0.

**Diagram**:
```
CurrencyPrice UNION sentinel:
  Real=1: EURUSD Bid=1.0850, GBPUSD Bid=1.2700, ...
  Real=0: InstrumentID=-1, Bid=-1 (sentinel for USD)

JOIN logic:
  ShouldConvert=0 (USD dividend) -> JOIN Real=0 (sentinel, Bid=-1, ignored by caller)
  ShouldConvert=1 (EUR dividend) -> JOIN Real=1 WHERE InstrumentID=EURUSD InstrumentID

Caller applies:
  ShouldConvert=0: USD amount = DividendValueInCurrency (no conversion)
  ShouldConvert=1, IsReciprocal=0: USD amount = DividendValueInCurrency * Bid
  ShouldConvert=1, IsReciprocal=1: USD amount = DividendValueInCurrency / Bid
```

### 2.2 Batch Processing via Table-Valued Parameter

**What**: Multiple dividends can be converted in a single call using the DividendTbl UDT.

**Columns/Parameters Involved**: `@Dividends [Trade].[DividendTbl]`, `DividendID`

**Rules**:
- [Trade].[DividendTbl] is a UDT containing a single column: DividendID INT.
- Caller passes a pre-populated table variable; procedure JOINs to it for set-based processing.
- All dividends in the batch share the same CurrencyPrice snapshot (consistent rates within one call).
- Non-existent DividendIDs in @Dividends silently return no rows (INNER JOIN).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Dividends | [Trade].[DividendTbl] READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the DividendIDs to process. DividendTbl UDT has a single column: DividendID INT. Caller populates this with the batch of dividends requiring USD conversion. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DividendValueInCurrency | DECIMAL(16,8) | NO | - | CODE-BACKED | The dividend value in the dividend's native currency (from Trade.IndexDividends.DividendValueInCurrency, cast to DECIMAL(16,8)). This is the raw amount before USD conversion. |
| 3 | ShouldConvert | bit/int | NO | - | VERIFIED | Conversion flag from Trade.GetMoneyConversionsView: 0=dividend is already in USD (no conversion needed), 1=must convert using the Bid rate. Inherited from GetMoneyConversionsView. |
| 4 | IsReciprocal | int | NO | - | VERIFIED | Reciprocal flag from Trade.GetMoneyConversionsView: 0=multiply DividendValueInCurrency by Bid, 1=divide by Bid. -1=sentinel (only when ShouldConvert=0). Inherited from GetMoneyConversionsView. |
| 5 | Bid | money/decimal | NO | - | CODE-BACKED | Current market bid rate for the conversion instrument. From Trade.CurrencyPrice. -1 when ShouldConvert=0 (USD, sentinel row - caller must check ShouldConvert before using Bid). |
| 6 | DividendID | INT | NO | - | CODE-BACKED | Dividend identifier echoed back to correlate output rows with input @Dividends rows. From Trade.IndexDividends. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Trade.IndexDividends | Reader via JOIN | Dividend event data: DividendValueInCurrency, DividendCurrencyID |
| DividendCurrencyID | Trade.GetMoneyConversionsView | Reader via JOIN | Currency-to-USD conversion metadata: ShouldConvert, IsReciprocal, ConversionInstrumentID |
| ConversionInstrumentID | Trade.CurrencyPrice | Reader via CTE JOIN | Current market bid rate for the conversion instrument |
| @Dividends | [Trade].[DividendTbl] | UDT reference | Table-valued input parameter type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp service | @Dividends | Application call | EXECUTE permission granted to DividendsApp DB user - called during dividend payment processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRateInDollarsForDividends (procedure)
+-- Trade.IndexDividends (table) - dividend event data
+-- Trade.GetMoneyConversionsView (view) - currency conversion metadata
|     +-- Trade.GetCurrencyConversionsView (view)
|     +-- Dictionary.Currency (table - cross-schema)
+-- Trade.CurrencyPrice (table) - live exchange rates
+-- [Trade].[DividendTbl] (UDT) - input parameter type
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | INNER JOIN on DividendID to get DividendValueInCurrency and DividendCurrencyID |
| Trade.GetMoneyConversionsView | View | INNER JOIN on DividendCurrencyID to get ShouldConvert, IsReciprocal, ConversionInstrumentID |
| Trade.CurrencyPrice | Table | CTE JOIN on ConversionInstrumentID to get current Bid rate |
| [Trade].[DividendTbl] | UDT | Table-valued input parameter type (DividendID INT) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp service | External application | USD conversion step in dividend payment pipeline |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| INNER JOIN Trade.IndexDividends | Implicit filter | DividendIDs not present in IndexDividends return no rows |
| INNER JOIN Trade.GetMoneyConversionsView | Implicit filter | Dividends with unknown/unmapped currency return no rows |
| CTE sentinel (Real=0) | Design pattern | Allows uniform JOIN logic for USD (ShouldConvert=0) without CASE/ISNULL branching |

---

## 8. Sample Queries

### 8.1 Convert rates for a batch of dividends

```sql
-- Declare and populate table-valued parameter, then call
DECLARE @Divs [Trade].[DividendTbl];
INSERT INTO @Divs (DividendID) VALUES (1001), (1002), (1003);
EXEC Trade.GetRateInDollarsForDividends @Dividends = @Divs;
```

### 8.2 Equivalent inline query showing conversion logic

```sql
WITH curentPrice (Real, InstrumentID, Bid) AS (
    SELECT 1, InstrumentID, Bid FROM Trade.CurrencyPrice WITH (NOLOCK)
    UNION
    SELECT 0, -1, -1
)
SELECT
    CAST(TIDS.DividendValueInCurrency AS DECIMAL(16,8)) AS DividendValueInCurrency,
    MCV.ShouldConvert,
    MCV.IsReciprocal,
    CP.Bid,
    TIDS.DividendID
FROM Trade.IndexDividends TIDS WITH (NOLOCK)
INNER JOIN Trade.GetMoneyConversionsView MCV WITH (NOLOCK)
    ON TIDS.DividendCurrencyID = MCV.CurrencyID
INNER JOIN curentPrice CP ON (
    (MCV.ShouldConvert = 0 AND CP.Real = 0)
    OR (MCV.ShouldConvert = 1 AND CP.Real = 1 AND MCV.ConversionInstrumentID = CP.InstrumentID)
)
WHERE TIDS.DividendID IN (1001, 1002, 1003);
```

### 8.3 Check what dividends need currency conversion vs pass-through

```sql
SELECT TIDS.DividendID, TIDS.DividendCurrencyID,
       MCV.ShouldConvert,
       CASE WHEN MCV.ShouldConvert = 0 THEN 'Already USD - no conversion'
            WHEN MCV.IsReciprocal = 0 THEN 'Multiply by Bid rate'
            ELSE 'Divide by Bid rate'
       END AS ConversionMethod
FROM Trade.IndexDividends TIDS WITH (NOLOCK)
INNER JOIN Trade.GetMoneyConversionsView MCV WITH (NOLOCK)
    ON TIDS.DividendCurrencyID = MCV.CurrencyID
WHERE TIDS.Status IN (0, 1);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (DividendsApp) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRateInDollarsForDividends | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRateInDollarsForDividends.sql*
