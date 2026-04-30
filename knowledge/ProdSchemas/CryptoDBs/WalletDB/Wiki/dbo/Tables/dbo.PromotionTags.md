# dbo.PromotionTags

> SCD Type 2 history table tracking promotional crypto reward tags, defining tagged amounts of specific cryptocurrencies for marketing campaigns with temporal validity.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (int, no PK constraint) |
| **Partition** | No |
| **Indexes** | 1 active (ix_PromotionTags CLUSTERED on EndDate, BeginDate) |

---

## 1. Business Meaning

This table defines cryptocurrency-based promotional reward tags used in marketing campaigns. Each row represents a tagged promotion for a specific cryptocurrency with a defined reward amount and temporal validity window (BeginDate/EndDate SCD Type 2 pattern). Promotions might include "Buy BTC and get X bonus" or crypto-specific campaign incentives.

The table currently has 0 rows, suggesting promotions are either managed elsewhere now or the feature is dormant. The SCD Type 2 pattern with PAGE compression and clustered index on EndDate/BeginDate follows the same temporal pattern as other dbo history tables (Wallets, TransactionsHistory, RedemptionsHistory).

No stored procedures, views, or functions reference this table directly. It may have been consumed by application code or external reporting.

---

## 2. Business Logic

### 2.1 Temporal Versioning (SCD Type 2)

**What**: Each promotion tag is versioned using BeginDate/EndDate ranges - the same pattern used across all dbo history tables.

**Columns/Parameters Involved**: `Id`, `BeginDate`, `EndDate`

**Rules**:
- Current/active version has EndDate in the far future (e.g., '3000-01-01')
- Historical versions have EndDate set to the time the next version was created
- BeginDate marks when this version became effective

---

## 3. Data Overview

Table is currently empty (0 rows). No sample data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Promotion tag identifier. Groups all temporal versions of the same promotion definition. |
| 2 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency this promotion applies to. Maps to Wallet.CryptoTypes: 1=BTC, 2=ETH, 3=BCH, 4=XRP, etc. |
| 3 | Name | varchar(100) | NO | - | NAME-INFERRED | Display name or label for the promotion tag (e.g., campaign name or reward type identifier). |
| 4 | Description | varchar(100) | YES | - | NAME-INFERRED | Human-readable description of the promotion - what the tag represents or the campaign context. |
| 5 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Promotional reward amount in native cryptocurrency units. The crypto value associated with this promotion tag. |
| 6 | BeginDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version start timestamp. When this version of the promotion tag became effective. |
| 7 | EndDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version end timestamp. Far-future date (e.g., 3000-01-01) indicates the current active version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | Implicit | Cryptocurrency the promotion applies to (1=BTC, 2=ETH, etc.) |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PromotionTags | CLUSTERED | EndDate, BeginDate | - | - | Active |

Data compression: PAGE.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find active promotion tags
```sql
SELECT Id, CryptoId, Name, Description, Amount
FROM dbo.PromotionTags WITH (NOLOCK)
WHERE EndDate > GETDATE() AND BeginDate <= GETDATE()
```

### 8.2 Promotion history for a specific tag
```sql
SELECT Id, Name, Amount, BeginDate, EndDate
FROM dbo.PromotionTags WITH (NOLOCK)
WHERE Id = 1
ORDER BY BeginDate
```

### 8.3 Promotions by crypto with readable names
```sql
SELECT pt.Id, ct.Name AS CryptoName, pt.Name, pt.Amount, pt.BeginDate, pt.EndDate
FROM dbo.PromotionTags pt WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = pt.CryptoId
ORDER BY pt.CryptoId, pt.BeginDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.8/10 (Elements: 7.1/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PromotionTags | Type: Table | Source: WalletDB/dbo/Tables/dbo.PromotionTags.sql*
