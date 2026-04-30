# Apex.UserDataUpdates

> Tracks each user data change event with a bitmask identifying which specific fields were modified, enabling the system to determine which Apex API update calls are needed.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | UserDataUpdatesId (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 nonclustered (GCID) |

---

## 1. Business Meaning

Apex.UserDataUpdates records each user data modification event with a bitmask indicating which fields changed. When a customer updates their personal data (address, phone, name, etc.), a row is inserted here with an UpdatesMask value that encodes which fields were modified. The Apex integration then uses this mask to determine which specific API calls to make to Apex Clearing.

This table enables efficient change tracking - instead of comparing all fields before/after, the system records exactly which fields changed using Dictionary.UserDataUpdatesMask bitmask values. Multiple changes can be batched into a single mask value using bitwise OR.

Data is written by Apex.SaveUserDataUpdates. Read by GetUserDataUpdates and GetLastUserDataUpdates (for the most recent change event). System versioning with History.UserDataUpdates.

---

## 2. Business Logic

### 2.1 Bitmask-Based Change Tracking

**What**: Each update event encodes which fields changed using a bitmask from Dictionary.UserDataUpdatesMask.

**Columns/Parameters Involved**: `GCID`, `UpdatesMask`

**Rules**:
- UpdatesMask uses bitwise OR of Dictionary.UserDataUpdatesMask values
- Example: UpdatesMask=4096 means Instructions field was updated
- Example: UpdatesMask=192 (128+64) means both HomeAddress and PhoneNumber were updated
- Multiple updates per customer are possible (GCID is not unique - indexed but not PK)
- See [User Data Updates Mask](_glossary.md#user-data-updates-mask) for bitmask values

---

## 3. Data Overview

| UserDataUpdatesId | GCID | UpdatesMask | BeginTime | Meaning |
|------------------|------|-------------|-----------|---------|
| 1193755 | 22055177 | 4096 | 2026-04-14 11:52 | Instructions field was updated (Mask=4096). Most recent change event. |
| 1193753 | 12052384 | 4096 | 2026-04-14 11:32 | Another Instructions-only update. Instructions appears to be a commonly updated field. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserDataUpdatesId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Over 1.1M update events recorded. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Indexed (IX_UserDataUpdates_GCID) for lookup. Not unique - a customer can have multiple update events over time. |
| 3 | UpdatesMask | int | NO | - | VERIFIED | Bitmask encoding which user data fields were modified. Uses Dictionary.UserDataUpdatesMask values: 1=Disclosures, 2=Name, 4=DateOfBirth, 8=CitizenshipCountry, 16=SSN, 32=BirthCountry, 64=PhoneNumber, 128=HomeAddress, 256=Email, 512=PermanentResident, 1024=TrustedContact, 2048=MailingAddress, 4096=Instructions. See [User Data Updates Mask](_glossary.md#user-data-updates-mask). |
| 4 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserDataUpdates. |
| 5 | EndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveUserDataUpdates | @GCID | Writer | Inserts update events |
| Apex.GetUserDataUpdates | @GCID | Reader | Retrieves update history |
| Apex.GetLastUserDataUpdates | @GCID | Reader | Gets most recent update |
| Apex.DeleteUserDataUpdates | @GCID | Deleter | Removes update history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveUserDataUpdates | Stored Procedure | Writer |
| Apex.GetUserDataUpdates | Stored Procedure | Reader |
| Apex.GetLastUserDataUpdates | Stored Procedure | Reader |
| Apex.DeleteUserDataUpdates | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserDataUpdates | CLUSTERED PK | UserDataUpdatesId ASC | - | - | Active |
| IX_UserDataUpdates_GCID | NONCLUSTERED | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserDataUpdates | PRIMARY KEY | Clustered on UserDataUpdatesId |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserDataUpdates |

---

## 8. Sample Queries

### 8.1 Get update history for a customer with decoded mask

```sql
SELECT u.UserDataUpdatesId, u.GCID, u.UpdatesMask, u.BeginTime,
       STUFF((SELECT ', ' + m.Name
              FROM Dictionary.UserDataUpdatesMask m WITH (NOLOCK)
              WHERE u.UpdatesMask & m.Mask = m.Mask
              FOR XML PATH('')), 1, 2, '') AS ChangedFields
FROM Apex.UserDataUpdates u WITH (NOLOCK)
WHERE u.GCID = 22055177
ORDER BY u.UserDataUpdatesId DESC;
```

### 8.2 Find recent address changes

```sql
SELECT UserDataUpdatesId, GCID, UpdatesMask, BeginTime
FROM Apex.UserDataUpdates WITH (NOLOCK)
WHERE UpdatesMask & 128 = 128
ORDER BY BeginTime DESC;
```

### 8.3 Count updates by field type

```sql
SELECT m.Name, COUNT(*) AS UpdateCount
FROM Apex.UserDataUpdates u WITH (NOLOCK)
CROSS JOIN Dictionary.UserDataUpdatesMask m WITH (NOLOCK)
WHERE u.UpdatesMask & m.Mask = m.Mask
GROUP BY m.Name
ORDER BY UpdateCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserDataUpdates | Type: Table | Source: USABroker/Apex/Tables/Apex.UserDataUpdates.sql*
