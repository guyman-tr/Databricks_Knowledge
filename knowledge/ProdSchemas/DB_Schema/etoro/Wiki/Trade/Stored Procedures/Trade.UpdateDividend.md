# Trade.UpdateDividend

> Updates a pending dividend record's instrument, date, and payment amounts; validates the instrument is an index type and the dividend date is not in the past before committing the change.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendID - identifies the dividend record to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateDividend is the write path for correcting or updating a scheduled dividend event in `Trade.IndexDividends` before it enters processing. After operations teams create a dividend record (via Trade.InsertDividend), they may need to fix the payment amounts, correct the InstrumentID, or adjust the DividendDate before PaymentDate arrives. This procedure enforces the two business rules that gate any such correction: the instrument must be a valid index/stock type (InstrumentTypeID=4), and the dividend date must not already be in the past.

The procedure only updates rows with `Status=0` (Pending) - once a dividend advances to Status=1 (In Progress) or Status=2 (Completed), it is immutable by this procedure. This is the safety net that prevents corrections to dividend events already being processed or paid.

The `IndexDividend` database role has EXECUTE permission on this procedure - it is invoked via OpsFlow admin tooling used by operations teams managing the dividend calendar.

Note: The DDL contains a copy-paste bug - the date validation RAISERROR appears twice consecutively with different error messages, but both check the same condition (`@DividendDate < GETUTCDATE()`). The second message incorrectly reads "Can not delete a record about an event that already occurred" (copied from Trade.DeleteDividend). This is a cosmetic code defect; functionally only one check is needed and the behavior is correct (both fire together before the UPDATE).

---

## 2. Business Logic

### 2.1 Instrument Type Validation - Index/Stock Only

**What**: Verifies the supplied InstrumentID is an active index or stock instrument before allowing any update.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.GetInstrument.InstrumentTypeID`

**Rules**:
- Queries `Trade.GetInstrument` view WHERE InstrumentID=@InstrumentID AND InstrumentTypeID=4
- InstrumentTypeID=4 = Index/Stock instruments (the only type for which dividends exist)
- If the instrument does not exist OR exists with a different InstrumentTypeID, RAISERROR fires: "The Instrument does not exist in the database or it has the wrong type"
- This prevents associating a dividend event with a non-dividend-paying instrument (e.g., FX pair, crypto)

### 2.2 Future-Date Validation - No Past Dividends

**What**: Blocks updates to dividend records whose date has already passed, preventing correction of events that are no longer pending.

**Columns/Parameters Involved**: `@DividendDate`, `GETUTCDATE()`

**Rules**:
- `IF @DividendDate < GETUTCDATE()` -> RAISERROR fires
- The check appears twice in the DDL (copy-paste bug): first message "You can not insert a Dividend that happend in the past", second "Can not delete a record about an event that already occurred"
- Functionally: both checks execute in sequence before the UPDATE, so a past date always raises before any data modification
- Protects against accidentally advancing or re-dating a dividend to a historical date that would immediately trigger payment processing

### 2.3 Status=0 Guard - Only Pending Dividends

**What**: The UPDATE WHERE clause limits changes to dividends that have not yet entered the payment pipeline.

**Columns/Parameters Involved**: `Trade.IndexDividends.Status`, `@DividendID`

**Rules**:
- `WHERE DividendID = @DividendID AND Status = 0`
- Status=0 = Pending (safe to modify)
- Status=1 = In Progress (payment snapshot already taken - cannot modify)
- Status=2 = Completed (already paid - cannot modify)
- If the row was already advanced past Status=0 by Trade.GetCIDsForIndexDividends, @@ROWCOUNT=0 after the UPDATE
- @@ROWCOUNT=0 -> RAISERROR: "Could not find a record to update. Make sure that you passed the corect ID"

**Diagram**:
```
EXEC Trade.UpdateDividend(@DividendID, @InstrumentID, @DividendDate, ...)
  |
  +-> GetInstrument check: InstrumentTypeID=4? NO -> RAISERROR
  |
  +-> @DividendDate < GETUTCDATE()? YES -> RAISERROR (x2, copy-paste bug)
  |
  +-> UPDATE IndexDividends WHERE DividendID=@DividendID AND Status=0
        @@ROWCOUNT=0? -> RAISERROR (already in-progress or wrong ID)
        @@ROWCOUNT=1? -> commit (success)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendID | INT | NO | - | CODE-BACKED | Primary key of the Trade.IndexDividends row to update. The UPDATE targets exactly one row WHERE DividendID=@DividendID AND Status=0. If no match (wrong ID or status advanced past 0), RAISERROR fires. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument to associate with this dividend event. Must exist in Trade.GetInstrument with InstrumentTypeID=4 (index/stock). This can be changed from the original - e.g., if the wrong instrument was originally set when the dividend was created. |
| 3 | @DividendDate | DATE | NO | - | CODE-BACKED | The ex-dividend date (when holders qualify for payment). Must be in the future (>= GETUTCDATE()) at the time of the call. Sets IndexDividends.DividendDate. Cannot be a past date. |
| 4 | @BuyPaymentInDollars | MONEY | NO | - | CODE-BACKED | Dollar amount to pay per unit to customers in BUY (long) positions. Sets IndexDividends.BuyPaymentInDollars. Positive value. |
| 5 | @SellPaymentInDollars | MONEY | NO | - | CODE-BACKED | Dollar amount to charge (or credit) per unit to customers in SELL (short) positions. Sets IndexDividends.SellPaymentInDollars. Typically negative - short sellers owe dividends to the counterparty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Instrument validation | Trade.GetInstrument | Read (view) | Validates InstrumentID exists and has InstrumentTypeID=4 |
| UPDATE target | Trade.IndexDividends | Modifier | Updates InstrumentID, DividendDate, BuyPaymentInDollars, SellPaymentInDollars WHERE DividendID=@DividendID AND Status=0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| IndexDividend (DB role) | GRANT EXECUTE | Permission | Operations role for dividend calendar management has execute permission; invoked via OpsFlow tooling |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateDividend (procedure)
+-- Trade.GetInstrument (view) - instrument type validation
+-- Trade.IndexDividends (table) - UPDATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | Validates @InstrumentID exists with InstrumentTypeID=4 |
| Trade.IndexDividends | Table | UPDATE target - sets InstrumentID, DividendDate, BuyPaymentInDollars, SellPaymentInDollars WHERE DividendID=@DividendID AND Status=0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| IndexDividend (role / OpsFlow tooling) | Permission grantee | Operations teams call this to correct pending dividend records before payment processing begins |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. The procedure uses SET NOCOUNT ON and TRY/CATCH with THROW. Notable DDL defect: the past-date RAISERROR appears twice consecutively with different messages (copy-paste from Trade.DeleteDividend); functionally correct but the second message is misleading.

---

## 8. Sample Queries

### 8.1 Update a pending dividend record
```sql
EXEC Trade.UpdateDividend
    @DividendID           = 42001,
    @InstrumentID         = 799,         -- must be InstrumentTypeID=4
    @DividendDate         = '2026-04-15', -- must be in the future
    @BuyPaymentInDollars  = 0.65,
    @SellPaymentInDollars = -0.65;
```

### 8.2 Check current pending dividends eligible for update
```sql
SELECT DividendID, InstrumentID, DividendDate,
       BuyPaymentInDollars, SellPaymentInDollars,
       Status, PositionType
FROM   Trade.IndexDividends WITH (NOLOCK)
WHERE  Status = 0
  AND  DividendDate >= GETUTCDATE()
ORDER  BY DividendDate;
```

### 8.3 Verify update result
```sql
SELECT DividendID, InstrumentID, DividendDate,
       BuyPaymentInDollars, SellPaymentInDollars,
       Status, ValidFrom
FROM   Trade.IndexDividends WITH (NOLOCK)
WHERE  DividendID = 42001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateDividend | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateDividend.sql*
