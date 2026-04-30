# dbo.qry_aff_FirstPositionsDetailAllTiers

> Pivoted all-tiers detail view for FirstPositions events, joining the base event table with all 5 tier-filter views to show complete multi-tier commission breakdown per event in a single row.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_FirstPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_FirstPositionsDetailAllTiers is the comprehensive detail view for FirstPositions commissions, pivoting all 5 tier levels into a single row per event. It LEFT OUTER JOINs the base event table (tblaff_FirstPositions) with each of the 5 tier-filter views (qry_aff_Tier1-5FirstPositionsCommissions) and tblaff_Country for the country name. This produces a denormalized row showing the event details alongside each tier's affiliate, commission amount, paid status, and sub-affiliate tag.

Used by the affiliate admin interface for detailed commission reports where users need to see all tier breakdowns for each event on a single line.

---

## 2. Business Logic

### 2.1 All-Tiers Pivot Pattern

**What**: Flattens 5 separate tier commission records into one row per event.

**Columns/Parameters Involved**: FirstPositionID, Tier1-5 AffiliateID/Commission/Paid/SubAffiliateID

**Rules**:
- LEFT OUTER JOIN ensures events appear even if they have no commission at certain tiers
- Tier1 is always the direct affiliate; Tier 2-5 are parent affiliates
- NULL values in TierN columns mean no commission exists at that tier level
- CountryName is resolved from tblaff_Country via CountryID

---

## 3. Data Overview

Pivoted view combining event details with all 5 tier commission breakdowns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FirstPositionID | int | NO | - | VERIFIED | Event ID from base table. |
| 2 | CUSTOMER_ID | nvarchar(50) | YES | - | VERIFIED | Customer identifier. |
| 3 | ORDER_DATE | datetime | YES | - | VERIFIED | Event date. |
| 4 | COUNTRY | nvarchar(50) | YES | - | VERIFIED | Country name (denormalized). |
| 5 | GRAND_TOTAL | float | YES | - | VERIFIED | Event total amount. |
| 6 | AffiliateFirstPositionAccepted | bit/int | YES | - | VERIFIED | Whether the affiliate accepted this event for commission. |
| 7 | IPAddress | nvarchar | YES | - | VERIFIED | Customer IP at time of event. |
| 8 | Browser | nvarchar | YES | - | VERIFIED | Customer browser. |
| 9 | Valid | bit/int | YES | - | VERIFIED | Event validity flag. |
| 10 | Reason | nvarchar | YES | - | VERIFIED | Rejection reason if invalid. |
| 11 | BannerID | int | YES | - | VERIFIED | Marketing banner. |
| 12 | DaysToConvert | int | YES | - | VERIFIED | Days from registration to this event. |
| 13 | Optional1-3 | nvarchar | YES | - | VERIFIED | Optional tracking fields. |
| 14 | DownloadID | int | YES | - | VERIFIED | Download tracking. |
| 15 | ProviderID | int | YES | - | VERIFIED | Provider/broker. |
| 16 | CountryName | nvarchar | YES | - | VERIFIED | Country name from tblaff_Country JOIN. |
| 17-19 | Tier1AffiliateID, Tier1Commission, Tier1Paid | int/float/bit | YES | - | VERIFIED | Tier 1 (direct) commission details. |
| 20-22 | Tier2AffiliateID, Tier2Commission, Tier2Paid | int/float/bit | YES | - | VERIFIED | Tier 2 commission details. |
| 23-25 | Tier3AffiliateID, Tier3Commission, Tier3Paid | int/float/bit | YES | - | VERIFIED | Tier 3 commission details. |
| 26-28 | Tier4AffiliateID, Tier4Commission, Tier4Paid | int/float/bit | YES | - | VERIFIED | Tier 4 commission details. |
| 29-31 | Tier5AffiliateID, Tier5Commission, Tier5Paid | int/float/bit | YES | - | VERIFIED | Tier 5 commission details. |
| 32-36 | Tier1-5SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tags per tier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (event cols) | dbo.tblaff_FirstPositions | Base table | Event details |
| (tier 1 cols) | dbo.qry_aff_Tier1FirstPositionsCommissions | LEFT OUTER JOIN | Tier 1 commission data |
| (tier 2 cols) | dbo.qry_aff_Tier2FirstPositionsCommissions | LEFT OUTER JOIN | Tier 2 |
| (tier 3 cols) | dbo.qry_aff_Tier3FirstPositionsCommissions | LEFT OUTER JOIN | Tier 3 |
| (tier 4 cols) | dbo.qry_aff_Tier4FirstPositionsCommissions | LEFT OUTER JOIN | Tier 4 |
| (tier 5 cols) | dbo.qry_aff_Tier5FirstPositionsCommissions | LEFT OUTER JOIN | Tier 5 |
| CountryName | dbo.tblaff_Country | LEFT OUTER JOIN | Country name resolution |

### 5.2 Referenced By (other objects point to this)

No dependents found in SSDT. Used by affiliate admin interface.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_FirstPositionsDetailAllTiers (view)
  +-- dbo.tblaff_FirstPositions (table)
  +-- dbo.qry_aff_Tier1FirstPositionsCommissions (view)
  +-- dbo.qry_aff_Tier2FirstPositionsCommissions (view)
  +-- dbo.qry_aff_Tier3FirstPositionsCommissions (view)
  +-- dbo.qry_aff_Tier4FirstPositionsCommissions (view)
  +-- dbo.qry_aff_Tier5FirstPositionsCommissions (view)
  +-- dbo.tblaff_Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions | Table | Base event data |
| dbo.qry_aff_Tier1-5FirstPositionsCommissions | Views | Tier commission data (LEFT OUTER JOIN) |
| dbo.tblaff_Country | Table | Country name resolution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 All-tiers detail for a specific event
```sql
SELECT * FROM dbo.qry_aff_FirstPositionsDetailAllTiers WITH (NOLOCK)
WHERE FirstPositionID = @EventID
```

### 8.2 Unpaid events with tier 1 commission
```sql
SELECT FirstPositionID, Tier1AffiliateID, Tier1Commission, ORDER_DATE
FROM dbo.qry_aff_FirstPositionsDetailAllTiers WITH (NOLOCK)
WHERE Tier1Paid = 0 AND Tier1AffiliateID = @AffiliateID
ORDER BY ORDER_DATE DESC
```

### 8.3 Events with multi-tier commissions
```sql
SELECT TOP 10 FirstPositionID, ORDER_DATE,
       Tier1Commission, Tier2Commission, Tier3Commission
FROM dbo.qry_aff_FirstPositionsDetailAllTiers WITH (NOLOCK)
WHERE Tier2AffiliateID IS NOT NULL
ORDER BY ORDER_DATE DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 8/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 20 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_FirstPositionsDetailAllTiers | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_FirstPositionsDetailAllTiers.sql*
