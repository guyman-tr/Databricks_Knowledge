# Wallet.Monitor_Validiations

> Operational monitoring view returning the 100 most recent AML validations from the last hour, enriched with the crypto market symbol and customer GCID for rapid compliance alerting and investigation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | Id (int, from AmlValidations.Id - ordered DESC) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a real-time operational monitor of AML (Anti-Money Laundering) screening activity. It returns the 100 most recent AML validations created in the past hour, showing all screening results (both green/clean and flagged) along with the crypto symbol and the customer who owns the wallet. This gives the compliance monitoring team an at-a-glance view of current AML screening throughput and any emerging risk patterns.

Unlike Wallet.AMLTransactionsView (which filters to non-green only and looks back 24 hours), this view shows ALL validations (including green) but only from the last hour. It is designed for operational dashboards where the team needs to see recent activity volume and spot anomalies in real time.

The view uses `SELECT TOP 100 av.*` with all columns from Wallet.AmlValidations, plus MarketRatesCurrencySymbol from CryptoMarketRatesMappings and Gcid from CustomerWalletsView. The `ORDER BY 1 DESC` sorts by AmlValidations.Id descending (newest first). Note: the object name has a typo ("Validiations" instead of "Validations") which is preserved as-is in the SSDT.

---

## 2. Business Logic

### 2.1 Rolling 1-Hour Window with TOP 100 Cap

**What**: The view returns at most 100 records from the last hour, providing a bounded real-time window.

**Columns/Parameters Involved**: `Created`, `Id`

**Rules**:
- `av.Created >= DATEADD(HOUR, -1, GETUTCDATE())`: Only validations from the last 60 minutes
- `TOP 100`: Caps output at 100 rows even if more validations occurred. During high-traffic periods, only the 100 most recent are shown
- `ORDER BY 1 DESC`: Newest first (highest Id = most recent)
- Uses `GETUTCDATE()` (not `GETDATE()`) for consistent UTC-based time filtering

### 2.2 Customer and Crypto Enrichment

**What**: Raw AML validation records are enriched with human-readable context.

**Columns/Parameters Involved**: `CryptoId`, `WalletId`, `MarketRatesCurrencySymbol`, `Gcid`

**Rules**:
- `CryptoMarketRatesMappings ON CryptoId`: Adds the market trading symbol (BTC, ETH, etc.)
- `CustomerWalletsView ON Id = WalletId`: Adds the customer's GCID for identity resolution
- Both JOINs are INNER, meaning validations for non-active wallets or unmapped cryptos are excluded

---

## 3. Data Overview

| Id | AmlProviderId | IsSend | ProviderStatus | CryptoId | Amount | Address (truncated) | Meaning |
|---|---|---|---|---|---|---|---|
| 2726460 | 1 (Chainalysis) | false | Green | 4 (XRP) | 1.22 | rD4G6gtD2K... | Clean incoming XRP validation - no risk. The most common outcome in normal operations. |
| 2726459 | 1 (Chainalysis) | false | Red | 4 (XRP) | 0.000001 | rDQSFBVK7N... | Red-flagged incoming XRP from a gambling site (Rainbet.com per DetailsJson). Dust amount but flagged due to sender's risk profile. |
| 2726458 | 1 (Chainalysis) | true | Amber | 107 (USDC) | 367.99 | 0x379cC535... | Amber-flagged outbound USDC send. Medium risk - approved (IsPositiveDecision=true) but logged for review. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Auto-incrementing surrogate key from AmlValidations. Used for ordering (newest first). From Wallet.AmlValidations.Id. |
| 2 | AmlProviderId | int | NO | - | VERIFIED | AML screening provider: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders. From Wallet.AmlValidations. |
| 3 | IsSend | bit | NO | - | VERIFIED | Transaction direction: 1=outbound (screening destination before sending), 0=inbound (screening sender after receiving). From Wallet.AmlValidations. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address being screened. For sends: destination address. For receives: sender address. NULL for provider-level checks. From Wallet.AmlValidations. |
| 5 | WalletId | uniqueidentifier | NO | - | VERIFIED | The eToro wallet involved. FK to Wallet.WalletPool.WalletId. From Wallet.AmlValidations. |
| 6 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Transaction amount in native crypto units. From Wallet.AmlValidations. |
| 7 | ProviderStatus | varchar(50) | YES | - | CODE-BACKED | AML risk assessment: Green (clean), Amber (medium risk), Red (high risk). From Wallet.AmlValidations. |
| 8 | IsPositiveDecision | bit | NO | - | VERIFIED | Final compliance decision: 1=approved, 0=blocked. Gates whether the transaction proceeds. From Wallet.AmlValidations. |
| 9 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links to the parent request in Wallet.Requests for end-to-end tracing. From Wallet.AmlValidations. |
| 10 | Created | datetime2(7) | NO | - | CODE-BACKED | When this screening was performed. Filtered by `>= DATEADD(HOUR, -1, GETUTCDATE())`. From Wallet.AmlValidations. |
| 11 | BlockchainTransactionId | nvarchar(100) | YES | - | CODE-BACKED | On-chain transaction hash for receive screenings. NULL for pre-send screenings. From Wallet.AmlValidations. |
| 12 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | Full JSON response from the AML provider containing risk scores, cluster info (e.g., "Rainbet.com"), and screening metadata. From Wallet.AmlValidations. |
| 13 | CryptoId | int | NO | - | VERIFIED | Cryptocurrency being transacted. FK to Wallet.CryptoTypes.CryptoID. From Wallet.AmlValidations. |
| 14 | CategoryId | int | YES | - | CODE-BACKED | Chainalysis risk category if identified. NULL for clean transactions. See [Chainalysis Category](../../_glossary.md#chainalysis-category). From Wallet.AmlValidations. |
| 15 | MarketRatesCurrencySymbol | nvarchar | NO | - | CODE-BACKED | Trading symbol of the cryptocurrency (e.g., BTC, ETH, USDC). Resolved via JOIN to Wallet.CryptoMarketRatesMappings. |
| 16 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. Resolved via JOIN to Wallet.CustomerWalletsView. Enables compliance team to identify the customer behind the flagged activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all av.* columns) | Wallet.AmlValidations | SELECT (source) | All AML screening records from the last hour |
| CryptoId | Wallet.CryptoMarketRatesMappings | JOIN | Resolves crypto trading symbol |
| WalletId | Wallet.CustomerWalletsView | JOIN | Resolves customer Gcid from wallet |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view. Referenced in MonitorTeam.sql for permissions. Consumed by external compliance monitoring dashboards.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Monitor_Validiations (view)
+-- Wallet.AmlValidations (table)
+-- Wallet.CryptoMarketRatesMappings (table)
+-- Wallet.CustomerWalletsView (view)
    +-- Wallet.Wallets (table)
    +-- Wallet.WalletPool (table)
    +-- Wallet.WalletAssets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlValidations | Table | Source of AML screening records |
| Wallet.CryptoMarketRatesMappings | Table | Resolves crypto symbol |
| Wallet.CustomerWalletsView | View | Resolves wallet owner (Gcid) |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Consumed by external monitoring tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View current AML monitoring feed
```sql
SELECT Id, AmlProviderId, IsSend, ProviderStatus, Amount, Address, Gcid, Created
FROM Wallet.Monitor_Validiations WITH (NOLOCK)
```

### 8.2 Count validations by provider status in the last hour
```sql
SELECT ProviderStatus, COUNT(*) AS ValidationCount
FROM Wallet.Monitor_Validiations WITH (NOLOCK)
GROUP BY ProviderStatus
ORDER BY ValidationCount DESC
```

### 8.3 Find Red-flagged validations with customer details
```sql
SELECT Id, Gcid, MarketRatesCurrencySymbol, Amount, Address, DetailsJson, Created
FROM Wallet.Monitor_Validiations WITH (NOLOCK)
WHERE ProviderStatus = 'Red'
ORDER BY Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Monitor_Validiations | Type: View | Source: WalletDB/Wallet/Views/Wallet.Monitor_Validiations.sql*
