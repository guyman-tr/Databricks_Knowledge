# AffiliateCommission.CreditIDChargeBackID

> Mapping table linking Credit IDs to their corresponding chargeback IDs in the legacy affiliate system, enabling cross-system reconciliation of payment reversals.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

CreditIDChargeBackID maps credit events in the new commission system to their corresponding chargeback records in the legacy affiliate system (dbo.tblaff_Chargebacks). When a deposit is reversed (chargeback), both the new system creates a Credit record (CreditTypeID 4 or 5) and the legacy system creates a chargeback record. This table bridges the two for reconciliation and backward compatibility.

The table has 2,521 rows, closely matching the Credit table's chargeback count (2,438 type 4 + 8,038 type 5 = 10,476 total chargebacks). The lower mapping count suggests not all chargebacks need legacy system mapping, or that mapping was introduced after some chargebacks were processed.

---

## 2. Business Logic

No complex business logic. Pure ID mapping for cross-system reconciliation.

---

## 3. Data Overview

| CreditID | ChargeBackID | Meaning |
|---|---|---|
| 2154339199 | 7050 | Maps new-system credit 2154339199 to legacy chargeback 7050. |
| 2154339180 | 7049 | Sequential IDs suggest batch processing. |
| 2154339179 | 7048 | Continuous sequence of chargeback mappings. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Credit event ID. PK. References Credit.CreditID for chargeback-type credits. |
| 2 | ChargeBackID | int | YES | - | CODE-BACKED | Legacy chargeback record ID. References dbo.tblaff_Chargebacks. Nullable for edge cases. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | AffiliateCommission.Credit | Implicit FK | New-system credit record |
| ChargeBackID | dbo.tblaff_Chargebacks | Implicit FK | Legacy chargeback record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditIDChargeBackID (table)
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
| PK_AffiliateCommissionCreditIDChargeBackID | CLUSTERED PK | CreditID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateCommissionCreditIDChargeBackID | PRIMARY KEY | Unique CreditID |

---

## 8. Sample Queries

### 8.1 Look up chargeback by credit
```sql
SELECT ChargeBackID FROM AffiliateCommission.CreditIDChargeBackID WITH (NOLOCK) WHERE CreditID = 2154339199;
```

### 8.2 Join with Credit for full chargeback context
```sql
SELECT m.CreditID, m.ChargeBackID, c.CreditDate, c.Amount, c.CreditTypeID, c.CID
FROM AffiliateCommission.CreditIDChargeBackID m WITH (NOLOCK)
JOIN AffiliateCommission.Credit c WITH (NOLOCK) ON m.CreditID = c.CreditID
ORDER BY m.CreditID DESC;
```

### 8.3 Credits without chargeback mapping
```sql
SELECT c.CreditID, c.CreditDate, c.Amount
FROM AffiliateCommission.Credit c WITH (NOLOCK)
LEFT JOIN AffiliateCommission.CreditIDChargeBackID m WITH (NOLOCK) ON c.CreditID = m.CreditID
WHERE c.CreditTypeID IN (4, 5) AND m.CreditID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditIDChargeBackID | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CreditIDChargeBackID.sql*
