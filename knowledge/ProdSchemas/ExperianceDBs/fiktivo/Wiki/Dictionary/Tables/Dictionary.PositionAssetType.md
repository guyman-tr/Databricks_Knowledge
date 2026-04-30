# Dictionary.PositionAssetType

> Lookup table classifying financial instrument asset classes for trading positions, used for commission segmentation and first-position-based affiliate plans.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PositionAssetType defines the 12 asset class categories for trading positions. When a customer opens a trading position, the instrument is classified into one of these asset types. This classification drives commission plan segmentation - affiliates may earn different commission rates depending on whether their referred customers trade Forex, Stocks, Crypto, or other asset classes.

This table is particularly important for the "First Position Asset Plan" commission model, where affiliates earn a one-time commission when a referred customer opens their first position in a specific asset class. The AffiliateConfiguration.FirstPositionAssetPlan and AffiliateConfiguration.TraderFirstAssetPosition tables reference this for tracking which asset classes a customer has traded.

PositionAssetType is referenced by configuration tables, reporting procedures, and the commission calculation pipeline. Reports segment commission revenue by asset type to show which products drive the most affiliate value.

---

## 2. Business Logic

### 2.1 Asset Class Taxonomy

**What**: Twelve asset classes plus a wildcard "All" value for filter contexts, covering the full range of tradeable instruments.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- ID=0 (All) is a wildcard/aggregate value used in filter contexts (e.g., commission plans that apply to all asset types)
- Traditional finance: Forex (1), Commodity (2), Indices (4), Stocks (5), ETF (6), Bonds (7)
- Derivatives: CFD (3), Options (9)
- Alternative: Crypto (10), TrustFunds (8)
- Platform-specific: Copy (11) represents CopyTrader positions where one trader mirrors another
- Commission plans typically define rates per asset type, with some using ID=0 as a default rate

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | All | Wildcard value representing all asset types in filter and configuration contexts. Used in commission plans as a default rate when no asset-specific rate is defined |
| 1 | Forex | Foreign exchange currency pairs (EUR/USD, GBP/JPY, etc.). The highest-volume asset class on the platform and traditionally the core affiliate revenue driver |
| 5 | Stocks | Individual company equities (Apple, Tesla, etc.). Growing asset class for affiliate commissions as stock trading adoption increases among retail traders |
| 10 | Crypto | Cryptocurrency assets (Bitcoin, Ethereum, etc.). High-volatility asset class with growing affiliate interest. May have different commission structures due to market characteristics |
| 11 | Copy | CopyTrader positions where one trader automatically mirrors another's trades. Platform-specific asset classification that tracks the social trading feature |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the asset class. Values: 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See [Position Asset Type](../../_glossary.md#position-asset-type) for full definitions. ID=0 serves as a wildcard in filter contexts. |
| 2 | Name | nvarchar(100) | NO | - | VERIFIED | Human-readable label for the asset class. Used in commission plan configuration, reporting displays, and admin UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateConfiguration.FirstPositionAssetPlan | PositionAssetTypeID | Implicit FK | Commission plan config for first-position bonuses by asset type |
| AffiliateConfiguration.TraderFirstAssetPosition | PositionAssetTypeID | Implicit FK | Tracks which asset classes each trader has opened their first position in |
| History.FirstPositionAssetPlan | PositionAssetTypeID | Implicit FK | Historical first-position plan snapshots |
| AffiliateAdmin.UpdateInsertAffiliateType | JOIN | Lookup | Admin procedure for configuring asset-type commission plans |
| AffiliateReport.ReportSummaryByAffiliate | GROUP BY | Aggregation | Reports aggregate by asset type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateConfiguration.FirstPositionAssetPlan | Table | Asset-type commission config |
| AffiliateConfiguration.TraderFirstAssetPosition | Table | Tracks first position per asset type |
| History.FirstPositionAssetPlan | Table | Historical plan records |
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | MODIFIER - configures asset-type plans |
| AffiliateAdmin.GetAffiliateTypeData | Stored Procedure | READER - returns asset-type config |
| AffiliateReport.ReportSummaryByAffiliate | Stored Procedure | READER - aggregates by asset type |
| AffiliateCommission.SetTraderFirstAssetPosition | Stored Procedure | WRITER - records first position by asset type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryPositionAssetType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all asset types (excluding wildcard)
```sql
SELECT ID, Name
FROM Dictionary.PositionAssetType WITH (NOLOCK)
WHERE ID > 0
ORDER BY ID
```

### 8.2 Show first-position plan rates by asset type
```sql
SELECT pat.Name AS AssetType, fp.CommissionRate
FROM AffiliateConfiguration.FirstPositionAssetPlan fp WITH (NOLOCK)
JOIN Dictionary.PositionAssetType pat WITH (NOLOCK) ON fp.PositionAssetTypeID = pat.ID
ORDER BY pat.ID
```

### 8.3 Check which asset types a trader has first-position credit for
```sql
SELECT pat.Name AS AssetType, tfap.FirstPositionDate
FROM AffiliateConfiguration.TraderFirstAssetPosition tfap WITH (NOLOCK)
JOIN Dictionary.PositionAssetType pat WITH (NOLOCK) ON tfap.PositionAssetTypeID = pat.ID
WHERE tfap.TraderID = @TraderID
ORDER BY tfap.FirstPositionDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PositionAssetType | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.PositionAssetType.sql*
