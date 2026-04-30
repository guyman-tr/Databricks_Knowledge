# Trade.GetGcidByCidAndParentGcidByParentUserName

> Resolves both a customer's GCID and their parent (copy-leader) GCID in a single call, using CID and parent UserName as inputs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | GCID, ParentGCID (two-column result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves two Global Customer IDs (GCIDs) simultaneously: the GCID of a given customer (identified by CID) and the GCID of that customer's parent/copy-leader (identified by UserName). GCID is the cross-system global identifier used for external integrations, notifications, and identity federation - as opposed to CID which is an internal numeric identifier.

The procedure exists to support the Copy Notifications Push (CNP) service, which needs both the copier's and the leader's global identifiers when sending copy-trade-related notifications. Without this SP, two separate database calls would be required - one to resolve the copier's GCID and another to look up the parent by username and get their GCID.

Data flow: the CNP service calls this procedure with a customer's CID and the parent's UserName. The SP performs a self-join on Customer.CustomerStatic - one alias filters by CID, the other by UserName - and returns both GCIDs in a single row. The application treats a successful call as one where both GCIDs are positive integers.

---

## 2. Business Logic

### 2.1 Dual GCID Resolution via Self-Join

**What**: Resolves two different customers' GCIDs from a single table access using different lookup keys.

**Columns/Parameters Involved**: `@CID`, `@ParentUserName`, `GCID`, `ParentGCID`

**Rules**:
- The copier is identified by `@CID` (numeric internal ID) while the parent/leader is identified by `@ParentUserName` (unique username string)
- Both rows come from the same Customer.CustomerStatic table via a self-join (no ON relationship between the two aliases - this is effectively a cross join filtered by WHERE and ON conditions)
- The join condition `cc1.UserName = @ParentUserName` uses the unique index `Unique_CustomerStatic_UserName_LOWER` on CustomerStatic
- The application considers the call successful only when both `GCID > 0` and `ParentGCID > 0`

**Diagram**:
```
Customer.CustomerStatic (cc)     Customer.CustomerStatic (cc1)
  WHERE CID = @CID                 ON UserName = @ParentUserName
  --> returns cc.GCID               --> returns cc1.GCID as ParentGCID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID - internal numeric identifier for the copier customer. Primary key of Customer.CustomerStatic. The CNP service passes this from its notification context to identify which customer's GCID to resolve. |
| 2 | @ParentUserName | NVARCHAR(20) | NO | - | VERIFIED | Username of the parent/copy-leader. Matched against Customer.CustomerStatic.UserName (indexed via Unique_CustomerStatic_UserName_LOWER). Used to find the leader's row and extract their GCID. |
| 3 | GCID (output) | INT | - | - | VERIFIED | Global Customer ID of the copier (the customer identified by @CID). Cross-system identifier used for external integrations and notification routing. Sourced from Customer.CustomerStatic.GCID. Application validates GCID > 0 for success. |
| 4 | ParentGCID (output) | INT | - | - | VERIFIED | Global Customer ID of the parent/copy-leader (the user identified by @ParentUserName). Used by the CNP service to route copy-trade notifications to the leader. Sourced from Customer.CustomerStatic.GCID via the self-join alias cc1. Application validates ParentGCID > 0 for success. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | FROM (WHERE) | Filters to the copier's row by CID to extract GCID |
| @ParentUserName | Customer.CustomerStatic | JOIN (ON) | Self-join to the parent's row by UserName to extract ParentGCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CNPNotificationsUserProd | GRANT EXECUTE | Permission | CNP Notifications production service account has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetGcidByCidAndParentGcidByParentUserName (procedure)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Self-joined: filtered by CID (WHERE) and by UserName (JOIN ON) to resolve two GCIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetGCIDByCID | Stored Procedure | Simpler variant - resolves only the customer's own GCID (no parent). Both serve the CNP notification service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Relevant indexes on Customer.CustomerStatic used by this SP**:
- **PK (CID)**: Clustered index - used for `WHERE cc.CID = @CID`
- **Unique_CustomerStatic_UserName_LOWER**: Unique nonclustered on `UserName_LOWER` (computed `LOWER(UserName)`) with INCLUDE(GCID) - supports the join `cc1.UserName = @ParentUserName`
- **IDX_Customer_Customer_GCID**: Nonclustered on GCID - covers the output column

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve copier and leader GCIDs

```sql
EXEC Trade.GetGcidByCidAndParentGcidByParentUserName
    @CID = 12345,
    @ParentUserName = N'LeaderUser01';
```

### 8.2 Equivalent direct query with NOLOCK

```sql
SELECT  cc.GCID     AS GCID,
        cc1.GCID    AS ParentGCID
FROM    Customer.CustomerStatic cc WITH (NOLOCK)
JOIN    Customer.CustomerStatic cc1 WITH (NOLOCK)
        ON cc1.UserName = N'LeaderUser01'
WHERE   cc.CID = 12345;
```

### 8.3 Verify both GCIDs are positive (application validation logic)

```sql
DECLARE @GCID INT, @ParentGCID INT;

SELECT  @GCID = cc.GCID,
        @ParentGCID = cc1.GCID
FROM    Customer.CustomerStatic cc WITH (NOLOCK)
JOIN    Customer.CustomerStatic cc1 WITH (NOLOCK)
        ON cc1.UserName = N'LeaderUser01'
WHERE   cc.CID = 12345;

SELECT  CASE WHEN @GCID > 0 AND @ParentGCID > 0
            THEN 'Both resolved'
            ELSE 'Resolution failed'
        END AS Status;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CNP - Notifications Service Production](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/11783667965) | Confluence | Confirms this SP is part of the CNP notification service's permission set alongside related GCID lookup procedures |

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 10.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 1 repos / 3 files | Corrections: 0 applied*
*Object: Trade.GetGcidByCidAndParentGcidByParentUserName | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetGcidByCidAndParentGcidByParentUserName.sql*
