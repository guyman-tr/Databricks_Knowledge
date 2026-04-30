# Dictionary.CountryEconomicType

> Lookup table defining the 3 economic/political classifications for countries — Unknown, EU (European Union), and EEA (European Economic Area).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.CountryEconomicType classifies countries by their relationship to European economic and political structures. This classification is important for regulatory compliance — EU and EEA membership determines which financial regulations apply (MiFID II, ESMA leverage restrictions, passporting rights), which payment corridors are available (SEPA), and what level of investor protection is required.

The three-value system distinguishes between EU member states (full EU regulation applies), EEA states (EU single market access but not full EU membership — includes Norway, Iceland, Liechtenstein), and Unknown/other (non-European countries where European regulations do not directly apply). This is referenced by the `Dictionary.Country` table to tag each country with its economic zone.

No FK references or procedure consumers were found in the SSDT project referencing this specific table, suggesting it is consumed via the Country table's economic type column or by application-layer code.

---

## 2. Business Logic

### 2.1 European Regulatory Classification

**What**: Three tiers of European economic zone membership.

**Columns/Parameters Involved**: `ID`, `Type`, `Meaning`

**Rules**:
- **Unknown (ID=0)**: Default/unclassified — country has no specific European economic zone designation. Applies to all non-European countries and any country not yet classified.
- **EU (ID=1)**: European Union member state — full EU financial regulation applies including MiFID II, ESMA, PSD2, and SEPA. Customers from EU countries get EU-regulated entity (eToro Europe) as their counterparty.
- **EEA (ID=2)**: European Economic Area member but not EU — includes Norway, Iceland, and Liechtenstein. These countries have EU single market access and most EU regulations apply, but with some differences in financial services regulation.

---

## 3. Data Overview

| ID | Type | Meaning |
|---|---|---|
| 0 | Unknown | Default classification for countries not in the European economic framework — includes all non-European countries and any unclassified entries. No specific European regulatory requirements apply. |
| 1 | EU | European Union member state — customers are subject to the strictest tier of European financial regulation. eToro must comply with MiFID II leverage limits, ESMA guidelines, and GDPR data protection for these customers. |
| 2 | EEA | European Economic Area (non-EU) — Norway, Iceland, Liechtenstein. Similar regulatory framework to EU but under the EEA Agreement rather than direct EU membership. Some differences in financial regulation implementation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the economic type. Values: 0=Unknown, 1=EU, 2=EEA. Used as a FK target by the country classification system. |
| 2 | Type | varchar(10) | NO | - | VERIFIED | Short code for the economic type ('Unknown', 'EU', 'EEA'). Used as a compact programmatic identifier in regulatory logic and configuration. |
| 3 | Meaning | varchar(50) | NO | - | VERIFIED | Full descriptive label ('Unknown', 'Europe Union', 'Europe Economic Area'). Human-readable explanation used in admin UIs and reports. Note: 'Europe Union' is a slight abbreviation of 'European Union'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No FK references found in the SSDT project. Likely consumed via the Country table's economic type column.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_CountryEconomicType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all economic types
```sql
SELECT  ID,
        Type,
        Meaning
FROM    Dictionary.CountryEconomicType WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find EU member states
```sql
SELECT  C.*
FROM    Dictionary.Country C WITH (NOLOCK)
WHERE   C.CountryEconomicTypeID = 1
ORDER BY C.Name;
```

### 8.3 Compare country counts by economic type
```sql
SELECT  CET.ID,
        CET.Type,
        CET.Meaning,
        COUNT(C.CountryID) AS CountryCount
FROM    Dictionary.CountryEconomicType CET WITH (NOLOCK)
LEFT JOIN Dictionary.Country C WITH (NOLOCK)
        ON C.CountryEconomicTypeID = CET.ID
GROUP BY CET.ID, CET.Type, CET.Meaning
ORDER BY CET.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CountryEconomicType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryEconomicType.sql*
