# Dictionary.RiskCountryPairs

> Mapping table with 725 conflicting country pairs — identifying geopolitically sensitive country combinations that trigger enhanced risk scrutiny when a customer's nationality/residence conflicts with deposit or trading activity origins.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (CountryID, ConflictingCountryID) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RiskCountryPairs identifies pairs of countries that are considered "conflicting" from a compliance and risk perspective. When a customer registered in Country A has financial activity (deposits, withdrawals, or IP connections) originating from Country B, and (A, B) is a conflicting pair, the system triggers enhanced risk review.

This supports AML/KYC compliance requirements where certain geopolitical relationships indicate elevated risk — for example, a customer in one country making transactions from a sanctioned or high-risk jurisdiction.

The data shows most countries are paired with CountryIDs 210 and 219 (likely representing sanctioned jurisdictions), while specific bilateral conflicts exist (e.g., Country 3 ↔ 74, Country 9 ↔ 43, Country 12 ↔ 13/38/196). Contains 725 pairs across nearly all countries.

Managed via SQL_RoutingTool user permissions.

---

## 2. Business Logic

### 2.1 Conflicting Country Detection

**What**: Each row declares that two countries form a risk-relevant conflicting pair.

**Columns/Parameters Involved**: `CountryID`, `ConflictingCountryID`

**Rules**:
- Pairs are NOT symmetric — (A, B) existing does NOT imply (B, A) exists.
- Most countries are paired with IDs 210 and 219, suggesting these are universally flagged jurisdictions (likely sanctioned countries).
- Some countries have specific bilateral conflicts (e.g., Country 12/Australia has conflicts with 13, 38, 196).
- The presence of a pair triggers enhanced review in compliance workflows.
- 725 total pairs, covering most Dictionary.Country entries.

---

## 3. Data Overview

| CountryID | ConflictingCountryID | Meaning |
|---|---|---|
| 1 | 210 | Country 1 conflicts with Country 210 (likely sanctioned jurisdiction) |
| 1 | 219 | Country 1 conflicts with Country 219 (likely sanctioned jurisdiction) |
| 9 | 43 | Specific bilateral conflict (Country 9 ↔ 43) |
| 12 | 13 | Australia ↔ Country 13 (bilateral risk pair) |
| 12 | 38 | Australia ↔ Canada (bilateral risk pair) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Part of composite PK. The customer's country of registration/residence. References Dictionary.Country (implicit). |
| 2 | ConflictingCountryID | int | NO | - | VERIFIED | Part of composite PK. The conflicting country that triggers enhanced risk review when detected in the customer's financial activity. References Dictionary.Country (implicit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.Country | CountryID | Implicit | Customer's registration country |
| Dictionary.Country | ConflictingCountryID | Implicit | Conflicting country |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers. Managed by compliance tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Dictionary.Country implicitly (both columns).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit — both CountryID and ConflictingCountryID |

### 6.2 Objects That Depend On This

No known SQL dependents. Managed via SQL_RoutingTool permissions.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryRiskCountryPairs | CLUSTERED PK | CountryID ASC, ConflictingCountryID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryRiskCountryPairs | PRIMARY KEY | Unique country pair combination |

---

## 8. Sample Queries

### 8.1 Find conflicting countries for a specific country
```sql
SELECT  c.Name AS ConflictingCountry
FROM    [Dictionary].[RiskCountryPairs] rcp WITH (NOLOCK)
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON rcp.ConflictingCountryID = c.CountryID
WHERE   rcp.CountryID = 12
ORDER BY c.Name;
```

### 8.2 Count conflicts per country
```sql
SELECT  c.Name AS CountryName,
        COUNT(*) AS ConflictCount
FROM    [Dictionary].[RiskCountryPairs] rcp WITH (NOLOCK)
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON rcp.CountryID = c.CountryID
GROUP BY c.Name
ORDER BY ConflictCount DESC;
```

### 8.3 Find most commonly flagged conflicting countries
```sql
SELECT  c.Name AS ConflictingCountry,
        COUNT(*) AS TimesConflicting
FROM    [Dictionary].[RiskCountryPairs] rcp WITH (NOLOCK)
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON rcp.ConflictingCountryID = c.CountryID
GROUP BY c.Name
ORDER BY TimesConflicting DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RiskCountryPairs | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskCountryPairs.sql*
