# Billing.GetMessageGroup

> Maps a payment status code and optional provider error code to a customer-facing message group - the two-path lookup that drives localized deposit error messages in the eToro UI.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentStatusID + optional @ErrorCode - returns (PaymentStatusMessageGroupID, MessageGroupName, Conditions, ErrorCode) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMessageGroup` resolves the customer-facing error message category for a failed or notable payment event. When a deposit fails, the payment provider returns a numeric status code and sometimes an error code. This procedure translates those codes into a `MessageGroupName` (e.g., "A", "Y", "AK") that the application uses to look up the localized error message displayed to the customer.

The procedure has two query paths: when `@ErrorCode` is NULL, it returns the generic message group for the status (the fallback). When `@ErrorCode` is provided, it returns all matches - both the specific error code match AND the generic fallback (via the `ISNULL(PM.ErrorCode, @ErrorCode) = @ErrorCode` trick). The calling application then selects the most appropriate message.

Created by Shay O. 24/10/2021 (PAYIL-3185) - the only consumer of `Billing.PaymentStatusMessageGroup`.

---

## 2. Business Logic

### 2.1 Path 1: Generic Fallback (NULL ErrorCode)

**What**: Returns the generic message group for the payment status when no error code is known.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@ErrorCode=NULL`, `PM.ErrorCode IS NULL`

**Rules**:
- Called when provider returned no error code or error code is unavailable
- `WHERE PM.PaymentStatusID = @PaymentStatusID AND PM.ErrorCode IS NULL`
- Returns only rows where `PaymentStatusMessageGroup.ErrorCode` is NULL (the generic/fallback rows)
- Each PaymentStatusID has at least one fallback row

### 2.2 Path 2: Error-Code Specific (ErrorCode Provided)

**What**: Returns both the specific error code mapping AND the generic fallback, letting the caller prefer the specific match.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@ErrorCode`, `ISNULL(PM.ErrorCode, @ErrorCode) = @ErrorCode`

**Rules**:
- `WHERE PM.PaymentStatusID = @PaymentStatusID AND ISNULL(PM.ErrorCode, @ErrorCode) = @ErrorCode`
- `ISNULL(PM.ErrorCode, @ErrorCode)`: if `PM.ErrorCode IS NULL`, substitute `@ErrorCode` -> equals `@ErrorCode` -> row included
- Effect: returns rows where `PM.ErrorCode = @ErrorCode` (specific match) AND rows where `PM.ErrorCode IS NULL` (fallback)
- If both a specific and fallback row match, BOTH are returned (caller chooses which to display)
- If no specific match exists: only fallback rows are returned

**Diagram**:
```
@ErrorCode = 490, @PaymentStatusID = 3:
  PM rows matching:
    { ErrorCode=490, MessageGroupID=25, MessageGroupName='Y' }  <- specific match
    { ErrorCode=NULL, MessageGroupID=X, MessageGroupName='A' }  <- fallback included

@ErrorCode = NULL, @PaymentStatusID = 3:
  PM rows matching:
    { ErrorCode=NULL, MessageGroupID=X, MessageGroupName='A' }  <- fallback only
```

### 2.3 Conditions Column

**What**: An optional runtime flag that allows the same (PaymentStatusID, ErrorCode) to route to different message groups based on application state.

**Columns/Parameters Involved**: `Conditions`

**Rules**:
- Returned as part of the result set but not filtered server-side
- Only `"1"` observed in live data (one row, PaymentStatusMessageGroupID=1)
- Evaluated by the calling application after retrieval - SQL does not interpret it
- NULL for the vast majority of rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentStatusID | INT | NO | - | CODE-BACKED | The payment status to look up (from Dictionary.PaymentStatus). Observed values with mappings: 3 (failed/declined - 173 mappings), 4 (cancelled - 17), 6 (1), 13 (1), 35 (36). |
| 2 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Optional provider error code. NULL triggers Path 1 (generic fallback). Non-NULL triggers Path 2 (specific + fallback combined). Example: 490, 500, 653, 720, 1474-1506. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PaymentStatusMessageGroupID | int | NO | - | CODE-BACKED | Surrogate PK of the matching row in Billing.PaymentStatusMessageGroup. Not used for message lookup - returned for reference. |
| 4 | MessageGroupName | varchar | NO | - | CODE-BACKED | Alphabetical message group code (e.g., "A", "Y", "AK", "GP"). Used by the application to look up the localized error message in the frontend. The code is opaque in SQL but maps to a UI message key. |
| 5 | Conditions | varchar(255) | YES | NULL | CODE-BACKED | Optional runtime condition flag (only "1" observed; NULL for most rows). Evaluated by the calling application - not filtered in SQL. |
| 6 | ErrorCode | int | YES | NULL | CODE-BACKED | The ErrorCode value from the matched Billing.PaymentStatusMessageGroup row (NULL for fallback rows, non-NULL for specific matches). Helps the caller identify which match is specific vs. fallback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INNER JOIN (MG) | Dictionary.MessageGroup | Direct Read | Resolves MessageGroupID to MessageGroupName and Conditions |
| INNER JOIN (PM) | Billing.PaymentStatusMessageGroup | Direct Read | Source of (PaymentStatusID, ErrorCode) -> MessageGroupID mappings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Called from payment processing application code after a deposit failure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMessageGroup (procedure)
├── Billing.PaymentStatusMessageGroup (table)
└── Dictionary.MessageGroup (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentStatusMessageGroup | Table | INNER JOIN - maps (PaymentStatusID, ErrorCode) to MessageGroupID |
| Dictionary.MessageGroup | Table | INNER JOIN - resolves MessageGroupID to MessageGroupName |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get generic message for a failed payment (no error code)

```sql
EXEC Billing.GetMessageGroup @PaymentStatusID = 3
-- Returns: fallback message group rows for failed payments (ErrorCode IS NULL rows)
```

### 8.2 Get specific message for a provider error

```sql
EXEC Billing.GetMessageGroup @PaymentStatusID = 3, @ErrorCode = 490
-- Returns: MessageGroupName='Y' (specific match) + fallback rows
-- Application uses the specific match (non-NULL ErrorCode in results) when available
```

### 8.3 Inspect all message groups for PaymentStatusID=3

```sql
SELECT pm.ErrorCode, mg.MessageGroupName, pm.Conditions
FROM Billing.PaymentStatusMessageGroup pm WITH (NOLOCK)
INNER JOIN Dictionary.MessageGroup mg WITH (NOLOCK) ON pm.MessageGroupID = mg.MessageGroupID
WHERE pm.PaymentStatusID = 3
ORDER BY pm.ErrorCode NULLS FIRST
```

---

## 9. Atlassian Knowledge Sources

PAYIL-3185 (Shay O., 24/10/2021): Initial version - introduced payment status-to-message-group routing for customer-facing deposit error messages.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMessageGroup | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMessageGroup.sql*
