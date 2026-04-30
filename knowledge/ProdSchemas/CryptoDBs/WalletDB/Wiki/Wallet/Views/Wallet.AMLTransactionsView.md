# Wallet.AMLTransactionsView

> Real-time AML monitoring view showing non-green (flagged) Chainalysis screening results for verified sent and received transactions in the last 24 hours, resolving the customer identity and crypto symbol for compliance dashboards.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | Composite: gcid + Address + IsSend (no single PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a real-time AML (Anti-Money Laundering) compliance dashboard showing all crypto transactions from the last 24 hours that were flagged as non-green by the Chainalysis screening provider. It answers the compliance question: "Which customer transactions in the past day have been flagged for AML review, and what is their risk level?"

Without this view, the compliance team would need to manually join transaction tables with AML validation results and apply the complex 24-hour rolling window and status filters. The view centralizes AML monitoring logic and ensures consistent filtering across sent and received transactions.

The view combines two UNION blocks: one for sent transactions (IsSend=1) and one for received transactions (IsSend=0). Both blocks join through Wallet.CustomerWalletsView to resolve the customer (Gcid) and crypto details, and filter to Chainalysis (AmlProviderId=1) validations with non-green ProviderStatus. For receives, it additionally excludes transactions from omnibus wallet addresses (Gcid=0) to avoid flagging internal transfers.

---

## 2. Business Logic

### 2.1 AML Risk Filtering

**What**: The view only shows transactions flagged by Chainalysis as potentially risky (non-green status).

**Columns/Parameters Involved**: `ProviderStatus`, `AmlProviderId`, `IsSend`

**Rules**:
- `AmlProviderId = 1`: Only Chainalysis validations (the primary AML screening provider). Other providers are excluded
- `ProviderStatus <> 'green'`: Excludes clean transactions. Typical non-green values seen in data: 'Amber' (medium risk, requires review)
- `StatusId = 2` (Verified): Only transactions that have been blockchain-verified. Pending transactions are excluded to avoid false positives
- 24-hour rolling window: Sent uses `st.Occurred >= DATEADD(HOUR, -24, GETDATE())`, Received uses `rt.BlockchainTransactionDate >= DATEADD(HOUR, -24, GETDATE())`

### 2.2 Omnibus Exclusion (Receives Only)

**What**: Received transactions from omnibus/system wallet addresses are excluded to prevent internal transfers from appearing as AML flags.

**Columns/Parameters Involved**: `Gcid`, `SenderAddress`, `CryptoId`

**Rules**:
- `cwv.Gcid > 0` on the receiving wallet: Only customer wallets (not system wallets) appear as recipients
- `rt.SenderAddress NOT IN (SELECT Address FROM CustomerWalletsView WHERE Gcid = 0 AND CryptoId = rt.CryptoId)`: Filters out receives where the sender is an omnibus wallet
- This prevents internal funding transfers or wallet management operations from triggering AML alerts

---

## 3. Data Overview

| gcid | CryptoId | MarketRatesCurrencySymbol | Amount | Address | ProviderStatus | IsSend | Meaning |
|---|---|---|---|---|---|---|---|
| 11790732 | 1 | BTC | 0.00289 | 194B2bau... | Amber | 1 | Customer sent BTC to an address flagged Amber by Chainalysis. Compliance team should review this outgoing transaction. |
| 23076949 | 2 | ETH | 0.0338 | 0xAF9B54... | Amber | 1 | Customer sent ETH to an Amber-flagged address. Small amount but compliance review required. |
| 28838164 | 107 | USDC | 4080.04 | 0x84ca9a... | Amber | 1 | Large USDC send to an Amber address. Higher amount warrants priority compliance review. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. Only customer wallets (Gcid > 0) are included - omnibus/system wallets are excluded. Resolved via Wallet.CustomerWalletsView.Gcid. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency involved in the flagged transaction. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 3 | MarketRatesCurrencySymbol | nvarchar | NO | - | CODE-BACKED | Trading symbol of the cryptocurrency (e.g., BTC, ETH, USDC). Resolved via JOIN to Wallet.CryptoMarketRatesMappings on CryptoId. Useful for display in compliance dashboards without additional lookups. |
| 4 | Amount | decimal | YES | - | CODE-BACKED | The transaction amount screened by AML. From AmlValidations.Amount. Represents the value assessed by Chainalysis for risk scoring. |
| 5 | Address | nvarchar | YES | - | CODE-BACKED | The blockchain address that was AML-screened. From AmlValidations.Address. For sends: this is the destination address. For receives: this is the sender address being checked. |
| 6 | ProviderStatus | nvarchar | NO | - | VERIFIED | The AML risk assessment from Chainalysis. Always non-green in this view (green transactions are filtered out). Known values: 'Amber' (medium risk, review required), 'Red' (high risk, potential sanctions/illicit activity). From AmlValidations.ProviderStatus. |
| 7 | IsSend | int | NO | - | CODE-BACKED | Transaction direction: 1=Sent (outgoing, customer sent to a flagged address), 0=Received (incoming, received from a flagged address). Hard-coded per UNION block. Aligns with AmlValidations.IsSend. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.CustomerWalletsView | JOIN | Resolves customer Gcid and filters to active customer wallets |
| CryptoId | Wallet.CryptoMarketRatesMappings | JOIN | Resolves crypto symbol for display |
| CorrelationId | Wallet.AmlValidations | JOIN | AML screening results from Chainalysis |
| SentTransactionId | Wallet.SentTransactions | Source (sends) | Outgoing transaction details |
| SentTransactionId | Wallet.SentTransactionStatuses | JOIN | Filters to Verified status (StatusId=2) |
| ReceivedTransactionId | Wallet.ReceivedTransactions | Source (receives) | Incoming transaction details |
| ReceivedTransactionId | Wallet.ReceivedTransactionStatuses | JOIN | Filters to Verified status (StatusId=2) |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view. Its consumer is external monitoring tools / compliance dashboards. Referenced in MonitorTeam.sql for permissions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AMLTransactionsView (view)
+-- Wallet.CustomerWalletsView (view)
|   +-- Wallet.Wallets (table)
|   +-- Wallet.WalletPool (table)
|   +-- Wallet.WalletAssets (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.AmlValidations (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.CryptoMarketRatesMappings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Resolves wallet owner (Gcid) and filters to active customer wallets |
| Wallet.SentTransactions | Table | Source of outgoing transactions (last 24h) |
| Wallet.SentTransactionStatuses | Table | Filters to Verified status |
| Wallet.AmlValidations | Table | AML screening results from Chainalysis |
| Wallet.ReceivedTransactions | Table | Source of incoming transactions (last 24h) |
| Wallet.ReceivedTransactionStatuses | Table | Filters to Verified status |
| Wallet.CryptoMarketRatesMappings | Table | Resolves crypto symbol for display |

### 6.2 Objects That Depend On This

No dependents found in SSDT. External compliance dashboards consume this view.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all current AML flags grouped by risk level
```sql
SELECT ProviderStatus, IsSend, COUNT(*) AS FlaggedCount
FROM Wallet.AMLTransactionsView WITH (NOLOCK)
GROUP BY ProviderStatus, IsSend
ORDER BY ProviderStatus, IsSend
```

### 8.2 Find the highest-value flagged transactions
```sql
SELECT gcid, CryptoId, MarketRatesCurrencySymbol, Amount, ProviderStatus,
    CASE IsSend WHEN 1 THEN 'Sent' ELSE 'Received' END AS Direction
FROM Wallet.AMLTransactionsView WITH (NOLOCK)
ORDER BY Amount DESC
```

### 8.3 List flagged receives with sender details
```sql
SELECT aml.gcid, aml.MarketRatesCurrencySymbol, aml.Amount, aml.Address AS FlaggedSender, aml.ProviderStatus
FROM Wallet.AMLTransactionsView aml WITH (NOLOCK)
WHERE aml.IsSend = 0
ORDER BY aml.Amount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AMLTransactionsView | Type: View | Source: WalletDB/Wallet/Views/Wallet.AMLTransactionsView.sql*
