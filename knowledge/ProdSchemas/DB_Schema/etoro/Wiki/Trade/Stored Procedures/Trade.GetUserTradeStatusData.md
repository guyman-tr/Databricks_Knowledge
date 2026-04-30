# Trade.GetUserTradeStatusData

> Output-parameter stored procedure - sets @PlayerStatusID, @IsCopyBlocked, @Gcid, and @IsFund via OUTPUT parameters rather than a result set, for use by callers that need scalar values without result-set handling overhead.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserTradeStatusData` is a minimal, output-parameter-based customer status loader. Unlike most procedures in this batch which return result sets, this one uses OUTPUT parameters to return four scalar values: the customer's player status, copy block flag, GCID, and fund account flag.

This design pattern is used when the caller (often a natively compiled procedure or a stored procedure that needs to minimize result-set marshaling) wants individual scalar values directly in SQL variables. The caller assigns `@PlayerStatusID OUTPUT` etc. to local variables without needing to process a SELECT result set.

The procedure is logically equivalent to a minimal subset of `Trade.GetUserInfo` but returns values via OUTPUT parameters rather than rows. It focuses on the four values most commonly needed for immediate trade routing decisions: can this customer trade? are they blocked? are they a fund?

---

## 2. Business Logic

### 2.1 OUTPUT Parameter Pattern

**What**: Returns values via OUTPUT parameters, not result sets.

**Rules**:
- `@PlayerStatusID INT = NULL OUTPUT`: current player account status
- `@IsCopyBlocked BIT = NULL OUTPUT`: `ISNULL(CBO.OperationTypeID, 0)` - non-zero if blocked
- `@Gcid INT = NULL OUTPUT`: Global Customer ID
- `@IsFund BIT = NULL OUTPUT`: `IIF(BC.AccountTypeID = 9, 1, 0)` - AccountTypeID=9 = fund
- All four are assigned in a single SELECT statement

### 2.2 Copy Block Check (OperationTypeID=1)

**What**: Checks for general operation block (OperationTypeID=1).

**Rules**:
- Same as GetUserInfoSlim and GetUserInfoByGCIDs: uses OperationTypeID=1 only
- `@IsCopyBlocked = ISNULL(CBO.OperationTypeID, 0)`
- Note: returns the OperationTypeID (integer) despite the parameter being declared as BIT - the assignment converts the integer to BIT (0=false, non-zero=true)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | 0 | CODE-BACKED | Customer ID to look up. Default 0 (callers should always supply a real CID). |
| 2 | @PlayerStatusID | INT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: Customer's current PlayerStatusID from Customer.CustomerStatic. FK to Dictionary.PlayerStatus. |
| 3 | @IsCopyBlocked | BIT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: ISNULL(CBO.OperationTypeID, 0). Non-zero (TRUE) = copy blocked (OperationTypeID=1 block exists). |
| 4 | @Gcid | INT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: Global Customer ID (GCID) from Customer.CustomerStatic. |
| 5 | @IsFund | BIT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: 1 if AccountTypeID=9 (fund account); 0 otherwise. From BackOffice.Customer. |

No output result set - all output via OUTPUT parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Customer.CustomerStatic | FROM | PlayerStatusID, GCID |
| JOIN | BackOffice.Customer | INNER JOIN | AccountTypeID |
| LEFT JOIN | Customer.BlockedCustomerOperations | LEFT JOIN | OperationTypeID=1 block check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (execution engine callers) | @CID, OUTPUT params | EXEC caller | When scalar output params are preferred over result-set |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserTradeStatusData (procedure)
+-- Customer.CustomerStatic (view/table)
+-- BackOffice.Customer (table)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | View/Table | PlayerStatusID, GCID |
| BackOffice.Customer | Table | AccountTypeID for IsFund |
| Customer.BlockedCustomerOperations | Table | OperationTypeID=1 block check |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OUTPUT parameters | Interface pattern | Returns scalars via OUTPUT rather than result set |
| WITH (NOLOCK) | Isolation | All three reads use dirty read |
| OperationTypeID = 1 | Block type | Only general operation block checked |

---

## 8. Sample Queries

### 8.1 Call with OUTPUT parameters
```sql
DECLARE @playerStatus INT, @isCopyBlocked BIT, @gcid INT, @isFund BIT;

EXEC Trade.GetUserTradeStatusData
    @CID = 123456,
    @PlayerStatusID = @playerStatus OUTPUT,
    @IsCopyBlocked = @isCopyBlocked OUTPUT,
    @Gcid = @gcid OUTPUT,
    @IsFund = @isFund OUTPUT;

SELECT @playerStatus AS PlayerStatus, @isCopyBlocked AS CopyBlocked,
       @gcid AS GCID, @isFund AS IsFund;
```

### 8.2 Equivalent SELECT (for reference)
```sql
SELECT CC.PlayerStatusID,
       ISNULL(CBO.OperationTypeID, 0) AS IsCopyBlocked,
       CC.GCID,
       IIF(BC.AccountTypeID = 9, 1, 0) AS IsFund
FROM Customer.CustomerStatic CC WITH (NOLOCK)
     INNER JOIN BackOffice.Customer BC WITH (NOLOCK) ON CC.CID = BC.CID
     LEFT JOIN Customer.BlockedCustomerOperations CBO WITH (NOLOCK)
         ON CC.CID = CBO.CID AND CBO.OperationTypeID = 1
WHERE CC.CID = 123456
```

### 8.3 N/A - third query not applicable

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Minimal status loader not separately documented.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserTradeStatusData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserTradeStatusData.sql*
