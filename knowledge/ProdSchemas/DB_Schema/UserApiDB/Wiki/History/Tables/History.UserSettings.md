# History.UserSettings

> Audit history table storing temporal snapshots of Customer.UserSettings changes (privacy policy, opt-out reason).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerVersionID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

History.UserSettings stores temporal snapshots of user settings changes. Tracks only PrivacyPolicyID and OptOutReasonID (the columns tracked by the UPDATE trigger on Customer.UserSettings). Includes connection audit trace.

---

## 2. Business Logic

Same temporal pattern. Populated by UPDATE trigger on Customer.UserSettings (EntityType=5 sync events).

---

## 3. Data Overview

N/A - audit history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerVersionID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | Version start. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | Version end. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 5 | PrivacyPolicyID | int | YES | - | CODE-BACKED | Privacy policy version at this point. |
| 6 | OptOutReasonID | smallint | YES | - | CODE-BACKED | Marketing opt-out reason at this point. |
| 7 | Trace | varchar(max) | YES | JSON | CODE-BACKED | Connection audit context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Populated by triggers on Customer.UserSettings.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Triggers on Customer.UserSettings.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserSettings_CustomerVersionID | CLUSTERED PK | CustomerVersionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_HistoryUserSettings_Trace | DEFAULT | Connection context JSON |

---

## 8. Sample Queries

### 8.1 Settings history
```sql
SELECT ValidFrom, ValidTo, PrivacyPolicyID, OptOutReasonID FROM History.UserSettings WITH (NOLOCK) WHERE GCID = @GCID ORDER BY CustomerVersionID DESC
```

### 8.2 Privacy policy changes
```sql
SELECT ValidFrom, PrivacyPolicyID FROM History.UserSettings WITH (NOLOCK) WHERE GCID = @GCID AND PrivacyPolicyID IS NOT NULL ORDER BY ValidFrom
```

### 8.3 Current version
```sql
SELECT * FROM History.UserSettings WITH (NOLOCK) WHERE GCID = @GCID AND ValidTo = '3000-01-01'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.UserSettings | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.UserSettings.sql*
