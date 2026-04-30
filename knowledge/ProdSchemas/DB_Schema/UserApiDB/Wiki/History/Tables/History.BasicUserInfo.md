# History.BasicUserInfo

> Audit history table storing temporal snapshots of Customer.BasicUserInfo changes (username, name, DOB, gender, language, player level).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerVersionID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on GCID,CustomerVersionID DESC) |

---

## 1. Business Meaning

History.BasicUserInfo stores temporal snapshots of basic user profile changes. Same trigger-populated pattern as History.AccountUserInfo. Tracks changes to: UserName, PlayerLevelID, LanguageID, FirstName, LastName, MiddleName, Gender, BirthDate. The Trace column provides connection audit context.

---

## 2. Business Logic

Same temporal snapshot pattern as History.AccountUserInfo. ValidTo='3000-01-01' = current version.

---

## 3. Data Overview

N/A - large audit history table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerVersionID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Version identifier. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | When this snapshot became active. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | When superseded. '3000-01-01' = current. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 5 | UserName | varchar(20) MASKED | NO | - | CODE-BACKED | Username at this point. Dynamic data masking. |
| 6 | PlayerLevelID | int | NO | - | CODE-BACKED | eToro Club tier at this point. See [Player Level](_glossary.md#player-level). |
| 7 | LanguageID | int | NO | - | CODE-BACKED | Preferred language at this point. See [Language](_glossary.md#language). |
| 8 | FirstName | nvarchar(50) | YES | - | CODE-BACKED | First name at this point. |
| 9 | LastName | nvarchar(50) | YES | - | CODE-BACKED | Last name at this point. |
| 10 | MiddleName | nvarchar(50) | YES | - | CODE-BACKED | Middle name at this point. |
| 11 | Gender | char(1) | YES | - | CODE-BACKED | Gender at this point: M/F/U. |
| 12 | BirthDate | datetime | YES | - | CODE-BACKED | Date of birth at this point (can change due to corrections). |
| 13 | Trace | varchar(max) | YES | JSON | CODE-BACKED | Connection audit context JSON. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints.

### 5.2 Referenced By (other objects point to this)

Populated by triggers on Customer.BasicUserInfo.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Triggers on Customer.BasicUserInfo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBasicUserInfo | CLUSTERED PK | CustomerVersionID | - | - | Active |
| Idx_HistoryBasic_GCID_CustomerVersionID | NONCLUSTERED | GCID ASC, CustomerVersionID DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_HistoryBasicUserInfo_Trace | DEFAULT | Connection context JSON |

---

## 8. Sample Queries

### 8.1 Name change history
```sql
SELECT ValidFrom, ValidTo, FirstName, LastName, UserName FROM History.BasicUserInfo WITH (NOLOCK) WHERE GCID = @GCID ORDER BY CustomerVersionID DESC
```

### 8.2 Player level progression
```sql
SELECT h.ValidFrom, pl.Name AS Level FROM History.BasicUserInfo h WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON h.PlayerLevelID = pl.PlayerLevelID WHERE h.GCID = @GCID ORDER BY h.ValidFrom
```

### 8.3 Current version
```sql
SELECT * FROM History.BasicUserInfo WITH (NOLOCK) WHERE GCID = @GCID AND ValidTo = '3000-01-01'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.BasicUserInfo | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.BasicUserInfo.sql*
