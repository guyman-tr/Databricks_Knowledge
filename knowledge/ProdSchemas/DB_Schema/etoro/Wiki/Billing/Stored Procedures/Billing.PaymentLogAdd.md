# Billing.PaymentLogAdd

> Appends a payment gateway communication log entry to History.PaymentLog, capturing the raw message and direction for a given payment action.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: SCOPE_IDENTITY() (new PaymentLogID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentLogAdd` is the append-only write entry point for `History.PaymentLog`, the communication audit trail for legacy payment gateway interactions. Each log entry records the raw message exchanged with the payment gateway (request or response) alongside the direction of communication and the associated payment action.

The procedure enables complete traceability of every message in the legacy payment processing flow: what was sent/received, when, and in response to which payment action. This audit trail is essential for dispute resolution, fraud investigation, and gateway reconciliation for pre-2011 `Billing.Payment` era transactions.

The message content is stored as unstructured TEXT (free-form), accommodating gateway-specific formats (XML, ISO 8583, plain text). The log is append-only with no update or delete path.

---

## 2. Business Logic

### 2.1 Payment Direction Classification

**What**: Each log entry is tagged with the direction of the communication.

**Parameters Involved**: `@PaymentDirectionID`

**Rules**:
- FK to Dictionary.PaymentDirection:
  - 1 = "From Googess" (likely gateway-initiated or inbound direction - possible typo for "From Goges" or similar gateway name)
  - 2 = "From PSP" (Payment Service Provider response)
- Direction identifies whether the message originated from the internal system or was received from the payment gateway/PSP

### 2.2 Relationship to PaymentAction

**What**: Each log entry is associated with a specific payment action.

**Parameters Involved**: `@PaymentActionID`

**Rules**:
- FK to History.PaymentAction - every log entry belongs to a specific payment action (created by Billing.PaymentActionAdd)
- Multiple log entries can exist for a single PaymentActionID (one for the request, one for the response, etc.)
- Indexed by PaymentActionID for efficient lookup

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentDirectionID | INTEGER | NO | - | VERIFIED | Communication direction. FK to Dictionary.PaymentDirection: 1="From Googess" (inbound/gateway-initiated), 2="From PSP" (Payment Service Provider response). Classifies whether this message was received from the gateway or sent to it. |
| 2 | @PaymentActionID | INTEGER | NO | - | CODE-BACKED | FK to History.PaymentAction (created by Billing.PaymentActionAdd). Associates this log entry with its parent payment action. Indexed in History.PaymentLog for lookup. |
| 3 | @PaymentLogDate | DATETIME | NO | - | CODE-BACKED | Timestamp of the logged gateway communication. Caller-supplied (not defaulted in proc). |
| 4 | @PaymentMessage | TEXT | NO | - | CODE-BACKED | Raw message content from the payment gateway communication. Free-form text; may be XML, ISO 8583 format, or plain text depending on the payment protocol. Stored in History.PaymentLog (TEXT type, PAGE-compressed). |
| 5 | Result set | INTEGER | - | - | CODE-BACKED | SELECT SCOPE_IDENTITY() - returns the new PaymentLogID assigned to the inserted log entry. |
| 6 | RETURN value | INTEGER | - | 0 | CODE-BACKED | Always returns 0. No error handling - INSERT errors will surface as exceptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | History.PaymentLog | WRITER | Appends a new gateway communication log entry |
| @PaymentDirectionID | Dictionary.PaymentDirection | Lookup | 1=From Googess, 2=From PSP |
| @PaymentActionID | History.PaymentAction | FK | Links log to the parent payment action |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service (external) | - | EXEC caller | Called during legacy payment gateway communication cycles to log each message |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentLogAdd (procedure)
└── History.PaymentLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PaymentLog | Table | INSERT - appends communication log entry |
| Dictionary.PaymentDirection | Table | FK lookup - PaymentDirectionID |
| History.PaymentAction | Table | FK target - PaymentActionID must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Called to log each gateway request/response in the legacy payment flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. History.PaymentLog enforces FK on PaymentDirectionID -> Dictionary.PaymentDirection and PaymentActionID -> History.PaymentAction.

---

## 8. Sample Queries

### 8.1 Find all log entries for a specific payment action

```sql
SELECT
    hpl.PaymentLogID,
    hpl.PaymentLogDate,
    pd.Name AS Direction,
    LEFT(CAST(hpl.PaymentMessage AS VARCHAR(500)), 200) AS MessagePreview
FROM History.PaymentLog hpl WITH (NOLOCK)
INNER JOIN Dictionary.PaymentDirection pd WITH (NOLOCK) ON pd.PaymentDirectionID = hpl.PaymentDirectionID
WHERE hpl.PaymentActionID = 12345
ORDER BY hpl.PaymentLogDate;
```

### 8.2 Find all PSP response logs for a given day

```sql
SELECT
    hpl.PaymentLogID,
    hpl.PaymentActionID,
    hpl.PaymentLogDate,
    LEFT(CAST(hpl.PaymentMessage AS VARCHAR(500)), 200) AS MessagePreview
FROM History.PaymentLog hpl WITH (NOLOCK)
WHERE hpl.PaymentDirectionID = 2  -- From PSP
  AND hpl.PaymentLogDate >= '2010-01-01'
  AND hpl.PaymentLogDate < '2010-01-02'
ORDER BY hpl.PaymentLogDate;
```

### 8.3 Count log entries per direction

```sql
SELECT
    pd.Name AS Direction,
    COUNT(*) AS LogCount
FROM History.PaymentLog hpl WITH (NOLOCK)
INNER JOIN Dictionary.PaymentDirection pd WITH (NOLOCK) ON pd.PaymentDirectionID = hpl.PaymentDirectionID
GROUP BY pd.Name
ORDER BY LogCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentLogAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentLogAdd.sql*
