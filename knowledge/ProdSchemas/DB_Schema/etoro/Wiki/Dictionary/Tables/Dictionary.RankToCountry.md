# Dictionary.RankToCountry

> Mapping table assigning countries to 3 risk/KYC ranks — used by Billing.GetCountryAndRank to determine deposit and withdrawal restrictions based on country risk tier.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Composite (RankID, CountryID) — no PK defined |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Dictionary.RankToCountry classifies every country into one of 3 risk ranks that determine deposit and withdrawal rules. This is a key compliance/KYC table that drives payment restrictions based on the customer's country of registration.

- **Rank 1** (34 countries) — Tier-1 regulated markets (US, UK, Germany, Australia, major EU countries). Highest trust level.
- **Rank 2** (20 countries) — Emerging/secondary markets with moderate KYC requirements.
- **Rank 3** (~200 countries) — All remaining countries including a "catch-all" CountryID=0. Higher restrictions.

The table is consumed by Billing.GetCountryAndRank, which looks up the rank for a given country to apply the appropriate deposit/withdrawal rules via Dictionary.RankToCountryConfiguration.

---

## 2. Business Logic

### 2.1 Country Risk Tiering

**What**: Each country is assigned to exactly one rank that determines its KYC/payment treatment.

**Columns/Parameters Involved**: `RankID`, `CountryID`

**Rules**:
- **Rank 1** — Major regulated markets: USA (218), UK (244), Germany (233), France (185), Australia (12), Netherlands (19), Spain (82), Italy (94), etc.
- **Rank 2** — Secondary markets: Austria (14), Canada (38), China (43), South Korea (132), etc.
- **Rank 3** — All other countries. CountryID=0 is included as a catch-all/default.
- No PK or unique constraint — the table relies on data integrity at the application level.
- The rank drives Dictionary.RankToCountryConfiguration to determine allowed withdrawal country ranges and deposit requirements.

**Diagram**:
```
Country Risk Ranks
├── Rank 1 (34 countries) — Tier-1 regulated (US, UK, DE, AU, FR, ...)
├── Rank 2 (20 countries) — Secondary markets (AT, CA, CN, KR, ...)
└── Rank 3 (~200 countries) — All others + catch-all (ID=0)
```

---

## 3. Data Overview

| RankID | CountryID | Meaning |
|---|---|---|
| 1 | 218 | United States — Rank 1 (highest trust) |
| 1 | 244 | United Kingdom — Rank 1 |
| 1 | 233 | Germany — Rank 1 |
| 2 | 43 | China — Rank 2 (moderate) |
| 3 | 0 | Catch-all default — Rank 3 (most restrictive) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RankID | int | NO | - | VERIFIED | Risk rank tier (1, 2, or 3). Lower number = higher trust level. Used by Billing.GetCountryAndRank to look up payment rules. |
| 2 | CountryID | int | NO | - | VERIFIED | References Dictionary.Country. 0=catch-all default for unlisted countries. Each country appears exactly once. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.Country | CountryID | Implicit | Country being ranked |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Dictionary.Country implicitly.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit — country reference |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCountryAndRank | Stored Procedure | Reader — looks up country rank for payment rules |
| Dictionary.RankToCountryConfiguration | Table | Uses RankID to define deposit/withdrawal rules |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. This is a heap table.

### 7.2 Constraints

No constraints defined. No PK, no FK.

---

## 8. Sample Queries

### 8.1 List countries by rank
```sql
SELECT  r.RankID,
        c.Name AS CountryName,
        r.CountryID
FROM    [Dictionary].[RankToCountry] r WITH (NOLOCK)
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON r.CountryID = c.CountryID
ORDER BY r.RankID, c.Name;
```

### 8.2 Count countries per rank
```sql
SELECT  RankID,
        COUNT(*) AS CountryCount
FROM    [Dictionary].[RankToCountry] WITH (NOLOCK)
GROUP BY RankID
ORDER BY RankID;
```

### 8.3 Find the rank for a specific country
```sql
SELECT  RankID
FROM    [Dictionary].[RankToCountry] WITH (NOLOCK)
WHERE   CountryID = 218;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RankToCountry | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RankToCountry.sql*
