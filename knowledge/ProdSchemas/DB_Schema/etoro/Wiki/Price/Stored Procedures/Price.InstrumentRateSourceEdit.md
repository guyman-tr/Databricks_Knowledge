# Price.InstrumentRateSourceEdit

> Updates the Priority of an existing InstrumentRateSources row identified by InstrumentRateSourceID, with existence check guard and explicit transaction using the legacy @@ERROR pattern (error code 60000 on any DML failure).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentRateSourceID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.InstrumentRateSourceEdit changes the priority tier of an existing instrument-to-rate-source mapping. It is the targeted update path for adjusting how a specific rate source is ranked in an instrument's fallback chain (Priority=10=primary, 20=secondary, 30=tertiary, 40=quaternary).

This procedure is called by Price.InstrumentRateSourceAdd as part of its upsert logic: when InstrumentRateSourceAdd finds that the (InstrumentID, AccountRateSourceID) combination already exists, it calls InstrumentRateSourceEdit to update the Priority of the existing row rather than inserting a duplicate. It can also be called directly when an operator needs to demote or promote a specific feed source for an instrument.

The procedure only allows Priority to be changed - no other columns of InstrumentRateSources are mutable via this procedure. To add a new source or delete one, InstrumentRateSourceAdd or a direct DELETE is used instead.

---

## 2. Business Logic

### 2.1 Existence Guard Before Update

**What**: Checks that the target row exists before attempting the UPDATE; raises error 60000 if not found.

**Columns/Parameters Involved**: `@InstrumentRateSourceID`

**Rules**:
- `IF EXISTS (SELECT 1 FROM Price.InstrumentRateSources WITH(NOLOCK) WHERE InstrumentRateSourceID = @InstrumentRateSourceID)`: read with NOLOCK for the existence check (optimistic - safe since the UPDATE will acquire proper locks)
- If NOT EXISTS: `RAISERROR(60000, 16, 1, 'Price.InstrumentRateSources', 60000)` + `RETURN 60000` - returns error code 60000 to caller
- If EXISTS: proceeds to UPDATE

### 2.2 Transacted Update with @@ERROR Pattern

**What**: The UPDATE is wrapped in an explicit transaction with old-style @@ERROR error checking.

**Columns/Parameters Involved**: `@Priority`, `Priority`

**Rules**:
- `BEGIN TRAN` -> `UPDATE Price.InstrumentRateSources SET Priority = @Priority WHERE InstrumentRateSourceID = @InstrumentRateSourceID`
- `IF @@ERROR = 0`: successful update -> `COMMIT; RETURN 0` (returns 0 = success)
- `ELSE`: update error -> `ROLLBACK; RAISERROR(60000, 16, 1, 'Price.InstrumentRateSourceEdit', @@ERROR)` - rolls back and raises error 60000 with the original @@ERROR value as a substitution argument
- This is the legacy @@ERROR pattern (pre-TRY/CATCH style), as opposed to the TRY/CATCH + THROW style used in InsertPricingConfiguration
- Error number 60000: a custom user-defined error message number (registered via sp_addmessage in the database). Severity 16 = state error (caller-correctable).

### 2.3 Return Values

**What**: Returns numeric codes to indicate success or failure.

**Rules**:
- `RETURN 0`: success (UPDATE committed)
- `RETURN 60000`: row not found (existence check failed)
- RAISERROR on UPDATE failure: no explicit RETURN after RAISERROR in the failure branch - execution continues after RAISERROR (which does not stop execution unless severity >= 20 or the caller uses XACT_ABORT)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentRateSourceID | INT | NOT NULL | - | CODE-BACKED | The specific InstrumentRateSources row to update. Identity PK of Price.InstrumentRateSources. Must exist; RAISERROR + RETURN 60000 if not found. |
| 2 | @Priority | INT | NOT NULL | - | CODE-BACKED | The new priority tier for this rate source mapping. Standard values: 10=primary, 20=secondary, 30=tertiary, 40=quaternary. Lower value = higher precedence in the pricing engine fallback chain. |

**Result set**: None. Returns 0 (success) or 60000 (not found) via RETURN. RAISERROR raised on DML failure.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentRateSourceID | Price.InstrumentRateSources | WRITER (UPDATE) | Updates Priority of the identified rate source mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentRateSourceAdd | @InstrumentRateSourceID | CALLER | Called when InstrumentRateSourceAdd detects the (InstrumentID, AccountRateSourceID) combination already exists - upsert delegates priority update to this procedure |
| (pricing configuration API/OPS tool) | @InstrumentRateSourceID | CALLER | Called directly to adjust a source's priority in an instrument's fallback chain |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentRateSourceEdit (procedure)
+-- Price.InstrumentRateSources (table) - UPDATE target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | Existence check (SELECT WITH NOLOCK) + UPDATE Priority |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSourceAdd | Stored Procedure | EXEC call in upsert path when row already exists |
| (pricing configuration API) | External | Direct calls to change a source's priority |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON (returns row count from UPDATE). Uses legacy @@ERROR pattern (not TRY/CATCH). Error code 60000 is a custom user-defined message number - this is a schema-wide convention in the Price schema for DML errors (seen in InstrumentRateSourceAdd as well). The `RAISERROR(60000, 16, 1, ...)` signature uses the message number (not message string) overload - the format string for 60000 must be registered in sys.messages via sp_addmessage. The RAISERROR in the "not found" branch (RETURN 60000 after RAISERROR) is redundant in the RAISERROR-then-RETURN sense, but both the error and the return code allow callers to handle the failure either via TRY/CATCH or via checking RETURN value. The RAISERROR after ROLLBACK in the UPDATE failure path has no matching RETURN statement - the procedure simply exits after RAISERROR.

---

## 8. Sample Queries

### 8.1 Update priority for a specific rate source mapping

```sql
DECLARE @ReturnCode INT;
EXEC @ReturnCode = Price.InstrumentRateSourceEdit
    @InstrumentRateSourceID = 42,
    @Priority = 20;
-- @ReturnCode = 0 on success, 60000 if row not found
```

### 8.2 Find InstrumentRateSourceID for a specific instrument+source combination

```sql
SELECT InstrumentRateSourceID, InstrumentID, AccountRateSourceID, Priority
FROM Price.InstrumentRateSources WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Priority;
```

### 8.3 Equivalent manual update

```sql
UPDATE Price.InstrumentRateSources
SET Priority = 20
WHERE InstrumentRateSourceID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentRateSourceEdit | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.InstrumentRateSourceEdit.sql*
