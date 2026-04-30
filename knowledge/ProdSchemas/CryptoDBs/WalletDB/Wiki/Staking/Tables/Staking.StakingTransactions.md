# Staking.StakingTransactions

> Records the blockchain transfer details for each staking operation, including the destination staking pool address and associated fees.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Staking.StakingTransactions captures the blockchain-level transfer details for each staking operation. Each row links a staking record (from Staking.Staking) to the external blockchain address where the assets were sent and records the fees involved. This is the on-chain execution record complementing the business-level staking record.

Without this table, the system would have no record of where staked assets were actually sent on the blockchain or what fees were charged. It provides the audit trail connecting business staking operations to their blockchain counterparts.

Rows are created by `Staking.InsertStakingTransaction`, which looks up the staking record by CorrelationId and resolves the user's wallet via Wallet.CustomerWalletsView. There is a 1:1 relationship with Staking.Staking (2,181 rows each). The table is consumed by the Staking.StakingData view, which joins on StakingId to include EtoroFee and BlockchainEstFee in the reporting dataset.

---

## 2. Business Logic

### 2.1 Fee Structure

**What**: Each staking transaction tracks two fee components - eToro's fee and the estimated blockchain network fee.

**Columns/Parameters Involved**: `EtoroFee`, `BlockchainEstFee`

**Rules**:
- EtoroFee: eToro's service fee for processing the staking delegation (currently 0 across all records)
- BlockchainEstFee: estimated blockchain gas/network fee for the staking transaction (currently 0 across all records)
- Both fees being 0 indicates staking transfers are currently fee-free for users, consistent with eToro absorbing the costs

### 2.2 Staking Pool Address Tracking

**What**: Each transaction records the exact on-chain destination address for the staked assets.

**Columns/Parameters Involved**: `ExternalStakingAddress`, `StakingId`

**Rules**:
- The address matches the active entry in Staking.StakingExternalAddress for the crypto being staked
- Currently all 2,181 records use `0xCB2A66540680c344bab5f818d68c3e4B9D57363B` (eToro's ETH staking pool)
- The address is stored per-transaction (denormalized from StakingExternalAddress) to preserve the historical record if the pool address changes

---

## 3. Data Overview

| Id | StakingId | ExternalStakingAddress | EtoroFee | BlockchainEstFee | Meaning |
|----|-----------|----------------------|----------|-----------------|---------|
| 2181 | 2181 | 0xCB2A665...363B | 0 | 0 | Most recent staking transfer to the ETH pool - no fees charged to the user |
| 2178 | 2178 | 0xCB2A665...363B | 0 | 0 | Same pool address, same zero-fee pattern - typical of all staking transactions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate key. |
| 2 | ExternalStakingAddress | varchar(64) | NO | - | VERIFIED | The blockchain address of the staking pool where assets were sent. For ETH, an Ethereum address (0x-prefixed). Denormalized from Staking.StakingExternalAddress to preserve historical address even if the active pool changes. Passed as a parameter to InsertStakingTransaction. |
| 3 | StakingId | bigint | NO | - | VERIFIED | The staking operation this transaction belongs to. FK to Staking.Staking.Id. 1:1 relationship - each staking operation has exactly one transaction record. Used by Staking.StakingData view to join fees into the reporting dataset. |
| 4 | EtoroFee | decimal(36,18) | NO | - | VERIFIED | eToro's service fee for processing the staking delegation, in the staked crypto's units. Currently 0 across all records - staking transfers are fee-free for users. |
| 5 | BlockchainEstFee | decimal(36,18) | NO | - | VERIFIED | Estimated blockchain network fee (gas fee) for the staking transaction, in the staked crypto's units. Currently 0 across all records - blockchain fees absorbed by eToro. |
| 6 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this transaction record was created. Closely follows the Staking.Staking.Occurred timestamp (typically within 1 second). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StakingId | Staking.Staking | FK | Links this transaction to its parent staking operation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Staking.StakingData | StakingId | JOIN | View joins to include EtoroFee and BlockchainEstFee in reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.StakingTransactions (table)
  (no code-level dependencies - leaf node)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | FK target for StakingId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingData | View | JOIN on StakingId for fee columns in reporting |
| Staking.InsertStakingTransaction | Stored Procedure | WRITER - creates transaction records for staking operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StakingTransactions | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StakingTransactions | PRIMARY KEY | Clustered on Id, PAGE compression |
| DF_Staking_StakingTransactions__Occurred | DEFAULT | getutcdate() for Occurred |
| FK_Staking_StakingTransactions_Staking_Staking_StakingId | FOREIGN KEY | StakingId -> Staking.Staking.Id |

---

## 8. Sample Queries

### 8.1 Get transaction details for a staking operation
```sql
SELECT st.ExternalStakingAddress, st.EtoroFee, st.BlockchainEstFee, st.Occurred
FROM Staking.StakingTransactions st WITH (NOLOCK)
WHERE st.StakingId = @StakingId
```

### 8.2 Staking operations with fees and amounts
```sql
SELECT s.Id, s.Amount, s.CryptoId, st.ExternalStakingAddress, st.EtoroFee, st.BlockchainEstFee
FROM Staking.Staking s WITH (NOLOCK)
INNER JOIN Staking.StakingTransactions st WITH (NOLOCK) ON st.StakingId = s.Id
ORDER BY s.Id DESC
```

### 8.3 Check for staking operations missing transaction records
```sql
SELECT s.Id, s.CorrelationId, s.Amount
FROM Staking.Staking s WITH (NOLOCK)
LEFT JOIN Staking.StakingTransactions st WITH (NOLOCK) ON st.StakingId = s.Id
WHERE st.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | eToro manages staking transfers to pools on behalf of users; staking pool addresses are managed centrally |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.StakingTransactions | Type: Table | Source: WalletDB/Staking/Tables/Staking.StakingTransactions.sql*
