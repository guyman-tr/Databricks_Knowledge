# Dictionary.State

> Reference table of states/provinces linked to countries for user address data. Contains 68 states with 2-character codes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StateID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.State stores states and provinces for user address fields during registration and KYC. Unlike Dictionary.RegionByIP (which is IP-derived), this table is used for user-declared address data. Each state has a 2-character code (e.g., "CA" for California) and belongs to one country.

This table is used in registration forms when a state/province dropdown is needed based on the user's country selection. It supports address verification and regulatory routing for jurisdictions that require state-level granularity.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

68 rows. States/provinces across multiple countries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StateID | int | NO | - | CODE-BACKED | Primary key. State identifier. |
| 2 | CountryID | int | NO | 0 | CODE-BACKED | FK to Dictionary.Country. The country this state belongs to. Default: 0. |
| 3 | Code | char(2) | YES | - | CODE-BACKED | 2-character state/province code (e.g., "CA", "NY", "NSW"). ISO 3166-2 subdivision codes. |
| 4 | Name | char(50) | NO | - | CODE-BACKED | Full state/province name. Padded char(50) type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Explicit FK | State belongs to this country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer address tables | StateID | Lookup | Stores user's state in their address |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.State (table)
  +-- Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: CountryID |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DSTA | CLUSTERED PK | StateID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_CountryID | DEFAULT | (0) - default country |
| FK_State_CountryID | FOREIGN KEY | CountryID -> Dictionary.Country(CountryID) |

---

## 8. Sample Queries

### 8.1 States for a country
```sql
SELECT StateID, Code, RTRIM(Name) AS Name FROM Dictionary.State WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON State.CountryID = c.CountryID WHERE c.Name = 'United States' ORDER BY Name
```

### 8.2 All states with country
```sql
SELECT RTRIM(s.Name) AS State, s.Code, c.Name AS Country FROM Dictionary.State s WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON s.CountryID = c.CountryID ORDER BY c.Name, s.Name
```

### 8.3 Count states per country
```sql
SELECT c.Name, COUNT(*) AS StateCount FROM Dictionary.State s WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON s.CountryID = c.CountryID GROUP BY c.Name ORDER BY StateCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.State | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.State.sql*
