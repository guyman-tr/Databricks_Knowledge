# AffiliateCommission.CreditIDDepositID

> Mapping table linking Credit IDs to their corresponding deposit IDs in the legacy affiliate system, enabling cross-system reconciliation of deposit-based commissions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only, PAGE compression) |

---

## 1. Business Meaning

CreditIDDepositID maps credit events in the new commission system to their corresponding deposit records in the legacy affiliate system (dbo.tblaff_Deposits). When a customer deposits money, both the new system creates a Credit record and the legacy system creates a deposit record. This table bridges the two for reconciliation and backward compatibility during the gradual migration.

The table has 935,477 rows, a subset of the 4.74 million deposits in Credit. This suggests the mapping was introduced during migration and only covers deposits that needed legacy system tracking (earlier deposits before full migration).

---

## 2. Business Logic

No complex business logic. Pure ID mapping for cross-system reconciliation.

---

## 3. Data Overview

| CreditID | DepositID | Meaning |
|---|---|---|
| 2154342609 | 1414186 | Maps new credit to legacy deposit. Sequential IDs. |
| 2154342608 | 1414185 | Continuous mapping sequence. |
| 2154342607 | 1414184 | 1:1 sequential mapping pattern. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Credit event ID. PK. References Credit.CreditID for deposit-type credits. |
| 2 | DepositID | int | YES | - | CODE-BACKED | Legacy deposit record ID. References dbo.tblaff_Deposits. Nullable for edge cases. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | AffiliateCommission.Credit | Implicit FK | New-system credit record |
| DepositID | dbo.tblaff_Deposits | Implicit FK | Legacy deposit record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditIDDepositID (table)
└── AffiliateCommission.Credit (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | CreditID references credit events |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateCommissionCreditIDDepositID | CLUSTERED PK | CreditID ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateCommissionCreditIDDepositID | PRIMARY KEY | Unique CreditID |

---

## 8. Sample Queries

### 8.1 Look up deposit by credit
```sql
SELECT DepositID FROM AffiliateCommission.CreditIDDepositID WITH (NOLOCK) WHERE CreditID = 2154342609;
```

### 8.2 Join with Credit for deposit context
```sql
SELECT m.CreditID, m.DepositID, c.CreditDate, c.Amount, c.IsFirstDeposit, c.CID
FROM AffiliateCommission.CreditIDDepositID m WITH (NOLOCK)
JOIN AffiliateCommission.Credit c WITH (NOLOCK) ON m.CreditID = c.CreditID
WHERE c.IsFirstDeposit = 1
ORDER BY m.CreditID DESC;
```

### 8.3 Deposits without legacy mapping
```sql
SELECT TOP 100 c.CreditID, c.CreditDate, c.Amount
FROM AffiliateCommission.Credit c WITH (NOLOCK)
LEFT JOIN AffiliateCommission.CreditIDDepositID m WITH (NOLOCK) ON c.CreditID = m.CreditID
WHERE c.CreditTypeID = 1 AND m.CreditID IS NULL
ORDER BY c.CreditID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditIDDepositID | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CreditIDDepositID.sql*
