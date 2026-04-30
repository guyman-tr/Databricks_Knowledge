# Trade.CIDsAndPositionIDs

> A table-valued parameter type that pairs Customer IDs with specific Position IDs. Used to verify manual position operations by linking customers to their positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID + PositionID (composite pair) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CIDsAndPositionIDs is a table-valued parameter (TVP) type that links Customer IDs (CIDs) to Position IDs in a single batch. Each row represents one customer-position pair: a customer and one of their positions. This pairing is used when verifying or operating on manual positions - positions that were opened or adjusted outside the normal order flow.

The consuming procedure Trade.CheckListOfManuallPositions uses this type to validate that the provided CID-PositionID pairs are valid and authorized. Without this type, callers would need to pass separate arrays and rely on positional alignment, which is error-prone.

Application workflows that need to verify or process a set of manual positions collect the (CID, PositionID) pairs, populate the TVP, and pass it to the procedure for validation or further action.

---

## 2. Business Logic

### 2.1 CID-PositionID Pairing

**What**: Each row asserts that a specific position belongs to a specific customer.

**Columns/Parameters Involved**: `CID`, `PositionID`

**Rules**:
- Both CID and PositionID are required (NOT NULL).
- Each row represents one pair; the same PositionID may appear with different CIDs only if data allows (the procedure enforces business rules).
- Used for verification of manual position lists - the procedure checks that each pair is valid.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - the account that owns or is associated with the position. References Customer.CustomerTbl. Used to validate that the position belongs to this customer. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Position ID - the specific position. References Trade.PositionTbl. Must belong to the CID on the same row per business rules enforced in the procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared outgoing references. CID semantically references Customer.CustomerTbl; PositionID references Trade.PositionTbl.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckListOfManuallPositions | Parameter (TVP) | TVP | Receives the list of CID-PositionID pairs for manual position verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckListOfManuallPositions | Stored Procedure | READONLY TVP parameter for manual position list verification |

---

## 7. Technical Details

### 7.1 Indexes

None. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Pass CID-PositionID pairs for verification

```sql
DECLARE @Pairs Trade.CIDsAndPositionIDs;
INSERT INTO @Pairs (CID, PositionID) VALUES (10001, 500001), (10001, 500002), (10002, 500003);
EXEC Trade.CheckListOfManuallPositions @Pairs = @Pairs;
```

### 8.2 Build pairs from position table for a date range

```sql
DECLARE @Pairs Trade.CIDsAndPositionIDs;
INSERT INTO @Pairs (CID, PositionID)
SELECT CID, PositionID
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  OpenDateTime > '2025-01-01' AND IsManual = 1;
EXEC Trade.CheckListOfManuallPositions @Pairs = @Pairs;
```

### 8.3 Verify a single customer's manual positions

```sql
DECLARE @Pairs Trade.CIDsAndPositionIDs;
INSERT INTO @Pairs (CID, PositionID)
SELECT @CID, PositionID
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  CID = @CID AND IsManual = 1;
EXEC Trade.CheckListOfManuallPositions @Pairs = @Pairs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CIDsAndPositionIDs | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CIDsAndPositionIDs.sql*
