# Customer.Settings

> Legacy user settings table storing social and display preferences (show full name, feed unlocked, share/follow, homepage).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.Settings is a legacy user preferences table keyed by CID (not GCID). It stores social feature settings: whether the user allows their full name to be displayed publicly, whether their news feed is unlocked, and their homepage preference. The newer Customer.UserSettings table (keyed by GCID) is the modern replacement.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Legacy settings table.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Surrogate key. Auto-incrementing. |
| 2 | CID | int | NO | - | CODE-BACKED | Primary key (clustered). Legacy Customer ID. Note: keyed by CID not GCID (legacy). |
| 3 | AllowDisplayFullName | bit | NO | 0 | CODE-BACKED | Whether the user allows their real name to be shown publicly on the platform. Default: 0 (hidden). |
| 4 | DateModified | datetime | YES | - | CODE-BACKED | When settings were last changed. |
| 5 | DateCreated | datetime | NO | - | CODE-BACKED | When the settings record was created. |
| 6 | FeedUnlocked | bit | NO | 0 | CODE-BACKED | Whether the user's news feed is unlocked/visible. Default: 0 (locked). |
| 7 | AllowShareFollow | bit | YES | - | CODE-BACKED | Whether the user allows being followed/shared in social features. |
| 8 | HomepageId | int | YES | - | CODE-BACKED | User's preferred homepage/landing page after login. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetSettings | CID | SP reads | Returns user settings |
| Customer.UpdateSettings | CID | SP writes | Updates settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetSettings | Stored Procedure | Reads from |
| Customer.UpdateSettings | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Settings | CLUSTERED PK | CID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Settings_AllowDisplayFullName | DEFAULT | (0) |
| DF_Settings_IsActivatedUnlockMyFeed | DEFAULT | (0) |

---

## 8. Sample Queries

### 8.1 Get settings for a user
```sql
SELECT AllowDisplayFullName, FeedUnlocked, AllowShareFollow, HomepageId FROM Customer.Settings WITH (NOLOCK) WHERE CID = @CID
```

### 8.2 Users with public full name
```sql
SELECT CID FROM Customer.Settings WITH (NOLOCK) WHERE AllowDisplayFullName = 1
```

### 8.3 Recent settings changes
```sql
SELECT TOP 100 CID, DateModified FROM Customer.Settings WITH (NOLOCK) WHERE DateModified IS NOT NULL ORDER BY DateModified DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.Settings | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.Settings.sql*
