# BackOffice.AddToQueueConversationFromDynamics

> Deactivated stub procedure - originally enqueued a customer conversation event from Microsoft Dynamics CRM to the BackOffice customer support queue via SQL Server Service Broker. Currently returns 0 with no action.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure was originally designed to bridge Microsoft Dynamics CRM and the eToro BackOffice customer support queue via SQL Server Service Broker. When a customer support conversation was recorded in Dynamics, this procedure would be called to enqueue it in the BackOffice system, allowing BackOffice agents to see the conversation in their workflow queue alongside other support activity.

The procedure has been fully deactivated: the entire logic is commented out and the body consists only of `RETURN 0`. The procedure signature is preserved to avoid breaking callers that may still invoke it (those calls now succeed silently without any side effects).

The commented-out code reveals the original intent: look up the BackOffice ManagerID by their Dynamics email address, build an XML payload from `Customer.Customer` data (omitting test users where `PlayerLevelID=4`), and send the XML to `svcCustomerSupport` via a Service Broker dialog. The deactivation likely reflects migration away from the Dynamics integration or Service Broker deprecation.

---

## 2. Business Logic

### 2.1 Deactivated - No Active Logic

**What**: The procedure is a no-op stub. All business logic is commented out.

**Rules**:
- Current behavior: accepts all parameters, returns 0 immediately
- No tables are read or written
- No errors are raised for any input
- Safe to call with any parameter values

### 2.2 Original Intent (Commented Out)

**What**: The commented body reveals a Service Broker-based Dynamics CRM integration.

**Rules** (historical, not active):
- Would look up ManagerID from BackOffice.Manager WHERE Email = @Email AND IsActive=1
- Would query Customer.Customer WHERE CID=@CID AND PlayerLevelID<>4 (skip test users)
- Would build XML with: CustomerSupportType='CONVERSATION', ManagerID, Commission=0, Answered, CID, plus customer marketing/tracking fields (ProviderID, CountryIDByIP, SerialID, etc.)
- Would send XML to svcCustomerSupport Service Broker service via BEGIN DIALOG CONVERSATION
- Test users (PlayerLevelID=4) were excluded: NULL XML check caused early RETURN(0)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Accepted but unused (body is commented out). Originally used to query Customer.Customer and filter test users (PlayerLevelID<>4). |
| 2 | @Email | VARCHAR(50) | NO | - | CODE-BACKED | Email address. Accepted but unused. Originally used to resolve BackOffice ManagerID from BackOffice.Manager. |
| 3 | @Answered | BIT | NO | - | CODE-BACKED | Whether the conversation was answered. Accepted but unused. Originally included in the Service Broker XML payload. |
| 4 | @Occurred | datetime | NO | - | CODE-BACKED | Timestamp of the conversation event. Accepted but unused. Originally included in the XML payload. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no active references - all code is commented out. Historically referenced:
- BackOffice.Manager (lookup ManagerID by Email)
- Customer.Customer (build XML payload, filter test users)
- svcCustomerSupport (Service Broker send target)

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in BackOffice schema. Called from Microsoft Dynamics CRM integration when a customer conversation is recorded.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AddToQueueConversationFromDynamics (procedure)
(no active dependencies - body is commented out, RETURN 0 only)
```

### 6.1 Objects This Depends On

No dependencies. Body is commented out.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Microsoft Dynamics CRM integration | External | Calls this procedure when a conversation is recorded; currently receives RETURN 0 silently |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Deactivated | Design | All DML and Service Broker logic is commented out. RETURN 0 is the only active statement. |

---

## 8. Sample Queries

### 8.1 Call the stub (no-op)

```sql
-- This call returns 0 and does nothing
EXEC BackOffice.AddToQueueConversationFromDynamics
    @CID = 12345,
    @Email = 'agent@etoro.com',
    @Answered = 1,
    @Occurred = GETUTCDATE()
```

### 8.2 Verify the procedure body is commented out

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('BackOffice.AddToQueueConversationFromDynamics'))
```

### 8.3 Find any callers of this procedure in other BackOffice procedures

```sql
-- Search for references in SQL Server metadata
SELECT OBJECT_NAME(referencing_id) AS CallerName
FROM sys.sql_expression_dependencies WITH (NOLOCK)
WHERE referenced_entity_name = 'AddToQueueConversationFromDynamics'
  AND referenced_schema_name = 'BackOffice'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (1, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (stub) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AddToQueueConversationFromDynamics | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AddToQueueConversationFromDynamics.sql*
