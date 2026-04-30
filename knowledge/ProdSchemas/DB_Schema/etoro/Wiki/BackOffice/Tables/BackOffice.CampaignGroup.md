# BackOffice.CampaignGroup

> Named grouping container for marketing campaigns, used to organize bonus campaigns by responsible staff member, product, or marketing initiative.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CampaignGroupID (INT IDENTITY, NC PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 nonclustered PK + 1 unique nonclustered on Name) |

---

## 1. Business Meaning

BackOffice.CampaignGroup is a simple name registry for grouping marketing campaigns. Each row is a named category that clusters related BackOffice.Campaign records together, making it easier for BackOffice staff to filter, track, and report on bonus campaigns by their organizational owner (a staff member's name, a product vertical, or a marketing channel).

Without this table, all campaigns would appear as an undifferentiated list in the BackOffice system. The group structure allows account managers and marketing staff to see "all campaigns that Dori is running" or "all VIP Club promotions" in one filtered view, and to assign budget and authorization at the group level.

BackOffice.CampaignGroupAdd creates new groups, BackOffice.CampaignGroupEdit renames them, and BackOffice.CampaignGroupDelete removes empty groups. BackOffice.Campaign stores the CampaignGroupID FK pointing to this table.

---

## 2. Business Logic

### 2.1 Staff-Owned Campaign Groups

**What**: Campaign groups are primarily named after individual staff members who own and manage a collection of bonus campaigns.

**Columns Involved**: `Name`, `CampaignGroupID`

**Rules**:
- Many group names are personal names (e.g., "Nivi's people", "Dori", "Ryan", "Itay Manor", "Gil Ariel") - these represent individual account managers or marketing staff who have their own campaign budget authority
- Some groups are product/segment-based ("Silver Club", "Gold Club", "VIP Club", "FTD", "SEM", "Affiliates")
- Some groups are test/training entries ("BOTraining", "botr2", "test") - operational artifacts
- Note: IDs start at 16 (IDs 1-15 were presumably deleted or never committed to production)

---

## 3. Data Overview

| CampaignGroupID | Name | Meaning |
|-----------------|------|---------|
| 28 | Silver Club | Groups campaigns for Silver-tier eToro Club members - loyalty program campaigns with deposit/trading incentives targeting mid-tier customers |
| 29 | Gold Club | Campaigns for Gold-tier Club members - higher-value promotions for customers with larger account sizes |
| 30 | VIP Club | Campaigns for VIP-tier Club members - premium campaigns for highest-value customers |
| 42 | Affiliates | Groups all affiliate partner campaigns - promotions run through external referral partners (IBs, online affiliates) |
| 69 | FTD | First-Time Deposit campaigns - promotions specifically designed to convert registered users into depositing customers |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CampaignGroupID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-generated unique identifier for each campaign group. NK is NONCLUSTERED - note this table uses a non-clustered primary key (unusual; means heap storage with NC PK index). Referenced as FK by BackOffice.Campaign.CampaignGroupID. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable group name. Unique (enforced by BCMG_NAME index). Examples: "Silver Club", "FTD", "Affiliates", "Monthly Massive". Often a staff member's first name indicating who owns the campaigns in this group. Maximum 50 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Campaign | CampaignGroupID | FK | Each campaign belongs to exactly one group for organizational classification. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignGroup (table)
- No dependencies (leaf table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Campaign | Table | Stores CampaignGroupID as FK for group membership |
| BackOffice.CampaignGroupAdd | Procedure | WRITER - inserts new campaign group |
| BackOffice.CampaignGroupEdit | Procedure | MODIFIER - updates group Name |
| BackOffice.CampaignGroupDelete | Procedure | DELETER - removes empty campaign group |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCMG | NC PK | CampaignGroupID ASC | - | - | Active |
| BCMG_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BCMG_NAME | UNIQUE INDEX | Group names must be unique - prevents duplicate group names |

---

## 8. Sample Queries

### 8.1 Get all campaign groups with campaign count
```sql
SELECT
    cg.CampaignGroupID,
    cg.Name AS GroupName,
    COUNT(c.CampaignID) AS CampaignCount
FROM BackOffice.CampaignGroup cg WITH (NOLOCK)
LEFT JOIN BackOffice.Campaign c WITH (NOLOCK) ON cg.CampaignGroupID = c.CampaignGroupID
GROUP BY cg.CampaignGroupID, cg.Name
ORDER BY CampaignCount DESC
```

### 8.2 Get all campaigns in a specific group
```sql
SELECT
    c.CampaignID,
    c.Name AS CampaignName,
    cg.Name AS GroupName,
    m.FirstName + ' ' + m.LastName AS ResponsibleManager
FROM BackOffice.Campaign c WITH (NOLOCK)
JOIN BackOffice.CampaignGroup cg WITH (NOLOCK) ON c.CampaignGroupID = cg.CampaignGroupID
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON c.ManagerID = m.ManagerID
WHERE cg.CampaignGroupID = 30  -- 30 = VIP Club
ORDER BY c.Name
```

### 8.3 Find all VIP or Club campaign groups
```sql
SELECT CampaignGroupID, Name
FROM BackOffice.CampaignGroup WITH (NOLOCK)
WHERE Name LIKE '%Club%' OR Name LIKE '%VIP%'
ORDER BY Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignGroup | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CampaignGroup.sql*
