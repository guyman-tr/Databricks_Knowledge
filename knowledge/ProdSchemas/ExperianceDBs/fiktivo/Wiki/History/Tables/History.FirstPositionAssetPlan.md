# History.FirstPositionAssetPlan

> SQL Server temporal history table storing all historical versions of first-position asset plan configurations, which define CPA commission amounts by affiliate type, country, and asset class for an affiliate's referred customer's first trade.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | ID (int) - plan entry identifier across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.FirstPositionAssetPlan is the system-versioned temporal history table for AffiliateConfiguration.FirstPositionAssetPlan. It captures every historical version of first-position commission plan configurations. These plans define how much CPA (Cost Per Acquisition) commission an affiliate earns when a referred customer opens their first trading position, segmented by affiliate type, country, and asset class (forex, stocks, crypto, etc.).

This table is critical for commission dispute resolution. When an affiliate questions why their first-position CPA amount differed from expectations, temporal queries reveal the exact plan configuration that was active at the time of the customer's first trade. It also supports compliance requirements by preserving the complete history of commission rate changes.

Data flows in automatically via SQL Server's temporal mechanism when AffiliateConfiguration.FirstPositionAssetPlan is modified. The Trace column shows that changes are triggered by the UpdateInsertAffiliateType procedure, indicating that first-position plans are managed as part of the affiliate type configuration workflow.

---

## 2. Business Logic

### 2.1 CPA Commission by Asset Class and Country

**What**: Each plan entry defines the CPA commission for a specific combination of affiliate type, country, and position asset type.

**Columns/Parameters Involved**: `AffiliateTypeID`, `CountryID`, `PositionAssetTypeID`, `CPAAmount`, `MinimumCommission`

**Rules**:
- AffiliateTypeID links to the affiliate's commission plan (dbo.tblaff_AffiliateTypes)
- CountryID = NULL means the plan applies to all countries (wildcard)
- PositionAssetTypeID = 0 means the plan applies to all asset types. See [Position Asset Type](_glossary.md#position-asset-type) for values (1=Forex, 5=Stocks, 10=Crypto, etc.)
- CPAAmount is the flat commission paid to the affiliate when the condition is met
- MinimumCommission sets a floor - if the calculated commission is below this, the minimum applies instead

---

## 3. Data Overview

| ID | AffiliateTypeID | CountryID | PositionAssetTypeID | MinimumCommission | CPAAmount | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 3866 | 4770 | NULL | 0 | 5.0 | 10.0 | 2026-02-18 07:39:05 | 2026-02-18 07:39:06 | Plan for affiliate type 4770 covering all countries and all asset types - $10 CPA with $5 minimum, superseded within 1 second (test) |
| 3844 | 4768 | NULL | 0 | 0.0 | 0.0 | 2026-02-17 21:59:14 | 2026-02-17 21:59:15 | Zero-commission plan entry - affiliate type does not earn first-position CPA |
| 3833 | 4767 | NULL | 0 | 0.0 | 0.0 | 2026-02-17 21:59:14 | 2026-02-17 21:59:15 | Another zero-commission plan - short-lived test configuration |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the plan entry. Matches AffiliateConfiguration.FirstPositionAssetPlan.ID. Multiple history rows share the same ID for version history. |
| 2 | AffiliateTypeID | int | NO | - | CODE-BACKED | The affiliate type this plan applies to. FK to dbo.tblaff_AffiliateTypes.AffiliateTypeID. Determines which affiliates receive this CPA rate. |
| 3 | CountryID | bigint | YES | - | CODE-BACKED | Country of the customer whose first position triggers the commission. NULL = applies to all countries (wildcard). When set, restricts this plan to customers from a specific country. |
| 4 | PositionAssetTypeID | int | NO | - | CODE-BACKED | Asset class of the first position. 0 = all asset types. See [Position Asset Type](../../Dictionary/Tables/Dictionary.PositionAssetType.md) for values: 1=Forex, 2=Commodity, 3=CFD, 5=Stocks, 10=Crypto, 11=Copy. |
| 5 | MinimumCommission | float | YES | - | CODE-BACKED | Minimum commission floor. If the calculated commission is below this amount, this minimum is paid instead. NULL or 0 = no minimum. |
| 6 | CPAAmount | float | NO | - | CODE-BACKED | Fixed CPA (Cost Per Acquisition) commission amount paid to the affiliate when a referred customer opens their first position matching this plan's criteria. |
| 7 | DateModified | datetime | NO | - | CODE-BACKED | Timestamp when this plan entry was last modified in the base table. |
| 8 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. Contains HostName, AppName, SUserName, SPID, DBName, ObjectName (typically "UpdateInsertAffiliateType"). |
| 9 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version became active. Set by SQL Server temporal mechanism. |
| 10 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version was superseded. Set by SQL Server temporal mechanism. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | AffiliateConfiguration.FirstPositionAssetPlan | Temporal History | Stores historical versions of the base table |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | The affiliate type plan this CPA configuration belongs to |
| PositionAssetTypeID | Dictionary.PositionAssetType | Implicit FK | Asset class filter for the first-position trigger |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on AffiliateConfiguration.FirstPositionAssetPlan.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FirstPositionAssetPlan (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateConfiguration.FirstPositionAssetPlan | Table | SYSTEM_VERSIONING - superseded versions stored here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FirstPositionAssetPlan | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View CPA plan history for a specific affiliate type
```sql
SELECT ID, AffiliateTypeID, CountryID, PositionAssetTypeID,
       CPAAmount, MinimumCommission, ValidFrom, ValidTo
FROM AffiliateConfiguration.FirstPositionAssetPlan FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateTypeID = 4770
ORDER BY ValidFrom
```

### 8.2 Find active CPA rates at a specific date
```sql
SELECT fp.AffiliateTypeID, at.Description AS AffiliateTypeName,
       fp.PositionAssetTypeID, fp.CPAAmount, fp.MinimumCommission
FROM AffiliateConfiguration.FirstPositionAssetPlan FOR SYSTEM_TIME AS OF '2025-06-01' fp WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON fp.AffiliateTypeID = at.AffiliateTypeID
WHERE fp.CPAAmount > 0
ORDER BY fp.AffiliateTypeID
```

### 8.3 Audit recent CPA plan changes
```sql
SELECT ID, AffiliateTypeID, CPAAmount, MinimumCommission,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       ValidFrom, ValidTo
FROM History.FirstPositionAssetPlan WITH (NOLOCK)
WHERE ValidTo > DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FirstPositionAssetPlan | Type: Table | Source: fiktivo/History/Tables/History.FirstPositionAssetPlan.sql*
