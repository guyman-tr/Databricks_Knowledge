# AffiliateCommission.LoadAffiliateTraderRegistrationQueue

> DISABLED procedure (early RETURN) that was originally designed to dequeue registration messages from Service Broker into the AffiliateTraderRegistrationQueue staging table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateTraderRegistrationInfo XML OUTPUT, @IDENTITY BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

LoadAffiliateTraderRegistrationQueue was the Service Broker dequeue procedure for registration messages, analogous to LoadAffiliateTraderCreditQueue for credits. However, it has been **intentionally disabled** by adding an early RETURN statement at the top of the procedure body (March 2023, PART-1253).

The procedure still exists in the schema for backward compatibility but does nothing when called. The registration pipeline has been migrated away from Service Broker to a different message delivery mechanism. All code after the RETURN statement is dead code.

---

## 2. Business Logic

### 2.1 Disabled - Early Return

**What**: Procedure exits immediately without any action.

**Columns/Parameters Involved**: N/A

**Rules**:
- RETURN is the first executable statement (after BEGIN TRAN / BEGIN TRY)
- All subsequent code (EXEC Broker.actAffiliateTraderRegistration, INSERT into queue) is never executed
- Disabled per PART-1253 (2023-03-19, Noga Rozen)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTraderRegistrationInfo | xml (OUTPUT) | YES | - | CODE-BACKED | Would contain the dequeued XML registration message. Always NULL since procedure is disabled. |
| 2 | @IDENTITY | bigint (OUTPUT) | YES | - | CODE-BACKED | Would contain the queue row IDENTITY. Always NULL since procedure is disabled. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.AffiliateTraderRegistrationQueue | WRITE (dead code) | Would insert registration messages (disabled) |
| - | Broker.actAffiliateTraderRegistration | EXEC (dead code) | Would dequeue from Service Broker (disabled) |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. May still be called by legacy job but has no effect.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.LoadAffiliateTraderRegistrationQueue (procedure)
+-- (DISABLED - early RETURN, no active dependencies)
```

### 6.1 Objects This Depends On

No active dependencies (procedure is disabled with early RETURN).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Legacy SQL Agent job) | External | May still call this procedure, but it has no effect |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Call the disabled procedure (no-op)
```sql
DECLARE @Msg XML, @ID BIGINT
EXEC [AffiliateCommission].[LoadAffiliateTraderRegistrationQueue]
    @AffiliateTraderRegistrationInfo = @Msg OUTPUT,
    @IDENTITY = @ID OUTPUT
-- Both outputs will be NULL
```

### 8.2 Check if any registration queue messages exist
```sql
SELECT COUNT(*) AS QueueDepth
FROM [AffiliateCommission].[AffiliateTraderRegistrationQueue] WITH (NOLOCK)
```

### 8.3 View registration queue entries (historical only)
```sql
SELECT TOP 10 ID, DateCreated, DateModified
FROM [AffiliateCommission].[AffiliateTraderRegistrationQueue] WITH (NOLOCK)
ORDER BY DateCreated DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-1253: Disabled the call to registration Service Broker (2023-03-19, Noga Rozen)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.LoadAffiliateTraderRegistrationQueue | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.LoadAffiliateTraderRegistrationQueue.sql*
