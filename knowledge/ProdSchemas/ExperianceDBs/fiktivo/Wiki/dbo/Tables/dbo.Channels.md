# dbo.Channels

> Denormalized lookup mapping affiliates to their group and marketing expense channel, combining IDs with display names for fast reporting.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table provides a denormalized view of affiliate channel assignments, combining the affiliate's group and marketing expense information with their display names in a single flat structure. This avoids JOINs in reporting queries that need to display affiliate channel information.

Each affiliate has exactly one channel entry. The table stores both IDs and names, so reports can display human-readable channel names without joining to tblaff_AffiliatesGroups or tblaff_MarketingExpense.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A - Denormalized lookup table. See element descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Primary key. References dbo.tblaff_Affiliates. One channel entry per affiliate. |
| 2 | AffiliatesGroupsID | int | NO | - | CODE-BACKED | The affiliate's group ID. Denormalized from tblaff_Affiliates.AffiliatesGroupsID. |
| 3 | MarketingExpenseID | bigint | NO | - | CODE-BACKED | Marketing expense channel ID. Denormalized from tblaff_Affiliates.MarketingExpenseID. |
| 4 | MarketingExpenseName | nvarchar(50) | NO | - | CODE-BACKED | Display name of the marketing expense channel. Denormalized from tblaff_MarketingExpense.MarketingExpenseName. |
| 5 | AffiliatesGroupsName | nvarchar(50) | NO | - | CODE-BACKED | Display name of the affiliate group. Denormalized from tblaff_AffiliatesGroups.AffiliatesGroupsName. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | One-to-one with the affiliate record. |
| AffiliatesGroupsID | dbo.tblaff_AffiliatesGroups | Implicit FK | Denormalized group reference. |
| MarketingExpenseID | dbo.tblaff_MarketingExpense | Implicit FK | Denormalized marketing expense reference. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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
| PK_Channels | CLUSTERED PK | AffiliateID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all channel assignments
```sql
SELECT AffiliateID, AffiliatesGroupsName, MarketingExpenseName
FROM dbo.Channels WITH (NOLOCK)
ORDER BY AffiliatesGroupsName, MarketingExpenseName
```

### 8.2 Count affiliates per marketing expense channel
```sql
SELECT MarketingExpenseName, COUNT(*) AS AffiliateCount
FROM dbo.Channels WITH (NOLOCK)
GROUP BY MarketingExpenseName
ORDER BY AffiliateCount DESC
```

### 8.3 Find affiliates in a specific group
```sql
SELECT AffiliateID, MarketingExpenseName
FROM dbo.Channels WITH (NOLOCK)
WHERE AffiliatesGroupsName = 'Default Group'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Channels | Type: Table | Source: fiktivo/dbo/Tables/dbo.Channels.sql*
