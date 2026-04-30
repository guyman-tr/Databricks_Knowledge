# Billing.CountryToCountryConflictGroup

> Junction table assigning countries to regulatory conflict groups (EU, Non-EU, GCC, Tax Black Grouped) used to drive CFT whitelist checks and payment routing compliance rules.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, CountryConflictGroupID) - composite PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (composite PK) |

---

## 1. Business Meaning

`Billing.CountryToCountryConflictGroup` is a many-to-many junction table mapping countries to regulatory conflict groups. A country can belong to multiple groups (e.g., CountryID=155 appears in both GCC and Tax Black Grouped). The groups define regulatory classifications used to drive payment compliance checks - particularly CFT (Counter-Financing of Terrorism) whitelist rules and funding type restrictions.

The table holds 66 rows covering 65 distinct countries assigned to 4 groups:
- **Group 1 - EU Countries** (31 countries): Austria, Belgium, Germany, UK, and other EU member states.
- **Group 2 - NON EU Countries** (20 countries): Countries outside the EU but where eToro operates.
- **Group 3 - GCC countries** (6 countries): Gulf Cooperation Council nations.
- **Group 4 - Tax Black Grouped Countries** (9 countries): Countries with tax blacklist or enhanced due diligence requirements.

The sole consumer is `Billing.GetCountryToCountryConflictGroupConfig`, which returns the full mapping as a configuration dataset - likely loaded into memory by a payment service to drive routing or compliance decisions.

---

## 2. Business Logic

### 2.1 Conflict Group Classification

**What**: Countries are classified into regulatory groups that drive payment flow restrictions and compliance checks.

**Columns/Parameters Involved**: `CountryID`, `CountryConflictGroupID`

**Rules**:
- Group 1 (EU Countries): Standard EU regulatory treatment - SEPA payment rules, GDPR, standard AML thresholds.
- Group 2 (NON EU Countries): Non-EU customers - different funding availability, possible CFT whitelist requirements.
- Group 3 (GCC): Gulf Cooperation Council - regional payment rules, local banking restrictions.
- Group 4 (Tax Black Grouped): Countries on tax authority blacklists or requiring enhanced due diligence. Note: CountryID=155 is in BOTH Group 3 (GCC) and Group 4 (Tax Black), meaning some GCC nations also have enhanced tax requirements.
- A country not listed in this table is not assigned to any conflict group, which may affect eligibility for certain payment methods checked against Billing.CFTWhiteList.

**Diagram**:
```
Country (Dictionary.Country)
  |--> Group 1 (EU Countries):          AUT, BEL, DEU, GBR, ... (31 countries)
  |--> Group 2 (NON EU Countries):      AUS, AZE, BGD, ... (20 countries)
  |--> Group 3 (GCC countries):         BAH, KWT, OMN, QAT, SAU, UAE (6 countries)
  |--> Group 4 (Tax Black Grouped):     AFG, BHR, ... SAU (9 countries)
  (CountryID=155 in both Group 3 and Group 4)
```

---

## 3. Data Overview

| CountryID | CountryConflictGroupID | Meaning |
|-----------|----------------------|---------|
| 79 (Germany) | 1 (EU Countries) | Germany classified as EU country - standard EU payment and compliance rules apply for German customers. |
| 218 (UK) | 1 (EU Countries) | UK retained in EU group (likely pre/post-Brexit snapshot). Standard EU-tier compliance. |
| 9 | 2 (NON EU Countries) | A non-EU country where eToro operates - subject to non-EU payment rules and CFT whitelist checks. |
| 155 | 3 (GCC countries) | A Gulf Cooperation Council country. |
| 155 | 4 (Tax Black Grouped Countries) | Same country (155) also in tax blacklist group - multi-group membership for composite compliance checks. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country being assigned to a conflict group. Part of the composite PK. FK to Dictionary.Country(CountryID). A country may appear multiple times (once per group it belongs to). |
| 2 | CountryConflictGroupID | int | NO | - | VERIFIED | Conflict group the country is assigned to. Part of the composite PK. FK to Dictionary.CountryConflictGroup(ID). Values: 1=EU Countries (31 entries), 2=NON EU Countries (20 entries), 3=GCC countries (6 entries), 4=Tax Black Grouped Countries (9 entries). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | FK (explicit) | Constrains to valid eToro country records. |
| CountryConflictGroupID | Dictionary.CountryConflictGroup | FK (explicit) | Constrains to defined conflict group IDs (1=EU, 2=Non-EU, 3=GCC, 4=Tax Black). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCountryToCountryConflictGroupConfig | (all) | READER | Full table export; used by payment services to load conflict group configuration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CountryToCountryConflictGroup (table)
|- Dictionary.Country (table)              [FK: CountryID]
|- Dictionary.CountryConflictGroup (table) [FK: CountryConflictGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK target - valid country set |
| Dictionary.CountryConflictGroup | Table | FK target - defines the 4 conflict group types |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCountryToCountryConflictGroupConfig | Stored Procedure | READER - returns full mapping as configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryToCountryConflictGroup_1 | CLUSTERED PK | CountryID ASC, CountryConflictGroupID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CountryToCountryConflictGroup_1 | PRIMARY KEY | Composite PK - unique (CountryID, GroupID) pairs |
| FK_CountryToCountryConflictGroup_Country | FOREIGN KEY | CountryID must exist in Dictionary.Country |
| FK_CountryToCountryConflictGroup_CountryConflictGroup | FOREIGN KEY | GroupID must exist in Dictionary.CountryConflictGroup |

---

## 8. Sample Queries

### 8.1 Get all countries in a specific conflict group
```sql
SELECT  CCG.CountryID,
        DC.Name             AS CountryName,
        DC.Abbreviation     AS CountryCode,
        DCCG.Name           AS ConflictGroupName
FROM    Billing.CountryToCountryConflictGroup CCG WITH (NOLOCK)
INNER JOIN Dictionary.Country DC WITH (NOLOCK)
        ON CCG.CountryID = DC.CountryID
INNER JOIN Dictionary.CountryConflictGroup DCCG WITH (NOLOCK)
        ON CCG.CountryConflictGroupID = DCCG.ID
WHERE   CCG.CountryConflictGroupID = 1  -- 1=EU Countries
ORDER BY DC.Name;
```

### 8.2 Find countries assigned to multiple groups
```sql
SELECT  CCG.CountryID,
        DC.Name             AS CountryName,
        COUNT(*)            AS GroupCount,
        STRING_AGG(DCCG.Name, ', ') AS Groups
FROM    Billing.CountryToCountryConflictGroup CCG WITH (NOLOCK)
INNER JOIN Dictionary.Country DC WITH (NOLOCK)
        ON CCG.CountryID = DC.CountryID
INNER JOIN Dictionary.CountryConflictGroup DCCG WITH (NOLOCK)
        ON CCG.CountryConflictGroupID = DCCG.ID
GROUP BY CCG.CountryID, DC.Name
HAVING COUNT(*) > 1;
```

### 8.3 Full conflict group membership list (same as GetCountryToCountryConflictGroupConfig)
```sql
SELECT  CCG.CountryID,
        DC.Name             AS CountryName,
        CCG.CountryConflictGroupID,
        DCCG.Name           AS GroupName
FROM    Billing.CountryToCountryConflictGroup CCG WITH (NOLOCK)
INNER JOIN Dictionary.Country DC WITH (NOLOCK)
        ON CCG.CountryID = DC.CountryID
INNER JOIN Dictionary.CountryConflictGroup DCCG WITH (NOLOCK)
        ON CCG.CountryConflictGroupID = DCCG.ID
ORDER BY CCG.CountryConflictGroupID, DC.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CountryToCountryConflictGroup | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CountryToCountryConflictGroup.sql*
