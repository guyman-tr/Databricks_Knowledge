# Customer.AdditionalCitizenship

> Stores additional citizenship/nationality for users who hold dual or multiple citizenships, with temporal history tracking via system versioning.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | AdditionalCitizenshipID (BIGINT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + unique on GCID) |

---

## 1. Business Meaning

Customer.AdditionalCitizenship records a user's secondary nationality beyond their primary country of residence/citizenship stored in ContactUserInfo. This is relevant for regulatory compliance (CRS/FATCA tax reporting requires all citizenships), sanctions screening (citizenship in sanctioned countries), and KYC verification.

Currently limited to one additional citizenship per user (unique constraint on GCID). Uses SQL Server system versioning (temporal tables) to automatically maintain a full change history in History.AdditionalCitizenship.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single additional citizenship per user with temporal history.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AdditionalCitizenshipID | bigint (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing surrogate key. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Unique constraint - one additional citizenship per user. |
| 3 | CountryID | int | NO | - | CODE-BACKED | The additional citizenship country. Implicit FK to Dictionary.Country. See [Country](_glossary.md#country). |
| 4 | StartTime | datetime2(7) | NO | - | CODE-BACKED | System versioning row start time (GENERATED ALWAYS AS ROW START). |
| 5 | EndTime | datetime2(7) | NO | - | CODE-BACKED | System versioning row end time (GENERATED ALWAYS AS ROW END). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | The additional citizenship country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AdditionalCitizenship | - | System Versioning | Temporal history table |
| Customer.GetAdditionalCitizenship | GCID | SP reads | Returns additional citizenship |
| Customer.SaveAdditionalCitizenship | GCID | SP writes | Creates/updates additional citizenship |
| Customer.DeleteAdditionalCitizenship | GCID | SP deletes | Removes additional citizenship |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (CountryID is implicit FK only).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AdditionalCitizenship | Table | System versioning history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | AdditionalCitizenshipID | - | - | Active |
| UQ_AdditionalCitizenship_GCID | NONCLUSTERED UNIQUE | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ_AdditionalCitizenship_GCID | UNIQUE | One additional citizenship per user |
| SYSTEM_VERSIONING | Temporal | History table: History.AdditionalCitizenship |

---

## 8. Sample Queries

### 8.1 Get additional citizenship for a user
```sql
SELECT ac.GCID, c.Name AS AdditionalCitizenship
FROM Customer.AdditionalCitizenship ac WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ac.CountryID = c.CountryID
WHERE ac.GCID = @GCID
```

### 8.2 Users with dual citizenship in a specific country
```sql
SELECT ac.GCID FROM Customer.AdditionalCitizenship ac WITH (NOLOCK) WHERE ac.CountryID = @CountryID
```

### 8.3 Citizenship change history (temporal query)
```sql
SELECT ac.GCID, c.Name AS Country, ac.StartTime, ac.EndTime
FROM Customer.AdditionalCitizenship FOR SYSTEM_TIME ALL ac
JOIN Dictionary.Country c WITH (NOLOCK) ON ac.CountryID = c.CountryID
WHERE ac.GCID = @GCID ORDER BY ac.StartTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.AdditionalCitizenship | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.AdditionalCitizenship.sql*
