# Billing.DepositLogAdd

> Two-phase deposit request/response logger - inserts the request record first (returning the new log ID), then updates it with the response when called a second time with the same ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT/UPDATE into History.DepositLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositLogAdd` is a two-phase logging procedure for deposit payment gateway interactions. It records both sides of a request/response conversation with a payment processor by using the same procedure with different parameter patterns:

- **Phase 1 (request)**: Called with `@DepositLogID = NULL` - inserts a new row in `History.DepositLog` with the request details and returns the new log ID via `SELECT SCOPE_IDENTITY()`.
- **Phase 2 (response)**: Called with the log ID from Phase 1 - updates the same row with the response date and message.

This pattern ensures that even if the payment gateway call times out or fails, the request attempt is already logged. The calling code captures the log ID from the SELECT result, then calls the procedure again after receiving the gateway response.

Note: A newer alternative `Billing.DepositLogInsert` inserts the full request+response in one call. `DepositLogAdd` supports the asynchronous pattern where request and response arrive at different times.

---

## 2. Business Logic

### 2.1 Two-Phase Log Pattern

**What**: A single procedure serves both INSERT (request) and UPDATE (response) operations, controlled by whether @DepositLogID is NULL.

**Columns/Parameters Involved**: `@DepositLogID`, `@DepositActionID`, `@RequestDate`, `@RequestMessage`, `@ResponseDate`, `@ResponseMessage`

**Rules**:
- When `@DepositLogID IS NULL`: INSERT. Only request fields are written (DepositActionID, RequestDate, RequestMessage). Response fields remain NULL in the DB row until Phase 2.
- When `@DepositLogID IS NOT NULL`: UPDATE. Sets ResponseDate and ResponseMessage on the existing row matching the ID.
- The new log ID is returned via `SELECT SCOPE_IDENTITY()` (a result set, not an OUTPUT parameter). The caller must read the first result set to get the ID.
- If `@DepositLogID IS NOT NULL` during the INSERT path, it is silently treated as an UPDATE (the INSERT branch is skipped). This means passing a non-null ID to "insert" will incorrectly execute the UPDATE path.

```
Call 1: @DepositLogID = NULL
  -> INSERT History.DepositLog (DepositActionID, RequestDate, RequestMessage)
  -> SELECT SCOPE_IDENTITY() -> caller captures this as the new @DepositLogID

... gateway call ...

Call 2: @DepositLogID = <ID from Call 1>
  -> UPDATE History.DepositLog SET ResponseDate, ResponseMessage WHERE DepositLogID = <ID>
  -> SCOPE_IDENTITY() is NULL for UPDATE, so SELECT returns NULL
```

### 2.2 Difference vs DepositLogInsert

**What**: Two procedures serve the same logical purpose but different calling patterns.

**Columns/Parameters Involved**: `@ResponseDate`, `@ResponseMessage`

**Rules**:
- `DepositLogAdd`: @ResponseDate and @ResponseMessage default to NULL, enabling request-only inserts; returns new ID as SELECT result set.
- `DepositLogInsert`: All parameters required (no defaults); always inserts both request AND response together; returns new ID via OUTPUT parameter assignment (`SET @DepositLogID = SCOPE_IDENTITY()`).
- Use `DepositLogAdd` when the response arrives asynchronously after the request is logged.
- Use `DepositLogInsert` when both request and response are available simultaneously.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositLogID | INTEGER | YES | - | CODE-BACKED | OUTPUT-style parameter (though not declared OUTPUT). Controls operation mode: NULL = INSERT new log row; non-NULL = UPDATE existing row by this ID. After INSERT, the caller reads the new ID from the SELECT SCOPE_IDENTITY() result set. |
| 2 | @DepositActionID | INTEGER | NO | - | CODE-BACKED | FK to History.DepositAction (inferred). Links this log entry to the deposit action being processed. Only used in the INSERT path. |
| 3 | @RequestDate | DATETIME | NO | - | CODE-BACKED | Timestamp when the request was sent to the payment gateway. Stored on INSERT. Not updated during the response path. |
| 4 | @RequestMessage | TEXT | NO | - | CODE-BACKED | Full text of the request payload sent to the payment gateway (XML or JSON string from the calling application). Stored on INSERT. |
| 5 | @ResponseDate | DATETIME | YES | NULL | CODE-BACKED | Timestamp when the gateway response was received. NULL on INSERT (Phase 1). Set on UPDATE (Phase 2) when the response arrives. |
| 6 | @ResponseMessage | TEXT | YES | NULL | CODE-BACKED | Full text of the response received from the payment gateway. NULL on INSERT (Phase 1). Set on UPDATE (Phase 2). Contains the gateway's approval/decline response payload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositActionID | History.DepositLog | WRITER (INSERT/UPDATE) | Inserts new log entries (Phase 1) or updates existing entries with response (Phase 2). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Payment processing application layer) | - | EXEC | Called by the deposit processing service when making payment gateway calls. Not referenced by other stored procedures in the SSDT repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositLogAdd (procedure)
└── History.DepositLog (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositLog | Table (cross-schema) | INSERT new rows (Phase 1) and UPDATE existing rows (Phase 2). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. Called by application layer during deposit processing. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Important behavioral note**: The procedure uses `SELECT SCOPE_IDENTITY()` (returns a 1-row result set) rather than `SET @DepositLogID = SCOPE_IDENTITY()` (OUTPUT assignment). Callers must handle the result set to retrieve the new log ID. This differs from `Billing.DepositLogInsert` which uses the OUTPUT parameter pattern.

---

## 8. Sample Queries

### 8.1 Log a deposit request (Phase 1)

```sql
DECLARE @NewLogID INT = NULL;
EXEC [Billing].[DepositLogAdd]
    @DepositLogID = @NewLogID,
    @DepositActionID = 12345,
    @RequestDate = GETDATE(),
    @RequestMessage = '<Request>...</Request>';
-- Capture the SCOPE_IDENTITY() from the result set as @NewLogID
```

### 8.2 Log the gateway response (Phase 2)

```sql
EXEC [Billing].[DepositLogAdd]
    @DepositLogID = 99887,   -- ID captured from Phase 1
    @DepositActionID = 12345,
    @RequestDate = '2026-01-01 10:00:00',
    @RequestMessage = '<Request>...</Request>',
    @ResponseDate = GETDATE(),
    @ResponseMessage = '<Response><Status>Approved</Status></Response>';
```

### 8.3 Verify log entries in History.DepositLog

```sql
SELECT TOP 10
    DepositLogID, DepositActionID,
    RequestDate, LEFT(RequestMessage, 100) AS RequestPreview,
    ResponseDate, LEFT(ResponseMessage, 100) AS ResponsePreview
FROM [History].[DepositLog] WITH (NOLOCK)
ORDER BY DepositLogID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Deposit Log Additions (Jira 1637)](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1775633086) | Confluence | Page found in search but not accessible (restricted MG space). No content extracted. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 1 Confluence (not accessible) + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositLogAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositLogAdd.sql*
