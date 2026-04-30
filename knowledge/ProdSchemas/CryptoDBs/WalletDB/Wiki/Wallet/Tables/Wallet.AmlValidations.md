# Wallet.AmlValidations

> Records every AML (Anti-Money Laundering) screening result for blockchain transactions, capturing the provider's risk assessment, address analysis, and compliance decision for both sent and received transactions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores the complete record of every AML screening performed on crypto transactions. Each row captures a single screening event - including which provider performed it, the wallet and address screened, the amount, the provider's risk verdict, and any risk category identified. With ~2.72M rows, it provides a comprehensive compliance audit trail.

Without this table, eToro would have no record of AML compliance checks performed on transactions, which is a regulatory requirement. It serves both real-time decision making (should this transaction proceed?) and retrospective auditing (demonstrate to regulators that all transactions were screened).

Rows are created by `Wallet.StoreAmlValidation` during the AML screening phase of transaction processing (RequestStatuses 8=AmlEnqueued, 9=ReadByAml). The `IsPositiveDecision` flag determines whether the transaction proceeds (true=pass) or is blocked (false=fail). The `CategoryId` links to Chainalysis risk categories when a risk factor is identified.

---

## 2. Business Logic

### 2.1 Directional Screening

**What**: AML screening is performed separately for sent (outbound) and received (inbound) transactions.

**Columns/Parameters Involved**: `IsSend`, `Address`, `WalletId`

**Rules**:
- IsSend=true: Screening the destination address before sending crypto out (is the receiver safe?)
- IsSend=false: Screening the sender address after receiving crypto in (did the funds come from a safe source?)
- Both directions use the same providers but may apply different risk thresholds

### 2.2 Risk Category Tagging

**What**: When a screening identifies a risk factor, the Chainalysis category is recorded.

**Columns/Parameters Involved**: `CategoryId`, `IsPositiveDecision`, `ProviderStatus`

**Rules**:
- CategoryId is NULL when no risk factor is found (clean transaction)
- When populated, links to Dictionary.ChainalysisCategoryId for the specific risk type (e.g., darknet market, sanctioned entity)
- IsPositiveDecision=true: Transaction approved regardless (category may still be logged for monitoring)
- IsPositiveDecision=false: Transaction blocked due to AML risk
- See [Chainalysis Category](../../_glossary.md#chainalysis-category) and [AML Status Type](../../_glossary.md#aml-status-type).

---

## 3. Data Overview

| Id | AmlProviderId | IsSend | CryptoId | Amount | IsPositiveDecision | CategoryId | Meaning |
|---|---|---|---|---|---|---|---|
| 2726151 | 1 (Chainalysis) | false | 1 (BTC) | 0.00246 | true | NULL | Incoming BTC screened by Chainalysis - clean, no risk category identified |
| 2726150 | 4 (ChainalysisCDN) | false | 64 (SOL) | 0 | true | NULL | SOL validation via CDN - zero amount likely a wallet activation check |
| 2726149 | 1 (Chainalysis) | false | 4 (XRP) | 1.2225 | true | 46 | XRP screened, positive decision but CategoryId=46 logged for monitoring |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AmlProviderId | int | NO | - | VERIFIED | Which AML provider performed this screening: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders. |
| 3 | IsSend | bit | NO | - | VERIFIED | Direction of the transaction: 1=outbound (screening destination before sending), 0=inbound (screening sender after receiving). |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | The blockchain address being screened. For sends, this is the destination address. For receives, this is the sender address. NULL when screening is provider-level (not address-specific). |
| 5 | WalletId | uniqueidentifier | NO | - | VERIFIED | The eToro wallet involved in the transaction. FK to Wallet.WalletPool.WalletId. For sends, the source wallet. For receives, the receiving wallet. |
| 6 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Transaction amount in the crypto's native units. Used for risk scoring (higher amounts may trigger additional scrutiny). |
| 7 | ProviderStatus | varchar(50) | YES | - | CODE-BACKED | Raw status string returned by the AML provider. Provider-specific format (e.g., Chainalysis risk score). |
| 8 | IsPositiveDecision | bit | NO | - | VERIFIED | Final compliance decision: 1=approved (transaction can proceed), 0=rejected (transaction blocked). This is the field that gates transaction execution. |
| 9 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links this screening to the parent request in Wallet.Requests via CorrelationId. Enables end-to-end tracing of the AML check within the request lifecycle. |
| 10 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this screening was performed. |
| 11 | BlockchainTransactionId | nvarchar(100) | YES | - | CODE-BACKED | For receive screenings, the blockchain transaction hash being evaluated. NULL for pre-send screenings (transaction not yet broadcast). |
| 12 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | Full JSON response from the AML provider. Contains detailed risk scores, alerts, cluster information, and screening metadata. Used for audit and investigation purposes. |
| 13 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency being transacted. FK to Wallet.CryptoTypes.CryptoID. Determines which AML provider contract is used (via Wallet.AmlProviderContracts). |
| 14 | CategoryId | int | YES | - | CODE-BACKED | Chainalysis risk category if a risk factor was identified. NULL for clean transactions. Implicit reference to Dictionary.ChainalysisCategoryId. See [Chainalysis Category](../../_glossary.md#chainalysis-category). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AmlProviderId | Dictionary.AmlProviders | FK | Identifies the screening provider |
| CryptoId | Wallet.CryptoTypes | FK | Identifies the cryptocurrency |
| WalletId | Wallet.WalletPool | FK | Identifies the wallet involved |
| CategoryId | Dictionary.ChainalysisCategoryId | Implicit | Risk category from provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreAmlValidation | - | Writer | Creates screening records |
| Wallet.GetAmlValidation | - | Reader | Reads screening results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AmlValidations (table)
├── Wallet.CryptoTypes (table)
│     └── Wallet.BlockchainCryptos (table)
├── Wallet.WalletPool (table)
│     └── Wallet.BlockchainCryptos (table)
└── Dictionary.AmlProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AmlProviders | Table | FK target for AmlProviderId |
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Wallet.WalletPool | Table | FK target for WalletId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreAmlValidation | Stored Procedure | Inserts screening records |
| Wallet.GetAmlValidation | Stored Procedure | Reads screening results |
| Wallet.VerifyAddressNotKnownBadAML | Stored Procedure | Checks address history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AmlValidations | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_AmlValidations | NC | IsSend, CorrelationId, Created DESC | - | - | Active |
| IX_Wallet_AmlValidations_Address | NC | Address | - | - | Active |
| IX_Wallet_AmlValidations_IsSend_Created | NC | IsSend, Created | - | - | Active |
| IX_Wallet_AmlValidations_WalletId | NC | WalletId | - | - | Active |
| IX_Wallet_AmlValidations_WalletId_CryptoId_Created | NC | WalletId, CryptoId, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AmlValidations_Created | DEFAULT | getutcdate() |
| FK_...AmlProviderId | FK | AmlProviderId -> Dictionary.AmlProviders.Id |
| FK_...CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |
| FK_...WalletId | FK | WalletId -> Wallet.WalletPool.WalletId |

---

## 8. Sample Queries

### 8.1 Get AML screening history for a wallet
```sql
SELECT av.Id, ap.Name AS Provider, av.IsSend, av.Amount, av.IsPositiveDecision, av.CategoryId, av.Created
FROM Wallet.AmlValidations av WITH (NOLOCK)
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON av.AmlProviderId = ap.Id
WHERE av.WalletId = 'F05F83B8-963A-4796-B160-3BC1E018AAFB'
ORDER BY av.Created DESC
```

### 8.2 Find rejected transactions
```sql
SELECT TOP 20 av.Id, av.Address, ct.Name AS Crypto, av.Amount, cc.CategoryName, av.Created
FROM Wallet.AmlValidations av WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON av.CryptoId = ct.CryptoID
LEFT JOIN Dictionary.ChainalysisCategoryId cc WITH (NOLOCK) ON av.CategoryId = cc.categoryId
WHERE av.IsPositiveDecision = 0
ORDER BY av.Created DESC
```

### 8.3 AML screening volume by provider
```sql
SELECT ap.Name AS Provider, COUNT(*) AS Screenings,
    SUM(CASE WHEN av.IsPositiveDecision = 1 THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN av.IsPositiveDecision = 0 THEN 1 ELSE 0 END) AS Rejected
FROM Wallet.AmlValidations av WITH (NOLOCK)
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON av.AmlProviderId = ap.Id
GROUP BY ap.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AmlValidations | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.AmlValidations.sql*
