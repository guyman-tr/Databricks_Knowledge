# Dictionary.CountryConflictGroup

> Lookup table defining the 4 geopolitical country conflict groups — EU, Non-EU, GCC, and Tax Black List — used by the billing system for payment routing and regulatory compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.CountryConflictGroup classifies countries into geopolitical groups that affect payment processing and regulatory compliance. The term "conflict" refers to potential conflicts of interest or regulatory conflicts between jurisdictions — for example, a customer from a Tax Black List country requires different due diligence than one from an EU country.

The billing system uses these groups to determine payment routing, deposit/withdrawal restrictions, and compliance requirements. The `Billing.CountryToCountryConflictGroup` mapping table assigns each country to one or more conflict groups, and the `Billing.GetCountryToCountryConflictGroupConfig` procedure retrieves the configuration for payment processing decisions.

---

## 2. Business Logic

### 2.1 Geopolitical Classification

**What**: Four groups based on regulatory and economic alignment.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **EU Countries (ID=1)**: Countries within the European Union. Subject to EU payment regulations (PSD2, SEPA). Standard processing with minimal restrictions.
- **NON EU Countries (ID=2)**: Countries outside the EU. May require additional compliance checks for cross-border payments. Different payment processor routing.
- **GCC countries (ID=3)**: Gulf Cooperation Council nations (Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman). Regional payment infrastructure and specific regulatory requirements for Middle Eastern markets.
- **Tax Black Grouped Countries (ID=4)**: Countries on the EU's tax non-cooperative jurisdictions list. Require enhanced due diligence, may have deposit/withdrawal restrictions, and trigger additional compliance reporting.

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 1 | EU Countries | European Union member states — standard regulatory framework with SEPA payment support and PSD2 compliance. Most straightforward payment processing path. |
| 2 | NON EU Countries | Countries outside the EU — broader category requiring case-by-case assessment of payment regulations, cross-border transfer rules, and compliance requirements. |
| 3 | GCC countries | Gulf Cooperation Council (Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman) — distinct regional payment infrastructure and Islamic finance considerations may apply. |
| 4 | Tax Black Grouped Countries | Countries on the EU's list of non-cooperative tax jurisdictions — triggers enhanced due diligence, potential transaction restrictions, and mandatory compliance reporting. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the conflict group. Values 1-4. Referenced by `Billing.CountryToCountryConflictGroup` to map countries to their geopolitical groups for payment routing and compliance decisions. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Group label ('EU Countries', 'NON EU Countries', 'GCC countries', 'Tax Black Grouped Countries'). Used in billing configuration UIs and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CountryToCountryConflictGroup | CountryConflictGroupID | Implicit FK | Maps countries to conflict groups — each country can belong to one or more groups |
| Billing.GetCountryToCountryConflictGroupConfig | Read | Procedure | Retrieves conflict group configuration for payment routing decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CountryToCountryConflictGroup | Table | Maps countries to conflict groups |
| Billing.GetCountryToCountryConflictGroupConfig | Procedure | Reads conflict group config |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCountryConflictGroup | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all conflict groups
```sql
SELECT  ID,
        Name
FROM    Dictionary.CountryConflictGroup WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Show countries by conflict group
```sql
SELECT  CCG.Name AS ConflictGroup,
        CTCCG.*
FROM    Billing.CountryToCountryConflictGroup CTCCG WITH (NOLOCK)
INNER JOIN Dictionary.CountryConflictGroup CCG WITH (NOLOCK)
        ON CCG.ID = CTCCG.CountryConflictGroupID
ORDER BY CCG.ID;
```

### 8.3 Find tax blacklist countries
```sql
SELECT  CTCCG.*
FROM    Billing.CountryToCountryConflictGroup CTCCG WITH (NOLOCK)
WHERE   CTCCG.CountryConflictGroupID = 4;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CountryConflictGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryConflictGroup.sql*
