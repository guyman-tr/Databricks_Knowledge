# History.DepositLog

> Synonym providing local-schema access to DB_Logs.History.DepositLog - the deposit payment request/response log table in the DB_Logs database, tracking the HTTP/API communication between eToro and payment providers for each deposit action.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.DepositLog |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.DepositLog` is a cross-database synonym that makes `DB_Logs.History.DepositLog` accessible within the etoro database. The target table records the raw request and response messages for each deposit action - the actual communication between eToro's system and payment providers. This is distinct from `History.DepositStep` (which tracks workflow step outcomes); DepositLog stores the low-level payment gateway message payloads.

From `Billing.DepositLogAdd` usage, the underlying table has a dual-purpose pattern: if `@DepositLogID IS NULL`, a new log row is INSERTed (recording the request); if `@DepositLogID` has a value, that row is UPDATEd with the response. This INSERT-then-UPDATE pattern tracks the full request/response lifecycle of a single payment action in one row. Columns: DepositLogID (IDENTITY, SELECT SCOPE_IDENTITY() returned), DepositActionID, RequestDate, RequestMessage (TEXT), ResponseDate (nullable), ResponseMessage (TEXT, nullable).

Three Billing procedures use this synonym: `Billing.DepositLogAdd` (write), `Billing.DepositLogInsert` (write), and `Billing.GetLastDepositActionForLog` (read).

---

## 2. Business Logic

### 2.1 Two-Phase Request/Response Logging

**What**: Each deposit action communication is logged in two phases: request INSERT then response UPDATE.

**Columns/Parameters Involved**: DepositLogID, DepositActionID, RequestDate, RequestMessage, ResponseDate, ResponseMessage

**Rules**:
- Phase 1 (INSERT): when request is sent to payment provider - @DepositLogID is NULL, new row created with DepositActionID, RequestDate, RequestMessage; SCOPE_IDENTITY() returned as the new ID
- Phase 2 (UPDATE): when response arrives - @DepositLogID is the ID from Phase 1, ResponseDate and ResponseMessage are added to the same row
- DepositActionID links to the specific deposit action (e.g., authorize, capture, refund) in Billing schema
- RequestMessage and ResponseMessage are TEXT type - legacy large-text columns for payment gateway XML/JSON payloads

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs; MCP access not available).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.DepositLog. Target columns inferred from Billing.DepositLogAdd usage: DepositLogID (IDENTITY), DepositActionID, RequestDate (datetime), RequestMessage (TEXT), ResponseDate (datetime, nullable), ResponseMessage (TEXT, nullable). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.DepositLog | Synonym | All operations redirect to this target in DB_Logs |
| DepositActionID | Billing schema | Implicit | Links each log row to a specific deposit action in the Billing schema |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositLogAdd | INSERT + UPDATE | Writer | Primary writer; inserts request row and later updates with response |
| Billing.DepositLogInsert | INSERT | Writer | Secondary insert writer for deposit logs |
| Billing.GetLastDepositActionForLog | SELECT | Reader | Reads the most recent log entry for a deposit action |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DepositLog (synonym)
└── DB_Logs.History.DepositLog (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.DepositLog | Table (external DB) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositLogAdd | Procedure | INSERT request + UPDATE with response |
| Billing.DepositLogInsert | Procedure | Inserts deposit log entries |
| Billing.GetLastDepositActionForLog | Procedure | Reads most recent deposit action log |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Find recent deposit log entries (requires cross-DB permission)

```sql
SELECT TOP 20
    DepositLogID,
    DepositActionID,
    RequestDate,
    RequestMessage,
    ResponseDate,
    ResponseMessage
FROM History.DepositLog WITH (NOLOCK)
ORDER BY DepositLogID DESC
```

### 8.2 Find incomplete request/response pairs (request sent, no response)

```sql
SELECT TOP 20
    DepositLogID,
    DepositActionID,
    RequestDate,
    RequestMessage
FROM History.DepositLog WITH (NOLOCK)
WHERE ResponseDate IS NULL
  AND RequestDate < DATEADD(HOUR, -1, GETDATE())
ORDER BY RequestDate DESC
```

### 8.3 Find all log entries for a specific deposit action

```sql
SELECT
    DepositLogID,
    RequestDate,
    RequestMessage,
    ResponseDate,
    ResponseMessage
FROM History.DepositLog WITH (NOLOCK)
WHERE DepositActionID = 99999
ORDER BY RequestDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym - structure from target DB not accessible)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.DepositLog | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.DepositLog.sql*
