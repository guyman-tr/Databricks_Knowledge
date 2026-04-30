# Dictionary.RafPlayerLevel_NogaJunk210725

> Lookup table defining 8 eToro Club tiers for the Refer-A-Friend (RAF) program — Bronze through Diamond — used to determine tier-based referral rewards. Legacy/junk table from July 2021.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerLevelID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.RafPlayerLevel_NogaJunk210725 defines the eToro Club tiers used specifically in the Refer-A-Friend compensation model (RafModelTypeID=1, "Club"). The tier determines the referral bonus amount — higher club tiers earn larger referral rewards. This is a snapshot of the club tier definitions as they existed in July 2021.

The "_NogaJunk210725" suffix indicates this is a legacy table preserved from a cleanup/migration. It mirrors Dictionary.PlayerLevel but is isolated for the RAF system to maintain stable referral tier definitions independent of the main club tier table.

Referenced by Customer.RafConfigurationModels_NogaJunk210725, Customer.RafEligibleCustomers_NogaJunk210725, Customer.RafViewCustomerStatus_NogaJunk210725, and related RAF procedures.

---

## 2. Business Logic

### 2.1 Club Tier Hierarchy

**What**: Each tier represents a level in the eToro Club program, ordered by prestige and equity requirements.

**Columns/Parameters Involved**: `PlayerLevelID`, `Name`

**Rules**:
- **1 = Bronze** — Entry-level tier.
- **5 = Silver** — Second tier.
- **3 = Gold** — Mid-tier.
- **2 = Platinum** — High tier.
- **6 = Platinum Plus** — Enhanced high tier.
- **7 = Diamond** — Top tier.
- **4 = Internal** — eToro staff accounts.
- **100 = Bronze Plus** — Enhanced entry tier (added later, hence the gap in IDs).
- IDs are NOT in tier order — the Name defines the ranking, not the ID.

**Diagram**:
```
eToro Club Tiers (RAF)
Bronze (1) → Bronze Plus (100) → Silver (5) → Gold (3)
→ Platinum (2) → Platinum Plus (6) → Diamond (7)
Internal (4) = staff accounts
```

---

## 3. Data Overview

| PlayerLevelID | Name | Meaning |
|---|---|---|
| 1 | Bronze | Entry-level eToro Club tier. Base referral reward rate. |
| 100 | Bronze Plus | Enhanced entry tier with slightly better rewards than Bronze. |
| 5 | Silver | Second tier — moderate referral rewards. |
| 3 | Gold | Mid-tier — above-average referral rewards. |
| 2 | Platinum | High-tier — premium referral rewards. |
| 6 | Platinum Plus | Enhanced premium tier — high referral rewards. |
| 7 | Diamond | Top-tier — maximum referral rewards. |
| 4 | Internal | eToro staff accounts — special handling in RAF calculations. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | VERIFIED | Primary key. Non-sequential IDs (1-7, 100). Maps to club tiers. Referenced by RAF configuration tables. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Club tier label. Unique index enforces no duplicate names. Used in RAF reward calculation and display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafConfigurationModels_NogaJunk210725 | PlayerLevelID | Implicit | RAF reward configuration per club tier |
| Customer.RafEligibleCustomers_NogaJunk210725 | PlayerLevelID | Implicit | Eligible referrers by club tier |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafConfigurationModels_NogaJunk210725 | Table | RAF reward amounts per tier |
| Customer.RafEligibleCustomers_NogaJunk210725 | Table | Tracks eligible referrers |
| Customer.RafViewCustomerStatus_NogaJunk210725 | View | Displays customer RAF status with tier |
| Customer.FN_RafViewCustomerStatusByDate_NogaJunk210725 | Function | Date-filtered RAF status with tier |
| Customer.GetRafStatusByGCID_NogaJunk210725 | Stored Procedure | Reader — gets RAF status by GCID |
| Customer.RafGetReferralHistory_NogaJunk210725 | Stored Procedure | Reader — referral history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RDPLL | CLUSTERED PK | PlayerLevelID ASC | - | - | Active (FF=90) |
| IX_RafPlayerLevel_Name | UNIQUE NONCLUSTERED | Name ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RDPLL | PRIMARY KEY | Unique tier identifier |
| IX_RafPlayerLevel_Name | UNIQUE INDEX | Prevents duplicate tier names |

---

## 8. Sample Queries

### 8.1 List all RAF club tiers
```sql
SELECT  PlayerLevelID,
        Name
FROM    [Dictionary].[RafPlayerLevel_NogaJunk210725] WITH (NOLOCK)
ORDER BY PlayerLevelID;
```

### 8.2 Find RAF reward config per tier
```sql
SELECT  rpl.Name AS Tier,
        rc.*
FROM    [Customer].[RafConfigurationModels_NogaJunk210725] rc WITH (NOLOCK)
JOIN    [Dictionary].[RafPlayerLevel_NogaJunk210725] rpl WITH (NOLOCK) ON rc.PlayerLevelID = rpl.PlayerLevelID;
```

### 8.3 Count tiers excluding Internal
```sql
SELECT  COUNT(*) AS CustomerTiers
FROM    [Dictionary].[RafPlayerLevel_NogaJunk210725] WITH (NOLOCK)
WHERE   Name <> 'Internal';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RafPlayerLevel_NogaJunk210725 | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RafPlayerLevel_NogaJunk210725.sql*
