# Wallet.AmlProviderContracts

> Maps each cryptocurrency to its designated AML (Anti-Money Laundering) screening provider, determining which compliance service checks transactions for each crypto asset.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table maps each supported cryptocurrency to its AML screening provider. Before any transaction (send or receive), the system looks up which AML provider to use for that crypto and routes the screening request accordingly. Different cryptos may use different providers based on blockchain analytics availability and regulatory requirements.

Without this table, the system would not know which AML provider to invoke for a given crypto, breaking the compliance screening pipeline for all transactions. It is queried during every transaction's AML check phase.

The 17 rows cover all actively transactable cryptos and some ERC-20 tokens. Original cryptos (BTC, ETH, BCH, LTC) use Chainalysis (Id=1) directly. Newer cryptos (TRX, ADA, DOGE, ETC, SOL) use ChainalysisCDN (Id=4) for faster cached lookups. XLM also uses ChainalysisCDN. EOS uses Unsupported (Id=3) since no AML analytics are available. Some ERC-20 tokens (101-105) use Chainalysis since they share Ethereum's address space.

---

## 2. Business Logic

### 2.1 Provider Assignment by Blockchain Maturity

**What**: The AML provider assigned to each crypto reflects the maturity and availability of blockchain analytics for that chain.

**Columns/Parameters Involved**: `CryptoId`, `AmlProviderId`

**Rules**:
- AmlProviderId=1 (Chainalysis API): Used for original/mature blockchains (BTC, ETH, BCH, LTC, XRP) and Ethereum ERC-20 tokens
- AmlProviderId=3 (Unsupported): Used for EOS where no AML analytics exist - transactions proceed without automated screening
- AmlProviderId=4 (ChainalysisCDN): Used for newer chains (TRX, ADA, DOGE, ETC, SOL, XLM) - uses cached Chainalysis data for faster lookups
- See [AML Provider](../../_glossary.md#aml-provider) for full provider definitions. FK to Dictionary.AmlProviders.
- Unique constraint on CryptoId ensures exactly one AML provider per crypto

---

## 3. Data Overview

| Id | CryptoId | AmlProviderId | Meaning |
|---|---|---|---|
| 1 | 1 (BTC) | 1 (Chainalysis) | Bitcoin uses direct Chainalysis API for the most thorough blockchain analytics and risk scoring |
| 12 | 23 (EOS) | 3 (Unsupported) | EOS has no AML provider - no automated screening available for this blockchain |
| 14 | 18 (ADA) | 4 (ChainalysisCDN) | Cardano uses Chainalysis CDN for faster cached risk lookups |
| 17 | 64 (SOL) | 4 (ChainalysisCDN) | Solana (newest chain) uses ChainalysisCDN. Added Feb 2026. |
| 7 | 101 | 1 (Chainalysis) | ERC-20 tokens share Ethereum's address analytics via direct Chainalysis API |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this AML mapping applies to. FK to Wallet.CryptoTypes.CryptoID. Unique constraint ensures one AML provider per crypto. |
| 3 | AmlProviderId | int | NO | - | VERIFIED | The AML screening provider to use: 1=Chainalysis (direct API), 2=BlackList (internal), 3=Unsupported (no screening), 4=ChainalysisCDN (cached). See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders. |
| 4 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this mapping was created. Tracks when each crypto's AML integration went live. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies which crypto asset this mapping is for |
| AmlProviderId | Dictionary.AmlProviders | FK | Identifies which AML provider to use |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetAmlProviderContracts | - | Reader | Reads all crypto-to-AML-provider mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AmlProviderContracts (table)
├── Wallet.CryptoTypes (table)
│     └── Wallet.BlockchainCryptos (table)
└── Dictionary.AmlProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Dictionary.AmlProviders | Table | FK target for AmlProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetAmlProviderContracts | Stored Procedure | Reads all mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AmlProviderContracts | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_AmlProviderContracts_CryptoId | NC UNIQUE | CryptoId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AmlProviderContracts_Created | DEFAULT | getutcdate() |
| FK_...AmlProviderId | FK | AmlProviderId -> Dictionary.AmlProviders.Id |
| FK_...CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |

---

## 8. Sample Queries

### 8.1 List all crypto AML provider assignments
```sql
SELECT ct.Name AS Crypto, ap.Name AS AmlProvider, apc.Created
FROM Wallet.AmlProviderContracts apc WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON apc.CryptoId = ct.CryptoID
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON apc.AmlProviderId = ap.Id
ORDER BY ct.Name
```

### 8.2 Find which AML provider handles a specific crypto
```sql
SELECT ap.Name AS AmlProvider
FROM Wallet.AmlProviderContracts apc WITH (NOLOCK)
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON apc.AmlProviderId = ap.Id
WHERE apc.CryptoId = 1  -- BTC
```

### 8.3 Cryptos without full AML screening
```sql
SELECT ct.Name AS Crypto, ap.Name AS AmlProvider
FROM Wallet.AmlProviderContracts apc WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON apc.CryptoId = ct.CryptoID
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON apc.AmlProviderId = ap.Id
WHERE apc.AmlProviderId = 3  -- Unsupported
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AmlProviderContracts | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.AmlProviderContracts.sql*
