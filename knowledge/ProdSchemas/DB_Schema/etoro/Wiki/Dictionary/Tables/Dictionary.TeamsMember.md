# Dictionary.TeamsMember

> Assigns individual staff members to operational teams with active/inactive status tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TeamMemberID (int, PK) |
| **Row Count** | 169 |
| **Indexes** | 1 (clustered PK) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TeamsMember is a roster table linking individual staff members to their operational teams. It tracks who belongs to which team and whether they are currently active, enabling task assignment and workload distribution within the BackOffice system.

### Why It Exists
The platform's internal operations require tracking which staff members are available for task assignment. When risk reviews, deposit verifications, or KYC checks need to be assigned, the system needs to know which team members are active and eligible. This table provides the staff-to-team mapping with active/inactive status for workforce management.

### How It Works
Each row represents a team member identified by `TeamMemberID`, assigned to a team via `TeamID` (FK to `Dictionary.Teams`). The `IsActive` flag (default 1) tracks whether the member is currently active. The optional `TeamManagerID` column provides self-referencing hierarchy support (manager-to-subordinate), though in practice it's NULL for all current rows.

---

## 2. Business Logic

### Team Distribution (169 members total)

| TeamID | Team | Total Members | Active | Inactive |
|--------|------|---------------|--------|----------|
| 1 | Deposit | 1 | 1 | 0 |
| 3 | Risk | 168 | ~120 | ~48 |
| 2, 4, 5 | Cashout, Partners, KYC | 0 | 0 | 0 |

### Observations
- The Risk team dominates with 168 members, reflecting the scale of compliance operations
- Teams 2 (Cashout), 4 (Partners), and 5 (KYC) have no members assigned, suggesting those functions may use different assignment systems or haven't been populated
- `TeamMemberID = 0` is a special "Unassigned" placeholder in the Deposit team
- Staff span multiple offices: Cyprus, Romania, Philippines, Israel, UK — evidenced by name origins
- Some staff appear with duplicate entries (different IDs), likely due to re-onboarding or system migration
- ID 56 contains a data entry artifact: "write inserts for all names"

---

## 3. Data Overview

| TeamMemberID | TeamMemberName | TeamID | IsActive | Scenario |
|-------------|----------------|--------|----------|----------|
| 0 | Unassigned | 1 (Deposit) | 1 | Default placeholder for unassigned deposit tasks |
| 15 | Marta Tomaszkiewicz | 3 (Risk) | 1 | Active risk team member for compliance reviews |
| 45 | Raluca Marsavela | 3 (Risk) | 1 | Active risk analyst |
| 1 | Razvan Condunina | 3 (Risk) | 0 | Inactive — former risk team member |
| 100 | Emanuel Grigorasi | 3 (Risk) | 0 | Deactivated team member |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TeamMemberID | int | NO | — | HIGH | Primary key identifying the team member. `0` = Unassigned placeholder. Not auto-incrementing (manually assigned IDs). |
| 2 | TeamMemberName | nvarchar(150) | NO | — | HIGH | Full name of the team member. Unicode-enabled for international names. Some entries contain data artifacts (e.g., ID 56). |
| 3 | TeamID | int | NO | — | HIGH | FK to `Dictionary.Teams.TeamID`. Assigns this member to a team. Currently all members are in team 1 (Deposit) or 3 (Risk). |
| 4 | TeamManagerID | int | YES | — | MEDIUM | Self-referencing FK to `TeamMemberID` for manager hierarchy. Currently NULL for all rows — hierarchy feature not actively used. |
| 5 | IsActive | int | NO | 1 | HIGH | Active status flag. `1` = active (available for task assignment), `0` = inactive (left team or deactivated). Default is 1 (active). Int type rather than bit, allowing potential future multi-state values. |

---

## 5. Relationships

### Depends On (Implicit)

| Referenced Table | Column | Relationship | Evidence |
|-----------------|--------|-------------|----------|
| Dictionary.Teams | TeamID | Implicit FK → TeamID | Team assignment |
| Dictionary.TeamsMember (self) | TeamManagerID → TeamMemberID | Self-referencing hierarchy | Manager relationship (unused) |

### Referenced By

No consumers found in SSDT procedures or views — this table appears to be consumed by application-layer code or BackOffice UI directly.

---

## 6. Dependencies

### Depends On
- `Dictionary.Teams` — TeamID references Teams for department assignment

### Depended On By
- BackOffice application layer (task assignment UI)

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_TeamsMember | CLUSTERED PK | TeamMemberID ASC | FILLFACTOR 95 |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |
| Default | IsActive = 1 |

---

## 8. Sample Queries

```sql
-- Get all active team members with team names
SELECT  tm.TeamMemberID,
        tm.TeamMemberName,
        t.TeamName,
        tm.IsActive
FROM    Dictionary.TeamsMember tm WITH (NOLOCK)
JOIN    Dictionary.Teams t WITH (NOLOCK)
        ON tm.TeamID = t.TeamID
WHERE   tm.IsActive = 1
ORDER BY t.TeamName, tm.TeamMemberName;

-- Count active vs inactive by team
SELECT  t.TeamName,
        SUM(CASE WHEN tm.IsActive = 1 THEN 1 ELSE 0 END) AS Active,
        SUM(CASE WHEN tm.IsActive = 0 THEN 1 ELSE 0 END) AS Inactive
FROM    Dictionary.TeamsMember tm WITH (NOLOCK)
JOIN    Dictionary.Teams t WITH (NOLOCK)
        ON tm.TeamID = t.TeamID
GROUP BY t.TeamName;

-- Find the Unassigned placeholder
SELECT  tm.TeamMemberID,
        tm.TeamMemberName,
        t.TeamName
FROM    Dictionary.TeamsMember tm WITH (NOLOCK)
JOIN    Dictionary.Teams t WITH (NOLOCK)
        ON tm.TeamID = t.TeamID
WHERE   tm.TeamMemberID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TeamsMember`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TeamsMember | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TeamsMember.sql*
