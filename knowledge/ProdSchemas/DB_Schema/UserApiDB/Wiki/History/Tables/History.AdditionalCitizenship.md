# History.AdditionalCitizenship

> System versioning history table for Customer.AdditionalCitizenship, automatically storing temporal snapshots of additional citizenship changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | AdditionalCitizenshipID + temporal range (no PK - clustered on EndTime,StartTime) |
| **Partition** | No |
| **Indexes** | 1 (clustered on EndTime,StartTime) |

---

## 1. Business Meaning

History.AdditionalCitizenship is the system versioning history target for Customer.AdditionalCitizenship. SQL Server automatically manages rows here - when the source table is updated or deleted, the previous version is moved to this table with its temporal validity period (StartTime to EndTime). Queryable via FOR SYSTEM_TIME syntax.

---

## 2. Business Logic

No business logic. Automatically managed by SQL Server system versioning.

---

## 3. Data Overview

N/A - system-managed history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AdditionalCitizenshipID | bigint | NO | - | CODE-BACKED | Original PK from source table. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | CountryID | int | NO | - | CODE-BACKED | Additional citizenship country at this point in time. |
| 4 | StartTime | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 5 | EndTime | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Automatically populated by system versioning on Customer.AdditionalCitizenship.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

System versioning pair with Customer.AdditionalCitizenship.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_AdditionalCitizenship | CLUSTERED | EndTime, StartTime | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None (system versioning history tables have no PK).

---

## 8. Sample Queries

### 8.1 Citizenship history for a user
```sql
SELECT * FROM Customer.AdditionalCitizenship FOR SYSTEM_TIME ALL WHERE GCID = @GCID ORDER BY StartTime
```

### 8.2 Direct history query
```sql
SELECT GCID, CountryID, StartTime, EndTime FROM History.AdditionalCitizenship WITH (NOLOCK) WHERE GCID = @GCID ORDER BY StartTime
```

### 8.3 Citizenship at a point in time
```sql
SELECT * FROM Customer.AdditionalCitizenship FOR SYSTEM_TIME AS OF '2025-01-01' WHERE GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.AdditionalCitizenship | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.AdditionalCitizenship.sql*
