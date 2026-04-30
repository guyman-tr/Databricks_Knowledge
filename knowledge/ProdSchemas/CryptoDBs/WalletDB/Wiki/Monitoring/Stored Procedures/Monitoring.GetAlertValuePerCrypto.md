# Monitoring.GetAlertValuePerCrypto

> Calculates an alert threshold percentage per cryptocurrency by comparing omnibus wallet redemption balances against the maximum daily verified redemption volume over the past 7 days.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns alert percentages per crypto with balance and max daily value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetAlertValuePerCrypto is a liquidity monitoring procedure that assesses whether the omnibus (Gcid=0) redemption wallet has sufficient balance relative to recent withdrawal activity. For each cryptocurrency, it computes the ratio of the current redemption wallet balance to the maximum single-day verified redemption amount over the past 7 days, expressed as a percentage. A low percentage indicates the wallet may not have enough reserves to handle peak redemption demand.

Without this procedure, the operations team would have no early warning that a particular crypto's redemption reserves are running low relative to recent demand. This could lead to failed user redemption (crypto-to-fiat) transactions if the omnibus wallet is depleted.

The procedure first calculates daily verified redemption volumes from TransactionsView for the omnibus account, then finds the maximum daily value per crypto, and finally joins this against the current Redeem-type wallet balance to produce the alert percentage. Only the omnibus account (Gcid=0) is analyzed because redemptions are processed through omnibus wallets.

---

## 2. Business Logic

### 2.1 Alert Ratio Calculation

**What**: Measures how many times the current balance can cover the peak daily redemption volume.

**Columns/Parameters Involved**: `Balance`, `MaxValue`, `Alert`

**Rules**:
- Alert = (Balance / MaxValue) * 100
- A value of 100% means the balance exactly equals the max daily redemption volume
- Values below 100% indicate the balance cannot cover a repeat of the peak day
- Values above 100% provide a safety margin
- CryptoId 18 is explicitly excluded from the analysis

**Diagram**:
```
Last 7 days verified Redeem transactions (Gcid=0)
  |
  v
GROUP BY CryptoId, Date -> Daily totals
  |
  v
MAX(DailyValue) per CryptoId -> Peak day
  |
  v
Current Redeem wallet balance / Peak day * 100 = Alert %
  |
  v
Low % = reserves running thin vs recent demand
```

### 2.2 Omnibus Wallet Scoping

**What**: Only omnibus accounts (Gcid=0) with Redeem wallet type are analyzed.

**Columns/Parameters Involved**: `Gcid`, `WalletTypeId`

**Rules**:
- Gcid = 0 filters to the omnibus/platform wallets only
- WalletType = 'Redeem' targets the specific wallets used for customer crypto-to-fiat redemptions
- Individual customer wallets are excluded - this monitors platform-level liquidity only

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier. From Wallet.CryptoTypes. CryptoId 18 is explicitly excluded. |
| 2 | MaxValue | DECIMAL | NO | - | CODE-BACKED | Maximum single-day total verified redemption amount for this crypto over the past 7 days. Represents peak daily demand. |
| 3 | CryptoID | INT | NO | - | CODE-BACKED | Cryptocurrency identifier from the balance subquery. Matches CryptoId from MaxValue CTE. |
| 4 | CryptoName | NVARCHAR | NO | - | CODE-BACKED | Human-readable cryptocurrency name (e.g., Bitcoin, Ethereum). From Wallet.CryptoTypes.Name. |
| 5 | Balance | DECIMAL | NO | - | CODE-BACKED | Current balance in the omnibus Redeem wallet for this crypto. DateTo='3000' filter selects the active (non-historical) balance record. |
| 6 | Alert | DECIMAL | NO | - | CODE-BACKED | Alert percentage: (Balance / MaxValue) * 100. Low values indicate reserves are thin relative to recent redemption demand. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionsView | FROM (read) | Source of daily verified redemption amounts for Gcid=0 |
| Query body | Wallet.CustomerWalletsView | FROM (read) | Identifies omnibus Redeem wallets |
| Query body | Wallet.WalletBalances | JOIN | Current balance for each wallet/crypto combination |
| Query body | Dictionary.WalletTypes | JOIN | Filters to 'Redeem' wallet type |
| Query body | Wallet.CryptoTypes | JOIN | Maps CryptoId to CryptoName |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetAlertValuePerCrypto (procedure)
  ├── Wallet.TransactionsView (view)
  ├── Wallet.CustomerWalletsView (view)
  ├── Wallet.WalletBalances (table)
  ├── Dictionary.WalletTypes (table)
  └── Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionsView | View | FROM - source of daily redemption volumes |
| Wallet.CustomerWalletsView | View | FROM - identifies omnibus wallets |
| Wallet.WalletBalances | Table | JOIN - current crypto balances |
| Dictionary.WalletTypes | Table | JOIN - filters to Redeem wallet type |
| Wallet.CryptoTypes | Table | JOIN - crypto name lookup |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the alert check
```sql
EXEC Monitoring.GetAlertValuePerCrypto;
```

### 8.2 Check current omnibus Redeem balances independently
```sql
SELECT ct.CryptoID, ct.Name, wb.Balance
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
JOIN Wallet.WalletBalances wb WITH (NOLOCK) ON wb.WalletId = cwv.Id AND wb.CryptoId = cwv.CryptoId AND wb.DateTo = '3000'
JOIN Dictionary.WalletTypes iwt WITH (NOLOCK) ON iwt.Id = cwv.WalletTypeId
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = wb.CryptoId
WHERE cwv.Gcid = 0 AND iwt.Name = 'Redeem';
```

### 8.3 Check recent daily redemption volumes
```sql
SELECT CryptoId, CAST(TransDate AS DATE) AS Date, SUM(Amount) AS DailyValue
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE Gcid = 0 AND TransStatus = 'Verified' AND TransactionType = 'Redeem'
  AND TransDate BETWEEN DATEADD(DAY, -7, GETUTCDATE()) AND GETUTCDATE()
GROUP BY CryptoId, CAST(TransDate AS DATE)
ORDER BY CryptoId, Date;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetAlertValuePerCrypto | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetAlertValuePerCrypto.sql*
