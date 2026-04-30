# dbo.UpdateAffiliateType

## 1. Overview

Updates an existing affiliate type record in `tblaff_AffiliateTypes` with a complete set of commission configuration fields, and generates field-level audit log entries for every field that has changed. Covers the full commission structure including per-tier rates for CPA, Sales, Leads, Registrations, Clicks, Copy Traders, and First Positions, as well as slab-based commission thresholds, display settings, and cookie behaviour. This is the update-only counterpart to `UpdateInsertAffiliateType`.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_AffiliateTypes |
| Secondary Tables | dbo.AuditLog |
| Operation | UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

The procedure accepts approximately 130 parameters covering the complete affiliate type configuration. Key groupings:

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateTypeID | IN | Int | required | ID of the affiliate type to update. |
| @UserID | IN | Int | required | UserID performing the update; written to audit rows. |
| @ChangedSectionID | IN | Int | required | Audit log section ID. |
| @ReasonOfChange | IN | NVarChar(1000) | required | Audit log reason string. |
| @ReferencedChangedID | IN | Int | required | Referenced entity ID for audit rows. |
| @Description | IN | NVarChar(100) | NULL | Affiliate type description/name. |
| @Notes | IN | NVarChar(255) | NULL | Internal notes. |
| @Tiers | IN | Int | required | Number of commission tiers (1-5). |
| @TierType | IN | Int | required | Tier calculation method. |
| @PerCopyTrader | IN | Bit | required | Enable Copy Trader commission. |
| @PerDeposit | IN | Bit | required | Enable deposit (CPA) commission. |
| @PerSale | IN | Bit | required | Enable revenue share (sale) commission. |
| @PerPNL | IN | Bit | required | Enable PNL-based commission. |
| @PerLead | IN | Bit | required | Enable lead commission. |
| @PerRegistration | IN | Bit | required | Enable registration commission. |
| @PerClick | IN | Bit | required | Enable click commission. |
| @FlatRateOrPercentOfSale | IN | Bit | required | Commission calculation mode. |
| @CPAOrCPAD | IN | Bit | required | CPA vs CPAD qualification mode. |
| @PerDepositRate ... @PerDepositRate5 | IN | Float | required | Per-tier deposit commission rates. |
| @PerSaleRate ... @PerSaleRate5 | IN | Float | required | Per-tier sale commission rates. |
| @PerLeadRate ... @PerLeadRate5 | IN | Float | required | Per-tier lead commission rates. |
| @PerRegistrationRate ... @PerRegistrationRate5 | IN | Float | required | Per-tier registration commission rates. |
| @PerClickRate ... @PerClickRate5 | IN | Float | required | Per-tier click commission rates. |
| @AllTiersRate2 ... @AllTiersRate5 | IN | Float | required | Cross-tier override rates. |
| @CopyTraderSlab1To ... @CopyTraderSlab4Amount | IN | Int/Float | required | Copy Trader slab thresholds and amounts. |
| @DepositSlab1To ... @DepositSlab4Amount | IN | Int/Float | required | Deposit slab thresholds and amounts. |
| @SaleSlab1To ... @SaleSlab4Percent | IN | Int/Float | required | Revenue slab thresholds and percentages. |
| @CPADPercent | IN | Float | required | CPAD percentage rate. |
| @PNLSlab1To ... @PNLSlab4Percent | IN | Int/Float | required | PNL slab thresholds and percentages. |
| @LeadPerCountry | IN | Bit | required | Whether lead commission is per-country. |
| @RegistrationPerCountry | IN | Bit | required | Whether registration commission is per-country. |
| @MinimumCommission | IN | Float | NULL | Minimum commission amount. |
| (Display / cookie / bonus params) | IN | Bit/Int/Float | required | ~30 display settings and cookie/bonus configuration fields. |

## 5. Business Logic

1. Reads the current values of all updatable fields from `tblaff_AffiliateTypes` for `@AffiliateTypeID` into corresponding `_old` variables.
2. For each field, compares the old value to the new value; if different, INSERTs an audit row into `AuditLog` recording `ChangedSectionID`, the old and new values, the field name, and `ActionID = 2`.
3. Executes a single UPDATE on `tblaff_AffiliateTypes` setting all columns to the supplied parameter values.
4. `SET NOCOUNT ON` prevents row-count messages.
5. No explicit transaction; the UPDATE and each audit INSERT are individual implicit transactions.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_AffiliateTypes | Table | dbo | Stores affiliate type commission configurations |
| dbo.AuditLog | Table | dbo | Field-level audit trail |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The large number of parameters reflects the wide schema of `tblaff_AffiliateTypes`; the pattern of read-compare-audit-update is standard for this system's administrative procedures.
- No transaction wraps the audit inserts; if the server crashes mid-procedure some audit rows may be missing.
- For fields with no change, no audit row is written, keeping the audit log clean.

## 8. Usage Examples

```sql
-- Minimal call pattern (most parameters required; shown abbreviated)
EXEC dbo.UpdateAffiliateType
    @AffiliateTypeID    = 5,
    @UserID             = 99,
    @ChangedSectionID   = 2,
    @ReasonOfChange     = N'Updated CPA rates for Q3',
    @ReferencedChangedID= 5,
    @Description        = N'Standard CPA Plan',
    @Tiers              = 2,
    @TierType           = 1,
    @PerDeposit         = 1,
    @PerDepositRate     = 300.0,
    @PerDepositRate2    = 200.0,
    -- ... (all remaining parameters must be supplied)
    @MinimumCommission  = NULL;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2017-03-27 | Geri Reshef | 44363 | Created: [AW] - Affiliates CPA DCPA Qualified - DB changes |

---
*Object: dbo.UpdateAffiliateType | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateAffiliateType.sql*
