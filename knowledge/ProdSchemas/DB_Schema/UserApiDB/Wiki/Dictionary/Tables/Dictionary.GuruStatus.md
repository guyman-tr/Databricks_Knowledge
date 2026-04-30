# Dictionary.GuruStatus

> Lookup table defining Popular Investor (PI) program tier statuses that track a trader's progression through eToro's copy-trading program.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GuruStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.GuruStatus defines the tier levels in eToro's Popular Investor (PI) program, where successful traders ("gurus") allow other users to automatically copy their trades. Each tier represents a level of achievement, with higher tiers offering greater compensation and visibility on the platform. The program is a key differentiator for eToro's social trading platform.

This table is essential for the copy-trading ecosystem. A trader's guru status determines their visibility in PI search results, their compensation rate (% of AUM from copiers), platform marketing exposure, and access to PI-exclusive features. The tier system incentivizes consistent performance and growing copier bases.

Guru status is evaluated periodically (monthly/quarterly) based on performance metrics, copier count, and AUM thresholds. Traders can progress up through tiers or be Removed (7) for violations. New PI applicants who don't meet criteria are Rejected (8). The status is stored on Customer.AccountUserInfo and referenced extensively in aggregated user info procedures.

---

## 2. Business Logic

### 2.1 Popular Investor Tier Progression

**What**: Multi-tier achievement system for copy-trading leaders.

**Columns/Parameters Involved**: `GuruStatusID`, `Name`

**Rules**:
- No (0) is the default for all non-PI users
- Application -> Cadet (2) -> Rising Star (3) -> Champion (4) -> Elite (5) -> Elite Pro (6)
- Certified (1) is a legacy status from the old PI program
- Removed (7) = disqualified from the program (e.g., compliance violation, poor performance)
- Rejected (8) = PI application denied
- Higher tiers earn higher AUM-based compensation
- Demotion is possible if performance drops below tier thresholds

**Diagram**:
```
Non-PI (0) --> Apply --> Rejected(8)
                |
             Cadet(2) -> Rising Star(3) -> Champion(4) -> Elite(5) -> Elite Pro(6)
                |            |                |              |            |
                +--- Any tier can be demoted or Removed(7) ---+
```

---

## 3. Data Overview

| GuruStatusID | Name | Meaning |
|---|---|---|
| 0 | No | Standard user - not a Popular Investor. Default for all non-PI accounts |
| 1 | Certified | Legacy certified PI status from the old program structure - grandfathered |
| 2 | Cadet | Entry-level PI - met initial qualification criteria (min copiers, performance history) |
| 3 | Rising Star | Growing PI - expanding copier base and maintaining solid performance track record |
| 4 | Champion | Established PI - significant AUM, consistent returns, active engagement |
| 5 | Elite | Top-tier PI - large AUM, excellent long-term track record, platform featured |
| 6 | Elite Pro | Highest PI tier - premier status with maximum compensation, priority marketing exposure |
| 7 | Removed | Disqualified from PI program due to compliance violation, sustained poor performance, or voluntary exit |
| 8 | Rejected | PI application was reviewed and rejected - did not meet minimum qualification criteria |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GuruStatusID | int | NO | - | CODE-BACKED | Primary key. PI tier: 0=No (non-PI), 1=Certified (legacy), 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by Customer.AccountUserInfo and many aggregated info procedures. See [Guru Status](_glossary.md#guru-status). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Tier display name used in PI profiles, search results, and marketing materials. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.AccountUserInfo | GuruStatusID | Lookup | Stores user's current PI tier |
| History.AccountUserInfo | GuruStatusID | Lookup | Historical record of PI tier changes |
| Customer.GetSingleAggregatedInfo | GuruStatusID | Lookup | Returns PI status in aggregated user info |
| Customer.GetManyAggregatedInfo | GuruStatusID | Lookup | Returns PI status for bulk user queries |
| Customer.UpdateAccountInfo | GuruStatusID | Lookup | Updates PI status on user record |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.AccountUserInfo | Table | Stores GuruStatusID |
| History.AccountUserInfo | Table | Historical GuruStatusID tracking |
| Customer.GetSingleAggregatedInfo | Stored Procedure | Reads GuruStatusID |
| Customer.GetManyAggregatedInfo | Stored Procedure | Reads GuruStatusID |
| Customer.UpdateAccountInfo | Stored Procedure | Writes GuruStatusID |
| Customer.GetAccountInfo | Stored Procedure | Reads GuruStatusID |
| Customer.GetManyAccountInfo | Stored Procedure | Reads GuruStatusID |
| Customer.GetManyAccountUserInfo | Stored Procedure | Reads GuruStatusID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GuruStatusID | CLUSTERED PK | GuruStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all guru statuses
```sql
SELECT GuruStatusID, Name
FROM Dictionary.GuruStatus WITH (NOLOCK)
ORDER BY GuruStatusID
```

### 8.2 Find active Popular Investors by tier
```sql
SELECT gs.Name AS Tier, COUNT(*) AS PiCount
FROM Customer.AccountUserInfo aui WITH (NOLOCK)
JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON aui.GuruStatusID = gs.GuruStatusID
WHERE aui.GuruStatusID BETWEEN 2 AND 6 -- Active PI tiers
GROUP BY gs.Name
ORDER BY gs.GuruStatusID
```

### 8.3 Get a specific user's PI status with details
```sql
SELECT u.CustomerID, u.UserName, gs.Name AS GuruTier
FROM Customer.AccountUserInfo aui WITH (NOLOCK)
JOIN Customer.Users u WITH (NOLOCK) ON aui.CustomerID = u.CustomerID
JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON aui.GuruStatusID = gs.GuruStatusID
WHERE u.CustomerID = @CustomerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GuruStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.GuruStatus.sql*
