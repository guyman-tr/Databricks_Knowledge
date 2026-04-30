# Billing.PaymentStatusMessageGroup

> Routing table that maps payment status codes and provider error codes to message groups, enabling the billing system to return localized, customer-facing error messages for failed deposit/payment events.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | PaymentStatusMessageGroupID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=90) |

---

## 1. Business Meaning

Billing.PaymentStatusMessageGroup is a lookup/routing table that answers the question: "When a payment fails with this status code and error code, which message group should be shown to the customer?" When a deposit or payment operation fails, the provider returns a payment status and an optional numeric error code. This table maps those combinations to a Dictionary.MessageGroup row, which in turn resolves to a localized error message that is displayed in the eToro UI.

This table was introduced in October 2021 (Jira: PAYIL-3185, per code comment by Shay O.) and is consumed exclusively by Billing.GetMessageGroup. The message group names in Dictionary.MessageGroup use an alphabetical code system (A, B, C... AZ, BA, CA, CC, GP) that maps to UI message keys. The Conditions column adds a conditional flag (currently only "1" observed) allowing the same status+errorcode combination to map to different groups under different runtime conditions.

228 rows cover 5 distinct PaymentStatusID values. PaymentStatusID=3 dominates with 173 rows (failed deposits, covering dozens of provider-specific error codes). PaymentStatusID=35 has 36 rows. Values 4, 6, and 13 have 17, 1, and 1 rows respectively.

---

## 2. Business Logic

### 2.1 Error Code Resolution (Two-Path Lookup)

**What**: GetMessageGroup uses two separate query paths depending on whether an error code is provided.

**Columns/Parameters Involved**: `PaymentStatusID`, `ErrorCode`, `MessageGroupID`, `Conditions`

**Rules**:
- **Path 1 (no error code)**: WHERE PaymentStatusID = @PaymentStatusID AND ErrorCode IS NULL. Returns the generic fallback message group for that status. Multiple rows can match if Conditions differs.
- **Path 2 (with error code)**: WHERE PaymentStatusID = @PaymentStatusID AND ISNULL(ErrorCode, @ErrorCode) = @ErrorCode. The ISNULL trick means rows with NULL ErrorCode also match when an error code is passed - ensuring fallback rows are included alongside specific rows.
- When both a specific match (non-NULL ErrorCode) and a fallback (NULL ErrorCode) exist, both are returned. The caller decides which to use (likely the more specific one takes priority).
- Conditions column: only "1" observed in live data (one row, PaymentStatusMessageGroupID=1). Its semantic meaning is runtime-evaluated by the caller application - likely a flag that must match a runtime condition.

### 2.2 PaymentStatusID Domain

**What**: The 5 PaymentStatusID values covered correspond to specific payment lifecycle states that can generate customer-facing messages.

**Columns/Parameters Involved**: `PaymentStatusID`

**Rules**:
- PaymentStatusID=3: 173 rows - the primary use case. Represents failed/declined payment status. Most of the 173 rows are provider-specific error codes (e.g., 390, 490, 500, 653, 720, 1474-1479, 1486...) mapping to message groups A through AK and beyond.
- PaymentStatusID=4: 17 rows - another failure status (likely "Cancelled by provider").
- PaymentStatusID=6: 1 row - minor status (likely "Payment Sent" or similar).
- PaymentStatusID=13: 1 row - likely a specific terminal state.
- PaymentStatusID=35: 36 rows - a newer status (higher ID), added after the initial 2021 introduction.
- PaymentStatusID is NOT a FK to any dictionary table in this DDL - no explicit constraint.

### 2.3 MessageGroup Code System

**What**: Dictionary.MessageGroup uses alphabetical codes (A-Z, AA-AZ, BA, CA, CC, GP) that map to localized error message templates.

**Columns/Parameters Involved**: `MessageGroupID`

**Rules**:
- 52 distinct MessageGroupIDs used across the 228 rows.
- MessageGroup codes go beyond the alphabet: A(1) through Z(26), then AA(27) through AZ(52), then non-sequential entries: CA(53), BA(54), CC(55), GP(58). The non-sequential naming suggests groups were added out of order.
- Multiple error codes can map to the same MessageGroupID (e.g., MessageGroupID=25 is the most common - mapped by ErrorCodes 490, 503, 508, 674, 695 all in PaymentStatusID=3).
- The MessageGroupName is an opaque code; the actual customer-visible text is stored in the localization system (not in this DB schema).

---

## 3. Data Overview

| PaymentStatusID | Row Count | Meaning |
|----------------|-----------|---------|
| 3 | 173 | Failed/declined payment - the dominant use case with provider-specific error codes |
| 4 | 17 | Cancelled status error mappings |
| 6 | 1 | Single mapping for "Payment Sent" or similar intermediate state |
| 13 | 1 | Single mapping for a specific terminal state |
| 35 | 36 | Newer status added post-2021 with 36 error code mappings |
| **Total** | **228** | **5 distinct PaymentStatusIDs, 52 distinct MessageGroupIDs** |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentStatusMessageGroupID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Not used in business lookups - GetMessageGroup queries by PaymentStatusID+ErrorCode. |
| 2 | PaymentStatusID | int | NO | - | CODE-BACKED | Payment event status code from the payment provider pipeline. No declared FK constraint. Observed values: 3 (failed/declined - 173 rows), 4 (cancelled - 17 rows), 6 (1 row), 13 (1 row), 35 (36 rows). Represents the overall outcome classification of a payment operation. |
| 3 | ErrorCode | int | YES | - | CODE-BACKED | Provider-specific numeric error code accompanying the payment status. NULL means this is the generic fallback row for the PaymentStatusID (no specific error code). Non-NULL rows are more specific mappings for exact provider error codes (e.g., 390, 490, 500, 653, 720, 1474-1506). Observed range: 390 to 3408 for PaymentStatusID=3. |
| 4 | Conditions | varchar(255) | YES | - | CODE-BACKED | Optional runtime condition flag. NULL for most rows. Only "1" observed in live data. Allows the same (PaymentStatusID, ErrorCode) combination to route to different message groups depending on application state. Evaluated by the calling application, not by SQL. |
| 5 | MessageGroupID | int | NO | - | VERIFIED | FK to Dictionary.MessageGroup. The message group code to display for this error combination. Examples from live data: MessageGroupID=1 (Group "A"), 25 (Group "Y"), 37 (Group "AK"), 57 (not in observed MessageGroup rows - may be a gap). 52 distinct groups used across 228 rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MessageGroupID | Dictionary.MessageGroup | FK (FK_DMG_BRMG) | References the message group that determines the customer-facing error message. Explicit FK with CHECK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetMessageGroup | PaymentStatusID, ErrorCode, MessageGroupID | SELECT reader | Primary (only) reader. Takes @PaymentStatusID and optional @ErrorCode, returns matching MessageGroupName and Conditions. Two query paths: NULL ErrorCode path and specific ErrorCode path. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentStatusMessageGroup (table)
  -> Dictionary.MessageGroup (FK target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MessageGroup | Table | FK target for MessageGroupID - stores message group codes (A, B, C... GP) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetMessageGroup | Stored Procedure | SELECT reader - resolves payment status+errorcode to a message group for customer-facing error display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BRMG | CLUSTERED PK | PaymentStatusMessageGroupID ASC | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BRMG | PRIMARY KEY | PaymentStatusMessageGroupID clustered |
| FK_DMG_BRMG | FOREIGN KEY | MessageGroupID -> Dictionary.MessageGroup(MessageGroupID) WITH CHECK |

---

## 8. Sample Queries

### 8.1 Look up message group for a failed payment (using the SP)

```sql
-- Get message group for a failed payment (PaymentStatusID=3) with specific error code
EXEC Billing.GetMessageGroup @PaymentStatusID = 3, @ErrorCode = 490
-- Returns MessageGroupName='Y' (Group 25), Conditions=NULL

-- Get fallback message group for PaymentStatusID=3 with no error code
EXEC Billing.GetMessageGroup @PaymentStatusID = 3
```

### 8.2 View all mappings for a specific payment status

```sql
SELECT
    pm.PaymentStatusID,
    pm.ErrorCode,
    mg.MessageGroupName,
    pm.Conditions
FROM Billing.PaymentStatusMessageGroup pm WITH (NOLOCK)
INNER JOIN Dictionary.MessageGroup mg WITH (NOLOCK) ON pm.MessageGroupID = mg.MessageGroupID
WHERE pm.PaymentStatusID = 3
ORDER BY pm.ErrorCode
```

### 8.3 Find which error codes share the same message group

```sql
SELECT
    mg.MessageGroupName,
    pm.PaymentStatusID,
    COUNT(1) AS cnt
FROM Billing.PaymentStatusMessageGroup pm WITH (NOLOCK)
INNER JOIN Dictionary.MessageGroup mg WITH (NOLOCK) ON pm.MessageGroupID = mg.MessageGroupID
GROUP BY mg.MessageGroupName, pm.PaymentStatusID
ORDER BY cnt DESC
```

---

## 9. Atlassian Knowledge Sources

Code comment in Billing.GetMessageGroup references Jira ticket PAYIL-3185 (Shay O., 24/10/2021 - Initial version). This was the ticket that introduced the payment status-to-message-group routing feature.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PaymentStatusMessageGroup | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PaymentStatusMessageGroup.sql*
