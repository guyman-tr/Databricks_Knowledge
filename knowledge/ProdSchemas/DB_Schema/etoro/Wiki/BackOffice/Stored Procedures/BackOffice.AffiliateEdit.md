# BackOffice.AffiliateEdit

> Creates or updates an affiliate's status and spread group, cascades SpreadGroupID changes to all referred customers, and notifies Dynamics CRM via Service Broker.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary write path for managing affiliate partner records in the eToro affiliate marketing program. It handles creating new affiliate records when partners first join and updating their status tier or spread group assignment when those change. The AffiliateID is the same as the affiliate's own customer CID/SerialID - affiliates are eToro customers who also participate in the referral program.

The procedure exists because affiliate changes have cascading effects: changing an affiliate's spread group must also update the spread group of all customers they referred (linked via `Customer.Customer.SerialID`). Without this cascade, referred customers would retain the old spread conditions while their affiliate had new ones. The procedure handles this atomically in a single transaction.

Data flows as follows: a BackOffice operator updates an affiliate's tier or spread group in the BackOffice UI, which calls this procedure. After the upsert into `BackOffice.Affiliate` (and the customer cascade if SpreadGroupID changed), the procedure sends an XML notification to `svcDynamics` via SQL Server Service Broker, updating the affiliate's rank in Microsoft Dynamics CRM. The Dynamics notification fires for both INSERT and UPDATE paths.

---

## 2. Business Logic

### 2.1 Affiliate Upsert (CREATE or UPDATE)

**What**: Checks existence and either creates a new record or updates existing affiliate fields.

**Columns/Parameters Involved**: `@AffiliateID`, `@AffiliateStatusID`, `@SpreadGroupID`

**Rules**:
- IF NOT EXISTS in BackOffice.Affiliate: INSERT (AffiliateID, AffiliateStatusID, SpreadGroupID, ManagerID=NULL). ManagerID is not accepted as a parameter - defaults to NULL on creation.
- IF EXISTS: UPDATE SpreadGroupID and AffiliateStatusID WHERE AffiliateID=@AffiliateID
- Both branches use explicit transactions (BEGIN TRAN / COMMIT / ROLLBACK) with @@ERROR check; RAISERROR 60000 on failure
- On INSERT, ManagerID is not set (NULL). On UPDATE, ManagerID is preserved unchanged.

### 2.2 SpreadGroupID Cascade to Referred Customers

**What**: When an affiliate's spread group changes, all their referred customers' spread groups are updated.

**Columns/Parameters Involved**: `@SpreadGroupID`, `Customer.Customer.SpreadGroupID`, `Customer.Customer.SerialID`

**Rules**:
- On UPDATE path only: IF @SpreadGroupID <> @AffiliateSpreadGoup (old value)
- Updates Customer.Customer SET SpreadGroupID=@SpreadGroupID WHERE SerialID=@AffiliateID AND SpreadGroupID=@AffiliateSpreadGoup
- Only customers who still have the OLD spread group are updated (customers manually reassigned to a different group are not overwritten)
- SerialID in Customer.Customer identifies which affiliate referred the customer

**Diagram**:
```
SpreadGroupID changes: old=5 -> new=7
    BackOffice.Affiliate WHERE AffiliateID=X: SpreadGroupID=7
    Customer.Customer WHERE SerialID=X AND SpreadGroupID=5: SpreadGroupID=7
    Customer.Customer WHERE SerialID=X AND SpreadGroupID<>5: unchanged
```

### 2.3 Dynamics CRM Notification via Service Broker

**What**: After every upsert, the affiliate's new status is sent to Dynamics CRM.

**Columns/Parameters Involved**: `@AffiliateID`, `@AffiliateStatusID`

**Rules**:
- XML format: `<AffiliateRank><AffiliateID>{id}</AffiliateID><AffiliateStatusID>{status}</AffiliateStatusID></AffiliateRank>`
- Sent to `svcDynamics` via Service Broker SEND ON CONVERSATION
- Fires on BOTH INSERT and UPDATE paths - always sends current status
- Unlike AddToQueueConversationFromDynamics (which is deactivated), this Service Broker send IS active

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | NO | - | VERIFIED | Affiliate's ID - same as the affiliate's own customer SerialID/CID. Used as PK for BackOffice.Affiliate and to match Customer.Customer.SerialID for cascade updates. |
| 2 | @AffiliateStatusID | INT | NO | - | VERIFIED | Affiliate tier/reputation status. Known values from data: 1=Normal (93.2% of affiliates). Written to BackOffice.Affiliate and included in Dynamics CRM notification XML. |
| 3 | @SpreadGroupID | INT | NO | - | VERIFIED | Trading spread group to assign to the affiliate. Default=0 (standard/no custom spread). When changed, cascades to all referred customers who have the old SpreadGroupID via Customer.Customer.SerialID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | BackOffice.Affiliate | WRITER (UPSERT) | Creates or updates the affiliate record |
| @AffiliateID, @SpreadGroupID | Customer.Customer | MODIFIER (cascade) | Updates SpreadGroupID for referred customers on SpreadGroupID change; targets SerialID=@AffiliateID |
| @AffiliateID, @AffiliateStatusID | svcDynamics (Service Broker) | Notification | Sends AffiliateRank XML to Dynamics CRM after each upsert |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in BackOffice schema. Called from BackOffice application layer when managing affiliate partner records.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AffiliateEdit (procedure)
|- BackOffice.Affiliate (table) [EXISTS check + UPSERT]
|- Customer.Customer (table) [cascade UPDATE SpreadGroupID for referred customers]
+-- svcDynamics (Service Broker service) [Dynamics CRM notification]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Affiliate | Table | EXISTS check; INSERT on new affiliate; UPDATE on existing |
| Customer.Customer | Table | UPDATE SpreadGroupID WHERE SerialID=@AffiliateID AND SpreadGroupID=old value |
| svcDynamics | Service Broker | SEND target for AffiliateRank XML notification to Dynamics CRM |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called to create or update affiliate partner settings |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction on DML | Explicit | Both INSERT and UPDATE branches use BEGIN TRAN / COMMIT with @@ERROR check; ROLLBACK + RAISERROR(60000) on failure |
| Selective cascade | Design | Customer SpreadGroupID cascade only applies to customers still having the OLD SpreadGroupID - prevents overwriting manually-customized customer spread groups |

---

## 8. Sample Queries

### 8.1 Update affiliate status to a new tier

```sql
EXEC BackOffice.AffiliateEdit
    @AffiliateID = 123456,
    @AffiliateStatusID = 2,  -- updated tier
    @SpreadGroupID = 0       -- default spread group (no change)
```

### 8.2 Change affiliate spread group (cascades to referred customers)

```sql
EXEC BackOffice.AffiliateEdit
    @AffiliateID = 123456,
    @AffiliateStatusID = 1,   -- Normal
    @SpreadGroupID = 7        -- new spread group (will cascade to referred customers)
```

### 8.3 Check affiliate and their referred customers' spread groups

```sql
SELECT
    a.AffiliateID,
    a.AffiliateStatusID,
    a.SpreadGroupID AS AffiliateSpreadGroup,
    COUNT(c.CID) AS ReferredCustomers,
    COUNT(CASE WHEN c.SpreadGroupID = a.SpreadGroupID THEN 1 END) AS CustomersOnAffiliateSpread
FROM BackOffice.Affiliate a WITH (NOLOCK)
LEFT JOIN Customer.Customer c WITH (NOLOCK)
    ON c.SerialID = a.AffiliateID
WHERE a.AffiliateID = 123456
GROUP BY a.AffiliateID, a.AffiliateStatusID, a.SpreadGroupID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AffiliateEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AffiliateEdit.sql*
