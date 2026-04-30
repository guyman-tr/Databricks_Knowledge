# Wallet.vu_GetWalletBalanceReportV3

> V3 of the wallet balance reconciliation view - DDL-identical to V2 (excludes CryptoId 228, DECIMAL(19,10) TotalBalance). Exists as a separately versioned object for independent deployment or consumer isolation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | WalletId (uniqueidentifier) + CryptoId (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the V3 iteration of the wallet balance reconciliation report. Its DDL is identical to V2 - it excludes CryptoId 228, uses DECIMAL(19,10) precision for TotalBalance, and otherwise matches the full reconciliation logic of the base V1 view. See [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) for the complete business context.

The existence of a separate V3 object with identical logic to V2 suggests a deployment pattern where independent view versions allow consumers to be migrated incrementally (V1 -> V2 -> V3) or provide rollback capability. Different consumers may reference different versions, enabling non-breaking schema changes.

Data flow and reconciliation logic are identical to V1/V2: 4 CTEs (Customers, Receives, Sends, Balance) computing transaction-based expected balance vs provider-reported snapshot balance, with XRP reserve deduction and IsEtoroHandlingFee logic.

---

## 2. Business Logic

### 2.1 Differences from V1

**Rules**:
- Same as V2: `WHERE T1.CryptoId <> 228` (excludes CryptoId 228)
- Same as V2: `CAST(... AS DECIMAL(19, 10))` for TotalBalance
- All other logic identical to V1

See [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 2 for full business logic documentation.

---

## 3. Data Overview

| WalletId (truncated) | Gcid | CryptoId | TotalRecive | TotalSend | TotalBalance | TotalAmount | Meaning |
|---|---|---|---|---|---|---|---|
| 55AC9E57-... | 9248755 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | ETH wallet with perfect reconciliation. Dust remainder matches both computed and snapshot balance. |
| 0350C985-... | 7624226 | 2 (ETH) | 0.1 | 0.01 | 0.09 | 0.09 | ETH wallet: sent 10% of received amount, 90% remains. No discrepancy. DECIMAL(19,10) precision. |
| 3FB081AB-... | 6630253 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | Dust-balance ETH wallet. CryptoId 228 excluded (same as V2). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet being reconciled. From CustomerWalletsView.Id. |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID. From CustomerWalletsView.Gcid. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency (excluding 228). From CustomerWalletsView.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. From CustomerWalletsView.Address. |
| 5 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | Provider wallet identifier. From CustomerWalletsView.BlockchainProviderWalletId. |
| 6 | TotalRecive | decimal | NO | - | CODE-BACKED | Total crypto received (verified + pending, no self-receives). ISNULL defaults to 0. |
| 7 | TotalSend | decimal | NO | - | CODE-BACKED | Total crypto sent (verified + pending, fees included if not eToro-managed). ISNULL defaults to 0. |
| 8 | TotalBalance | decimal(19,10) | NO | - | VERIFIED | Current provider-reported balance. DECIMAL(19,10). ISNULL defaults to 0. |
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

Same as [Wallet.vu_GetWalletBalanceReportV2](Wallet.vu_GetWalletBalanceReportV2.md) Section 6.0.

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

### 8.1 Find wallets with balance discrepancies
```sql
SELECT WalletId, Gcid, CryptoId, TotalAmount - TotalBalance AS Discrepancy
FROM Wallet.vu_GetWalletBalanceReportV3 WITH (NOLOCK)
WHERE ABS(TotalAmount - TotalBalance) > 0.00001
  AND Gcid > 0
ORDER BY ABS(TotalAmount - TotalBalance) DESC
```

### 8.2 Get XRP wallets showing reserve impact
```sql
SELECT WalletId, Gcid, TotalRecive, TotalSend, TotalBalance, TotalAmount
FROM Wallet.vu_GetWalletBalanceReportV3 WITH (NOLOCK)
WHERE CryptoId = 4
  AND Gcid > 0
ORDER BY TotalBalance DESC
```

### 8.3 Recently active wallets with balance
```sql
SELECT WalletId, Gcid, CryptoId, TotalBalance, LastSentOccurred, LastReceivedOccurred
FROM Wallet.vu_GetWalletBalanceReportV3 WITH (NOLOCK)
WHERE TotalBalance > 0
  AND (LastSentOccurred >= DATEADD(day, -7, GETDATE()) OR LastReceivedOccurred >= DATEADD(day, -7, GETDATE()))
ORDER BY ISNULL(LastSentOccurred, LastReceivedOccurred) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vu_GetWalletBalanceReportV3 | Type: View | Source: WalletDB/Wallet/Views/Wallet.vu_GetWalletBalanceReportV3.sql*
