# Trade.InstrumentRateSourceDelete

> Deletes a specific instrument rate source mapping from Trade.InstrumentRateSources if it exists, returning error code 60000 if the record is not found or the delete fails.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentRateSourceID - ID of the rate source mapping to delete |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentRateSourceDelete removes an instrument-to-liquidity-account rate source mapping from Trade.InstrumentRateSources. When a price feed provider is decommissioned for a specific instrument, or when the priority configuration for an instrument's rate sources needs to be rebuilt from scratch, this procedure removes the specific mapping by its InstrumentRateSourceID.

Without this procedure there would be no safe, transactional way to remove rate source mappings. The procedure validates existence before attempting the delete, preventing silent no-ops that could confuse callers. The error code 60000 is a platform-standard error code used consistently across instrument management procedures.

Data flow: Operations tools or the instrument rate source administration interface identify the InstrumentRateSourceID to remove (typically via Trade.GetInstrumentRateSources view). This procedure is called to remove the mapping. The price subsystem will then no longer route rate requests for the affected instrument to the removed liquidity account.

---

## 2. Business Logic

### 2.1 Existence Check + Transactional Delete

**What**: The procedure checks existence before deleting, and wraps the DELETE in an explicit transaction with @@ERROR-based error handling.

**Columns/Parameters Involved**: `@InstrumentRateSourceID`

**Rules**:
- If InstrumentRateSourceID does NOT exist: RAISERROR 60000, RETURN 60000 (no transaction opened).
- If InstrumentRateSourceID exists: open transaction, DELETE, check @@ERROR.
  - @@ERROR != 0: ROLLBACK, RAISERROR 60000, RETURN 60000.
  - @@ERROR = 0: COMMIT, RETURN 0.
- Uses old-style @@ERROR error handling (pre-TRY/CATCH pattern, circa 2007-era SQL Server).
- Error code 60000 is the platform's generic instrument management error code (same across InstrumentRateSourceAdd, Edit, Delete).

**Diagram**:
```
@InstrumentRateSourceID
    |
    v
Does InstrumentRateSourceID exist in Trade.InstrumentRateSources?
    |
    +--[NO]--> RAISERROR(60000) + RETURN 60000
    |
    +--[YES]--> BEGIN TRAN
                    DELETE FROM Trade.InstrumentRateSources
                    WHERE InstrumentRateSourceID = @InstrumentRateSourceID
                        |
                        +--[@@ERROR != 0]--> ROLLBACK + RAISERROR(60000) + RETURN 60000
                        |
                        +--[@@ERROR = 0]---> COMMIT + RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentRateSourceID | int | NO | - | CODE-BACKED | Primary key of the Trade.InstrumentRateSources row to delete. Identifies a specific instrument-to-liquidity-account rate source mapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXISTS check + DELETE | Trade.InstrumentRateSources | Deleter | Validates and removes the specified rate source mapping |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase - called from instrument rate source administration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentRateSourceDelete (procedure)
└── Trade.InstrumentRateSources (table) - EXISTS check + DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentRateSources | Table | EXISTS check and DELETE target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Rate source administration tooling | External | Calls to remove instrument-to-liquidity-account mappings |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error code 60000 | Convention | Platform-standard error code for instrument management errors, used for both "not found" and "delete failed" conditions |
| @@ERROR pattern | Legacy | Uses pre-TRY/CATCH @@ERROR checking. Any statement between BEGIN TRAN and the @@ERROR check is vulnerable to partial execution if not all errors are caught. |

---

## 8. Sample Queries

### 8.1 Delete a rate source mapping

```sql
DECLARE @RC INT;
EXEC @RC = Trade.InstrumentRateSourceDelete @InstrumentRateSourceID = 42;
SELECT @RC AS ReturnCode;
-- 0 = success, 60000 = not found or delete error
```

### 8.2 Find the InstrumentRateSourceID before deleting

```sql
SELECT
    irs.InstrumentRateSourceID,
    irs.InstrumentID,
    irs.LiquidityAccountID,
    irs.PriceServerID,
    irs.Priority
FROM Trade.InstrumentRateSources irs WITH (NOLOCK)
WHERE irs.InstrumentID = @InstrumentID
ORDER BY irs.Priority;
```

### 8.3 Verify deletion

```sql
SELECT COUNT(*) AS RemainingRows
FROM Trade.InstrumentRateSources WITH (NOLOCK)
WHERE InstrumentRateSourceID = 42;
-- Expected 0 after successful delete
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentRateSourceDelete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InstrumentRateSourceDelete.sql*
