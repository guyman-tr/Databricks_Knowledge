# History.InsertLogErrorGeneral

> Central error logging writer: inserts SQL Server TRY/CATCH exception details into History.LogErrorGeneral, capturing the calling procedure name, its XML-serialized parameters, and all SQL Server error context for later diagnosis.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts to History.LogErrorGeneral; no RETURN value on success |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.InsertLogErrorGeneral` is the active error logging gateway for the etoro database. When stored procedures across multiple schemas (BackOffice, Customer, History, Stocks) catch an exception in their TRY/CATCH blocks, they call this procedure to persist the error details to `History.LogErrorGeneral`. This creates a queryable audit trail of server-side failures for engineering and support investigations.

The procedure captures two distinct levels of context: the outer procedure that caught the error (`@NameSP`), and the inner location where SQL Server says the error actually originated (`@ErrorProcedure`, `@ErrorLine` from ERROR_PROCEDURE() and ERROR_LINE()). When a nested procedure call fails and the outer procedure catches it, these two fields will differ - revealing both the business operation that was executing and the exact code location that faulted.

The `@Param_XML` parameter is the most operationally valuable field: it stores the full parameter set of the failing procedure as XML, enabling engineers to replay the exact inputs that caused the failure. This is critical for debugging intermittent failures and data-dependent errors.

On failure (CATCH block), the procedure re-raises using RAISERROR with code 60000, surfacing the original error number - so the caller knows the log write itself failed.

---

## 2. Business Logic

### 2.1 Dual-Context Error Capture

**What**: The procedure captures both the outer catching procedure and the inner failing procedure, providing context at two levels.

**Columns/Parameters Involved**: `@NameSP`, `@ErrorProcedure`, `@ErrorLine`, `@Param_XML`

**Rules**:
- @NameSP = the procedure that called InsertLogErrorGeneral (the one with the CATCH block). Manually passed by callers - not auto-detected.
- @ErrorProcedure = ERROR_PROCEDURE() from SQL Server's error context. The SP where the error actually originated.
- When @NameSP = @ErrorProcedure: the error happened directly in the catching SP (most common)
- When @NameSP != @ErrorProcedure: the error bubbled up from a nested SP call
- @ErrorLine = ERROR_LINE(): the line number within @ErrorProcedure where the error occurred - enables direct navigation to the failing code

### 2.2 Error Re-Raise on Log Failure

**What**: If the INSERT into History.LogErrorGeneral fails, the procedure raises error 60000 rather than silently succeeding.

**Columns/Parameters Involved**: error context

**Rules**:
- On CATCH: RAISERROR(60000, 16, 1, 'History.InsertLogErrorGeneral', @LocalError) where @LocalError = ERROR_NUMBER()
- The 5th argument to RAISERROR (the nvarchar subs param) receives @LocalError as the original error number
- Severity 16 = user-correctable errors; this signals the caller that even the error LOG failed
- This re-raise pattern means callers should wrap calls to this procedure in their own error handling if they need to gracefully handle log-write failures

### 2.3 Callers (Cross-Schema Error Logging)

**What**: Seven procedures across BackOffice, Customer, History, and Stocks schemas use this as their error logging endpoint.

**Callers**:
- `BackOffice.KycAddILQ` - KYC data entry error logging
- `BackOffice.usp_CloseZeroMirrors` - Zero-balance mirror position close
- `Customer.InsertRealCustomer` - Real customer registration errors
- `Customer.RegisterDemo` - Demo account registration errors
- `Customer.RegisterReal` - Real account registration errors
- `History.LogOutByLoginID` - Login/session logout errors
- `Stocks.SetStockDailyPrice` - Daily price setting errors

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NameSP | varchar(50) | NO | - | CODE-BACKED | Name of the stored procedure that caught the error and is calling InsertLogErrorGeneral. Passed manually by the caller. Stored as History.LogErrorGeneral.NameSP. Identifies the business operation context (the outer SP). Not the same as @ErrorProcedure when error bubbled from a nested call. |
| 2 | @Param_XML | xml | NO | - | CODE-BACKED | XML-serialized parameter values of the failing procedure at the time of the error. Stored as History.LogErrorGeneral.Param_XML. The most operationally valuable field: enables engineers to replay the exact inputs that caused the failure. Callers serialize their @param values into XML before passing. |
| 3 | @ErrorNumber | int | NO | - | CODE-BACKED | SQL Server error number from ERROR_NUMBER() in the caller's CATCH block. Stored as History.LogErrorGeneral.ErrorNumber. Common values: 547=FK constraint violation, 1105=filegroup full, 2601/2627=unique constraint violation. |
| 4 | @ErrorMessage | varchar(max) | NO | - | CODE-BACKED | Full error message text from ERROR_MESSAGE() in the caller's CATCH block. Stored as History.LogErrorGeneral.ErrorMessage. Contains the complete human-readable description of the SQL Server error. |
| 5 | @ErrorSeverity | int | NO | - | CODE-BACKED | SQL Server error severity from ERROR_SEVERITY() in the caller's CATCH block. Stored as History.LogErrorGeneral.ErrorSeverity. 16=user-correctable errors (FKs, constraints), 17=resource errors (disk full), 25=fatal. |
| 6 | @ErrorState | int | NO | - | CODE-BACKED | SQL Server error state from ERROR_STATE() in the caller's CATCH block. Stored as History.LogErrorGeneral.ErrorState. Sub-classification within the error number for certain error types. |
| 7 | @ErrorProcedure | varchar(100) | NO | - | CODE-BACKED | SQL Server's reported error procedure from ERROR_PROCEDURE() in the caller's CATCH block. Stored as History.LogErrorGeneral.ErrorProcedure. The SP where the exception actually originated - may differ from @NameSP when a nested SP faulted. |
| 8 | @ErrorLine | int | NO | - | CODE-BACKED | Line number within @ErrorProcedure where the error occurred, from ERROR_LINE(). Stored as History.LogErrorGeneral.ErrorLine. Enables direct navigation to the failing line of code when investigating errors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| all params | History.LogErrorGeneral | Write target | Inserts one error detail row per call |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.KycAddILQ | CATCH block | Caller | KYC data entry error logging |
| BackOffice.usp_CloseZeroMirrors | CATCH block | Caller | Zero-mirror close operation errors |
| Customer.InsertRealCustomer | CATCH block | Caller | Real customer registration errors |
| Customer.RegisterDemo | CATCH block | Caller | Demo account registration errors |
| Customer.RegisterReal | CATCH block | Caller | Real account registration errors |
| History.LogOutByLoginID | CATCH block | Caller | Login/session logout errors |
| Stocks.SetStockDailyPrice | CATCH block | Caller | Daily price update errors |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InsertLogErrorGeneral (procedure)
└── History.LogErrorGeneral (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.LogErrorGeneral | Table | INSERT target - one row per error logged |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.KycAddILQ | Procedure | Calls to log KYC errors |
| BackOffice.usp_CloseZeroMirrors | Procedure | Calls to log zero-mirror close errors |
| Customer.InsertRealCustomer | Procedure | Calls to log registration errors |
| Customer.RegisterDemo | Procedure | Calls to log demo account registration errors |
| Customer.RegisterReal | Procedure | Calls to log real account registration errors |
| History.LogOutByLoginID | Procedure | Calls to log logout errors |
| Stocks.SetStockDailyPrice | Procedure | Calls to log price setting errors |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. On catch: RAISERROR(60000, 16, 1, 'History.InsertLogErrorGeneral', @LocalError) where @LocalError is the error number from the failed INSERT. No RETURN value on success path (no explicit RETURN).

---

## 8. Sample Queries

### 8.1 Find recent errors logged by InsertLogErrorGeneral

```sql
SELECT TOP 20
    ID,
    Occurred,
    NameSP,
    ErrorNumber,
    ErrorMessage,
    ErrorSeverity,
    ErrorProcedure,
    ErrorLine
FROM History.LogErrorGeneral WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Find all errors for a specific calling procedure

```sql
SELECT
    ID,
    Occurred,
    NameSP,
    ErrorNumber,
    ErrorMessage,
    ErrorProcedure,
    ErrorLine,
    Param_XML
FROM History.LogErrorGeneral WITH (NOLOCK)
WHERE NameSP = 'Customer.RegisterReal'
ORDER BY ID DESC
```

### 8.3 Summarize error frequency by procedure and error number

```sql
SELECT
    NameSP,
    ErrorNumber,
    ErrorMessage,
    COUNT(*) AS OccurrenceCount,
    MIN(Occurred) AS FirstSeen,
    MAX(Occurred) AS LastSeen
FROM History.LogErrorGeneral WITH (NOLOCK)
GROUP BY NameSP, ErrorNumber, ErrorMessage
ORDER BY OccurrenceCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.InsertLogErrorGeneral | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.InsertLogErrorGeneral.sql*
