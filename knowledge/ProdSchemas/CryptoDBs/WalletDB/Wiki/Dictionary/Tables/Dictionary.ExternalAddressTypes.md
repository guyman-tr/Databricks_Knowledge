# Dictionary.ExternalAddressTypes

> Lookup table defining the types of external (eToro-controlled) cryptocurrency addresses used for platform operations like omnibus money-out, user withdrawals, and crypto-to-fiat conversions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies the types of external addresses that eToro operates for its own platform purposes (as opposed to customer wallet addresses). These are the platform's operational addresses used for different categories of outbound cryptocurrency transactions.

Each external address type serves a distinct operational purpose. Omnibus addresses handle bulk withdrawals, user money-out addresses handle individual customer withdrawals, crypto-to-fiat addresses handle conversion exits, and crypto-to-position addresses handle the transfer of crypto into trading positions.

The table is FK-referenced by `Wallet.EtoroExternalAddresses` and consumed by stored procedures that insert manual-out transactions.

---

## 2. Business Logic

### 2.1 Platform Operational Address Categories

**What**: Four categories of platform-operated external addresses.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `OmnibusMoneyOut` (1): Addresses used for bulk/omnibus withdrawal operations. Multiple customer withdrawals may be batched into a single blockchain transaction from these addresses for gas efficiency.
- `UserMoneyOut` (2): Addresses used for individual customer cryptocurrency withdrawals. Each withdrawal is a separate blockchain transaction from these addresses.
- `CryptoToFiat` (3): Addresses used when customers convert crypto holdings to fiat currency. Crypto is sent to these addresses as part of the off-ramp process.
- `CryptoToPosition` (4): Addresses used when crypto is converted into a trading position. Added in Dec 2025, supporting the crypto-to-position product feature.

---

## 3. Data Overview

| Id | Name | Created | Meaning |
|---|---|---|---|
| 1 | OmnibusMoneyOut | 2022-12-27 | Platform addresses for batched withdrawal operations. Multiple customer withdrawals are aggregated and sent from these addresses in a single blockchain transaction, reducing per-transaction gas costs. |
| 2 | UserMoneyOut | 2022-12-27 | Platform addresses for individual customer withdrawals. Each customer withdrawal is processed as a separate transaction from these addresses. |
| 3 | CryptoToFiat | 2022-12-27 | Platform addresses for crypto-to-fiat off-ramp operations. When a customer sells crypto for fiat, the crypto is transferred to these addresses before being liquidated. |
| 4 | CryptoToPosition | 2025-12-08 | Platform addresses for converting crypto holdings into trading positions. Added nearly 3 years after the initial three types, supporting a newer product feature. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the external address type. Values: 1=OmnibusMoneyOut, 2=UserMoneyOut, 3=CryptoToFiat, 4=CryptoToPosition. FK target for Wallet.EtoroExternalAddresses.ExternalAddressTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Descriptive label for the address category. Used in operational dashboards and transaction routing logic. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when the address type was registered. Types 1-3 created together (2022-12-27), type 4 added later (2025-12-08). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.EtoroExternalAddresses | ExternalAddressTypeId | FK | Classifies each platform-operated external address |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | FK on ExternalAddressTypeId |
| Wallet.InsertUserManualOutTransaction | Stored Procedure | References external address types for manual-out routing |
| Wallet.InsertOmnibusManualOutTransaction | Stored Procedure | References external address types for omnibus-out routing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExternalAddressTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (unnamed) | DEFAULT | getutcdate() for Created column |

---

## 8. Sample Queries

### 8.1 List all external address types
```sql
SELECT Id, Name, Created FROM Dictionary.ExternalAddressTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count external addresses by type
```sql
SELECT eat.Name, COUNT(eea.Id) AS AddressCount
FROM Dictionary.ExternalAddressTypes eat WITH (NOLOCK)
LEFT JOIN Wallet.EtoroExternalAddresses eea WITH (NOLOCK) ON eea.ExternalAddressTypeId = eat.Id
GROUP BY eat.Name ORDER BY eat.Name
```

### 8.3 List external addresses with type names
```sql
SELECT eea.Id, eea.Address, eat.Name AS AddressType
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
JOIN Dictionary.ExternalAddressTypes eat WITH (NOLOCK) ON eea.ExternalAddressTypeId = eat.Id
ORDER BY eat.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ExternalAddressTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ExternalAddressTypes.sql*
