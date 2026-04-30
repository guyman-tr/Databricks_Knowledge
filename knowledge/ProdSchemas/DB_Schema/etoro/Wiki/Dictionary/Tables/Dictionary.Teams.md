# Dictionary.Teams

> Defines internal operational teams for task assignment and workflow routing in the BackOffice system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TeamID (int, IDENTITY, PK) |
| **Row Count** | 5 |
| **Indexes** | 1 (clustered PK) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.Teams is a lookup table defining the internal operational teams within eToro's BackOffice. Each team represents a functional department responsible for specific customer-facing operations.

### Why It Exists
Internal workflows require tasks and team members to be organized by department. This table provides the canonical list of teams, enabling the `TeamsMember` table to assign staff to departments and downstream systems to route work items to the appropriate team.

### How It Works
The `TeamID` is referenced by `Dictionary.TeamsMember` to assign members to teams. The current 5 teams cover the core operational functions: deposit processing, withdrawal handling, risk/compliance review, partner management, and KYC verification.

---

## 2. Business Logic

### Value Map (Complete — 5 rows)

| TeamID | TeamName | Business Meaning |
|--------|----------|------------------|
| 1 | Deposit | Deposit processing and verification team |
| 2 | Cashout | Withdrawal/cashout processing team |
| 3 | Risk | Risk, compliance, and AML investigation team (largest — 168 members) |
| 4 | Partners | Partner/affiliate management team |
| 5 | KYC | Know Your Customer document verification team |

### Team Distribution
The Risk team (ID 3) contains the vast majority of team members (167 of 168 total), reflecting the significant staffing required for compliance operations across multiple global offices (Cyprus, Romania, Philippines, Israel, etc.).

---

## 3. Data Overview

| TeamID | TeamName | Scenario |
|--------|----------|----------|
| 1 | Deposit | New deposit requires manual review before crediting |
| 2 | Cashout | Large withdrawal flagged for manual approval |
| 3 | Risk | Suspicious trading pattern flagged for investigation |
| 4 | Partners | Affiliate commission dispute requires review |
| 5 | KYC | Customer document submission needs manual verification |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TeamID | int | NO | IDENTITY(1,1) | HIGH | Auto-incrementing primary key identifying the team. Referenced by `Dictionary.TeamsMember.TeamID`. Values 1-5 map to Deposit/Cashout/Risk/Partners/KYC. |
| 2 | TeamName | nvarchar(50) | NO | — | HIGH | Team display name. Unicode-enabled for international team names. |

---

## 5. Relationships

### Referenced By

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Dictionary.TeamsMember | TeamID | Implicit FK → TeamID | Team assignment for each member |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `Dictionary.TeamsMember` — assigns members to teams via TeamID

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_Teams | CLUSTERED PK | TeamID ASC | FILLFACTOR 95 |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |
| Identity | TeamID IDENTITY(1,1) |

---

## 8. Sample Queries

```sql
-- Get all teams
SELECT  TeamID,
        TeamName
FROM    Dictionary.Teams WITH (NOLOCK)
ORDER BY TeamID;

-- Count active members per team
SELECT  t.TeamName,
        COUNT(*) AS ActiveMembers
FROM    Dictionary.Teams t WITH (NOLOCK)
JOIN    Dictionary.TeamsMember tm WITH (NOLOCK)
        ON t.TeamID = tm.TeamID
WHERE   tm.IsActive = 1
GROUP BY t.TeamName
ORDER BY ActiveMembers DESC;

-- Find teams with no members
SELECT  t.TeamID,
        t.TeamName
FROM    Dictionary.Teams t WITH (NOLOCK)
LEFT JOIN Dictionary.TeamsMember tm WITH (NOLOCK)
        ON t.TeamID = tm.TeamID
WHERE   tm.TeamMemberID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `Dictionary.Teams`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.Teams | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Teams.sql*
