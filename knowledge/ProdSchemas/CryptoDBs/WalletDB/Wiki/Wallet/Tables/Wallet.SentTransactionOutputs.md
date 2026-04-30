# Wallet.SentTransactionOutputs

> Stores the output details (destination addresses, amounts, fees) for each sent blockchain transaction, supporting multi-output transactions like Bitcoin's UTXO model.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY(0,1), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores the individual outputs of sent blockchain transactions. A single transaction can have multiple outputs (especially on UTXO blockchains like Bitcoin where change is sent back). Each row records one output: the destination address, amount sent, eToro fees, blockchain fees, and optionally the source entity (e.g., a trading position for redemptions).

The `NormalizedToAddress` computed column strips protocol prefixes for consistent address matching. The `IsEtoroFee` flag distinguishes fee outputs from value-transfer outputs (on UTXO chains, the fee may be an explicit output).

Rows are created alongside sent transactions by the execution pipeline.

---

## 2. Business Logic

### 2.1 Multi-Output Transaction Support

**What**: A single sent transaction can have multiple outputs, each going to a different address.

**Columns/Parameters Involved**: `SentTransactionId`, `ToAddress`, `Amount`

**Rules**:
- UTXO blockchains (BTC, LTC, BCH) naturally produce multiple outputs (recipient + change)
- Account-based blockchains (ETH, XRP) typically have one output per transaction
- Each output records its own fee allocation

### 2.2 Source Entity Tracking

**What**: Outputs can be linked back to their business entity (e.g., a trading position).

**Columns/Parameters Involved**: `SourceId`, `SourceIdType`

**Rules**:
- SourceIdType=0 (PositionId): Output originated from a trading position redemption
- SourceId contains the PositionId value for redemption outputs
- See [Transaction Output Source ID Type](../../_glossary.md#transaction-output-source-id-type).
- NULL for non-redemption outputs

---

## 3. Data Overview

N/A for transactional detail table. Each row contains destination address, amount, and fee details for one output of a sent transaction.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(0,1) | CODE-BACKED | Auto-incrementing key starting at 0. |
| 2 | SentTransactionId | bigint | NO | - | VERIFIED | Parent sent transaction. FK to Wallet.SentTransactions.Id. Multiple outputs per transaction possible. |
| 3 | ToAddress | nvarchar(512) | NO | - | CODE-BACKED | Destination blockchain address for this output. |
| 4 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Amount of crypto sent to this output address. |
| 5 | EtoroFees | decimal(36,18) | NO | - | CODE-BACKED | eToro service fee allocated to this output. |
| 6 | BlockchainFees | decimal(36,18) | YES | - | CODE-BACKED | Network fee allocated to this output. NULL when fee is at transaction level. |
| 7 | SourceId | bigint | YES | - | CODE-BACKED | Business entity ID this output originated from. For redemptions, this is the PositionId. |
| 8 | SourceIdType | tinyint | YES | - | CODE-BACKED | Type of SourceId: 0=PositionId. See [Transaction Output Source ID Type](../../_glossary.md#transaction-output-source-id-type). |
| 9 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp of this output record creation. |
| 10 | IsEtoroFee | bit | YES | - | CODE-BACKED | Whether this output represents an eToro fee payment rather than a value transfer. 1=fee output, 0/NULL=value output. |
| 11 | NormalizedToAddress | computed | - | - | CODE-BACKED | Computed PERSISTED column stripping protocol prefix and query parameters from ToAddress. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SentTransactionId | Wallet.SentTransactions | FK | Parent sent transaction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetTransactionOutputsByTransactionId | - | Reader | Reads outputs for a transaction |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SentTransactionOutputs (table)
└── Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FK target for SentTransactionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetTransactionOutputsByTransactionId | Stored Procedure | Reads outputs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SentTransactionOutputs | CLUSTERED PK | Id ASC | - | - | Active |
| IX_SentTransactionOutputs_IsEtoroFee | NC | IsEtoroFee | SentTransactionId, ToAddress | - | Active |
| IX_Wallet_SentTransactionOutputs_SentTransactionId_Occurred | NC | SentTransactionId, Occurred DESC | - | - | Active |
| IX_Wallet_SentTransactionOutputs_SentTransactionId_Occurred_Inc | NC | SentTransactionId, Occurred DESC | ToAddress, Amount, EtoroFees | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_SentTransactionOutputs__Occurred | DEFAULT | getutcdate() |
| FK_...SentTransactionId | FK | -> Wallet.SentTransactions.Id |

---

## 8. Sample Queries

### 8.1 Get outputs for a sent transaction
```sql
SELECT sto.ToAddress, sto.Amount, sto.EtoroFees, sto.BlockchainFees, sto.IsEtoroFee
FROM Wallet.SentTransactionOutputs sto WITH (NOLOCK)
WHERE sto.SentTransactionId = 1907239
ORDER BY sto.Id
```

### 8.2 Find redemption outputs with position IDs
```sql
SELECT sto.SentTransactionId, sto.SourceId AS PositionId, sto.Amount, sto.ToAddress
FROM Wallet.SentTransactionOutputs sto WITH (NOLOCK)
WHERE sto.SourceIdType = 0
ORDER BY sto.Id DESC
```

### 8.3 Fee analysis
```sql
SELECT TOP 20 sto.SentTransactionId, sto.Amount, sto.EtoroFees, sto.BlockchainFees
FROM Wallet.SentTransactionOutputs sto WITH (NOLOCK)
WHERE sto.IsEtoroFee = 0 AND sto.EtoroFees > 0
ORDER BY sto.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SentTransactionOutputs | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SentTransactionOutputs.sql*
