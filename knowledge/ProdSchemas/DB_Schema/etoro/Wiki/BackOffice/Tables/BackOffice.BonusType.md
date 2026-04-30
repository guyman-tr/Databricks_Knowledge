# BackOffice.BonusType

> Hierarchical catalog of all bonus categories used to classify credit adjustments issued to customers, organized by the department that manages them (Sales, Marketing, Retention, Accounting, R&D).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | BonusTypeID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

BackOffice.BonusType is the master catalog of bonus categories. Every credit adjustment (bonus) issued to a customer through BackOffice.Bonus references a BonusTypeID to classify what kind of promotion or operational adjustment it represents. Types range from sales-driven first-deposit promotions to Accounting/Ops adjustments for fee refunds, from R&D test credits to MT4 platform fund transfers.

The table is organized as a two-level hierarchy: nine root categories correspond to the eToro departments or operational systems that own the bonus activity (Sales, Marketing, Retention, Accounting/Ops, R&D, ACT, MT4, Custom, Obsolete). Each root has child types that represent specific bonus programs within that category. This hierarchy allows the BackOffice UI and reporting systems to group bonus activity by department.

New bonus types are created via BackOffice.BonusAdd. The BackOffice.GetBonusType view exposes a simple ID/Name lookup for dropdown selection in the BackOffice application. The Affiliate Wizard (AffWiz) integration uses HideFromAffwiz to suppress internal-only types from the affiliate partner portal. DisplayName is the customer-facing label shown in account statements, while Name is the internal classification used by BackOffice staff.

---

## 2. Business Logic

### 2.1 Two-Level Departmental Hierarchy

**What**: Bonus types are organized under department-level parent categories, grouping financial adjustments by the team responsible for them.

**Columns Involved**: `BonusTypeID`, `ParentID`, `Name`

**Rules**:
- Root nodes (ParentID=NULL) are department/system categories and are never directly assigned to a bonus - they serve as grouping parents only
- Child nodes (ParentID IS NOT NULL) are the specific types assigned to customer bonuses in BackOffice.Bonus
- Self-referential FK constraint (FK_BBNT_BBNT) enforces that ParentID must reference a valid BonusTypeID

**Diagram**:
```
Root Categories (ParentID=NULL):
    3  = Custom (ad-hoc bonuses)
    8  = Accounting / Ops (fee adjustments, refunds)
    9  = R&D (technical credits, test bonuses)
   10  = Retention (loyalty programs, rebates)
   26  = Sales (deposit bonuses, promo codes)
   34  = ACT (ACT platform transfers)
   40  = Obsolete (deprecated - children should not be used)
   44  = Marketing / IB (affiliate promos, registration bonuses)
   52  = MT4 (MetaTrader 4 transfers)

Example child structure under 8=Accounting/Ops:
   13  = Satisfaction Bonus  (under 8)
   14  = Wire - Alternative Payment Method (under 8)
   17  = Refill - Negative Balance (under 8, IsActive=0)
   50  = Dormant Fee (under 8)
   66  = Foreclosure (under 8)
   68  = Hedge Abuser (under 8)
```

### 2.2 Internal vs. Customer-Facing Classification

**What**: Each bonus type has two names - an internal operational name (Name) and a customer-facing display label (DisplayName) shown in account statements.

**Columns Involved**: `Name`, `DisplayName`, `HideFromAffwiz`

**Rules**:
- Name is the internal classification used by BackOffice staff for reporting and routing (e.g., "Request for Documents", "Dormant Fee", "Hedge Abuser")
- DisplayName is the customer-visible label shown in the customer's account statement (e.g., "eToro credits adjustment", "Account maintenance fee", "Satisfaction Bonus")
- HideFromAffwiz=1 suppresses the type from the Affiliate Wizard partner portal - types with this flag are internal operational types that affiliates should not see or select
- HideFromAffwiz=NULL behaves the same as 0 (visible in AffWiz) - NULL represents the original pre-HideFromAffwiz schema state

### 2.3 Deposit-Related Bonus Tracking

**What**: IsDepositRelated flags bonus types that are triggered by or associated with a customer deposit, enabling differentiation between promotional and operational credits.

**Columns Involved**: `IsDepositRelated`, `IsWithdrawable`

**Rules**:
- IsDepositRelated=1 indicates the bonus was issued in connection with a deposit event (first deposit promotions, retention deposit bonuses, referral deposit bonuses)
- IsDepositRelated=0 means the bonus is an operational credit, technical adjustment, or non-deposit promotional grant
- IsWithdrawable is 0 (false) for all 70 active types - indicating this field may have been a planned feature that was never activated, or is controlled elsewhere in the bonus grant lifecycle
- IsActive=0 marks deprecated bonus types (17=Refill-Negative Balance, 23=Championship Winner Demo under Retention) that should no longer be issued

---

## 3. Data Overview

| BonusTypeID | ParentID | Name | DisplayName | IsDepositRelated | Meaning |
|-------------|----------|------|-------------|-----------------|---------|
| 3 | NULL | Custom | Custom | 0 | Root catch-all for ad-hoc bonuses not fitting other categories. Used as parent for 59=Share and Copy Bonus. BackOffice agents select this when issuing one-off credits. |
| 8 | NULL | Accounting / Ops | eToro credits adjustment | 0 | Root for all Accounting/Operations-initiated adjustments. Covers fee refunds (Over Weekend Fee, Dormant Fee), payment method adjustments, and regulatory actions (Hedge Abuser, Foreclosure). |
| 10 | NULL | Retention | Deposit Promotion | 1 | Root for all Retention team bonuses. IsDepositRelated=1 at root level - most children are deposit-related retention promotions. |
| 26 | NULL | Sales | Deposit Promotion | 1 | Root for Sales team bonuses. Children include first-deposit bonuses, promo codes, and referral programs managed by the Sales team. |
| 50 | 8 | Dormant Fee | Account maintenance fee | 0 | Dormant account fee charged to inactive customers. HideFromAffwiz=1 keeps this operational type hidden from affiliate partners. DisplayName "Account maintenance fee" is customer-visible. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusTypeID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-generated unique identifier for each bonus type. PK referenced by BackOffice.Bonus (BonusTypeID FK) and BackOffice.CampaignToBonusType. Also used as ParentID for child types in the hierarchy. |
| 2 | ParentID | int | YES | - | VERIFIED | Self-referential FK to BonusTypeID. NULL = root/department category (9 root nodes). Non-NULL = specific bonus program under a department. FK constraint FK_BBNT_BBNT enforces referential integrity. Has BBNT_PARENT index for efficient children lookups. |
| 3 | Name | varchar(50) | NO | - | VERIFIED | Internal name used by BackOffice staff for identification, reporting, and operational routing. Shown in the BackOffice UI dropdowns. NOT the customer-visible name - see DisplayName. Examples: "Dormant Fee", "Hedge Abuser", "Request for Documents", "Cashout Fee Reimbursment" (note: typo in production data). Has BBNT_NAME index. |
| 4 | Configuration | xml | YES | - | CODE-BACKED | XML configuration payload for parameterized bonus types. Only one active bonus type has this populated (BonusTypeID=2: `<DepositBonus/>`). Intended for deposit bonus configuration rules but largely unused - 69 of 70 types have NULL configuration. |
| 5 | IsWithdrawable | bit | NO | - | CODE-BACKED | Whether the bonus amount can be withdrawn by the customer. Currently 0 (false) for ALL 70 active bonus types - this field is either a planned feature or bonus withdrawability is controlled elsewhere in the bonus lifecycle. |
| 6 | IsActive | bit | NO | - | CODE-BACKED | Whether this bonus type is still in active use. 0=deprecated (should not be assigned to new bonuses). Active=0 types: 17=Refill-Negative Balance, 23=Championship Winner Demo. All other 68 types are IsActive=1. |
| 7 | HideFromAffwiz | tinyint | YES | (0) | CODE-BACKED | Controls visibility in the Affiliate Wizard (AffWiz) portal used by affiliate partners. 1=hide from affiliates (internal operational types not relevant to affiliate programs). 0 or NULL=visible. NULL represents rows created before this column was added. Types with HideFromAffwiz=1 include operational adjustments (Dormant Fee, Foreclosure, Hedge Abuser, P&L Adjustment, Merge Accounts) that affiliates should not access. |
| 8 | DisplayName | varchar(50) | YES | - | VERIFIED | Customer-facing label shown in the customer's account statement for this bonus type. Decouples internal classification from customer-visible text. Examples: "eToro credits adjustment" (generic ops adjustment), "Account maintenance fee" (Dormant Fee), "Withdraw Fee Reimbursement" (Cashout Fee Reimbursement), "Trading credits" (R&D technical bonus). Multiple bonus types share the same DisplayName (e.g., many types show "eToro credits adjustment"). |
| 9 | IsDepositRelated | tinyint | NO | (0) | VERIFIED | Whether this bonus type is triggered by or associated with a customer deposit event. 1=deposit-related (first deposit promos, retention deposit bonuses, NWA adjustment, referral-when-invited bonuses). 0=non-deposit operational credit or promotional grant. Used in reporting to distinguish promotional deposit incentives from operational adjustments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentID | BackOffice.BonusType | Self-Reference (FK) | Points to the parent department category. Leaf nodes point to root groupings. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Bonus | BonusTypeID | Implicit FK | Every bonus grant references its type classification here. |
| BackOffice.CampaignToBonusType | BonusTypeID | Implicit FK | Links marketing campaigns to the bonus types they can issue. |
| BackOffice.GetBonusType | BonusTypeID | View JOIN | Simple ID/Name lookup view for BackOffice UI dropdowns. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BonusType (table)
- Self-referential: ParentID -> BackOffice.BonusType.BonusTypeID
- No external dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table (self) | ParentID FK - self-referential hierarchy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetBonusType | View | READER - exposes BonusTypeID + Name for UI dropdown selection |
| BackOffice.BonusAdd | Procedure | WRITER - inserts new bonus types (ParentID, Name, Configuration, IsWithdrawable, IsActive) |
| BackOffice.BonusEdit | Procedure | MODIFIER - updates existing bonus type properties |
| BackOffice.JUNK_BonusDelete | Procedure | DELETER - legacy deletion proc (JUNK prefix = deprecated) |
| BackOffice.GetActivityList | Procedure | READER - joins BonusType in activity reporting |
| BackOffice.GetUserStatementTransactionList | Procedure | READER - joins BonusType for statement display |
| BackOffice.Bonus | Table | References BonusTypeID for each bonus grant issued |
| BackOffice.CampaignToBonusType | Table | Links campaign definitions to allowed bonus types |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BBNT | CLUSTERED PK | BonusTypeID ASC | - | - | Active |
| BBNT_NAME | NC | Name ASC | - | - | Active |
| BBNT_PARENT | NC | ParentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BBNT_BBNT | FK (WITH CHECK) | ParentID -> BackOffice.BonusType(BonusTypeID) - enforces valid parent reference |
| (unnamed) | DEFAULT | HideFromAffwiz = 0 - new types visible in AffWiz by default |
| DF_BackOfficeBonusType_IsDepositRlated | DEFAULT | IsDepositRelated = 0 - new types are non-deposit-related by default |

---

## 8. Sample Queries

### 8.1 Get full bonus type hierarchy with parent names
```sql
SELECT
    child.BonusTypeID,
    child.Name AS BonusTypeName,
    child.DisplayName AS CustomerLabel,
    parent.Name AS DepartmentCategory,
    child.IsDepositRelated,
    child.HideFromAffwiz,
    child.IsActive
FROM BackOffice.BonusType child WITH (NOLOCK)
LEFT JOIN BackOffice.BonusType parent WITH (NOLOCK) ON child.ParentID = parent.BonusTypeID
WHERE child.IsActive = 1
ORDER BY parent.Name, child.Name
```

### 8.2 Get all active deposit-related bonus types visible to affiliates
```sql
SELECT
    BonusTypeID,
    Name,
    DisplayName,
    ParentID
FROM BackOffice.BonusType WITH (NOLOCK)
WHERE IsActive = 1
  AND IsDepositRelated = 1
  AND (HideFromAffwiz = 0 OR HideFromAffwiz IS NULL)
ORDER BY Name
```

### 8.3 Get all child bonus types under a department root
```sql
SELECT
    bt.BonusTypeID,
    bt.Name,
    bt.DisplayName,
    bt.IsDepositRelated,
    bt.HideFromAffwiz
FROM BackOffice.BonusType bt WITH (NOLOCK)
WHERE bt.ParentID = 8  -- 8 = Accounting / Ops (replace as needed)
  AND bt.IsActive = 1
ORDER BY bt.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.3/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BonusType | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.BonusType.sql*
