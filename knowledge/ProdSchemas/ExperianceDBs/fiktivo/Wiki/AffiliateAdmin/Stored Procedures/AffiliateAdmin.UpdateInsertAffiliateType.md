# AffiliateAdmin.UpdateInsertAffiliateType

> Large upsert procedure for affiliate type commission structures with 80+ parameters covering all commission rates, display settings, and plan configurations, with comprehensive audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateTypeID (inserted or updated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertAffiliateType is one of the largest procedures in the AffiliateAdmin schema, accepting 80+ parameters that define the complete commission structure and operational configuration for an affiliate type. It handles both creating new affiliate types and updating existing ones. The procedure manages commission rates for deposits, sales, leads, clicks, copytrader activity, PNL-based commissions, and many other compensation models. It also manages associated plan configurations in `AffiliateConfiguration.FirstPositionAssetPlan`, `IOBPlan`, and `ISAPlan`.

**WHY:** Affiliate types are the central mechanism for defining how affiliates are compensated. Each type encapsulates dozens of commission rates, thresholds, and behavioral settings that determine the financial relationship between the platform and its affiliates. A single comprehensive upsert procedure ensures that all commission parameters are saved atomically, preventing inconsistent states where some rates are updated but others are not. The exhaustive audit trail captures every rate change for financial compliance and dispute resolution.

**HOW:** The procedure checks whether to INSERT (new type) or UPDATE (existing type) based on the incoming AffiliateTypeID. For new types, all parameters populate the initial `tblaff_AffiliateTypes` row. For updates, each of the 80+ fields is compared against current values, the record is updated, and individual audit log entries are created for every field that changed. After the main type record is saved, the procedure manages associated plan tables: `AffiliateConfiguration.FirstPositionAssetPlan` for first-position-based commissions, `IOBPlan` for IOB-structured plans, and `ISAPlan` for ISA-structured plans.

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
The procedure determines the operation mode based on the AffiliateTypeID parameter value. A zero or null value triggers an INSERT; a positive value triggers an UPDATE with field-level comparison and audit logging.

### 2.2 Commission Rate Categories
The 80+ parameters span multiple commission models:
- **Deposit Commission:** Rates for first deposit, subsequent deposits, deposit tiers
- **Sale Commission:** Revenue-share and CPA rates on trading activity
- **Lead Commission:** Payment per qualified lead registration
- **Click Commission:** Payment per click/visit from affiliate sources
- **CopyTrader Commission:** Rates specific to copy trading referrals
- **PNL Commission:** Profit-and-loss based commission models
- **Registration Commission:** Base registration-triggered payments
- **Display Settings:** Flags controlling which commission fields are visible/active

### 2.3 Plan Configuration Management
Beyond the `tblaff_AffiliateTypes` record, the procedure manages three plan configuration tables:
- **AffiliateConfiguration.FirstPositionAssetPlan:** Defines commission rules based on the first trading position of referred traders
- **AffiliateConfiguration.IOBPlan:** Defines Introducing Office of Business plan parameters
- **AffiliateConfiguration.ISAPlan:** Defines Investment Services Agreement plan parameters

### 2.4 Field-Level Audit Logging
On UPDATE, every field is individually compared. Each changed field generates a separate audit log entry with:
- Old value and new value
- Field name/identifier
- Performing user and reason of change
- AffiliateTypeID as the referenced entity

### 2.5 Category Associations
The procedure may invoke `SetAffiliateTypeCategory` to manage category assignments for the affiliate type, ensuring that category access is updated atomically with the type configuration.

### 2.6 Transaction Safety
Given the multi-table nature of the save operation (type record + plans + categories), the procedure operates within a transaction to ensure atomicity across all related changes.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

Key parameters are listed below. The procedure accepts 80+ parameters total covering all commission rates and configuration fields.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTypeID | INT | No | 0 | CODE-BACKED | 0 for INSERT, >0 for UPDATE of existing type |
| 2 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 3 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 4 | @Description | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Affiliate type name/description |
| 5 | @DepositCommission | DECIMAL | Yes | NULL | CODE-BACKED | Base deposit commission rate |
| 6 | @SaleCommission | DECIMAL | Yes | NULL | CODE-BACKED | Revenue-share sale commission rate |
| 7 | @LeadCommission | DECIMAL | Yes | NULL | CODE-BACKED | Per-lead commission amount |
| 8 | @ClickCommission | DECIMAL | Yes | NULL | CODE-BACKED | Per-click commission amount |
| 9 | @CopyTraderCommission | DECIMAL | Yes | NULL | CODE-BACKED | Copy trading referral commission |
| 10 | @PNLCommission | DECIMAL | Yes | NULL | CODE-BACKED | PNL-based commission rate |
| 11 | @RegistrationCommission | DECIMAL | Yes | NULL | CODE-BACKED | Per-registration commission amount |
| 12 | @ShowDeposit | BIT | Yes | 0 | CODE-BACKED | Display flag for deposit commission |
| 13 | @ShowSale | BIT | Yes | 0 | CODE-BACKED | Display flag for sale commission |
| 14 | @ShowLead | BIT | Yes | 0 | CODE-BACKED | Display flag for lead commission |
| 15 | @ShowClick | BIT | Yes | 0 | CODE-BACKED | Display flag for click commission |
| 16 | @ShowCopyTrader | BIT | Yes | 0 | CODE-BACKED | Display flag for copy trader commission |
| 17 | @ShowPNL | BIT | Yes | 0 | CODE-BACKED | Display flag for PNL commission |
| 18 | @FirstPositionAssetPlan | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | JSON or structured plan data for first position commissions |
| 19 | @IOBPlan | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | IOB plan configuration data |
| 20 | @ISAPlan | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | ISA plan configuration data |
| - | *(~60 additional)* | Various | Yes | Various | CODE-BACKED | Additional commission rates, tier thresholds, display flags, and plan parameters |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_AffiliateTypes` | Table | INSERT or UPDATE type record |
| `AffiliateConfiguration.FirstPositionAssetPlan` | Table | Manage first position plan |
| `AffiliateConfiguration.IOBPlan` | Table | Manage IOB plan |
| `AffiliateConfiguration.ISAPlan` | Table | Manage ISA plan |
| `dbo.tblaff_AffiliateTypeCategories` | Table | Category associations (via SetAffiliateTypeCategory) |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate type configuration screen | Application | Create or edit affiliate types |
| Commission plan management | Application | Define and modify commission structures |
| API type management | Application | REST endpoint for type CRUD |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertAffiliateType` -> check mode -> INSERT or (SELECT + compare + UPDATE) `tblaff_AffiliateTypes` -> manage `FirstPositionAssetPlan` + `IOBPlan` + `ISAPlan` -> `SetAffiliateTypeCategory` -> `AuditLog` (INSERT per changed field)

### 6.1 Depends On
- `dbo.tblaff_AffiliateTypes` - Core type record storage
- `AffiliateConfiguration.FirstPositionAssetPlan` - First position plan table
- `AffiliateConfiguration.IOBPlan` - IOB plan table
- `AffiliateConfiguration.ISAPlan` - ISA plan table
- `dbo.tblaff_AffiliateTypeCategories` - Category junction table
- `AffiliateAdmin.SetAffiliateTypeCategory` - Category replacement procedure
- `dbo.AuditLog` - Audit trail storage

### 6.2 Depend On This
No known database dependencies. Called from application layer affiliate type management module.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Create a new affiliate type with basic commission rates
EXEC AffiliateAdmin.UpdateInsertAffiliateType
    @AffiliateTypeID = 0,
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'New premium affiliate tier',
    @Description = N'Premium Partners',
    @DepositCommission = 25.00,
    @SaleCommission = 0.05,
    @LeadCommission = 10.00,
    @ShowDeposit = 1,
    @ShowSale = 1,
    @ShowLead = 1;
```

```sql
-- 2. Update commission rates for an existing type
EXEC AffiliateAdmin.UpdateInsertAffiliateType
    @AffiliateTypeID = 5,
    @UserEmail = N'finance@company.com',
    @ReasonOfChange = N'Q2 commission rate adjustment',
    @DepositCommission = 30.00,
    @SaleCommission = 0.07,
    @PNLCommission = 0.10,
    @ShowPNL = 1;
```

```sql
-- 3. Update display settings to show/hide commission columns
EXEC AffiliateAdmin.UpdateInsertAffiliateType
    @AffiliateTypeID = 3,
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'Enable copy trader commission display',
    @ShowCopyTrader = 1,
    @CopyTraderCommission = 15.00;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4763, PART-4262, PART-2448, PART-5461.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertAffiliateType | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.sql*
