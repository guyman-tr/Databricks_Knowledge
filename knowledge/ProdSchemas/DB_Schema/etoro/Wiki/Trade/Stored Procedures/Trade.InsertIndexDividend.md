# Trade.InsertIndexDividend

> Full-featured dividend event insert used by the DividendsApp service: validates correction dividend integrity, sets initial Status based on correction vs regular dividend, and returns the new DividendID via OUTPUT.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT, @ExDate DATE, @DividendID INT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertIndexDividend is the **primary dividend creation entrypoint** used by the DividendsApp application. Unlike the legacy `Trade.InsertDividend` (which takes simple buy/sell USD amounts), this SP supports the full dividend data model: position type separation (CFD vs REAL), multi-currency dividend amounts, tax codes and rates, ex-date vs payment-date distinction, correction workflows (CorrectionDividendID), and negative dividend allowance.

This SP exists because the dividend lifecycle is complex: dividends may be in any currency (converted to USD later), may affect CFD and REAL positions differently (via PositionType), and may be corrections to prior erroneous dividends. The correction validation (via `Trade.ValidateCorrectionDividendId`) enforces that a correction references a real, consistent original dividend before the row is inserted with Status=4 (Correction Pending) instead of Status=0 (Pending).

Data flow: the DividendsApp calls this SP when a new dividend event is submitted. The SP validates the correction reference, inserts into `Trade.IndexDividends` with appropriate initial status, and returns the generated DividendID via OUTPUT. The dividend then follows the standard pipeline: Status=0/4 (pending) -> Status=1 (in progress, when PaymentDate passes and GetCIDsForIndexDividends picks it up) -> Status=2 (completed).

---

## 2. Business Logic

### 2.1 Correction Dividend Validation

**What**: Validates that a correction dividend references a valid original dividend with matching ExDate and DividendCurrencyID.

**Columns/Parameters Involved**: `@CorrectionDividendID`, `@ExDate`, `@DividendCurrencyID`

**Rules**:
- Calls `Trade.ValidateCorrectionDividendId(@CorrectionDividendID, @ExDate, @DividendCurrencyID)` which returns `isValid BIT`
- If `@CorrectionDividendID IS NULL`: function returns `isValid=1` (regular dividend - no correction to validate)
- If `@CorrectionDividendID IS NOT NULL`: validates that the original dividend's ExDate AND DividendCurrencyID match the provided values
- If validation fails (`isValid != 1`): `THROW 50005, N'The ExDate and DividendCurrencyID must be equals to original one', 1`
- This prevents corrections that accidentally reference the wrong original dividend

### 2.2 Initial Status Based on Correction Type

**What**: Sets the initial Status of the new dividend row based on whether it is a regular or correction dividend.

**Columns/Parameters Involved**: `@CorrectionDividendID`, `Status`

**Rules**:
- `Status = IIF(@CorrectionDividendID IS NULL, 0, 4)`
- Status=0 (Pending): Regular new dividend - awaiting PaymentDate
- Status=4 (Correction Pending): Correction dividend - treated like pending but identified as a correction
- Status progression after insert is handled by `Trade.GetCIDsForIndexDividends`: 0/4 -> 1 (In Progress) -> 2 (Completed)

**Diagram**:
```
@CorrectionDividendID NULL?
  YES -> Status = 0 (Pending)
  NO  -> Validate ExDate + DividendCurrencyID match original
         PASS -> Status = 4 (Correction Pending)
         FAIL -> THROW 50005
```

### 2.3 Position Type Separation

**What**: Each dividend row is tied to a specific position type (CFD or REAL), allowing different payment processing for each.

**Columns/Parameters Involved**: `@PositionType`

**Rules**:
- `@PositionType TINYINT` - typically 1=CFD, 2=REAL (position type code)
- A single dividend event may result in two SP calls: one for PositionType=1 (CFD holders), one for PositionType=2 (REAL holders)
- DividendValueInCurrency, BuyTax, SellTax can differ between position types

### 2.4 Multi-Currency Dividend Value

**What**: Dividends are stored in their original declaration currency, with USD conversion handled later by the payment pipeline.

**Columns/Parameters Involved**: `@DividendValueInCurrency`, `@DividendCurrencyID`

**Rules**:
- `@DividendValueInCurrency MONEY` - per-share/per-unit dividend amount in `@DividendCurrencyID`
- `@DividendCurrencyID INT` - FK to Dictionary/Trade currency table (1=USD, others as needed)
- `Trade.GetRateInDollarsForDividends` (accessible by DividendsApp) converts to USD during payment processing

### 2.5 RetakeDividend Support

**What**: Allows a dividend to reference a prior dividend that is being retaken/reversed.

**Columns/Parameters Involved**: `@RetakeDividendID`

**Rules**:
- `@RetakeDividendID INT = NULL` (optional)
- Non-NULL when this dividend is a retake/reversal of a previously paid dividend
- Stored directly in Trade.IndexDividends.RetakeDividendID for downstream payment logic

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument for which the dividend is declared. No type validation in this SP (unlike Trade.InsertDividend) - instrument type is assumed valid by the calling DividendsApp. |
| 2 | @PositionType | TINYINT | NO | - | CODE-BACKED | Position type for this dividend row. 1=CFD, 2=REAL. Separates dividend events by position type since CFD and REAL holders may have different tax treatments and payment amounts. |
| 3 | @TaxCode | VARCHAR(40) | NO | - | CODE-BACKED | Tax code identifying the dividend tax regime (e.g., country-specific withholding tax rules). Stored in TaxCode column for reference during payment processing. |
| 4 | @EventType | VARCHAR(40) | NO | - | CODE-BACKED | Type of dividend event (e.g., 'CASH', 'SPECIAL', 'RETURN_OF_CAPITAL'). Categorizes the dividend for display and processing purposes. |
| 5 | @ExDate | DATE | NO | - | CODE-BACKED | Ex-dividend date - the date on which position holders are evaluated for eligibility. Positions open on this date receive the dividend. Also used for correction validation. |
| 6 | @PaymentDate | DATE | NO | - | CODE-BACKED | The date on which dividend payments are processed. Trade.GetCIDsForIndexDividends advances Status from 0 to 1 when PaymentDate arrives. |
| 7 | @DividendValueInCurrency | MONEY | NO | - | CODE-BACKED | Per-share dividend amount in the declaration currency (@DividendCurrencyID). Converted to USD by the payment pipeline using Trade.GetRateInDollarsForDividends. |
| 8 | @DividendCurrencyID | INT | NO | - | CODE-BACKED | Currency of the dividend declaration. Used in correction validation (must match original when CorrectionDividendID is provided). 1=USD; other values for foreign-currency dividends. |
| 9 | @BuyTax | DECIMAL(6,4) | NO | - | CODE-BACKED | Withholding tax rate applied to LONG (buy) position holders. E.g., 0.15 = 15% tax. Applied during dividend payment to reduce the gross amount paid. |
| 10 | @SellTax | DECIMAL(6,4) | NO | - | CODE-BACKED | Tax rate applied to SHORT (sell) position holders. May differ from BuyTax based on jurisdiction rules. |
| 11 | @CorrectionDividendID | INT | YES | NULL | CODE-BACKED | DividendID of the original dividend being corrected. If NULL: regular dividend (Status=0). If non-NULL: correction (Status=4); ExDate and DividendCurrencyID are validated against the original via Trade.ValidateCorrectionDividendId. |
| 12 | @NegativeDividendAllowed | BIT | YES | NULL | CODE-BACKED | Controls whether this dividend can result in a negative payment to customers. NULL defaults to standard behavior (no negative). Used for special dividend types where deductions may exceed the dividend amount. |
| 13 | @RetakeDividendID | INT | YES | NULL | CODE-BACKED | DividendID of a previously paid dividend being retaken/reversed. Non-NULL when this dividend corrects or reverses a prior payment. Used by downstream payment processing to net against the original. |
| 14 | @DividendID | INT OUTPUT | NO | - | CODE-BACKED | OUTPUT parameter. Returns the SCOPE_IDENTITY() of the newly inserted row (auto-generated DividendID from Trade.IndexDividends IDENTITY column). Caller uses this to track the new dividend and link it to subsequent operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calls) | Trade.ValidateCorrectionDividendId | Function call | Validates CorrectionDividendID integrity (ExDate + DividendCurrencyID must match original) |
| (inserts into) | Trade.IndexDividends | WRITER | Inserts one dividend event row with full metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp service account | EXEC Trade.InsertIndexDividend | Caller | SQL login 'DividendsApp' has GRANT EXECUTE - called by the dividends processing application |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertIndexDividend (procedure)
|- Trade.ValidateCorrectionDividendId (function, correction validation)
`-- Trade.IndexDividends (table, write target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ValidateCorrectionDividendId | Function | Called to validate CorrectionDividendID integrity before insert |
| Trade.IndexDividends | Table | Insert destination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp service | Application | Primary caller - creates dividend events via this SP |
| Trade.InsertDividend | Procedure | Legacy sibling (simpler params, no correction support, InstrumentTypeID check) |
| Trade.InsertMultipleIndexDividends | Procedure | Batch variant; may delegate to this SP per row |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Correction validation | Pre-insert check | THROW 50005 if CorrectionDividendID provided but ExDate/DividendCurrencyID mismatch |
| Status auto-set | IIF expression | Status = 0 for regular, 4 for correction; caller cannot override |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| OUTPUT parameter | SCOPE_IDENTITY() | Returns the generated DividendID to the caller |

---

## 8. Sample Queries

### 8.1 Insert a regular dividend

```sql
DECLARE @NewDividendID INT
EXEC Trade.InsertIndexDividend
    @InstrumentID = 1001,
    @PositionType = 1,         -- CFD
    @TaxCode = 'US_15PCT',
    @EventType = 'CASH',
    @ExDate = '2026-03-20',
    @PaymentDate = '2026-03-25',
    @DividendValueInCurrency = 0.42,
    @DividendCurrencyID = 1,   -- USD
    @BuyTax = 0.15,
    @SellTax = 0.00,
    @DividendID = @NewDividendID OUTPUT

SELECT @NewDividendID AS NewDividendID
```

### 8.2 Insert a correction dividend

```sql
DECLARE @CorrectionDividendID INT
EXEC Trade.InsertIndexDividend
    @InstrumentID = 1001,
    @PositionType = 1,
    @TaxCode = 'US_15PCT',
    @EventType = 'CASH',
    @ExDate = '2026-03-20',       -- must match original
    @PaymentDate = '2026-03-28',
    @DividendValueInCurrency = 0.45,  -- corrected amount
    @DividendCurrencyID = 1,      -- must match original
    @BuyTax = 0.15,
    @SellTax = 0.00,
    @CorrectionDividendID = 5001, -- original DividendID being corrected
    @DividendID = @CorrectionDividendID OUTPUT
-- Status will be 4 (Correction Pending)
```

### 8.3 Check dividend status pipeline

```sql
SELECT DividendID, InstrumentID, ExDate, PaymentDate, Status, CorrectionDividendID
FROM Trade.IndexDividends WITH (NOLOCK)
WHERE InstrumentID = 1001
ORDER BY DividendID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Guide for creating and running Dividends in STG environment | Confluence (TRAD space) | Context on dividend creation and processing workflow in staging environments |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 permissions file + 1 function analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertIndexDividend | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertIndexDividend.sql*
