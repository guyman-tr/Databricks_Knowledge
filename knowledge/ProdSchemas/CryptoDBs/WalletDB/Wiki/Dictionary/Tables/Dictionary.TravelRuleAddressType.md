# Dictionary.TravelRuleAddressType

> Lookup table defining whether a cryptocurrency address is private (self-hosted) or hosted by an exchange/custodian, as required by travel rule compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies cryptocurrency addresses into two categories required by travel rule regulations: private (self-hosted wallets controlled directly by the user) and hosted (wallets managed by an exchange or custodian with KYC). This classification determines the compliance obligations when sending crypto to the address.

FK-referenced by `Wallet.TravelRuleAddresses`. Consumed by travel rule SPs.

---

## 2. Business Logic

### 2.1 Address Hosting Classification

**What**: Two categories determining travel rule compliance requirements.

**Rules**:
- `Private` (1): Self-hosted wallet (hardware wallet, software wallet). Customer controls their own keys. Higher compliance burden - may require address ownership proof.
- `Hosted` (2): Exchange or custodian-managed wallet. The hosting entity has KYC on the recipient. Lower compliance burden - the host can provide recipient information.

---

## 3. Data Overview

| Id | Name | Created | Meaning |
|---|---|---|---|
| 1 | Private | 2022-07-24 | Self-hosted/non-custodial wallet address. The customer directly controls the private keys. Travel rule requires additional verification (ownership proof, declaration) before sending. |
| 2 | Hosted | 2022-07-24 | Exchange or custodian-managed wallet. A regulated entity holds the keys. Travel rule information can be exchanged between the sending and receiving institutions (VASP-to-VASP). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1=Private, 2=Hosted. FK target for Wallet.TravelRuleAddresses. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Address hosting type label. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Registration timestamp. Both types created 2022-07-24 when travel rule support was implemented. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.TravelRuleAddresses | TravelRuleAddressTypeId | FK | Classifies each address in the travel rule system |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TravelRuleAddresses | Table | FK |
| Wallet.GetTravelRuleAddress | Stored Procedure | Reads address type |
| Wallet.AddTravelRuleAddress | Stored Procedure | Sets address type on creation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TravelRuleAddressType | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (unnamed) | DEFAULT | getutcdate() for Created |

---

## 8. Sample Queries

### 8.1 List travel rule address types
```sql
SELECT Id, Name, Created FROM Dictionary.TravelRuleAddressType WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count addresses by hosting type
```sql
SELECT tra_type.Name, COUNT(tra.Id) AS Count
FROM Dictionary.TravelRuleAddressType tra_type WITH (NOLOCK)
LEFT JOIN Wallet.TravelRuleAddresses tra WITH (NOLOCK) ON tra.TravelRuleAddressTypeId = tra_type.Id
GROUP BY tra_type.Name
```

### 8.3 Private addresses (higher compliance burden)
```sql
SELECT tra.Id, tra.Address, tra_type.Name AS HostingType
FROM Wallet.TravelRuleAddresses tra WITH (NOLOCK)
JOIN Dictionary.TravelRuleAddressType tra_type WITH (NOLOCK) ON tra.TravelRuleAddressTypeId = tra_type.Id
WHERE tra_type.Id = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TravelRuleAddressType | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TravelRuleAddressType.sql*
