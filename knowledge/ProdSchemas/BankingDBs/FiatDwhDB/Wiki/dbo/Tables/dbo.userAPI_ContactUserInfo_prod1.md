# dbo.userAPI_ContactUserInfo_prod1

> Alternate staging table for UserAPI customer country data, with wider column sizes and no PK constraint - likely a bulk import target.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap table) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

userAPI_ContactUserInfo_prod1 is a variant of dbo.userAPI_ContactUserInfo_prod with wider column sizes (nvarchar(250) vs nvarchar(50)) and no primary key constraint. This suggests it is a bulk import staging area where data is loaded before being validated and moved to the primary staging table.

This table exists as an intermediate landing zone for UserAPI data imports. The wider columns and lack of constraints allow loading raw data without validation failures. The "prod1" suffix suggests it's a secondary/alternate version of the production staging table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a raw data landing table.

---

## 3. Data Overview

N/A - staging table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. NOT NULL but no PK constraint. |
| 2 | CountryID | nvarchar(250) | NO | - | NAME-INFERRED | Customer's country of residence identifier. Wider than prod table (250 vs 50) for raw import flexibility. |
| 3 | CitizenshipCountryID | nvarchar(250) | NO | - | NAME-INFERRED | Customer's citizenship country identifier. |
| 4 | POBCountryID | nvarchar(250) | YES | - | NAME-INFERRED | Customer's place-of-birth country identifier. Nullable (unlike prod table). |
| 5 | IsoCode | nvarchar(250) | NO | - | NAME-INFERRED | ISO country code for the customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this staging table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check row count
```sql
SELECT COUNT(*) AS Rows FROM dbo.userAPI_ContactUserInfo_prod1 WITH (NOLOCK);
```

### 8.2 Find duplicate GCIDs (no PK to prevent them)
```sql
SELECT GCID, COUNT(*) AS Cnt
FROM dbo.userAPI_ContactUserInfo_prod1 WITH (NOLOCK)
GROUP BY GCID HAVING COUNT(*) > 1;
```

### 8.3 Compare with primary staging table
```sql
SELECT p1.GCID
FROM dbo.userAPI_ContactUserInfo_prod1 p1 WITH (NOLOCK)
LEFT JOIN dbo.userAPI_ContactUserInfo_prod p WITH (NOLOCK) ON p.GCID = p1.GCID
WHERE p.GCID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 6/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.userAPI_ContactUserInfo_prod1 | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.userAPI_ContactUserInfo_prod1.sql*
