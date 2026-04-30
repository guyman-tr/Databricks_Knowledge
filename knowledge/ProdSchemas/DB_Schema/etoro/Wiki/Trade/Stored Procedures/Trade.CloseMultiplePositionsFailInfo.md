# Trade.CloseMultiplePositionsFailInfo

> Logs failure details when a batch close of multiple positions fails, recording the customer, affected position IDs, error description, and error code into History.CloseMultiplePositionsFail.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PositionIDsToClose (identifies the failed close attempt) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseMultiplePositionsFailInfo is an error logging procedure called when a batch position close operation fails. When a customer or the system attempts to close multiple positions simultaneously and the operation fails, this procedure records the failure details for audit, debugging, and support investigation.

The procedure is referenced in the code comments as step 5 in the close-by-instrument flow (History.CloseByInstrumentFailInfo). It captures the complete context of the failure: which customer, which positions were targeted, why it failed, when the request occurred, the client's request GUID for correlation, and an error code for programmatic handling.

---

## 2. Business Logic

### 2.1 Failure Logging

**What**: Records a single failure event for a multi-position close attempt.

**Columns/Parameters Involved**: `@CID`, `@PositionIDsToClose`, `@FailDescription`, `@RequestOccurred`, `@ClientRequestGuid`, `@ErrorCode`

**Rules**:
- Inserts one row into History.CloseMultiplePositionsFail per failure event
- FailOccurred is set to GETUTCDATE() (server time of the failure, distinct from @RequestOccurred which is when the client made the request)
- @PositionIDsToClose is a VARCHAR(MAX) containing a comma-separated or structured list of position IDs
- @ClientRequestGuid and @ErrorCode are optional (NULL defaults)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose multi-position close failed. Identifies the account affected. |
| 2 | @PositionIDsToClose | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated or structured list of PositionIDs that were targeted for closure. Stored as-is for debugging. |
| 3 | @FailDescription | VARCHAR(MAX) | NO | - | CODE-BACKED | Human-readable description of why the close operation failed (e.g., error message, exception details). |
| 4 | @RequestOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the client originally submitted the close request. May differ from the server-side FailOccurred time. |
| 5 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation GUID from the client application. Used to trace the request through distributed systems. |
| 6 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Machine-readable error code for programmatic failure classification. NULL when error code is not applicable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.CloseMultiplePositionsFail | INSERT | Writes one row per failure event with all parameters plus server-generated FailOccurred timestamp |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close-by-instrument flow (external) | - | EXEC | Called as error handler (step 5) when batch position close fails |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseMultiplePositionsFailInfo (procedure)
+-- History.CloseMultiplePositionsFail (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CloseMultiplePositionsFail | Table | INSERT - failure logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Position close flow | External | EXEC - error handler during batch close operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No TRY/CATCH | Error handling | Simple INSERT with no error handling - failure of this error logger itself would propagate to the caller |
| No transaction | Atomicity | Single INSERT - inherently atomic |

---

## 8. Sample Queries

### 8.1 View recent multi-position close failures

```sql
SELECT TOP 20 CID, PositionIDsToClose, FailDescription, RequestOccurred, FailOccurred, ErrorCode
FROM   History.CloseMultiplePositionsFail WITH (NOLOCK)
ORDER BY FailOccurred DESC;
```

### 8.2 Check failures for a specific customer

```sql
SELECT FailDescription, PositionIDsToClose, ErrorCode, FailOccurred
FROM   History.CloseMultiplePositionsFail WITH (NOLOCK)
WHERE  CID = 12345
ORDER BY FailOccurred DESC;
```

### 8.3 Aggregate failures by error code

```sql
SELECT ErrorCode, COUNT(*) AS FailCount, MAX(FailOccurred) AS LastOccurrence
FROM   History.CloseMultiplePositionsFail WITH (NOLOCK)
WHERE  FailOccurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY ErrorCode
ORDER BY FailCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseMultiplePositionsFailInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseMultiplePositionsFailInfo.sql*
