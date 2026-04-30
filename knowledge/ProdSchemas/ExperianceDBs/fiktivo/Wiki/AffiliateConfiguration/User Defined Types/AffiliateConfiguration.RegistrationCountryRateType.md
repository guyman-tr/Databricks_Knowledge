# AffiliateConfiguration.RegistrationCountryRateType

> Table-valued parameter type for bulk-inserting country-specific commission rates, reused for both registration rate plans and IOB (Introducing Broker) per-country commission plans.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | User Defined Type |
| **Key Identifier** | TVP (Table-Valued Parameter) - no primary key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateConfiguration.RegistrationCountryRateType is a general-purpose table-valued parameter (TVP) for passing country-specific commission rates into stored procedures. Despite its name suggesting registration rates only, it is reused for two distinct commission types: per-registration country rates and IOB (Introducing Broker) per-country commissions. Its simple two-column structure (CountryID + Rate) makes it versatile for any country-keyed rate configuration.

Without this TVP, the admin system would need individual INSERT statements per country when configuring geo-targeted commission rates. The TVP enables atomic bulk operations for rate plan management.

This TVP is consumed by two procedures:
1. [AffiliateAdmin.UpdateInsertAffiliateType](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) - as both `@RegistrationRateCountry` (for registration rates) and `@IOBPerCountry` (for IOB commissions)
2. [AffiliateAdmin.UpdateRegistrationRateCountry](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateRegistrationRateCountry.md) - as `@RegistrationRateCountry` for standalone registration rate updates

---

## 2. Business Logic

### 2.1 Dual-Purpose Country Rate Container

**What**: A generic country-to-rate mapping reused for two different commission models within the same procedure call.

**Columns/Parameters Involved**: `CountryID`, `Rate`

**Rules**:
- When used as `@RegistrationRateCountry`: Rate = per-registration commission for affiliates whose referred customers register from this country. Targets dbo.tblaff_Registration2Country.
- When used as `@IOBPerCountry`: Rate = IOB (Introducing Broker) commission for sub-affiliates from this country. Targets AffiliateConfiguration.IOBPlan (mapped to Commission column).
- CountryIDs are validated against dbo.tblaff_Country before insertion in both use cases
- Invalid countries trigger RAISERROR ('Invalid countries in Registration rates' or similar)
- Both use cases follow a compare-and-replace pattern (STRING_AGG old vs new, delete-and-reinsert if changed)

**Diagram**:
```
Admin UI -> @RegistrationRateCountry TVP -----> tblaff_Registration2Country
         -> @IOBPerCountry TVP (same type) ---> AffiliateConfiguration.IOBPlan
              |
              v
  UpdateInsertAffiliateType
    For each TVP:
      1. Validate CountryIDs against tblaff_Country
      2. Compare old vs new (STRING_AGG)
      3. If changed: DELETE old, INSERT new
      4. Audit log
```

### 2.2 Country Validation Gate

**What**: Both consuming procedures validate that every CountryID in the TVP exists in the country reference table before applying changes.

**Columns/Parameters Involved**: `CountryID`

**Rules**:
- The procedure counts distinct countries in the TVP and compares against matched countries in tblaff_Country
- If counts differ, at least one CountryID is invalid
- Invalid countries cause RAISERROR with severity 16, aborting the transaction
- This prevents orphaned rate entries pointing to non-existent countries

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter shape definition, not a persisted data store. See [dbo.tblaff_Registration2Country] for registration rate data or [AffiliateConfiguration.IOBPlan](../Tables/AffiliateConfiguration.IOBPlan.md) for IOB commission data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Target country for this rate entry. References [dbo.tblaff_Country](../../dbo/Tables/dbo.tblaff_Country.md). Validated by consuming procedures against tblaff_Country; invalid IDs trigger RAISERROR. Note: int type here vs bigint in tblaff_Country and FirstPositionAssetPlan - implicitly narrowed. |
| 2 | Rate | float | NO | - | CODE-BACKED | Commission rate for affiliates whose referred customers are from this country. Interpretation depends on usage context: as @RegistrationRateCountry it is a per-registration commission amount; as @IOBPerCountry it maps to the Commission column in IOBPlan (IOB per-country commission). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | dbo.tblaff_Country | Implicit | Country targeted by this rate entry. Validated at runtime by consuming procedures |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateInsertAffiliateType | @RegistrationRateCountry | Parameter Type | Carries per-registration country rates for tblaff_Registration2Country |
| AffiliateAdmin.UpdateInsertAffiliateType | @IOBPerCountry | Parameter Type | Reused to carry IOB per-country commissions for AffiliateConfiguration.IOBPlan |
| AffiliateAdmin.UpdateRegistrationRateCountry | @RegistrationRateCountry | Parameter Type | Standalone registration rate update procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is a type definition with no executable SQL.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | Accepts this TVP twice: as @RegistrationRateCountry and as @IOBPerCountry |
| AffiliateAdmin.UpdateRegistrationRateCountry | Stored Procedure | Accepts this TVP as @RegistrationRateCountry for standalone rate updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. Validation is performed by the consuming stored procedures (country existence checks with RAISERROR on mismatch).

---

## 8. Sample Queries

### 8.1 Declare and populate TVP for registration rates

```sql
DECLARE @regRates AffiliateConfiguration.RegistrationCountryRateType;

INSERT INTO @regRates (CountryID, Rate)
VALUES
  (233, 15.00),   -- US: $15 per registration
  (230, 12.00),   -- UK: $12 per registration
  (81, 10.00);    -- Germany: $10 per registration

EXEC AffiliateAdmin.UpdateRegistrationRateCountry
  @AffiliateTypeID = 418,
  @RegistrationRateCountry = @regRates;
```

### 8.2 Reuse TVP type for IOB per-country commissions

```sql
DECLARE @iobRates AffiliateConfiguration.RegistrationCountryRateType;

INSERT INTO @iobRates (CountryID, Rate)
VALUES
  (0, 77),      -- Global default: 77 commission
  (233, 100);   -- US-specific: 100 commission

-- Passed as @IOBPerCountry to UpdateInsertAffiliateType
-- (same TVP type, different parameter name, targets IOBPlan table)
```

### 8.3 Validate TVP countries against reference table

```sql
DECLARE @rates AffiliateConfiguration.RegistrationCountryRateType;
-- (populate @rates)

SELECT r.CountryID, c.Name AS CountryName
FROM @rates r
LEFT JOIN dbo.tblaff_Country c WITH (NOLOCK) ON r.CountryID = c.CountryID
ORDER BY r.CountryID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CPA New Compensation Plan - DB design](https://etoro-jira.atlassian.net/wiki/x/PLACEHOLDER) | Confluence | Registration rate configuration is part of the broader CPA compensation plan architecture |

PART-2448 (Jira): CPA New Compensation Design - introduced RegistrationCountryRateType as part of the new admin procedure structure (referenced in procedure header comments, Dec 2023).
PART-4262 (Jira): Referenced in UpdateRegistrationRateCountry procedure header (Apr 2025 update).
PART-4763 (Jira): IOB feature - added the reuse of this TVP as @IOBPerCountry (Sep 2025).

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.RegistrationCountryRateType | Type: User Defined Type | Source: fiktivo/AffiliateConfiguration/User Defined Types/AffiliateConfiguration.RegistrationCountryRateType.sql*
