# Trade.Gain_CheckWithdrawalStatus

> Retrieves credit records associated with a list of withdrawal IDs to check their processing status for the Gain calculation system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @withdrawalIds (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is used by the Gain (P&L calculation) service to check the status of specific withdrawals by looking up their associated credit records. When calculating customer gains, the system needs to know whether withdrawals have been fully processed (approved, reversed, etc.) because pending withdrawals affect how realized equity is calculated.

The procedure accepts a list of withdrawal IDs via a Table-Valued Parameter, copies them to a temp table with an index for efficient joining, and returns the matching credit records with their CreditTypeID (which indicates the withdrawal's current stage: request, approval, reversal, etc.).

---

## 2. Business Logic

### 2.1 Withdrawal Status Resolution via Credit History

**What**: Maps withdrawal IDs to their credit transaction records.

**Columns/Parameters Involved**: `WithdrawID`, `CreditID`, `CreditTypeID`

**Rules**:
- Each withdrawal generates multiple History.Credit records at different stages (request=9, approval=2, reversal=8, etc.)
- Returns ALL credit records matching the requested WithdrawIDs, not just the latest
- The calling Gain service uses the CreditTypeIDs to determine the net effect of each withdrawal

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @withdrawalIds | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing withdrawal IDs to check. READONLY. Contains a single column `Id` (int). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | History.Credit | READER | Reads credit records matching the specified WithdrawIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Checks withdrawal status during gain processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_CheckWithdrawalStatus (procedure)
+-- History.Credit (table)
+-- Trade.IdIntList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | JOIN on WithdrawID - returns credit records |
| Trade.IdIntList | User Defined Type | TVP type for @withdrawalIds parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: NC INDEX IX_ID on #Tbl(Id).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check Withdrawal Status

```sql
DECLARE @ids Trade.IdIntList
INSERT INTO @ids VALUES (1001), (1002), (1003)
EXEC Trade.Gain_CheckWithdrawalStatus @withdrawalIds = @ids
```

### 8.2 View Credit Types for Withdrawals

```sql
SELECT WithdrawID, CreditTypeID, COUNT(*) AS RecordCount
  FROM History.Credit WITH (NOLOCK)
 WHERE WithdrawID IN (1001, 1002, 1003)
 GROUP BY WithdrawID, CreditTypeID
```

### 8.3 Find Withdrawals with Only Request But No Approval

```sql
SELECT a.WithdrawID
  FROM History.Credit a WITH (NOLOCK)
 WHERE a.CreditTypeID = 9
   AND NOT EXISTS (SELECT 1 FROM History.Credit b WITH (NOLOCK) WHERE b.WithdrawID = a.WithdrawID AND b.CreditTypeID = 2)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_CheckWithdrawalStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_CheckWithdrawalStatus.sql*
