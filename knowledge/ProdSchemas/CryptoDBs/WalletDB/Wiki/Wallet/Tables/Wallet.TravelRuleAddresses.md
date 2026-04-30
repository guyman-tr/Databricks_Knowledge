# Wallet.TravelRuleAddresses

> Stores whitelisted external addresses for Travel Rule compliance, recording the beneficiary's address type (private/hosted), hosting company, and personal details with dynamic data masking for PII protection.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores addresses that customers have whitelisted for Travel Rule compliance. When a user wants to send crypto to an external address, they must declare whether the address is self-hosted (private wallet) or hosted by a VASP, and provide beneficiary information. This data is stored here and reused for subsequent sends to the same address, avoiding repeated data entry.

With only 89 rows, this is a small but compliance-critical table. PII fields (Name, Country, State, City, Address, Zipcode) use SQL Server Dynamic Data Masking to protect sensitive data from unauthorized queries. FK to Wallet.WalletPool links addresses to wallets, and Dictionary.TravelRuleAddressType classifies the address type.

---

## 2. Business Logic

### 2.1 PII Protection via Dynamic Data Masking

**What**: Personal beneficiary details are masked in query results for unauthorized users.

**Columns/Parameters Involved**: `Name`, `CountryAlpha3Code`, `State`, `City`, `Address`, `Zipcode`

**Rules**:
- All PII columns use MASKED WITH (FUNCTION = 'default()') - returns 'xxxx' for unauthorized users
- Only users with UNMASK permission see actual values
- Protects compliance-sensitive beneficiary information from accidental exposure

---

## 3. Data Overview

N/A for PII-containing compliance table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing PK. FK target for Wallet.TravelRuleSends. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | Customer wallet this address belongs to. FK to Wallet.WalletPool.WalletId. |
| 3 | ToAddress | nvarchar(512) | NO | - | CODE-BACKED | The whitelisted external blockchain address. |
| 4 | TravelRuleAddressTypeId | tinyint | NO | - | VERIFIED | Address type: 1=Private (self-hosted), 2=Hosted (VASP). See [Travel Rule Address Type](../../_glossary.md#travel-rule-address-type). FK to Dictionary.TravelRuleAddressType. |
| 5 | SelfAccount | bit | NO | - | CODE-BACKED | Whether the beneficiary is the same person as the sender: 1=self-transfer, 0=third-party transfer. Affects compliance requirements. |
| 6 | HostingCompany | varchar(255) | YES | - | CODE-BACKED | Name of the VASP hosting the destination address (from Wallet.HostingCompanies list). NULL for private/self-hosted addresses. |
| 7 | Name | nvarchar(255) | YES | - | CODE-BACKED | Beneficiary's full name. MASKED for PII protection. NULL for self-transfers. |
| 8 | CountryAlpha3Code | varchar(3) | YES | - | CODE-BACKED | Beneficiary's country (ISO 3166 alpha-3). MASKED. |
| 9 | State | varchar(255) | YES | - | CODE-BACKED | Beneficiary's state/province. MASKED. |
| 10 | City | nvarchar(255) | YES | - | CODE-BACKED | Beneficiary's city. MASKED. |
| 11 | Address | nvarchar(255) | YES | - | CODE-BACKED | Beneficiary's street address. MASKED. |
| 12 | Zipcode | nvarchar(20) | YES | - | CODE-BACKED | Beneficiary's postal code. MASKED. |
| 13 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this address was whitelisted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.WalletPool | FK | Customer's wallet |
| TravelRuleAddressTypeId | Dictionary.TravelRuleAddressType | FK | Private vs Hosted classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.TravelRuleSends | TravelRuleAddressId | FK | Links sends to whitelisted addresses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TravelRuleAddresses (table)
├── Wallet.WalletPool (table)
└── Dictionary.TravelRuleAddressType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK target for WalletId |
| Dictionary.TravelRuleAddressType | Table | FK target for TravelRuleAddressTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TravelRuleSends | Table | FK on TravelRuleAddressId |
| Wallet.AddTravelRuleAddress | Stored Procedure | Creates records |
| Wallet.GetTravelRuleAddress | Stored Procedure | Reads address details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TravelRuleAddresses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...ToAddress_Created | NC | ToAddress, Created DESC | - | - | Active |
| IX_...WalletId_ToAddress_Created | NC | WalletId, ToAddress, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Created) | DEFAULT | getutcdate() |
| FK_...WalletId | FK | -> Wallet.WalletPool.WalletId |
| FK_...TravelRuleAddressTypeId | FK | -> Dictionary.TravelRuleAddressType.Id |

---

## 8. Sample Queries

### 8.1 Get whitelisted addresses for a wallet
```sql
SELECT tra.ToAddress, trat.Name AS AddressType, tra.SelfAccount, tra.HostingCompany, tra.Created
FROM Wallet.TravelRuleAddresses tra WITH (NOLOCK)
JOIN Dictionary.TravelRuleAddressType trat WITH (NOLOCK) ON tra.TravelRuleAddressTypeId = trat.Id
WHERE tra.WalletId = '0E06BADB-7A8B-453A-82EB-34A465284F37'
ORDER BY tra.Created DESC
```

### 8.2 Count addresses by type
```sql
SELECT trat.Name AS AddressType, COUNT(*) AS Cnt
FROM Wallet.TravelRuleAddresses tra WITH (NOLOCK)
JOIN Dictionary.TravelRuleAddressType trat WITH (NOLOCK) ON tra.TravelRuleAddressTypeId = trat.Id
GROUP BY trat.Name
```

### 8.3 Self vs third-party transfers
```sql
SELECT SelfAccount, COUNT(*) AS Cnt FROM Wallet.TravelRuleAddresses WITH (NOLOCK) GROUP BY SelfAccount
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TravelRuleAddresses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TravelRuleAddresses.sql*
