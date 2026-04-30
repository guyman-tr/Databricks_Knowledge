# AffiliateCommission.CheckDepositExists

> Checks whether a specific deposit transaction already exists in the credit account mapping, used to prevent duplicate deposit credit processing with account-type-aware matching.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 (exists) or 0 (not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CheckDepositExists is a deduplication guard for deposit credit processing. Before the credit commission system creates a new Credit record for a deposit, it calls this procedure to verify the deposit has not already been processed. This prevents duplicate commission payouts when the same deposit event arrives multiple times.

This procedure exists because deposit events can be replayed from payment systems. The CreditAccountMapping table serves as the deduplication registry, and this procedure queries it to determine if a TransactionID (the deposit's external ID) has already been recorded for the matching account.

The procedure handles two account types differently: for options accounts (AccountTypeID = 2), it matches on GCID (Global Customer ID); for all other account types, it matches on CID (Customer ID). This dual-path matching reflects the fact that options accounts use a different identifier system than standard trading accounts.

---

## 2. Business Logic

### 2.1 Account-Type-Aware Deposit Matching

**What**: Deposit existence check uses different account identifiers depending on the account type.

**Columns/Parameters Involved**: `@CID`, `@GCID`, `@DepositID`, `AccountTypeID`

**Rules**:
- TransactionID is matched against @DepositID (cast to varchar, since TransactionID is stored as varchar in CreditAccountMapping)
- For AccountTypeID = 2 (Options): AccountID is matched against @GCID (cast to varchar)
- For AccountTypeID <> 2 (all others): AccountID is matched against @CID (cast to varchar)
- Both conditions are combined with OR in a single query, with AccountTypeID gating which path applies
- Returns IIF(COUNT(1) > 0, 1, 0) - binary exists check

**Diagram**:
```
Deposit Event (@CID, @GCID, @DepositID)
  |
  v
CreditAccountMapping lookup
  |
  +-- AccountTypeID = 2 (Options)
  |   Match: TransactionID = @DepositID AND AccountID = @GCID
  |
  +-- AccountTypeID <> 2 (Standard)
  |   Match: TransactionID = @DepositID AND AccountID = @CID
  |
  v
Returns 1 (found - skip) or 0 (not found - proceed)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID for standard (non-options) accounts. Used as the AccountID match when AccountTypeID <> 2. |
| 2 | @GCID | bigint (IN) | NO | - | CODE-BACKED | Global Customer ID for options accounts (AccountTypeID = 2). Used as the AccountID match for options deposits. |
| 3 | @DepositID | bigint (IN) | NO | - | CODE-BACKED | External deposit transaction identifier from the payment system. Cast to varchar and matched against CreditAccountMapping.TransactionID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | AffiliateCommission.CreditAccountMapping | READ (SELECT) | Checks TransactionID for deposit existence; also matches on AccountTypeID and AccountID |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. Called by the credit processing pipeline before InsertCredit.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CheckDepositExists (procedure)
+-- AffiliateCommission.CreditAccountMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditAccountMapping | Table | Queried for deposit existence by TransactionID and AccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit processing pipeline) | External | Calls before creating deposit credits to prevent duplicates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if deposit 999888 exists for customer 12345
```sql
EXEC [AffiliateCommission].[CheckDepositExists]
    @CID = 12345,
    @GCID = 67890,
    @DepositID = 999888
```

### 8.2 Find all deposits for a customer in CreditAccountMapping
```sql
SELECT TransactionID, AccountTypeID, AccountID, CreditInternalID, DateCreated
FROM [AffiliateCommission].[CreditAccountMapping] WITH (NOLOCK)
WHERE AccountID = CAST(12345 AS varchar)
ORDER BY DateCreated DESC
```

### 8.3 Count deposits by account type
```sql
SELECT AccountTypeID,
       IIF(AccountTypeID = 2, 'Options', 'Standard') AS AccountTypeName,
       COUNT(*) AS DepositCount
FROM [AffiliateCommission].[CreditAccountMapping] WITH (NOLOCK)
GROUP BY AccountTypeID
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found for this object. Jira MCP unavailable (410).

DDL comments reference:
- PART-4180: Check if deposit exists (2025-03-06)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CheckDepositExists | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.CheckDepositExists.sql*
