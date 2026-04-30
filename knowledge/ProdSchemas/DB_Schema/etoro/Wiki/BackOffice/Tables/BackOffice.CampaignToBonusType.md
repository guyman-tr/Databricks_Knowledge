# BackOffice.CampaignToBonusType

> Junction table linking marketing campaigns to their associated bonus types, with optional XML configuration defining the bonus parameters for each campaign-type pairing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CampaignID, BonusTypeID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 2 active (1 clustered composite PK + 1 NC on BonusTypeID) |

---

## 1. Business Meaning

BackOffice.CampaignToBonusType defines which bonus types are available under each marketing campaign. A campaign (BackOffice.Campaign) grants a specific type of credit (BackOffice.BonusType) - this table is the link between them. When a customer uses a campaign code during registration or deposit, this table determines what kind of bonus they receive and, via the Configuration XML, the parameters of that bonus (amount rules, eligibility conditions, etc.).

The table exists to support the many-to-many relationship: one campaign can grant multiple bonus types, and one bonus type can be associated with many campaigns. In practice, 89.1% of all 10,896 rows use BonusTypeID=7 (Sales Promotion Code Bonus), meaning the vast majority of campaigns are straightforward sales promotions with a single bonus type. The Configuration XML is populated for 99.1% of rows, providing the bonus-specific rules (e.g., bonus amount as a percentage of deposit, minimum deposit threshold, expiry).

Lifecycle is managed by three procedures: BonusLinkToCampaign (INSERT), BonusLinkToCampaignEdit (UPDATE Configuration), BonusUnLinkFromCampaign (DELETE). Both JUNK_BonusDelete and CampaignDelete guard against orphaning - they block deletion of a BonusType or Campaign if it has rows here.

---

## 2. Business Logic

### 2.1 Campaign-BonusType Linking Lifecycle

**What**: Three dedicated procedures manage the full lifecycle of campaign-to-bonustype associations.

**Columns Involved**: `CampaignID`, `BonusTypeID`, `Configuration`

**Rules**:
- BonusLinkToCampaign: simple INSERT. Called by CampaignBunchAdd after each campaign is created to link the BonusType. Also called directly via BackOffice UI.
- BonusLinkToCampaignEdit: UPDATE - modifies Configuration for an existing (CampaignID, BonusTypeID) pair.
- BonusUnLinkFromCampaign: DELETE - removes a bonus type from a campaign.
- Guard: JUNK_BonusDelete blocks BonusType deletion if CampaignToBonusType has rows for that BonusTypeID.
- Guard: CampaignDelete blocks Campaign deletion if CampaignToBonusType has rows for that CampaignID.

### 2.2 Dominant Pattern: Sales Promotion Code Bonuses

**What**: Almost all campaigns use a single BonusTypeID=7 (Sales Promotion Code Bonus).

**Columns Involved**: `BonusTypeID`, `Configuration`

**Rules**:
- BonusTypeID=7 (Sales Promotion Code Bonus, under Sales parent) accounts for 9,710 of 10,896 rows (89.1%).
- BonusTypeID=5 (Retention Deposit Bonus): 649 rows (5.9%) - retention team campaigns.
- BonusTypeID=2 (First Deposit Bonus): 318 rows (2.9%) - first-deposit incentive campaigns.
- The Configuration XML varies per row and encodes the bonus rules (amount, conditions) specific to that campaign-type pairing.

---

## 3. Data Overview

| CampaignID | BonusTypeID | BonusTypeName | CampaignCode | HasConfig | Meaning |
|------------|-------------|---------------|--------------|-----------|---------|
| 1 | 7 | Sales Promotion Code Bonus | wedding2010 | Yes | Earliest campaign, a 2010 wedding-themed sales promo. Configuration XML defines the bonus rules for this specific promo code. |
| 7 | 5 | Retention Deposit Bonus | abc | No | A retention deposit bonus campaign with no per-row configuration - bonus rules defined at the BonusType level. |
| 12 | 5 | Retention Deposit Bonus | aaa | No | Another retention deposit campaign. Multiple campaigns share the same BonusTypeID, each with a different code. |
| 13 | 5 | Retention Deposit Bonus | interest | No | Retention campaign for customer re-engagement. |
| 14 | 5 | Retention Deposit Bonus | depositors | No | Retention campaign targeted at existing depositors. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CampaignID | int | NO | - | VERIFIED | References the marketing campaign. Part of the composite PK. FK (WITH CHECK) to BackOffice.Campaign(CampaignID). Constraint FK_BCMP_BC2T. NC index on BonusTypeID supports lookup from BonusType direction. |
| 2 | BonusTypeID | int | NO | - | VERIFIED | The bonus type granted by this campaign. Part of the composite PK. FK (WITH CHECK) to BackOffice.BonusType(BonusTypeID). Constraint FK_BBNT_BC2T. Dominant value: 7=Sales Promotion Code Bonus (89.1%), then 5=Retention Deposit Bonus (5.9%), 2=First Deposit Bonus (2.9%). See BackOffice.BonusType for full hierarchy. |
| 3 | Configuration | xml | YES | - | CODE-BACKED | XML configuration defining bonus parameters for this specific campaign-type pairing (e.g., bonus amount as percentage of deposit, minimum deposit threshold, maximum bonus cap, expiry days). Populated for 99.1% of rows (10,793 of 10,896). NULL for 103 older rows that predate the configuration structure. Updated via BonusLinkToCampaignEdit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CampaignID | BackOffice.Campaign | FK (WITH CHECK) | The marketing campaign this bonus type is linked to |
| BonusTypeID | BackOffice.BonusType | FK (WITH CHECK) | The bonus type granted under this campaign |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BonusLinkToCampaign | CampaignID, BonusTypeID | WRITER | Inserts a new campaign-type link |
| BackOffice.BonusLinkToCampaignEdit | CampaignID, BonusTypeID | MODIFIER | Updates Configuration for an existing link |
| BackOffice.BonusUnLinkFromCampaign | CampaignID, BonusTypeID | DELETER | Removes a campaign-type link |
| BackOffice.CampaignBunchAdd | CampaignID, BonusTypeID | WRITER (via BonusLinkToCampaign) | Links bonus type after bulk campaign creation |
| BackOffice.CampaignDelete | CampaignID | READER (guard) | Blocks campaign deletion if rows exist here |
| BackOffice.JUNK_BonusDelete | BonusTypeID | READER (guard) | Blocks bonus type deletion if rows exist here |
| Billing.AmountAddBonus | CampaignID | READER | Reads campaign bonus type during bonus grant |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignToBonusType (table)
- FK targets (leaf nodes):
  ├── BackOffice.Campaign (table)
  └── BackOffice.BonusType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Campaign | Table | FK on CampaignID |
| BackOffice.BonusType | Table | FK on BonusTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusLinkToCampaign | Procedure | WRITER - inserts link |
| BackOffice.BonusLinkToCampaignEdit | Procedure | MODIFIER - updates Configuration |
| BackOffice.BonusUnLinkFromCampaign | Procedure | DELETER - removes link |
| BackOffice.CampaignDelete | Procedure | READER (guard check before deletion) |
| BackOffice.JUNK_BonusDelete | Procedure | READER (guard check before deletion) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BC2T | CLUSTERED PK | CampaignID ASC, BonusTypeID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BC2T_BONUSTYPE | NC | BonusTypeID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BC2T | PK | Uniqueness of (CampaignID, BonusTypeID) pairs |
| FK_BBNT_BC2T | FK (WITH CHECK) | BonusTypeID -> BackOffice.BonusType(BonusTypeID) |
| FK_BCMP_BC2T | FK (WITH CHECK) | CampaignID -> BackOffice.Campaign(CampaignID) |

---

## 8. Sample Queries

### 8.1 Get all bonus types linked to a specific campaign
```sql
SELECT
    c2bt.CampaignID,
    c.Code AS CampaignCode,
    bt.BonusTypeID,
    bt.Name AS BonusTypeName,
    bt.IsDepositRelated,
    c2bt.Configuration
FROM BackOffice.CampaignToBonusType c2bt WITH (NOLOCK)
JOIN BackOffice.Campaign c WITH (NOLOCK) ON c.CampaignID = c2bt.CampaignID
JOIN BackOffice.BonusType bt WITH (NOLOCK) ON bt.BonusTypeID = c2bt.BonusTypeID
WHERE c2bt.CampaignID = @CampaignID
```

### 8.2 Find all campaigns for a specific bonus type
```sql
SELECT
    c2bt.CampaignID,
    c.Code AS CampaignCode,
    c.IsActive,
    c.StartDate,
    c.EndDate,
    c.ParticipatedUsers,
    c.MaxNumberOfUsers
FROM BackOffice.CampaignToBonusType c2bt WITH (NOLOCK)
JOIN BackOffice.Campaign c WITH (NOLOCK) ON c.CampaignID = c2bt.CampaignID
WHERE c2bt.BonusTypeID = 7  -- Sales Promotion Code Bonus
  AND c.IsActive = 1
ORDER BY c.ParticipatedUsers DESC
```

### 8.3 Campaigns with multiple bonus types linked
```sql
SELECT
    c2bt.CampaignID,
    c.Code AS CampaignCode,
    COUNT(c2bt.BonusTypeID) AS LinkedBonusTypeCount
FROM BackOffice.CampaignToBonusType c2bt WITH (NOLOCK)
JOIN BackOffice.Campaign c WITH (NOLOCK) ON c.CampaignID = c2bt.CampaignID
GROUP BY c2bt.CampaignID, c.Code
HAVING COUNT(c2bt.BonusTypeID) > 1
ORDER BY LinkedBonusTypeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.7/10, Logic: 8.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignToBonusType | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CampaignToBonusType.sql*
