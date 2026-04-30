# Customer.UpdateBasicUserInfo

> Updates a customer's core personal data fields on CustomerStatic and queues an async action to propagate the change to downstream systems via Internal.ActionsToExecute_Registration (ActionID=9).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - GCID lookup for CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateBasicUserInfo is the write-path for a customer's basic personal data (name, gender, language, date of birth, player level) when called from the main eToro application (as opposed to the "Remote" variant, which is called from external systems). It updates Customer.CustomerStatic using a preserve-existing ISNULL pattern, then queues an async action (ActionID=9) in Internal.ActionsToExecute_Registration to propagate the change to downstream systems (e.g., CRM, notification services, or demo account synchronization).

The procedure exists to separate the write (to CustomerStatic) from the propagation (to downstream systems). The queue-based propagation via Internal.ActionsToExecute_Registration decouples this procedure from the downstream consumers - if the queue insert fails, the data is still written to CustomerStatic (the catch re-raises). The async queue allows high-throughput profile updates without blocking on downstream latency.

Data flow: called from the customer profile settings UI or onboarding flow when the customer updates their personal information. Compared to UpdateBasicUserInfoRemote, this version adds the Internal.ActionsToExecute_Registration queue entry (ActionID=9), which triggers downstream processing. @RowCount OUTPUT tells the caller how many CustomerStatic rows were updated.

---

## 2. Business Logic

### 2.1 Preserve-Existing ISNULL Pattern

**What**: All parameters default to NULL, and the UPDATE uses ISNULL(@param, ExistingColumn) to preserve existing values when the caller does not pass a field.

**Columns/Parameters Involved**: `@fName`, `@lName`, `@mName`, `@gender`, `@languageId`, `@dob`, `@level`

**Rules**:
- FirstName = ISNULL(@fName, FirstName) - only updates if @fName is not NULL
- Same pattern for LastName, MiddleName, Gender, LanguageID, BirthDate, PlayerLevelID
- Callers can update a subset of fields by passing only the ones that changed and NULLing the rest
- This allows partial updates without reading-then-writing the full record

### 2.2 Async Downstream Propagation via Action Queue

**What**: After the CustomerStatic UPDATE, all changed values are serialized to XML and inserted into the action queue for downstream processing.

**Columns/Parameters Involved**: All parameters, Internal.ActionsToExecute_Registration

**Rules**:
- XML built as: `<Root><gcid Value="{gcid}"/><fName Value="{fName}"/>...</Root>` using FOR XML Path
- ActionID = 9 identifies this as a "UpdateBasicUserInfo" action type in the action processor
- InsertedToQueue = GETUTCDATE(), CurrentTry = 0, Status = 0, RetVal = 0 (new/unprocessed)
- Queue INSERT is in a TRY/CATCH: if it fails, THROW re-raises the exception (unlike the UPDATE above which has no catch)
- NULL parameter values are included in the XML as NULL - downstream processor must handle them

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Used to look up the customer in CustomerStatic WHERE GCID=@gcid. |
| 2 | @fName | nvarchar(50) | YES | NULL | CODE-BACKED | Customer's first name. Maps to CustomerStatic.FirstName. ISNULL pattern: NULL preserves existing value. |
| 3 | @lName | nvarchar(50) | YES | NULL | CODE-BACKED | Customer's last name. Maps to CustomerStatic.LastName. ISNULL pattern: NULL preserves existing value. |
| 4 | @languageId | int | YES | NULL | CODE-BACKED | Customer's preferred language ID. Maps to CustomerStatic.LanguageID. ISNULL pattern: NULL preserves existing value. |
| 5 | @dob | datetime | YES | NULL | CODE-BACKED | Customer's date of birth. Maps to CustomerStatic.BirthDate. ISNULL pattern: NULL preserves existing value. |
| 6 | @gender | char(1) | YES | NULL | CODE-BACKED | Customer's gender code (e.g., 'M', 'F'). Maps to CustomerStatic.Gender. ISNULL pattern: NULL preserves existing value. |
| 7 | @level | int | YES | NULL | CODE-BACKED | Customer's player level ID. Maps to CustomerStatic.PlayerLevelID (gamification/tier system). ISNULL pattern: NULL preserves existing value. |
| 8 | @mName | nvarchar(50) | YES | NULL | CODE-BACKED | Customer's middle name. Maps to CustomerStatic.MiddleName. Added 2018-01-11. ISNULL pattern: NULL preserves existing value. |
| 9 | @RowCount | int | YES (OUTPUT) | NULL | CODE-BACKED | Output: @@RowCount from the CustomerStatic UPDATE. Non-zero means the customer was found and at least one field was changed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Modifier | Updates personal data fields via ISNULL-preserving SET |
| All params | Internal.ActionsToExecute_Registration | Writer | Queues ActionID=9 for downstream propagation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from customer profile update services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateBasicUserInfo (procedure)
├── Customer.CustomerStatic (table - UPDATE)
└── Internal.ActionsToExecute_Registration (table - queue INSERT)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE target for personal data fields via GCID lookup |
| Internal.ActionsToExecute_Registration | Table | Action queue target; INSERT (ActionID=9) for async downstream propagation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL pattern | Partial update | All UPDATE columns use ISNULL(@param, Column) to preserve existing values when parameter is NULL |
| TRY/CATCH on queue INSERT | Error handling | THROW re-raises if queue INSERT fails; RETURN -1 (unreachable due to THROW) |
| ActionID=9 | Protocol | Queue action type 9 = "UpdateBasicUserInfo" - consumed by Internal.ActionsToExecute_Registration processor |

---

## 8. Sample Queries

### 8.1 Update first and last name for a customer
```sql
DECLARE @Rows INT;
EXEC Customer.UpdateBasicUserInfo
    @gcid = 67890,
    @fName = N'John',
    @lName = N'Smith',
    @RowCount = @Rows OUTPUT;
SELECT @Rows AS RowsUpdated;
```

### 8.2 Update only language (preserve all other fields)
```sql
EXEC Customer.UpdateBasicUserInfo @gcid = 67890, @languageId = 3;
```

### 8.3 Check the action queued for downstream processing
```sql
SELECT TOP 5 ActionID, Params, InsertedToQueue, Status, RetVal
FROM Internal.ActionsToExecute_Registration WITH (NOLOCK)
WHERE ActionID = 9
ORDER BY InsertedToQueue DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateBasicUserInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateBasicUserInfo.sql*
