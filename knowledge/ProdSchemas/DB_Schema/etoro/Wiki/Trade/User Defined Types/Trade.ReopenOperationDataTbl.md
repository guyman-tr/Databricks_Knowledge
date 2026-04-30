# Trade.ReopenOperationDataTbl

> A table-valued parameter type for pairing PositionID with CID when submitting reopen operation data, used in reopen-trade workflows that restore closed positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID, CID |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.ReopenOperationDataTbl is a table-valued parameter (TVP) type that pairs PositionID with CID. Reopen operations allow back-office or automated workflows to reopen positions that were previously closed - for example, after a mistaken close or a system correction. The TVP carries the minimal data needed to identify which positions belong to which customers for reopen processing.

This type exists to support the reopen workflow, which uses Trade.ReopenOperation, Trade.PositionToReopen, and procedures like Trade.PositionsReopen. The type is granted to CashoutTool and ApprovalUserEtoro, indicating it is used by approval and cashout-related applications that may pass reopen data to procedures.

No procedures in the Trade Stored Procedures folder were found that accept this type as a parameter. Usage may be in application code or in procedures outside the Trade schema; the GRANTs confirm it is in active use.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type pairs two identifiers for reopen scope.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Closed position ID - identifies the position to be reopened. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID - the account that owned the position; used for validation and billing context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID and CID semantically reference History.Position and Customer; no declared FKs.

### 5.2 Referenced By (other objects point to this)

No stored procedures in Trade/Stored Procedures were found that accept this type. GRANT EXECUTE on the type exists for CashoutTool and ApprovalUserEtoro, indicating application or cross-schema usage.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Application / cross-schema) | - | Type is granted to CashoutTool, ApprovalUserEtoro; exact procedure(s) not found in Trade schema |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for reopen workflow

```sql
DECLARE @ReopenData Trade.ReopenOperationDataTbl;
INSERT INTO @ReopenData (PositionID, CID) VALUES (900000001, 12345), (900000002, 12345);
```

### 8.2 Build from closed positions for a customer

```sql
DECLARE @Data Trade.ReopenOperationDataTbl;
INSERT INTO @Data (PositionID, CID)
SELECT  PositionID, CID
FROM    History.Position WITH (NOLOCK)
WHERE   CID = @CID AND CloseOccurred > '2026-01-01';
```

### 8.3 Single position reopen

```sql
DECLARE @Row Trade.ReopenOperationDataTbl;
INSERT INTO @Row (PositionID, CID) VALUES (@PositionID, @CID);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperationDataTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.ReopenOperationDataTbl.sql*
