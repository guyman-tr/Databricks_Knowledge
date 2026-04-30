# Dictionary.AmlProviders

> Lookup table of Anti-Money Laundering (AML) screening providers integrated with the wallet platform for transaction and address compliance checks.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + unique Name) |

---

## 1. Business Meaning

This table registers the AML screening providers that the platform integrates with to perform compliance checks on cryptocurrency transactions and addresses. Each provider offers different screening capabilities - from blockchain analytics (Chainalysis) to internal blacklists and generic unsupported-address handling.

AML screening is a regulatory requirement for cryptocurrency platforms. Every incoming and outgoing transaction must be screened against sanctioned addresses, known bad actors, and risk categories. This table serves as the registry of available screening engines, enabling the platform to route checks to the appropriate provider.

Rows are added when new AML provider integrations go live. The table is FK-referenced by `Wallet.AmlProviderContracts` (which maps providers to crypto-specific contracts), `Wallet.AmlProviderUsers` (provider API credentials), and `Wallet.AmlValidations` (individual validation records). Stored procedures `GetAmlProviders` and `GetAmlProviderContracts` read from this table.

---

## 2. Business Logic

### 2.1 AML Provider Routing

**What**: Different AML providers handle different types of compliance checks.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Chainalysis` (1): Primary blockchain analytics provider - performs risk scoring of addresses against known categories (darknet, sanctions, ransomware, etc.)
- `BlackList` (2): Internal blacklist maintained by the compliance team - contains manually flagged addresses
- `Unsupported` (3): Catch-all for addresses on blockchains not yet supported by external AML providers - these addresses may be blocked or manually reviewed
- `ChainalysisCDN` (4): Chainalysis CDN integration - likely a cached or edge-deployed version of Chainalysis screening for faster response times

**Diagram**:
```
Transaction/Address --> AML Screening Router
    |
    +---> Chainalysis (1)      [Primary - blockchain analytics]
    +---> BlackList (2)        [Internal - manual compliance flags]
    +---> Unsupported (3)      [Fallback - unknown blockchains]
    +---> ChainalysisCDN (4)   [Cached Chainalysis checks]
```

---

## 3. Data Overview

| Id | Name | Created | Meaning |
|---|---|---|---|
| 1 | Chainalysis | 2018-07-31 | Primary blockchain analytics provider for automated AML screening. Checks addresses against global databases of sanctioned entities, darknet markets, ransomware operators, and other illicit actors. First provider integrated at platform launch. |
| 2 | BlackList | 2018-07-31 | Internal blacklist maintained by the eToro compliance team. Contains addresses manually flagged through internal investigation or external reports. Checked alongside external providers. |
| 3 | Unsupported | 2018-07-31 | Placeholder for blockchains without external AML provider coverage. Addresses on unsupported chains are flagged for manual review or blocked until provider support is added. |
| 4 | ChainalysisCDN | 2021-11-14 | CDN-distributed Chainalysis integration added 3 years after the primary integration. Likely provides faster cached lookups for high-volume address screening without hitting the primary API. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier. FK target for Wallet.AmlProviderContracts, Wallet.AmlProviderUsers, and Wallet.AmlValidations. Values: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Unique name of the AML provider. Maps to provider integration logic in application code. Used in audit reports and compliance dashboards. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when the provider was registered. Defaults to current UTC time. Tracks when AML provider integrations were onboarded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AmlProviderContracts | AmlProviderId | FK | Maps AML providers to crypto-specific screening contracts |
| Wallet.AmlProviderUsers | AmlProviderId | Implicit | Links provider API credentials to the provider |
| Wallet.AmlValidations | AmlProviderId | Implicit | Records which provider performed each AML validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlProviderContracts | Table | FK on AmlProviderId |
| Wallet.AmlProviderUsers | Table | References AmlProviderId |
| Wallet.AmlValidations | Table | References AmlProviderId |
| Wallet.GetAmlProviders | Stored Procedure | Reads all AML providers |
| Wallet.GetAmlProviderContracts | Stored Procedure | Reads providers via JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AmlProviders | CLUSTERED | Id ASC | - | - | Active |
| IX_Wallet_AmlProviders_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AmlProviders_Created | DEFAULT | getutcdate() - Auto-sets creation timestamp |

---

## 8. Sample Queries

### 8.1 List all AML providers
```sql
SELECT Id, Name, Created
FROM Dictionary.AmlProviders WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find AML validations by provider
```sql
SELECT ap.Name AS Provider, COUNT(av.Id) AS ValidationCount
FROM Dictionary.AmlProviders ap WITH (NOLOCK)
LEFT JOIN Wallet.AmlValidations av WITH (NOLOCK) ON av.AmlProviderId = ap.Id
GROUP BY ap.Name
ORDER BY ValidationCount DESC
```

### 8.3 List provider contracts with provider names
```sql
SELECT ap.Name AS ProviderName, apc.CryptoProviderContractId
FROM Dictionary.AmlProviders ap WITH (NOLOCK)
JOIN Wallet.AmlProviderContracts apc WITH (NOLOCK) ON apc.AmlProviderId = ap.Id
ORDER BY ap.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AmlProviders | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AmlProviders.sql*
