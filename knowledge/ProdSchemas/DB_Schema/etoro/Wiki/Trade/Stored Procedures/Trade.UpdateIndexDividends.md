# Trade.UpdateIndexDividends

> Null-safe batch update of dividend metadata fields in Trade.IndexDividends using a TVP; only non-null values from the TVP overwrite existing field values, matched by (InstrumentID, DividendID).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateIndexDividendsTbl (TVP - Trade.UpdateIndexDividendsTbl) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateIndexDividends is the comprehensive update path for dividend event metadata in `Trade.IndexDividends`. Unlike `Trade.UpdateDividend` (which updates a single dividend's payment amounts and validates Status=0), this procedure accepts a batch and updates a wider set of fields: PositionType, TaxCode, EventType, ex-dividend date, payment date, dividend value in original currency, currency denomination, buy/sell tax rates, and correction dividend linkage.

The DividendsApp database role has EXECUTE permission, indicating this is called by the Dividend Management Application - the operations tool used by the corporate actions team to manage dividend events (enter ex-dates, set tax rates, link corrections, mark retakes).

The null-safe IIF pattern makes the procedure suitable for partial updates: operations teams can pass a batch where only the ExDate column is populated for some rows, updating just that field without disturbing BuyTax, SellTax, or TaxCode. This is important for the dividend workflow, where different teams or processes may be responsible for different fields (e.g., the tax team sets TaxCode separately from the trading team setting PaymentDate).

Unlike Trade.UpdateDividend, this procedure does not validate Status=0 - it can update dividends at any lifecycle stage. The calling application is trusted to enforce status-gating.

---

## 2. Business Logic

### 2.1 IIF Null-Safe Partial Update Pattern

**What**: Each field is updated only if the TVP provides a non-null value; existing values are preserved when the TVP has NULL for that field.

**Columns/Parameters Involved**: All 10 updatable fields in Trade.IndexDividends

**Rules**:
- Pattern: `TID.FieldName = IIF(UIDT.FieldName IS NULL, TID.FieldName, UIDT.FieldName)`
- If UIDT (source TVP) value IS NULL -> preserve TID (target) existing value
- If UIDT value IS NOT NULL -> overwrite with new value
- Applied to: PositionType, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, DividendCurrencyID, BuyTax, SellTax, CorrectionDividendID
- Note: Status is in the TVP type definition but is NOT updated by this procedure (no `TID.Status = ...` assignment) - it is a read-only filter/context field in the TVP

**Diagram**:
```
TVP row:
  DividendID=101, InstrumentID=5, ExDate='2026-04-15', TaxCode=NULL, BuyTax=0.15, ...rest NULL

Result after UPDATE:
  ExDate    = '2026-04-15'  (was overwritten - new value provided)
  TaxCode   = <unchanged>   (NULL in TVP -> existing value preserved)
  BuyTax    = 0.15          (was overwritten - new value provided)
  ...other fields unchanged
```

### 2.2 Composite Key Match: InstrumentID + DividendID

**What**: The UPDATE joins on both InstrumentID and DividendID, ensuring the correct dividend row is targeted.

**Columns/Parameters Involved**: `TID.InstrumentID`, `TID.DividendID`, `UIDT.InstrumentID`, `UIDT.DividendID`

**Rules**:
- `INNER JOIN #UpdateIndexDividendsTbl UIDT ON TID.InstrumentID = UIDT.InstrumentID AND TID.DividendID = UIDT.DividendID`
- Both columns required for match - InstrumentID alone is not unique (an instrument can have many dividends)
- DividendID is the PK of IndexDividends; InstrumentID is redundant for matching but provides an additional safety check
- TVP is materialized into a temp table (#UpdateIndexDividendsTbl) before the UPDATE

### 2.3 CATCH Block Transaction Handling

**What**: The CATCH block contains unusual conditional rollback logic.

**Rules**:
- `IF @@TRANCOUNT = 1 ROLLBACK TRANSACTION ELSE COMMIT TRAN`
- If exactly 1 open transaction: ROLLBACK (standard error handling)
- If more than 1 open transaction (nested): COMMIT the outer transaction (unusual - may be a copy-paste artifact)
- In practice: this procedure is typically called without an explicit outer transaction, so @@TRANCOUNT=1 and ROLLBACK fires on error
- The ELSE COMMIT branch for nested transactions is likely a code template artifact

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateIndexDividendsTbl | Trade.UpdateIndexDividendsTbl READONLY | NO | - | CODE-BACKED | TVP containing the batch of dividend records to update. Required columns: DividendID (PK, required for JOIN), InstrumentID (required for JOIN). All other columns nullable - only non-null values overwrite existing data. Columns: PositionType (tinyint), TaxCode (varchar 40), EventType (varchar 40), ExDate (date), PaymentDate (date), DividendValueInCurrency (money), DividendCurrencyID (int), BuyTax (decimal 6,4), SellTax (decimal 6,4), CorrectionDividendID (int). Note: Status (tinyint) column exists in the TVP type but is not written by this procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UpdateIndexDividendsTbl | Trade.UpdateIndexDividendsTbl | TVP | Input parameter type with nullable metadata fields |
| UPDATE target | Trade.IndexDividends | Modifier | IIF null-safe update of 10 metadata fields, matched by (InstrumentID, DividendID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp (DB role) | GRANT EXECUTE | Permission | Dividend Management Application - corporate actions team tool for managing dividend events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateIndexDividends (procedure)
+-- Trade.UpdateIndexDividendsTbl (TVP type)
+-- Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateIndexDividendsTbl | User Defined Type (TVP) | Input parameter type defining the batch of dividend metadata to update |
| Trade.IndexDividends | Table | UPDATE target - IIF null-safe partial update of 10 fields per row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp (DB role / Dividend Management App) | Permission grantee | Corporate actions team application for managing dividend event metadata |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. TVP is materialized into `#UpdateIndexDividendsTbl` (no indexes created on temp table in this procedure).

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON. TRY/CATCH with conditional rollback. No Status=0 guard - procedure can update dividends regardless of lifecycle state. RETURN 0 on success.

---

## 8. Sample Queries

### 8.1 Update ExDate and PaymentDate for a batch of dividends
```sql
DECLARE @Updates Trade.UpdateIndexDividendsTbl;

INSERT INTO @Updates (DividendID, InstrumentID, ExDate, PaymentDate)
VALUES
  (101, 5, '2026-04-15', '2026-04-20'),
  (102, 8, '2026-04-16', '2026-04-21');
-- All other nullable columns remain NULL -> existing values preserved

EXEC Trade.UpdateIndexDividends @UpdateIndexDividendsTbl = @Updates;
```

### 8.2 Update tax rates for a specific dividend
```sql
DECLARE @Updates Trade.UpdateIndexDividendsTbl;

INSERT INTO @Updates (DividendID, InstrumentID, BuyTax, SellTax, TaxCode)
VALUES
  (101, 5, 0.1500, 0.1500, 'US-DIV');

EXEC Trade.UpdateIndexDividends @UpdateIndexDividendsTbl = @Updates;
```

### 8.3 Verify updated dividend metadata
```sql
SELECT DividendID, InstrumentID, PositionType, TaxCode, EventType,
       ExDate, PaymentDate, DividendValueInCurrency, BuyTax, SellTax, Status
FROM   Trade.IndexDividends WITH (NOLOCK)
WHERE  DividendID IN (101, 102)
ORDER  BY DividendID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateIndexDividends | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateIndexDividends.sql*
