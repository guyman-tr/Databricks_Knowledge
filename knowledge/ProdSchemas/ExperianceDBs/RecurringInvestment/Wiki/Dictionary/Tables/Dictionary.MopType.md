# Dictionary.MopType

> Lookup table defining Method of Payment types used for recurring investment deposits.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table defines the Method of Payment (MOP) types available for recurring investment deposit collection. MOP determines how funds are collected for the recurring plan - for example, credit card, bank transfer, or other payment methods supported by the Money Group's billing infrastructure.

Without this table, the system could not classify payment methods, which is needed for payment routing, MOP-specific business rules (e.g., some blacklists are filtered by MOP type), and for the Before Deposit Job which checks eligibility by MOP type.

The Plans table defaults MopType to 1 (the primary payment method). Several stored procedures filter by MOP type, including PlansGetLastDepositFailedBeforeNextDepositByMopType and PlanInstanceGetPlanInstancesBeforeDepositByMopTypes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple lookup for payment method classification.

---

## 3. Data Overview

Table is currently empty (0 rows). MOP type values may be maintained externally in the Money Group's billing system or in application configuration. The Plans table defaults MopType to 1, confirming at least one value exists in practice.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique numeric identifier for the method of payment type. Plans.MopType defaults to 1. See [MOP Type](../../_glossary.md#mop-type). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label describing the payment method type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.Plans | MopType | Implicit Lookup | Classifies the payment method used for the plan's recurring deposits |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | MopType column (defaults to 1) references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MopType | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all MOP types
```sql
SELECT ID, Name
FROM [Dictionary].[MopType] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count plans by MOP type
```sql
SELECT p.MopType, mt.Name, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
LEFT JOIN [Dictionary].[MopType] mt WITH (NOLOCK) ON p.MopType = mt.ID
GROUP BY p.MopType, mt.Name
ORDER BY p.MopType
```

### 8.3 Find last deposit failures by MOP type
```sql
SELECT p.MopType, mt.Name, p.ID AS PlanID, p.GCID, pi.HighLevelDepositStatusId
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
LEFT JOIN [Dictionary].[MopType] mt WITH (NOLOCK) ON p.MopType = mt.ID
JOIN [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK) ON p.ID = pi.PlanID
WHERE pi.HighLevelDepositStatusId IN (2, 3)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table includes MopType; deposit processing managed by Money Group |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MopType | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.MopType.sql*
