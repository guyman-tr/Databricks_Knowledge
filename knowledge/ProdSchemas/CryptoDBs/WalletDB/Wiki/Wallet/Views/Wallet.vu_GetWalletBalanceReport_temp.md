# Wallet.vu_GetWalletBalanceReport_temp

> Temporary copy of the wallet balance reconciliation view - DDL-identical to V1 (includes all CryptoIds, DECIMAL(36,18) TotalBalance). Exists as a separate named object for ad hoc testing, migration validation, or side-by-side comparison.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | WalletId (uniqueidentifier) + CryptoId (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is a temporary copy of [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) with identical DDL. The "_temp" suffix follows the WalletDB convention for temporary objects used during development, testing, or migration validation. It computes the same reconciliation: TotalReceived, TotalSent, TotalBalance, and TotalAmount for every active customer wallet.

Unlike V2/V3, this temp version includes ALL CryptoIds (no CryptoId 228 exclusion) and uses DECIMAL(36,18) precision for TotalBalance, making it a true clone of V1. It likely exists to allow parallel testing of changes to the main V1 view without disrupting existing consumers.

See [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) for complete business context, reconciliation logic, and business rules.

---

## 2. Business Logic

Identical to [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 2:
- Transaction-Based vs Snapshot Balance (4 CTEs: Customers, Receives, Sends, Balance)
- XRP Activation Reserve (0.0225 deduction for CryptoId=4)
- Fee Handling for eToro-Managed Fees (IsEtoroHandlingFee flag)

No differences from V1.

---

## 3. Data Overview

| WalletId (truncated) | Gcid | CryptoId | TotalRecive | TotalSend | TotalBalance | TotalAmount | Meaning |
|---|---|---|---|---|---|---|---|
| 55AC9E57-... | 9248755 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | ETH wallet with perfect reconciliation. Full DECIMAL(36,18) precision (same as V1). |
| 0350C985-... | 7624226 | 2 (ETH) | 0.1 | 0.01 | 0.09 | 0.09 | ETH wallet: 90% balance remaining after one send. No discrepancy detected. |
| 3FB081AB-... | 6630253 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | Dust-balance wallet. ALL CryptoIds included (unlike V2/V3 which exclude 228). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet being reconciled. From CustomerWalletsView.Id. |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID. From CustomerWalletsView.Gcid. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency (ALL CryptoIds included). From CustomerWalletsView.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. From CustomerWalletsView.Address. |
| 5 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | Provider wallet identifier. From CustomerWalletsView.BlockchainProviderWalletId. |
| 6 | TotalRecive | decimal | NO | - | CODE-BACKED | Total crypto received (verified + pending, no self-receives). ISNULL defaults to 0. |
| 7 | TotalSend | decimal | NO | - | CODE-BACKED | Total crypto sent (verified + pending, fees included if not eToro-managed). ISNULL defaults to 0. |
| 8 | TotalBalance | decimal(36,18) | NO | - | VERIFIED | Current provider-reported balance. DECIMAL(36,18) - full precision (same as V1). ISNULL defaults to 0. |
| 9 | TotalAmount | decimal | NO | - | CODE-BACKED | Expected balance: TotalRecive - TotalSend - XRP_reserve. |
| 10 | LastSentOccurred | datetime2(7) | YES | - | CODE-BACKED | Most recent sent transaction timestamp. NULL if no sends. |
| 11 | LastReceivedOccurred | datetime2(7) | YES | - | CODE-BACKED | Most recent received transaction timestamp. NULL if no receives. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 5.1.

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view.

---

## 6. Dependencies

### 6.0 Dependency Chain

Same as [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 6.0.

### 6.1 Objects This Depends On

Same as [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 6.1.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Compare temp vs V1 for a wallet
```sql
SELECT v1.TotalBalance AS V1_Balance, tmp.TotalBalance AS Temp_Balance
FROM Wallet.vu_GetWalletBalanceReport v1 WITH (NOLOCK)
JOIN Wallet.vu_GetWalletBalanceReport_temp tmp WITH (NOLOCK)
    ON v1.WalletId = tmp.WalletId AND v1.CryptoId = tmp.CryptoId
WHERE v1.Gcid = 9248755
```

### 8.2 Check if CryptoId 228 is included (temp should include it)
```sql
SELECT COUNT(*) AS Crypto228Count
FROM Wallet.vu_GetWalletBalanceReport_temp WITH (NOLOCK)
WHERE CryptoId = 228
```

### 8.3 Find largest discrepancies
```sql
SELECT WalletId, Gcid, CryptoId, TotalAmount - TotalBalance AS Discrepancy
FROM Wallet.vu_GetWalletBalanceReport_temp WITH (NOLOCK)
WHERE ABS(TotalAmount - TotalBalance) > 0.001
ORDER BY ABS(TotalAmount - TotalBalance) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vu_GetWalletBalanceReport_temp | Type: View | Source: WalletDB/Wallet/Views/Wallet.vu_GetWalletBalanceReport_temp.sql*
