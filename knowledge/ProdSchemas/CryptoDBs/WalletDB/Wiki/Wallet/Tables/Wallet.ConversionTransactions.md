# Wallet.ConversionTransactions

> Stores the per-leg transaction details of crypto-to-crypto conversions, recording the exchange rate, destination address, amounts, and fees for each side of the swap.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table stores the detailed execution parameters for each leg of a crypto conversion. A typical conversion has two legs: one for the crypto being sold (outgoing) and one for the crypto being purchased (incoming). Each row records the exchange rate, destination address, amount, and fee details for one leg. FK to both `Wallet.Conversions` and `Wallet.Wallets`/`Wallet.CryptoTypes`.

---

## 2. Business Logic

### 2.1 Dual-Leg Conversion Execution

**What**: Each conversion produces two transaction records - one per leg of the swap.

**Columns/Parameters Involved**: `ConversionId`, `WalletId`, `CryptoId`, `Amount`

**Rules**:
- Unique constraint on (ConversionId, WalletId, CryptoId) ensures one record per wallet-crypto per conversion
- The sell leg records the amount leaving the source wallet
- The buy leg records the amount entering the destination wallet
- CryptoRateUsd captures the USD price at execution time for valuation

---

## 3. Data Overview

N/A for transaction detail table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | Parent conversion. FK to Wallet.Conversions.Id. Part of unique constraint. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet for this conversion leg. FK to Wallet.Wallets.WalletId. Part of unique constraint. |
| 4 | CryptoRateUsd | decimal(36,18) | NO | - | CODE-BACKED | USD exchange rate of this crypto at execution time. Used for valuation and fee calculation. |
| 5 | ToAddress | nvarchar(512) | YES | - | CODE-BACKED | Destination blockchain address for this conversion leg. NULL when the transfer is internal. |
| 6 | Amount | decimal(36,18) | NO | - | VERIFIED | Amount of crypto for this conversion leg in native units. |
| 7 | EtoroFeePercentage | decimal(5,2) | YES | - | CODE-BACKED | eToro fee percentage applied to this leg. |
| 8 | EtoroFeeCalculated | decimal(36,18) | YES | - | CODE-BACKED | Calculated eToro fee amount in the crypto's native units. |
| 9 | EstimatedBlockChainFee | decimal(36,18) | NO | - | CODE-BACKED | Estimated blockchain network fee for this leg. |
| 10 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this transaction record creation. |
| 11 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency for this leg. FK to Wallet.CryptoTypes.CryptoID. Part of unique constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | Wallet.Conversions | FK | Parent conversion |
| WalletId | Wallet.Wallets | FK | Wallet for this leg |
| CryptoId | Wallet.CryptoTypes | FK | Crypto for this leg |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertConversionTransaction | - | Writer | Creates transaction records |
| Wallet.GetConversionTransaction | - | Reader | Reads conversion details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ConversionTransactions (table)
├── Wallet.Conversions (table)
├── Wallet.Wallets (table)
└── Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | FK target for ConversionId |
| Wallet.Wallets | Table | FK target for WalletId |
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertConversionTransaction | Stored Procedure | Inserts records |
| Wallet.GetConversionTransaction | Stored Procedure | Reads records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionTransactions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...ConversionId_WalletId_CryptoId | NC UNIQUE | ConversionId, WalletId, CryptoId | - | - | Active |
| IX_...WalletId_CryptoId_Occurred | NC | WalletId, CryptoId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...ConversionId | FK | -> Wallet.Conversions.Id |
| FK_...CryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | -> Wallet.Wallets.WalletId |

---

## 8. Sample Queries

### 8.1 Get both legs of a conversion
```sql
SELECT ct.ConversionId, c.Name AS Crypto, ct.Amount, ct.CryptoRateUsd, ct.EtoroFeeCalculated
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
JOIN Wallet.CryptoTypes c WITH (NOLOCK) ON ct.CryptoId = c.CryptoID
WHERE ct.ConversionId = 50268
```

### 8.2 Conversion fees analysis
```sql
SELECT TOP 20 ct.ConversionId, c.Name AS Crypto, ct.Amount, ct.EtoroFeePercentage, ct.EtoroFeeCalculated
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
JOIN Wallet.CryptoTypes c WITH (NOLOCK) ON ct.CryptoId = c.CryptoID
WHERE ct.EtoroFeeCalculated > 0
ORDER BY ct.Id DESC
```

### 8.3 Conversion volume for a wallet
```sql
SELECT c.Name AS Crypto, COUNT(*) AS LegCount, SUM(ct.Amount) AS TotalAmount
FROM Wallet.ConversionTransactions ct WITH (NOLOCK)
JOIN Wallet.CryptoTypes c WITH (NOLOCK) ON ct.CryptoId = c.CryptoID
WHERE ct.WalletId = '6CAC2E99-10D8-41F1-A684-D24B3CB4AF9F'
GROUP BY c.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ConversionTransactions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ConversionTransactions.sql*
