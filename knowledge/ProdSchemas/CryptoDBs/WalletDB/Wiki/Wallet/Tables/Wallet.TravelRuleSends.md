# Wallet.TravelRuleSends

> Links outbound send transactions to their Travel Rule whitelisted address records, tracking which compliance-approved address was used for each send operation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table links each outbound send transaction to the Travel Rule address record that was used. When a user sends crypto, the system records which whitelisted address from `Wallet.TravelRuleAddresses` was the destination, along with the wallet and correlation ID. This provides the compliance audit trail proving that each send used a properly whitelisted and compliant address.

---

## 2. Business Logic

No complex logic. Junction/audit table linking sends to whitelisted addresses.

---

## 3. Data Overview

N/A for compliance junction table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | Source wallet that performed the send. FK to Wallet.WalletPool.WalletId. |
| 3 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent send request. |
| 4 | TravelRuleAddressId | bigint | NO | - | VERIFIED | The whitelisted address used for this send. FK to Wallet.TravelRuleAddresses.Id. |
| 5 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this send-address linkage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.WalletPool | FK | Source wallet |
| TravelRuleAddressId | Wallet.TravelRuleAddresses | FK | Whitelisted destination address |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddTravelRuleSend | - | Writer | Creates linkage records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TravelRuleSends (table)
├── Wallet.WalletPool (table)
└── Wallet.TravelRuleAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK target for WalletId |
| Wallet.TravelRuleAddresses | Table | FK target for TravelRuleAddressId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddTravelRuleSend | Stored Procedure | Creates records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TravelRuleSends | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...CorrelationId | NC | CorrelationId | - | - | Active |
| IX_...WalletId_Created | NC | WalletId, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Created) | DEFAULT | getutcdate() |
| FK_...TravelRuleAddressId | FK | -> Wallet.TravelRuleAddresses.Id |
| FK_...WalletId | FK | -> Wallet.WalletPool.WalletId |

---

## 8. Sample Queries

### 8.1 Get sends with their travel rule addresses
```sql
SELECT trs.CorrelationId, tra.ToAddress, trat.Name AS AddressType, trs.Created
FROM Wallet.TravelRuleSends trs WITH (NOLOCK)
JOIN Wallet.TravelRuleAddresses tra WITH (NOLOCK) ON trs.TravelRuleAddressId = tra.Id
JOIN Dictionary.TravelRuleAddressType trat WITH (NOLOCK) ON tra.TravelRuleAddressTypeId = trat.Id
WHERE trs.WalletId = '0E06BADB-7A8B-453A-82EB-34A465284F37'
ORDER BY trs.Created DESC
```

### 8.2 Recent travel rule sends
```sql
SELECT TOP 20 Id, WalletId, TravelRuleAddressId, Created
FROM Wallet.TravelRuleSends WITH (NOLOCK) ORDER BY Created DESC
```

### 8.3 Send volume per address
```sql
SELECT TravelRuleAddressId, COUNT(*) AS SendCount
FROM Wallet.TravelRuleSends WITH (NOLOCK)
GROUP BY TravelRuleAddressId ORDER BY SendCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TravelRuleSends | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TravelRuleSends.sql*
