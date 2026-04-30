# Trade.InsertMultipleIndexDividends

> Bulk-inserts index dividend event records from a TVP directly into Trade.IndexDividends, enabling batch creation of multiple pending dividend payments (Status=1 default) for processing by the dividend pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MultiIndexDividendsInsertTbl TVP - batch of dividend rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertMultipleIndexDividends is the batch entry point for creating index dividend records. It accepts a batch of dividend events via the Trade.MultiIndexDividendsInsertTbl TVP and inserts all rows into Trade.IndexDividends in one statement. The inserted rows enter the dividend lifecycle as pending (Status defaults to 1 - not yet processed).

This SP serves the same purpose as Trade.InsertIndexDividend but handles multiple dividends in one call rather than one at a time. It is designed for scenarios where operations needs to bulk-load dividend schedules for multiple instruments or ex-dates at once, such as a quarterly dividend upload from a financial data provider.

Data flow: Rows inserted by this SP have Status=1 (pending). They appear in Trade.IndexDividendsDaylyNotPaidEmailReport on their PaymentDate. The dividend payment pipeline processes them (via Trade.IndexDividends_SetStatus or similar) and sets Status=2 (completed). Trade.IndexDividends24HoursEmailReport then shows completed ones.

---

## 2. Business Logic

### 2.1 Batch INSERT from TVP

**What**: All rows in the TVP are inserted into Trade.IndexDividends in a single set-based INSERT.

**Columns/Parameters Involved**: All TVP columns mapped directly to target table columns.

**Rules**:
- Column mapping is explicit: InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax.
- The Status column is NOT in the TVP or the INSERT list - it receives its table default (Status=1 = pending/not paid). Newly inserted dividends are always in pending state.
- DividendID (PK IDENTITY) is auto-generated for each inserted row.
- No deduplication or MERGE: duplicate InstrumentID/ExDate/PositionType combinations can be inserted. Callers are responsible for uniqueness validation before calling.
- All TVP columns except InstrumentID are nullable - partial data can be inserted for instruments where tax codes or position types are not yet confirmed.

### 2.2 TRY/CATCH with THROW - Error Propagation

**What**: Errors are re-raised to the caller rather than swallowed.

**Rules**:
- BEGIN TRY / END TRY wraps the INSERT. On success: RETURN(0).
- BEGIN CATCH / END CATCH: THROW (re-raises the original exception with full error details). RETURN(-1) follows but is unreachable after THROW.
- No explicit transaction - the INSERT is auto-commit. If the batch is partially inserted due to a row-level constraint error (rare for bulk INSERT), the batch behavior depends on SQL Server error type (typically all-or-nothing for batch violations).
- THROW pattern means the caller (application or SP) must handle exceptions.

### 2.3 Dividend Lifecycle Entry Point

**What**: Rows inserted here start the dividend processing lifecycle.

**Rules**:
- Status = 1 (pending) on insert (column default, not set by this procedure).
- PaymentDate drives the monitoring trigger: Trade.IndexDividendsDaylyNotPaidEmailReport surfaces rows on their PaymentDate when Status=1.
- ExDate determines which positions qualify: positions opened before ExDate receive the dividend.
- PositionType (tinyint) determines whether the dividend applies to BUY, SELL, CFD, or REAL position type holders.
- BuyTax/SellTax (decimal 6,4): tax rate fractions applied to dividend value for buy-side and sell-side holders.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MultiIndexDividendsInsertTbl | Trade.MultiIndexDividendsInsertTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter carrying the batch of dividend records to insert. READONLY. Defined as type Trade.MultiIndexDividendsInsertTbl with columns: InstrumentID INT NOT NULL, PositionType TINYINT, TaxCode VARCHAR(40), EventType VARCHAR(40), ExDate DATE, PaymentDate DATE, DividendValueInCurrency MONEY, DividendCurrencyID INT, BuyTax DECIMAL(6,4), SellTax DECIMAL(6,4). |

**TVP column details** (Trade.MultiIndexDividendsInsertTbl):

| # | TVP Column | Type | Nullable | Description |
|---|-----------|------|----------|-------------|
| 1 | InstrumentID | INT | NOT NULL | Instrument for which the dividend is declared. FK to Trade.Instrument. |
| 2 | PositionType | TINYINT | YES | Position type eligible for this dividend (e.g., BUY=1, SELL=2, CFD vs REAL). Resolved from Dictionary.PositionType. |
| 3 | TaxCode | VARCHAR(40) | YES | Tax classification code for this dividend event (e.g., "DIV", "INT"). Used by operations/finance to determine tax treatment. |
| 4 | EventType | VARCHAR(40) | YES | Dividend event classification (e.g., regular, special, return of capital). Determines processing rules. |
| 5 | ExDate | DATE | YES | Ex-dividend date. Positions opened before this date qualify for the dividend. |
| 6 | PaymentDate | DATE | YES | Scheduled payment date. Monitoring SPs surface rows on this date when Status=1 (pending). |
| 7 | DividendValueInCurrency | MONEY | YES | Dividend amount in the denomination currency (DividendCurrencyID) per unit/lot. |
| 8 | DividendCurrencyID | INT | YES | Currency of the dividend amount. FK to Dictionary.Currency. |
| 9 | BuyTax | DECIMAL(6,4) | YES | Tax rate fraction applied to dividend payments for BUY-side position holders. |
| 10 | SellTax | DECIMAL(6,4) | YES | Tax rate fraction applied to dividend payments for SELL-side position holders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MultiIndexDividendsInsertTbl | Trade.MultiIndexDividendsInsertTbl (UDT) | Type Reference | TVP parameter type definition |
| INSERT | Trade.IndexDividends | Write (INSERT) | Batch-inserts dividend records with Status=1 (pending) default |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by operations workflows or scheduled jobs that upload dividend schedules from financial data providers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertMultipleIndexDividends (procedure)
+-- Trade.MultiIndexDividendsInsertTbl (UDT) - TVP type
+-- Trade.IndexDividends (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MultiIndexDividendsInsertTbl | User Defined Type | @MultiIndexDividendsInsertTbl TVP type definition |
| Trade.IndexDividends | Table | INSERT target; DividendID IDENTITY generated per row |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by dividend administration tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READONLY TVP | Parameter constraint | @MultiIndexDividendsInsertTbl cannot be modified within the procedure |
| Status omitted | Column default | Status=1 (pending) applied by table default; not set by this procedure |
| THROW on error | Error propagation | Re-raises original exception; RETURN(-1) is unreachable after THROW |
| Auto-commit | Transaction | No explicit transaction; batch INSERT is atomic at statement level |

---

## 8. Sample Queries

### 8.1 Bulk-insert two index dividend records

```sql
DECLARE @dividends Trade.MultiIndexDividendsInsertTbl;
INSERT INTO @dividends (InstrumentID, PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax)
VALUES
    (100017, 1, 'DIV', 'Regular', '2026-03-15', '2026-03-17', 0.25, 1, 0.15, 0.0),  -- BUY position holders
    (100017, 2, 'DIV', 'Regular', '2026-03-15', '2026-03-17', 0.25, 1, 0.0, 0.15);  -- SELL position holders

EXEC Trade.InsertMultipleIndexDividends @MultiIndexDividendsInsertTbl = @dividends;
```

### 8.2 Verify inserted dividends

```sql
SELECT TOP 10 DividendID, InstrumentID, PositionType, TaxCode, ExDate, PaymentDate, DividendValueInCurrency, Status
FROM   Trade.IndexDividends WITH (NOLOCK)
WHERE  InstrumentID = 100017
ORDER  BY DividendID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertMultipleIndexDividends | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertMultipleIndexDividends.sql*
