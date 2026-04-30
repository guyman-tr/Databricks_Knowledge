# Customer.BasicUserInfo

> Core user profile table storing basic identity data: username, name, date of birth, gender, language preference, and eToro Club level.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.BasicUserInfo is one of the four core user profile tables. It stores the user's basic identity: username (unique platform handle), name (first, last, middle), date of birth, gender, preferred language, and eToro Club membership tier (PlayerLevelID). Every registered user has exactly one row.

This table is essential for user identification across the platform. Username is the public-facing identity used in social features, copy trading profiles, and news feeds. The UserName column uses dynamic data masking for security. PlayerLevelID and LanguageID have explicit FKs to Dictionary tables.

Changes trigger history rows to History.BasicUserInfo and sync events to Sync.PendingEntityEvents (EntityType=1 for BasicInfo). The INSERT/DELETE triggers are DISABLED while the UPDATE trigger is ENABLED.

---

## 2. Business Logic

### 2.1 Gender Validation

**What**: Constrained gender values.

**Columns/Parameters Involved**: `Gender`

**Rules**:
- CHECK constraint: Gender must be 'M' (Male), 'F' (Female), or 'U' (Undisclosed)
- No other values allowed at the database level

### 2.2 History and Sync Triggers

**What**: Automatic audit trail and cross-system synchronization.

**Columns/Parameters Involved**: All columns

**Rules**:
- UPDATE trigger writes to History.BasicUserInfo and Sync.PendingEntityEvents(EntityType=1)
- Tracks changes to: UserName, PlayerLevelID, LanguageID, FirstName, LastName, MiddleName, Gender, BirthDate

---

## 3. Data Overview

N/A - transactional table with millions of rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID - unique user identifier across all systems. |
| 2 | UserName | varchar(20) MASKED | NO | - | CODE-BACKED | User's unique platform handle. Dynamic data masking applied. Used in social features, PI profiles, and news feeds. Max 20 chars. |
| 3 | PlayerLevelID | int | NO | 0 | CODE-BACKED | eToro Club membership tier. FK to Dictionary.PlayerLevel. 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond. Default: 0. See [Player Level](_glossary.md#player-level). |
| 4 | LanguageID | int | NO | 0 | CODE-BACKED | User's preferred platform language. FK to Dictionary.Language. Determines UI language and email templates. Default: 0. See [Language](_glossary.md#language). |
| 5 | FirstName | nvarchar(50) | YES | - | CODE-BACKED | User's first/given name. Unicode support for international names. |
| 6 | LastName | nvarchar(50) | YES | - | CODE-BACKED | User's last/family name. Unicode support. |
| 7 | MiddleName | nvarchar(50) | YES | - | CODE-BACKED | User's middle name. Optional, used in some jurisdictions for KYC. |
| 8 | Gender | char(1) | YES | - | CODE-BACKED | User's gender: 'M'=Male, 'F'=Female, 'U'=Undisclosed. CHECK constraint enforced. |
| 9 | BirthDate | datetime | YES | - | CODE-BACKED | User's date of birth. Used for age verification, regulatory eligibility, and underage detection. |
| 10 | Registered | datetime | NO | getdate() | CODE-BACKED | Account registration timestamp. Default: current datetime. Immutable after creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LanguageID | Dictionary.Language | Explicit FK | User's preferred language |
| PlayerLevelID | Dictionary.PlayerLevel | Explicit FK | eToro Club membership tier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.BasicUserInfo | GCID | Trigger-written | Audit trail |
| Sync.PendingEntityEvents | GCID | Trigger-written | Sync queue (EntityType=1) |
| Customer.GetBasicUserInfo | GCID | SP reads | Returns basic profile data |
| Customer.UpdateBasicUserInfo | GCID | SP writes | Updates basic profile |
| Customer.InsertRealCustomer | GCID | SP writes | Initial profile creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.BasicUserInfo (table)
  +-- Dictionary.Language (table) [done]
  +-- Dictionary.PlayerLevel (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Language | Table | FK: LanguageID |
| Dictionary.PlayerLevel | Table | FK: PlayerLevelID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.BasicUserInfo | Table | Trigger writes audit rows |
| Customer.GetBasicUserInfo | Stored Procedure | Reads from |
| Customer.UpdateBasicUserInfo | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BasicUserInfo | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BUI_PlayerLevel | DEFAULT | (0) for PlayerLevelID |
| DF_BUI_Language | DEFAULT | (0) for LanguageID |
| DF_BUI_Registered | DEFAULT | getdate() for Registered |
| FK_BUI_Language | FOREIGN KEY | LanguageID -> Dictionary.Language |
| FK_BUI_PlayerLevel | FOREIGN KEY | PlayerLevelID -> Dictionary.PlayerLevel |
| CHEK_BUI_Gender | CHECK | Gender IN ('F', 'M', 'U') |

---

## 8. Sample Queries

### 8.1 Get basic info for a user
```sql
SELECT b.GCID, b.UserName, b.FirstName, b.LastName, b.BirthDate, l.Name AS Language, pl.Name AS PlayerLevel
FROM Customer.BasicUserInfo b WITH (NOLOCK)
JOIN Dictionary.Language l WITH (NOLOCK) ON b.LanguageID = l.LanguageID
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON b.PlayerLevelID = pl.PlayerLevelID
WHERE b.GCID = @GCID
```

### 8.2 Find users by username
```sql
SELECT GCID, UserName, FirstName, LastName FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE UserName = @UserName
```

### 8.3 Registration date range
```sql
SELECT COUNT(*) AS NewUsers FROM Customer.BasicUserInfo WITH (NOLOCK)
WHERE Registered BETWEEN @StartDate AND @EndDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.BasicUserInfo | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.BasicUserInfo.sql*
