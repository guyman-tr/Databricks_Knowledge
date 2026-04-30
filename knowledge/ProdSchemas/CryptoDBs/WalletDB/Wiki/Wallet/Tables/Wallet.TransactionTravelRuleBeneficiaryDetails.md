# Wallet.TransactionTravelRuleBeneficiaryDetails

> Stores beneficiary identity information for Travel Rule compliance, recording the recipient's name and detailed information submitted by the sender for qualifying cross-VASP transfers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 unique constraint + 1 clustered PK |

---

## 1. Business Meaning

This table stores the beneficiary (recipient) details required by Travel Rule regulations for qualifying crypto transfers. When a user sends crypto to an address hosted by another VASP, they must provide information about the beneficiary. Each row is linked 1:1 to a Travel Rule record via TravelRuleInformationId (unique constraint). The DetailsJson stores the full beneficiary information payload.

---

## 2. Business Logic

No complex logic. 1:1 extension of TransactionTravelRuleInformation with beneficiary details.

---

## 3. Data Overview

N/A for PII-containing compliance table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | TravelRuleInformationId | bigint | NO | - | VERIFIED | Parent Travel Rule record. FK to Wallet.TransactionTravelRuleInformation.Id. Unique constraint ensures 1:1 relationship. |
| 3 | BeneficiaryName | nvarchar(512) | YES | - | CODE-BACKED | Full name of the transfer beneficiary. May be NULL for self-transfers. |
| 4 | Created | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | Record creation timestamp. |
| 5 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | Full beneficiary details in JSON (address, date of birth, national ID, etc.). |
| 6 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links to the parent request. |
| 7 | TransactionType | nvarchar(50) | YES | - | CODE-BACKED | Type of transaction (e.g., "send", "receive"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TravelRuleInformationId | Wallet.TransactionTravelRuleInformation | FK | Parent Travel Rule record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddTravelRuleBeneficiaryDetails | - | Writer | Creates beneficiary records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TransactionTravelRuleBeneficiaryDetails (table)
└── Wallet.TransactionTravelRuleInformation (table)
      └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FK target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddTravelRuleBeneficiaryDetails | Stored Procedure | Creates records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionTravelRuleBeneficiaryDetails | CLUSTERED PK | Id ASC | - | - | Active |
| UQ_...TravelRuleInformationId | NC UNIQUE | TravelRuleInformationId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Created) | DEFAULT | sysutcdatetime() |
| FK_...TravelRuleInformationId | FK | -> Wallet.TransactionTravelRuleInformation.Id |

---

## 8. Sample Queries

### 8.1 Get beneficiary details for a Travel Rule record
```sql
SELECT BeneficiaryName, TransactionType, Created
FROM Wallet.TransactionTravelRuleBeneficiaryDetails WITH (NOLOCK)
WHERE TravelRuleInformationId = 33916
```

### 8.2 Recent beneficiary records
```sql
SELECT TOP 20 Id, TravelRuleInformationId, BeneficiaryName, TransactionType, Created
FROM Wallet.TransactionTravelRuleBeneficiaryDetails WITH (NOLOCK)
ORDER BY Created DESC
```

### 8.3 Count by transaction type
```sql
SELECT TransactionType, COUNT(*) AS Cnt
FROM Wallet.TransactionTravelRuleBeneficiaryDetails WITH (NOLOCK)
GROUP BY TransactionType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionTravelRuleBeneficiaryDetails | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TransactionTravelRuleBeneficiaryDetails.sql*
