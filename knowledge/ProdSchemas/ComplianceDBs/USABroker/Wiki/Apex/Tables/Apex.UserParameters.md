# Apex.UserParameters

> Tracks the cumulative bitmask of user data fields that have pending updates not yet sent to Apex Clearing, acting as a change queue for the account update workflow.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserParameters stores a cumulative bitmask of user data fields that have been changed but not yet sent to Apex Clearing as an account update request. When a customer modifies multiple fields over time, each change ORs its mask value into UpdatesMask. When the system is ready to send an update to Apex, it reads this mask to determine which fields to include.

Data is managed by Apex.GetUserParametersUpdatesMask (reader) and Apex.SaveUserParametersUpdatesMask (writer). System versioning with History.UserParameters.

---

## 2. Business Logic

### 2.1 Cumulative Update Mask Accumulation

**What**: UpdatesMask accumulates field change flags over time, cleared when the update is sent to Apex.

**Columns/Parameters Involved**: `GCID`, `UpdatesMask`

**Rules**:
- Uses Dictionary.UserDataUpdatesMask bitmask values (same as UserDataUpdates)
- UpdatesMask=0 means no pending changes
- Each field change ORs its bit into the mask
- When an Apex update request is sent, the mask is read and then cleared
- See [User Data Updates Mask](_glossary.md#user-data-updates-mask) for bitmask values

---

## 3. Data Overview

| GCID | UpdatesMask | BeginTime | Meaning |
|------|-------------|-----------|---------|
| 85152 | 0 | 2022-08-22 | No pending updates for this customer. Mask was cleared after last update was sent. |
| 92779 | 0 | 2023-06-19 | No pending updates. Clean state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. One parameter record per customer. |
| 2 | UpdatesMask | int | YES | - | CODE-BACKED | Cumulative bitmask of pending user data field changes. Uses Dictionary.UserDataUpdatesMask values. NULL or 0 means no pending changes. Accumulated via bitwise OR as fields change; cleared when the update is processed. See [User Data Updates Mask](_glossary.md#user-data-updates-mask). |
| 3 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserParameters. |
| 4 | EndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.GetUserParametersUpdatesMask | @GCID | Reader | Retrieves pending update mask |
| Apex.SaveUserParametersUpdatesMask | @GCID | Writer | Sets/clears the update mask |
| Apex.DeleteUserParameters | @GCID | Deleter | Removes parameter record |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.GetUserParametersUpdatesMask | Stored Procedure | Reader |
| Apex.SaveUserParametersUpdatesMask | Stored Procedure | Writer |
| Apex.DeleteUserParameters | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserParameters | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserParameters | PRIMARY KEY | Clustered on GCID |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserParameters |

---

## 8. Sample Queries

### 8.1 Find customers with pending updates

```sql
SELECT GCID, UpdatesMask, BeginTime
FROM Apex.UserParameters WITH (NOLOCK)
WHERE UpdatesMask > 0
ORDER BY BeginTime DESC;
```

### 8.2 Decode pending update fields for a customer

```sql
SELECT up.GCID, up.UpdatesMask, m.Name AS PendingField
FROM Apex.UserParameters up WITH (NOLOCK)
CROSS JOIN Dictionary.UserDataUpdatesMask m WITH (NOLOCK)
WHERE up.UpdatesMask & m.Mask = m.Mask AND up.GCID = 85152;
```

### 8.3 View parameter change history

```sql
SELECT GCID, UpdatesMask, BeginTime, EndTime
FROM Apex.UserParameters WITH (NOLOCK) WHERE GCID = 85152
UNION ALL
SELECT GCID, UpdatesMask, BeginTime, EndTime
FROM History.UserParameters WITH (NOLOCK) WHERE GCID = 85152
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserParameters | Type: Table | Source: USABroker/Apex/Tables/Apex.UserParameters.sql*
