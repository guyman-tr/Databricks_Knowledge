# Trade.BlockOperations

> A table-valued parameter type for passing pairs of operation type and block reason when applying trading restrictions to customers. Each row represents one operation type being blocked with its reason. Part of the compliance/risk management restriction system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OperationTypeID + BlockReasonID (composite) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.BlockOperations is a table-valued parameter type for bulk-setting customer trading restrictions. Each row pairs an operation type (e.g., open, close, edit) with a block reason (e.g., compliance, risk, manual). Trade.CustomerRestrictionsSet consumes this TVP to apply the specified operation-type + reason combinations to customers.

This type exists to support batch restriction updates. Without it, each operation-type + reason pair would need a separate call. Operations staff and automated jobs use it to apply multiple restrictions in one transaction - critical for compliance workflows and risk management.

Data flow: Restriction management UI or jobs build the TVP with the desired operation-reason pairs, optionally a CID list, and call CustomerRestrictionsSet. The procedure applies each pair to the target customers, recording the block reason for audit and display.

---

## 2. Business Logic

### 2.1 Operation Type and Block Reason Pairing

**What**: Each row defines one operation type to block, with the reason for the block.

**Columns/Parameters Involved**: `OperationTypeID`, `BlockReasonID`

**Rules**:
- OperationTypeID identifies which trading action is blocked (open, close, edit, etc.)
- BlockReasonID identifies why it is blocked (compliance, risk, manual override, etc.)
- The pair (OperationTypeID, BlockReasonID) is applied to target customers by CustomerRestrictionsSet
- Multiple rows allow blocking different operations for different reasons in one call

**Diagram**:
```
Row 1: Open + Compliance -> Block open for compliance
Row 2: Close + Risk -> Block close for risk
Row 3: Edit + Manual -> Block edit for manual override
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationTypeID | int | NO | - | CODE-BACKED | Operation type ID. Identifies which trading action to block (e.g., open position, close position, edit order). References operation type dictionary. |
| 2 | BlockReasonID | int | NO | - | CODE-BACKED | Block reason ID. Identifies why the operation is blocked (e.g., compliance, risk, manual). References block reason dictionary. Stored for audit and displayed to users. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OperationTypeID | Dictionary.OperationType (or similar) | Lookup | Operation type classification |
| BlockReasonID | Dictionary.BlockReason (or similar) | Lookup | Block reason classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CustomerRestrictionsSet | @BlockOperations (or similar) | Parameter (TVP) | Applies operation-reason pairs to customer restrictions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CustomerRestrictionsSet | Stored Procedure | READONLY parameter for bulk restriction application |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Block open and close for compliance

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @BlockOps Trade.BlockOperations;
INSERT INTO @CIDs (CID) VALUES (12345), (67890);
INSERT INTO @BlockOps (OperationTypeID, BlockReasonID) VALUES (1, 1), (2, 1);  -- Open+Compliance, Close+Compliance

EXEC Trade.CustomerRestrictionsSet @CIDs = @CIDs, @BlockOperations = @BlockOps;
```

### 8.2 Block multiple operations with different reasons

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @BlockOps Trade.BlockOperations;
INSERT INTO @CIDs (CID) VALUES (11111);
INSERT INTO @BlockOps (OperationTypeID, BlockReasonID)
VALUES (1, 2), (2, 2), (3, 1);  -- Open+Risk, Close+Risk, Edit+Compliance

EXEC Trade.CustomerRestrictionsSet @CIDs = @CIDs, @BlockOperations = @BlockOps;
```

### 8.3 Single operation block for manual override

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @BlockOps Trade.BlockOperations;
INSERT INTO @CIDs (CID) VALUES (99999);
INSERT INTO @BlockOps (OperationTypeID, BlockReasonID) VALUES (1, 3);  -- Open+Manual

EXEC Trade.CustomerRestrictionsSet @CIDs = @CIDs, @BlockOperations = @BlockOps;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BlockOperations | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.BlockOperations.sql*
