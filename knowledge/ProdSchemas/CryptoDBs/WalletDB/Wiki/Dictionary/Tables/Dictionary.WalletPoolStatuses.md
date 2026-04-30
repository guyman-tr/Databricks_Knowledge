# Dictionary.WalletPoolStatuses

> Lookup table defining the lifecycle statuses for pre-generated wallet addresses in the wallet pool, tracking progress from creation through funding to readiness for customer assignment.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique (Name) |

---

## 1. Business Meaning

This table defines the statuses for wallet addresses in the pre-generated pool. The platform pre-creates blockchain addresses so customers can instantly receive a wallet without waiting for blockchain key generation. Each pool address passes through verification, funding, and readiness stages before it can be assigned to a customer.

One of the most heavily referenced Dictionary tables (18+ consumers). FK-referenced by `Wallet.WalletPoolStatuses` and consumed by numerous pool management stored procedures.

---

## 2. Business Logic

### 2.1 Wallet Pool Lifecycle

**What**: Nine-state lifecycle for pool address management. Non-sequential IDs (gap at 8-9).

**Rules**:
- `Pending` (1): Address created, awaiting blockchain verification
- `Verified` (2): Address confirmed on blockchain, ready for funding
- `Failed` (3): Address creation or verification failed
- `FundingInitiated` (4): Funding transaction started (sending initial balance)
- `FundingSent` (5): Funding transaction broadcast to blockchain
- `FundingVerified` (6): Funding confirmed on chain - address has balance
- `FundingFailed` (7): Funding transaction failed
- `Timeout` (10): Address creation or funding timed out
- `VerifiedForAssign` (11): Address fully verified and ready for customer assignment

**Diagram**:
```
Pending(1) --> Verified(2) --> FundingInitiated(4) --> FundingSent(5)
    |              |                                      |
    v              v                              FundingVerified(6)
  Failed(3)    Timeout(10)                              |
                                                VerifiedForAssign(11)
                                                [Ready for customer]
                FundingFailed(7) <-- [failure at any funding step]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Pending | Pool address generated but not yet confirmed on the blockchain. Awaiting on-chain registration verification. |
| 2 | Verified | Address exists on the blockchain but has not been funded. Ready for the funding step. |
| 6 | FundingVerified | Address has been funded and the funding transaction is confirmed. Address has an initial balance. |
| 11 | VerifiedForAssign | Address is fully ready - verified on-chain, funded (if required), and eligible for assignment to a customer. Terminal ready state. |
| 10 | Timeout | Address creation or funding exceeded the expected time window. Requires investigation - may be retried or abandoned. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated, 5=FundingSent, 6=FundingVerified, 7=FundingFailed, 10=Timeout, 11=VerifiedForAssign. Gap at 8-9. FK target for Wallet.WalletPoolStatuses. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Status label. Unique constraint ensures no duplicates. Used in pool management dashboards and monitoring alerts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.WalletPoolStatuses | WalletPoolStatusId | FK | Records pool address status transitions |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPoolStatuses | Table | FK |
| Wallet.GetFreeWalletFromPool | Stored Procedure | Finds VerifiedForAssign addresses |
| Wallet.GetFreeWallets | Stored Procedure | Finds available pool wallets |
| Wallet.GetPendingWallets | Stored Procedure | Finds Pending addresses |
| Wallet.GetPendingWalletsInPool | Stored Procedure | Finds pending pool addresses |
| Wallet.GetFundingPendingWallets | Stored Procedure | Finds funding-stage addresses |
| Wallet.AssociateWalletToCustomer | Stored Procedure | Assigns pool wallet to customer |
| Wallet.AddWalletsStatus | Stored Procedure | Updates pool wallet status |
| Wallet.UpdateFundingSentStatus | Stored Procedure | Updates funding status |
| Wallet.SyncFundedWalletStatusesAsync | Stored Procedure | Syncs funded statuses |
| Wallet.RollbackFundingPendingWallets | Stored Procedure | Rolls back stuck funding |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletPoolStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_Dictionary_WalletPoolStatuses__Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond PK and unique Name.

---

## 8. Sample Queries

### 8.1 List all pool statuses
```sql
SELECT Id, Name FROM Dictionary.WalletPoolStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Pool inventory by status
```sql
SELECT wps_dict.Name, COUNT(wps.Id) AS Count
FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
JOIN Dictionary.WalletPoolStatuses wps_dict WITH (NOLOCK) ON wps.WalletPoolStatusId = wps_dict.Id
GROUP BY wps_dict.Name ORDER BY Count DESC
```

### 8.3 Available pool wallets ready for assignment
```sql
SELECT wp.WalletPoolId, wps_dict.Name AS Status
FROM Wallet.WalletPool wp WITH (NOLOCK)
JOIN Wallet.WalletPoolStatuses wps WITH (NOLOCK) ON wps.WalletPoolId = wp.WalletPoolId
JOIN Dictionary.WalletPoolStatuses wps_dict WITH (NOLOCK) ON wps.WalletPoolStatusId = wps_dict.Id
WHERE wps_dict.Id = 11 -- VerifiedForAssign
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 11 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WalletPoolStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.WalletPoolStatuses.sql*
