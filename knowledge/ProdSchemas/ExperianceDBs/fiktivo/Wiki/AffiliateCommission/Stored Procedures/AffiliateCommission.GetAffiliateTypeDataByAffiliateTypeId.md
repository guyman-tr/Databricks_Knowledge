# AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId

> Retrieves the complete commission compensation plan directly by AffiliateTypeID, returning four result sets covering base rates, first-position asset plans, IOB plans, and ISA plans.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 4 result sets of commission configuration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAffiliateTypeDataByAffiliateTypeId is the direct-by-type variant of the commission configuration loader. While GetAffiliateTypeDataByAffiliateId requires an AffiliateID and resolves the type through a join, this procedure takes the AffiliateTypeID directly, making it more efficient when the caller already knows the type (e.g., during batch processing or when configuring affiliate types in the admin system).

This procedure returns the same 4 result sets as its sibling: (1) full affiliate type rate card from dbo.tblaff_AffiliateTypes, (2) country-specific first-position CPA rates from AffiliateConfiguration.FirstPositionAssetPlan, (3) IOB plan rates, and (4) ISA plan rates. The key difference is that it queries dbo.tblaff_AffiliateTypes directly by AffiliateTypeID without needing the join through dbo.tblaff_Affiliates.

The procedure is called when the system needs the compensation configuration for an affiliate type itself (as opposed to a specific affiliate instance), such as during affiliate type management, plan configuration review, or batch commission recalculation across all affiliates of a type.

---

## 2. Business Logic

### 2.1 Direct Type Lookup (No Affiliate Resolution)

**What**: Retrieves the compensation plan by AffiliateTypeID directly, bypassing the affiliate-to-type resolution step.

**Columns/Parameters Involved**: `@ID` (AffiliateTypeID)

**Rules**:
- Queries dbo.tblaff_AffiliateTypes WHERE AffiliateTypeID = @ID (no join to dbo.tblaff_Affiliates)
- Result Set 1: Full rate card (35+ columns of commission rates, slab thresholds, tier config)
- Result Set 2: FirstPositionAssetPlan WHERE AffiliateTypeID = @ID
- Result Set 3: IOBPlan WHERE AffiliateTypeID = @ID
- Result Set 4: ISAPlan WHERE AffiliateTypeID = @ID
- Same output structure as GetAffiliateTypeDataByAffiliateId

### 2.2 Multi-Compensation-Model Rate Card

**What**: Returns the full commission rate configuration supporting multiple compensation models.

**Columns/Parameters Involved**: `PerDeposit`, `CPAOrCPAD`, `PerSale`, `PerPNL`, `PerFirstPosition`, `PerRegistration`

**Rules**:
- Same compensation models as GetAffiliateTypeDataByAffiliateId: per-deposit, CPA/CPAD, per-sale, per-PnL, per-first-position, per-registration
- Slab-based rate tiers for deposits (4 tiers), sales (4 tiers), and PnL (4 tiers)
- Multi-tier referral support up to 5 tiers with configurable rates

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int (IN) | NO | - | CODE-BACKED | The AffiliateTypeID to look up directly. Matched against dbo.tblaff_AffiliateTypes.AffiliateTypeID and the plan tables. |

**Result Sets: Same 4 result sets as GetAffiliateTypeDataByAffiliateId** (see that procedure's documentation for the full 30-column element listing). Key columns in Result Set 1:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AffiliateTypeID | int | - | - | CODE-BACKED | Compensation plan identifier. |
| 3 | PerDeposit | - | - | - | CODE-BACKED | Commission rate per deposit event. |
| 4 | CPAOrCPAD | - | - | - | CODE-BACKED | CPA vs CPAD compensation model flag. |
| 5 | PerSale | - | - | - | CODE-BACKED | Commission rate per closed position. |
| 6 | PerPNL | - | - | - | CODE-BACKED | Commission rate based on PnL. |
| 7 | Tiers | - | - | - | CODE-BACKED | Number of referral tiers (1-5). |
| 8 | TierType | - | - | - | CODE-BACKED | How tier rates are applied. |
| 9 | MinimumCommission | - | - | - | CODE-BACKED | Floor amount for commission payout. |
| 10 | IsTradeRequired | - | - | - | CODE-BACKED | Whether a trade is required for registration commission. |
| 11 | PerRegistration | - | - | - | CODE-BACKED | Registration commission rate. |
| 12 | PerFirstPosition | - | - | - | CODE-BACKED | First-position CPA commission flag. |
| 13 | PerFirstPositionRate | - | - | - | CODE-BACKED | Base rate for first-position commissions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | dbo.tblaff_AffiliateTypes | READ (SELECT) | Direct lookup by AffiliateTypeID for the full rate card |
| @ID | AffiliateConfiguration.FirstPositionAssetPlan | READ (SELECT) | Country-specific first-position CPA rates for this type |
| @ID | AffiliateConfiguration.IOBPlan | READ (SELECT) | Country-specific IOB commission rates for this type |
| @ID | AffiliateConfiguration.ISAPlan | READ (SELECT) | ISA product commission rates for this type |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. Called by the commission engine or admin tools when the AffiliateTypeID is already known.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId (procedure)
+-- dbo.tblaff_AffiliateTypes (table, external)
+-- AffiliateConfiguration.FirstPositionAssetPlan (table, external)
+-- AffiliateConfiguration.IOBPlan (table, external)
+-- AffiliateConfiguration.ISAPlan (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table (external) | Direct SELECT by AffiliateTypeID for the full commission rate card |
| AffiliateConfiguration.FirstPositionAssetPlan | Table (external) | SELECT by AffiliateTypeID for country/asset CPA rates |
| AffiliateConfiguration.IOBPlan | Table (external) | SELECT by AffiliateTypeID for country IOB commissions |
| AffiliateConfiguration.ISAPlan | Table (external) | SELECT by AffiliateTypeID for ISA product commissions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine / Admin tools) | External | Loads rate card by type ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get compensation plan for affiliate type 1
```sql
EXEC [AffiliateCommission].[GetAffiliateTypeDataByAffiliateTypeId] @ID = 1
```

### 8.2 List all affiliate types with their key rates
```sql
SELECT AffiliateTypeID, PerDeposit, CPAOrCPAD, PerSale, PerPNL, Tiers, MinimumCommission
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
ORDER BY AffiliateTypeID
```

### 8.3 Compare country-specific CPA rates across affiliate types
```sql
SELECT fpa.AffiliateTypeID, fpa.CountryID, fpa.PositionAssetTypeID, fpa.CPAAmount
FROM AffiliateConfiguration.FirstPositionAssetPlan AS fpa WITH (NOLOCK)
ORDER BY fpa.AffiliateTypeID, fpa.CountryID
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found for this object. Jira MCP unavailable (410).

DDL comments reference:
- PART-4763: Update (2025-09-10)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-1195: Added PerRegistration column (2023-02-26)
- PART-5458: Support for ISA plan (2026-01-22)
- Unlabeled: Added IsTradeRequired column (2022-01-02)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId.sql*
