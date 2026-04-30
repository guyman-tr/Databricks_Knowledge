# Customer.UserSettings

> Modern user preferences table (GCID-keyed) storing privacy policy, opt-out reasons, display name, and share/follow settings with history and sync triggers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.UserSettings is the modern replacement for Customer.Settings (which is keyed by CID). It stores user preferences keyed by GCID: privacy policy acceptance, marketing opt-out reason, display name visibility, share/follow permissions, and homepage preference. Changes trigger history rows to History.UserSettings and sync events to Sync.PendingEntityEvents (EntityType=5 for User settings).

---

## 2. Business Logic

### 2.1 History and Sync Triggers

**What**: Automatic audit trail and cross-system synchronization.

**Columns/Parameters Involved**: `PrivacyPolicyID`, `OptOutReasonID`

**Rules**:
- UPDATE trigger tracks changes to PrivacyPolicyID and OptOutReasonID only
- Writes to History.UserSettings and Sync.PendingEntityEvents(EntityType=5)
- INSERT/DELETE triggers are DISABLED; UPDATE trigger is ENABLED

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID. One settings record per user. |
| 2 | PrivacyPolicyID | int | YES | - | CODE-BACKED | Which privacy policy version the user accepted. Tracked in history for compliance. |
| 3 | OptOutReasonID | smallint | YES | - | CODE-BACKED | If user opted out of marketing, the reason code. Tracked in history. |
| 4 | AllowDisplayFullName | bit | NO | 0 | CODE-BACKED | Whether user allows their real name to be shown publicly. Default: 0 (hidden). |
| 5 | AllowShareFollow | bit | YES | - | CODE-BACKED | Whether user allows being followed/shared in social features. |
| 6 | HomepageId | int | YES | - | CODE-BACKED | User's preferred homepage/landing page after login. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.UserSettings | GCID | Trigger-written | Audit trail of privacy/opt-out changes |
| Sync.PendingEntityEvents | GCID | Trigger-written | Sync queue (EntityType=5) |
| Customer.GetUserSettings | GCID | SP reads | Returns user settings |
| Customer.UpdateUserSettings | GCID | SP writes | Updates settings |
| Customer.GetManyUserSettings | GCID | SP reads | Bulk settings retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.UserSettings | Table | Trigger writes audit rows |
| Customer.GetUserSettings | Stored Procedure | Reads from |
| Customer.UpdateUserSettings | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserSettings_GCID | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_UserSettings_AllowDisplayFullName | DEFAULT | (0) - hidden by default |

---

## 8. Sample Queries

### 8.1 Get user settings
```sql
SELECT GCID, PrivacyPolicyID, OptOutReasonID, AllowDisplayFullName, AllowShareFollow, HomepageId
FROM Customer.UserSettings WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Users who opted out
```sql
SELECT GCID, OptOutReasonID FROM Customer.UserSettings WITH (NOLOCK) WHERE OptOutReasonID IS NOT NULL
```

### 8.3 Users showing full name publicly
```sql
SELECT GCID FROM Customer.UserSettings WITH (NOLOCK) WHERE AllowDisplayFullName = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.UserSettings | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.UserSettings.sql*
