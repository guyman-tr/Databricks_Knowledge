# BackOffice.CompensationReason

> Hierarchical catalog of all compensation types used to classify cash adjustments made to customer accounts, carrying tax and accounting flags that drive regulatory reporting and cash-flow classification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CompensationReasonID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK + 1 nonclustered on Name) |

---

## 1. Business Meaning

BackOffice.CompensationReason is the master classification table for all compensation (credit/debit adjustment) transactions made to customer accounts. Every compensation event issued by BackOffice agents references a CompensationReasonID that determines how the transaction is categorized, whether it appears in the customer's history, how it is treated for tax reporting, and whether it counts as a cash-flow-for-gain event.

The table captures two fundamentally different business domains in one hierarchy: (1) operational compensations (fee refunds, satisfaction bonuses, error corrections, regulatory actions) managed by Accounting/Ops, R&D, Marketing, Sales, and ACT teams; and (2) corporate actions and dividends (Cash Dividend, Stock Split, Merger, Staking, etc.) managed through the Dividend root category (ID 45). The IsTaxable, IsCashflowForGain, and IsShownInHistory flags are critical for regulatory compliance - they determine how transactions appear on tax statements, CFTC/FCA reporting, and customer-visible account history.

New reasons are added directly to the table (no dedicated ADD procedure found) or via the GetActivityList procedure integration. The Dividend sub-tree (45 children) is heavily used by the corporate actions processing system to classify non-cash instrument events (stock splits, mergers, spinoffs) that require zero cash-flow and non-taxable treatment.

---

## 2. Business Logic

### 2.1 Two-Level Departmental Hierarchy

**What**: Compensation reasons are organized under department/domain root categories, identical in structure to BackOffice.BonusType.

**Columns Involved**: `CompensationReasonID`, `ParentID`, `Name`

**Rules**:
- Root nodes (ParentID=NULL) are organizational owners/domains; they should not be assigned directly to compensation transactions
- Child nodes are the specific compensation types used in transaction records
- Self-referential FK constraint FK_BCPR_BCPR enforces valid parent references

**Diagram**:
```
Root Categories (ParentID=NULL):
    1  = Custom (ad-hoc, catch-all)
    4  = Marketing (satisfaction, RAF, affiliate, guru payments)
    9  = Accounting / Ops (largest group - fees, adjustments, regulatory)
   10  = R&D (technical credits, P&L adjustments, reopen operations)
   16  = ACT (ACT platform transfers)
   23  = Obsolete (deprecated types - e.g., old Position lost child)
   35  = MT4 (MetaTrader 4 transfers)
   45  = Dividend (corporate actions: dividends, splits, mergers, rights)
   48  = Inactivity Fee For Non Depositor (standalone root, not a parent)

Dividend sub-tree (45) - largest group, all corporate action types:
   60=Cash in Lieu, 61=Cash Dividend, 62=Interest, 63=Return Of Capital,
   64=Dividend Reinvestments (DRS), 65=Redemption, 67=Reorg fee,
   68=Reverse split*, 75=Spinoff*, 76=Stock Dividend*, 77=Stock Split*,
   79=REORG Security*, 86=Name Change*, 88=Exchange*, 89=Merger*,
   91=Staking*, 74=Warrants*, 73=Rights offer*
   (* = IsShownInHistory=false, non-cash events)
```

### 2.2 Tax and Accounting Classification Flags

**What**: Three boolean flags control regulatory treatment, tax reporting, and customer visibility for each compensation type - making this table directly relevant to financial compliance.

**Columns Involved**: `IsTaxable`, `IsCashflowForGain`, `IsShownInHistory`

**Rules**:
- **IsTaxable=1**: Transaction is a taxable event - will appear on tax statements (1099, etc.) and fed to tax reporting systems. The vast majority (120+) of types are taxable
- **IsTaxable=0**: Non-taxable event (e.g., Stock Split=77, Spinoff=75, Merger=89, Stock Dividend=76, Reverse split=68, Rights offer=73, Warrants=74, Staking=91) - these are non-cash instrument adjustments with no immediate tax consequence
- **IsCashflowForGain=1**: Represents actual cash movement in/out of the account - counts toward gain/loss calculations in PnL and regulatory capital reporting
- **IsCashflowForGain=0**: Non-cash event (stock splits, merger share exchanges, position airdrops, reopen operations) - instrument quantity/price adjustments that don't move USD
- **IsShownInHistory=0**: Hidden from customer-visible account history (internal operations, instrument adjustments the customer doesn't need to see). Examples: Test-Internal (24), ReopenOperation (56), Position Airdrop (58), Stock Split (77), Spinoff (75)
- **IsShownInHistory=1**: Appears in customer's transaction history

**Diagram**:
```
Example: Cash Dividend (ID=61)
  IsShownInHistory=true  -> Customer sees it in statement
  IsCashflowForGain=true -> Counts toward realized gains
  IsTaxable=true         -> Appears on tax report (1099-DIV)

Example: Stock Split (ID=77)
  IsShownInHistory=false -> Hidden from customer (internal adjustment)
  IsCashflowForGain=false -> No cash moved
  IsTaxable=false        -> Not a taxable event

Example: ReopenOperation (ID=56)
  IsShownInHistory=false -> Hidden from customer (technical operation)
  IsCashflowForGain=false -> Technical position adjustment
  IsTaxable=false        -> Not taxable
```

### 2.3 Internal vs. Customer-Facing Names

**What**: Like BonusType, each reason has an internal Name (used by BackOffice staff) and a DisplayName (shown to customers in statements).

**Columns Involved**: `Name`, `DisplayName`

**Rules**:
- Name is the precise operational classification ("Foreclosure (taking all money)", "Hedge Abuser", "Chargeback (Negative compensation)")
- DisplayName is the customer-visible label ("Foreclosure account", "Hedge Abuser", "Chargeback reduction")
- 3 types have NULL DisplayName (ID 46=Offmarket abuse, 47=Transfer from external partner, 57=Interest Payment) - likely oversight or suppressed display
- Multiple types share the same DisplayName (many share "Adjustment", "eToro compensation", "Promotion")

---

## 3. Data Overview

| CompensationReasonID | Name | IsTaxable | IsCashflowForGain | IsShownInHistory | Meaning |
|---------------------|------|-----------|------------------|-----------------|---------|
| 9 | Accounting / Ops | true | true | true | Root category for all Accounting and Operations team compensations. Direct sub-types include fee refunds, dormant fees, foreclosure, merge accounts, SGFX credits, and regulatory actions. Most commonly used parent. |
| 30 | Dormant Fee | true | true | true | Account maintenance fee charged to dormant accounts (no login for 12+ months). Customer sees "Account maintenance fee" in statement. Taxable, cash movement. |
| 50 | Dormant Fee (under Accounting) | true | true | true | Charged when customer has been inactive. This type is under root 4=Marketing (interesting routing); DisplayName is "Guru cash no CO". |
| 77 | Stock Split | false | false | false | Non-cash instrument adjustment when a held stock undergoes a split. Hidden from customer history, no cash flow, not taxable - purely a share quantity recalculation. Under Dividend root (45). |
| 61 | Cash Dividend | true | true | true | Cash dividend payment from a held stock position. Customer sees it in history, counts toward gains, and is reportable for tax purposes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CompensationReasonID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-generated unique identifier. PK referenced by compensation transaction tables. Used as ParentID for child types in the hierarchy. 136 active rows (IDs not sequential - some were deleted). |
| 2 | ParentID | int | YES | - | VERIFIED | Self-referential FK to CompensationReasonID. NULL = root/department category (9 root nodes: 1, 4, 9, 10, 16, 23, 35, 45, 48). Non-NULL = specific compensation type. FK_BCPR_BCPR enforces valid reference. BCPR_NAME index on Name column. |
| 3 | Name | varchar(50) | NO | - | CODE-BACKED | Internal classification name used by BackOffice staff. Descriptive operational names like "Foreclosure (taking all money)", "Hedge Abuser", "Position Airdrop". Has BCPR_NAME index for fast name lookup. |
| 4 | DisplayName | varchar(50) | YES | - | VERIFIED | Customer-facing label shown in account statement. Decouples internal classification from customer visibility. NULL for 3 types (ID 46, 47, 57) - these may display as empty in statements. Multiple types share "Adjustment", "Promotion", "eToro compensation" as generic labels. |
| 5 | IsShownInHistory | bit | NO | (1) | VERIFIED | Whether this compensation type appears in the customer's transaction history/statement. 0=hidden from customer view (technical ops, non-cash instrument adjustments). Default 1 (shown). Used by reporting layer to filter customer-visible transactions. Types with 0: Test-Internal, ReopenOperation, Position Airdrop, Stock Split, Spinoff, Stock Dividend, Exchange, Merger, Name Change, Warrants, Rights offer, Staking, REORG Security. |
| 6 | IsCashflowForGain | bit | NO | (1) | VERIFIED | Whether this compensation represents actual cash flowing in/out of the account, relevant for gain/loss calculations and regulatory capital reporting. 0=non-cash event (instrument adjustments, position reopens, airdrops). Default 1. Critical for financial reporting - non-cash corporate actions (splits, mergers) must be 0. |
| 7 | IsTaxable | bit | NO | (1) | VERIFIED | Whether this compensation is a taxable event that must be reported on tax statements (1099 forms, etc.). 0=non-taxable (instrument adjustments like stock splits, mergers, spinoffs that don't trigger tax obligations). Default 1. Drives tax reporting system - every IsTaxable=1 transaction may appear on the customer's annual tax document. |
| 8 | IsActive | bit | NO | (1) | CODE-BACKED | Whether this type is still in active use. 0=deprecated (ID 3=Technical Problems under R&D, ID 26=Satisfaction Bonus under Accounting/Ops). Default 1. Inactive types should not be assigned to new compensations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentID | BackOffice.CompensationReason | Self-Reference (FK) | Points to the department/domain root category for hierarchy organization. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Compensation transaction table) | CompensationReasonID | Implicit FK | Each compensation event classifies itself with this reason. |
| BackOffice.GetActivityList | CompensationReasonID | READER | Joins CompensationReason for activity list reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CompensationReason (table)
- Self-referential: ParentID -> BackOffice.CompensationReason.CompensationReasonID
- No external dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CompensationReason | Table (self) | ParentID FK - self-referential hierarchy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetActivityList | Procedure | READER - joins CompensationReason for activity reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCPR | CLUSTERED PK | CompensationReasonID ASC | - | - | Active |
| BCPR_NAME | NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BCPR_BCPR | FK (WITH CHECK) | ParentID -> BackOffice.CompensationReason(CompensationReasonID) - self-referential hierarchy |
| (unnamed) | DEFAULT | IsShownInHistory = 1 - new reasons visible to customers by default |
| (unnamed) | DEFAULT | IsCashflowForGain = 1 - new reasons count as cash flow by default |
| (unnamed) | DEFAULT | IsTaxable = 1 - new reasons are taxable by default |
| (unnamed) | DEFAULT | IsActive = 1 - new reasons are active by default |

---

## 8. Sample Queries

### 8.1 Get all active compensation reasons with hierarchy and flags
```sql
SELECT
    child.CompensationReasonID,
    child.Name AS ReasonName,
    child.DisplayName AS CustomerLabel,
    parent.Name AS DepartmentCategory,
    child.IsTaxable,
    child.IsCashflowForGain,
    child.IsShownInHistory,
    child.IsActive
FROM BackOffice.CompensationReason child WITH (NOLOCK)
LEFT JOIN BackOffice.CompensationReason parent WITH (NOLOCK)
    ON child.ParentID = parent.CompensationReasonID
WHERE child.IsActive = 1
  AND child.ParentID IS NOT NULL  -- exclude root categories
ORDER BY parent.Name, child.Name
```

### 8.2 Get all non-cash corporate action types (instrument adjustments)
```sql
SELECT
    cr.CompensationReasonID,
    cr.Name,
    cr.DisplayName,
    cr.IsShownInHistory,
    cr.IsTaxable
FROM BackOffice.CompensationReason cr WITH (NOLOCK)
WHERE cr.IsCashflowForGain = 0
  AND cr.IsActive = 1
ORDER BY cr.Name
```

### 8.3 Get taxable compensation types visible to customers
```sql
SELECT
    cr.CompensationReasonID,
    cr.Name,
    cr.DisplayName,
    parent.Name AS Category
FROM BackOffice.CompensationReason cr WITH (NOLOCK)
LEFT JOIN BackOffice.CompensationReason parent WITH (NOLOCK)
    ON cr.ParentID = parent.CompensationReasonID
WHERE cr.IsTaxable = 1
  AND cr.IsShownInHistory = 1
  AND cr.IsActive = 1
  AND cr.ParentID IS NOT NULL
ORDER BY parent.Name, cr.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 7.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CompensationReason | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CompensationReason.sql*
