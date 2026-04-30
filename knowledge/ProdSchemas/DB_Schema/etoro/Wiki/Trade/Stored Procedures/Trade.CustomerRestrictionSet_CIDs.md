# Trade.CustomerRestrictionSet_CIDs

> Sets trading operation restrictions (blocks) for a batch of customer CIDs by inserting into Customer.BlockedCustomerOperations, skipping customers already blocked for the same operation and reason.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (TVP with customer IDs to block) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionSet_CIDs blocks a batch of customers from performing specific trading operations. Blocks are stored in Customer.BlockedCustomerOperations and are checked during trade execution to prevent restricted operations (e.g., opening positions, closing positions, withdrawals).

Restrictions are applied during compliance actions (AML/KYC holds), risk management escalations, or automated regulatory processes. Each block records the OperationTypeID (what is blocked), BlockReasonID (why), and a RequestGUID for traceability.

The procedure uses an anti-join (LEFT JOIN WHERE NULL) to skip customers who already have an active block for the same operation type and reason. This makes the procedure idempotent - calling it multiple times with the same parameters has no additional effect.

---

## 2. Business Logic

### 2.1 Idempotent Block Insert

**What**: Only inserts block records for customers not already blocked.

**Columns/Parameters Involved**: `@CID`, `@OperationTypeID`, `@BlockReasonID`

**Rules**:
- LEFT JOIN to Customer.BlockedCustomerOperations on CID + OperationTypeID + BlockReasonID
- WHERE a.CID IS NULL ensures only new blocks are inserted
- A customer already blocked for the same operation+reason is silently skipped
- Occurred = GETUTCDATE() for the new block timestamp

### 2.2 Auto-Generated RequestGUID

**What**: Generates a GUID if none is provided.

**Rules**:
- If @RequestGUID is NULL, a new GUID is generated via NEWID()
- Ensures every block has a traceable request identifier

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | Trade.CidList (TVP, READONLY) | NO | - | CODE-BACKED | List of customer CIDs to apply the trading restriction to. |
| 2 | @OperationTypeID | INT | NO | - | CODE-BACKED | Type of operation to block. Identifies which trading operation to restrict (e.g., open positions, close positions, withdraw). |
| 3 | @BlockReasonID | INT | NO | - | CODE-BACKED | Reason for the block. Recorded for audit and used to match when removing blocks. |
| 4 | @RequestGUID | NVARCHAR(50) | YES | NULL | CODE-BACKED | Correlation GUID for the block request. Auto-generated via NEWID() if NULL. Links to the initiating system/ticket. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | Customer.BlockedCustomerOperations | INSERT | Creates new block records |
| LEFT JOIN | Customer.BlockedCustomerOperations | SELECT | Anti-join to skip already-blocked customers |
| Type | Trade.CidList | Type | UDT for CID list parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CustomerRestrictionCIDs_Wrapper | (batch #20) | EXEC | Wrapper procedure calls this for bulk blocking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionSet_CIDs (procedure)
+-- Customer.BlockedCustomerOperations (table)
+-- Trade.CidList (user-defined table type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | INSERT + LEFT JOIN - creates blocks, checks existing |
| Trade.CidList | UDT | TVP parameter type for CID list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CustomerRestrictionCIDs_Wrapper | Procedure | EXEC - wrapper that orchestrates block/unblock in batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Anti-join idempotency | Safety | LEFT JOIN WHERE NULL prevents duplicate blocks |
| NEWID() fallback | Audit | Auto-generates RequestGUID if not provided |

---

## 8. Sample Queries

### 8.1 View active blocks for a customer

```sql
SELECT  CID, OperationTypeID, BlockReasonID, Occurred, RequestGUID
FROM    Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Block a batch of customers

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) VALUES (12345), (67890);
EXEC Trade.CustomerRestrictionSet_CIDs
    @CID = @CIDs,
    @OperationTypeID = 1,
    @BlockReasonID = 3,
    @RequestGUID = 'COMPLIANCE-REVIEW-2026-001';
```

### 8.3 Check if a specific customer is blocked

```sql
SELECT  COUNT(*) AS IsBlocked
FROM    Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE   CID = 12345 AND OperationTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionSet_CIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionSet_CIDs.sql*
