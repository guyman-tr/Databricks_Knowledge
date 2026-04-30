# dbo.UpdateInsertAffiliateType

## 1. Overview

Upserts an affiliate type record in `tblaff_AffiliateTypes`: inserts a new type when `@AffiliateTypeID = 0`, or updates all commission configuration fields on an existing type otherwise. For updates, generates field-level audit log entries for each field that has changed. Covers the complete commission structure including per-tier rates, slab thresholds, display settings, cookie behaviour, and promoted-country registration flags. Returns the ID of the affected type via an OUTPUT parameter.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_AffiliateTypes |
| Secondary Tables | dbo.AuditLog |
| Operation | INSERT or UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned. The ID of the inserted or updated affiliate type is returned via `@OutputAffiliateTypeID OUTPUT`.

## 4. Parameters

The procedure accepts approximately 140 parameters. Key groupings:

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateTypeID | IN | Int | 0 | 0 to insert a new type; existing ID to update. |
| @ChangedByUserID | IN | Int | required | UserID of the user performing the operation; written to audit rows. |
| @ReasonOfChange | IN | NVarChar(1000) | NULL | Reason written to audit log rows (update path only). |
| @ReferencedChangedID | IN | Int | NULL | Referenced entity ID for audit rows (update path only). |
| @Description | IN | NVarChar(100) | NULL | Affiliate type description/name. |
| @Notes | IN | NVarChar(255) | NULL | Internal notes. |
| @Tiers | IN | Int | required | Number of commission tiers (1-5). |
| @TierType | IN | Int | required | Tier calculation mode. |
| @PerCopyTrader ... @PerClick | IN | Bit | required | Commission-enable flags per event type. |
| @FlatRateOrPercentOfSale | IN | Bit | required | Commission calculation method. |
| @CPAOrCPAD | IN | Bit | required | CPA vs CPAD qualification logic. |
| @PerDepositRate ... @PerDepositRate5 | IN | Float | required | Per-tier deposit commission rates. |
| @PerSaleRate ... @PerSaleRate5 | IN | Float | required | Per-tier sale commission rates. |
| @PerLeadRate ... @PerLeadRate5 | IN | Float | required | Per-tier lead commission rates. |
| @PerRegistrationRate ... @PerRegistrationRate5 | IN | Float | required | Per-tier registration rates. |
| @PerClickRate ... @PerClickRate5 | IN | Float | required | Per-tier click rates. |
| @AllTiersRate2 ... @AllTiersRate5 | IN | Float | required | Cross-tier override rates. |
| @CopyTraderSlab1To ... @CopyTraderSlab4Amount | IN | Int/Float | required | Copy Trader slab thresholds and amounts. |
| @DepositSlab1To ... @DepositSlab4Amount | IN | Int/Float | required | Deposit slab thresholds and amounts. |
| @SaleSlab1To ... @SaleSlab4Percent | IN | Int/Float | required | Revenue slab thresholds and percentages. |
| @CPADPercent | IN | Float | required | CPAD percentage rate. |
| @PNLSlab1To ... @PNLSlab4Percent | IN | Int/Float | required | PNL slab thresholds and percentages. |
| @LeadPerCountry | IN | Bit | required | Lead commission per-country flag. |
| @RegistrationPerCountry | IN | Bit | required | Registration commission per-country flag. |
| @PerFirstPosition | IN | Bit | required | Enable first-position commission. |
| @PerFirstPositionRate | IN | Float | required | First-position commission rate. |
| @ActionID | IN | Int | NULL | Audit action ID; overridden to 2 for updates. |
| @OutputAffiliateTypeID | OUT | Int | NULL | OUTPUT: ID of the inserted or updated affiliate type. |
| @MinimumCommission | IN | Float | NULL | Minimum commission threshold. |
| @FatherAffiliateTypeID | IN | Int | NULL | Parent affiliate type ID for hierarchy. |
| @IsTradeRequired | IN | bit | required | Whether a trade is required for commission eligibility. |
| @BlockTrackingLinks | IN | tinyint | required | Tracking link blocking level. |
| @BlockCreatives | IN | tinyint | required | Creative blocking level. |
| (display/cookie/bonus params) | IN | Bit/Int/Float | required | ~30 display settings and cookie/bonus configuration fields. |

## 5. Business Logic

**Insert path (`@AffiliateTypeID = 0`):**
1. INSERTs a new row into `tblaff_AffiliateTypes` with all column values.
2. Retrieves the new `AffiliateTypeID` by `SELECT TOP 1 ... WHERE Description = @Description ORDER BY AffiliateTypeID DESC`.
3. Sets `@OutputAffiliateTypeID`.
4. INSERTs an audit row with action 1 and reason `'Add new affiliatesType With ID: <ID>'`.

**Update path (`@AffiliateTypeID != 0`):**
1. Forces `@ActionID = 2`.
2. Reads all current field values from `tblaff_AffiliateTypes` into `_old` variables.
3. For each field, if old != new, INSERTs an audit row with the field name, old value, and new value.
4. Executes a single UPDATE with all column values.
5. Does not populate `@OutputAffiliateTypeID` in the update path.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_AffiliateTypes | Table | dbo | Stores affiliate type commission configurations |
| dbo.AuditLog | Table | dbo | Field-level audit trail |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Like `UpdateInsertAffiliateGroup`, the new-ID retrieval after INSERT uses `SELECT TOP 1 ... ORDER BY DESC` which carries a concurrency risk; an `OUTPUT` clause would be safer.
- The parameter list is among the longest in the system (~140 params), reflecting the breadth of `tblaff_AffiliateTypes`; callers must supply all required parameters with no defaults.
- `@BlockTrackingLinks` and `@BlockCreatives` are `tinyint`; allowed values and their meanings should be documented in the affiliate type business rules.

## 8. Usage Examples

```sql
-- Insert a new affiliate type (abbreviated - all parameters required)
DECLARE @newTypeID INT;
EXEC dbo.UpdateInsertAffiliateType
    @AffiliateTypeID     = 0,
    @ChangedByUserID     = 99,
    @Description         = N'Hybrid CPA Plan',
    @Tiers               = 2,
    @TierType            = 1,
    @PerDeposit          = 1,
    @PerDepositRate      = 250.0,
    -- ... (all remaining required parameters)
    @IsTradeRequired     = 0,
    @BlockTrackingLinks  = 0,
    @BlockCreatives      = 0,
    @OutputAffiliateTypeID = @newTypeID OUTPUT;
SELECT @newTypeID AS NewAffiliateTypeID;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2022-03-14 | Gil Haba via Noga Rozen | ONBRD-5948 | Add promoted countries to Affiliate registration |

---
*Object: dbo.UpdateInsertAffiliateType | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateInsertAffiliateType.sql*
