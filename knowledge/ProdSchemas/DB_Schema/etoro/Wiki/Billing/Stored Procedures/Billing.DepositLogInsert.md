# Billing.DepositLogInsert

> Inserts a complete deposit gateway request/response pair into the audit log in a single call - the synchronous alternative to DepositLogAdd for scenarios where both request and response are available at once.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into History.DepositLog; new ID returned via @DepositLogID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositLogInsert` creates a complete deposit gateway interaction log record in `History.DepositLog` in a single call. Unlike `Billing.DepositLogAdd` which supports a two-phase pattern (request first, then response update), this procedure requires all fields - both request and response - to be provided together.

This is the preferred pattern when the calling code has a complete request/response pair available before logging (e.g., after a synchronous gateway call completes). The new log ID is returned via the `@DepositLogID OUTPUT` parameter (not a result set), making it easier to chain into further processing without reading a result set.

The procedure was likely created as an improved replacement for `DepositLogAdd` with cleaner OUTPUT parameter semantics, while the older procedure was retained for backward compatibility with existing callers that depend on the two-phase pattern.

---

## 2. Business Logic

### 2.1 Single-Phase Complete Insert

**What**: Inserts all six fields (both request and response) in one atomic INSERT.

**Columns/Parameters Involved**: `@DepositActionID`, `@RequestDate`, `@RequestMessage`, `@ResponseDate`, `@ResponseMessage`, `@DepositLogID`

**Rules**:
- All parameters are required (no defaults). Callers must provide all values.
- The INSERT writes all fields simultaneously: no intermediate state where ResponseDate is NULL.
- After INSERT, `SET @DepositLogID = SCOPE_IDENTITY()` assigns the new row's identity to the OUTPUT parameter.
- RETURN 0 on success.

### 2.2 Comparison with DepositLogAdd

**What**: Two procedures serve the same logging purpose but with different calling semantics.

**Columns/Parameters Involved**: `@DepositLogID` (OUTPUT vs SELECT), `@ResponseDate`, `@ResponseMessage`

**Rules**:
- `DepositLogInsert`: All fields required; single INSERT; ID returned via `SET @DepositLogID = SCOPE_IDENTITY()` (OUTPUT parameter).
- `DepositLogAdd`: Response fields optional (nullable defaults); two-phase INSERT+UPDATE; ID returned via `SELECT SCOPE_IDENTITY()` (result set).
- Choose `DepositLogInsert` for synchronous gateway calls where request and response are available together.
- Choose `DepositLogAdd` for asynchronous calls where the request is logged before the response arrives.

```
DepositLogInsert:  One call -> Complete row inserted -> ID in OUTPUT param
DepositLogAdd:     Call 1 (request) -> Partial row + SELECT result -> Call 2 (response) -> Row updated
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositLogID | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Returns the new History.DepositLog row ID after INSERT via `SET @DepositLogID = SCOPE_IDENTITY()`. Caller should declare as OUTPUT. Pass NULL initially; the procedure sets it. |
| 2 | @DepositActionID | INTEGER | NO | - | CODE-BACKED | FK to History.DepositAction (inferred). Links this log entry to the deposit action context. Required - no default. |
| 3 | @RequestDate | DATETIME | NO | - | CODE-BACKED | Timestamp when the request was sent to the payment gateway. Required. |
| 4 | @RequestMessage | TEXT | NO | - | CODE-BACKED | Full text of the request payload sent to the payment gateway (XML, JSON, or form data). Required. |
| 5 | @ResponseDate | DATETIME | NO | - | CODE-BACKED | Timestamp when the response was received from the payment gateway. Required (no NULL default, unlike DepositLogAdd). |
| 6 | @ResponseMessage | TEXT | NO | - | CODE-BACKED | Full text of the response payload from the payment gateway. Required (no NULL default, unlike DepositLogAdd). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all parameters) | History.DepositLog | WRITER (INSERT) | Creates a complete request+response log row in the History schema audit table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application payment processing layer) | - | EXEC | Called by the deposit service after synchronous gateway calls complete. Not referenced by other stored procedures in the SSDT repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositLogInsert (procedure)
└── History.DepositLog (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositLog | Table (cross-schema) | INSERT target - writes the complete request/response record. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. Called by application layer. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Key difference from DepositLogAdd**: Uses `SET @DepositLogID = SCOPE_IDENTITY()` (OUTPUT parameter assignment) instead of `SELECT SCOPE_IDENTITY()` (result set). This means the caller must declare `@DepositLogID OUTPUT` and pass it as `OUTPUT` in the EXEC call.

---

## 8. Sample Queries

### 8.1 Log a complete synchronous gateway interaction

```sql
DECLARE @LogID INT;
EXEC [Billing].[DepositLogInsert]
    @DepositLogID = @LogID OUTPUT,
    @DepositActionID = 12345,
    @RequestDate = '2026-03-18 10:00:00',
    @RequestMessage = '<Request><Amount>100</Amount></Request>',
    @ResponseDate = '2026-03-18 10:00:01',
    @ResponseMessage = '<Response><Status>Approved</Status><AuthCode>XYZ123</AuthCode></Response>';
SELECT @LogID AS NewDepositLogID;
```

### 8.2 Verify the inserted log record

```sql
SELECT TOP 1
    DepositLogID, DepositActionID, RequestDate,
    LEFT(RequestMessage, 200) AS RequestPreview,
    ResponseDate, LEFT(ResponseMessage, 200) AS ResponsePreview
FROM [History].[DepositLog] WITH (NOLOCK)
ORDER BY DepositLogID DESC;
```

### 8.3 Compare DepositLogInsert vs DepositLogAdd usage patterns

```sql
-- DepositLogInsert pattern (synchronous - OUTPUT param):
DECLARE @ID1 INT;
EXEC [Billing].[DepositLogInsert] @DepositLogID = @ID1 OUTPUT,
    @DepositActionID = 1, @RequestDate = GETDATE(), @RequestMessage = 'req',
    @ResponseDate = GETDATE(), @ResponseMessage = 'resp';

-- DepositLogAdd pattern (asynchronous - SELECT result):
EXEC [Billing].[DepositLogAdd]
    @DepositLogID = NULL, @DepositActionID = 1,
    @RequestDate = GETDATE(), @RequestMessage = 'req';
-- Must read SCOPE_IDENTITY() from the result set returned
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositLogInsert | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositLogInsert.sql*
