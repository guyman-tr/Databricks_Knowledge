# History.AffiliateBlockedCountries

> SQL Server temporal history table storing all historical versions of the affiliate-to-blocked-country mapping, tracking which countries each affiliate was prevented from operating in over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID + CountryID (composite) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.AffiliateBlockedCountries is the system-versioned temporal history table for Affiliate.BlockedCountries. It captures every historical version of the per-affiliate country blocking configuration. Blocked countries prevent an affiliate from earning commissions on customers originating from those countries, typically due to regulatory restrictions, licensing limitations, or fraud prevention.

This table is essential for compliance auditing - it answers "Which countries were blocked for this affiliate at the time of a specific commission event?" With 1,049 historical versions, country blocking configurations change frequently as regulatory requirements evolve.

Data flows in automatically via SQL Server's temporal mechanism when Affiliate.BlockedCountries is modified through the UpdateInsertBlockedCountries procedure.

---

## 2. Business Logic

### 2.1 Per-Affiliate Country Blocking

**What**: Each row represents one country blocked for one affiliate. Multiple rows per affiliate create the complete blocked list.

**Columns/Parameters Involved**: `AffiliateID`, `CountryID`

**Rules**:
- When a country is unblocked, the row moves from the base table to this history table
- When a country blocking is added or modified, the previous version appears here
- An affiliate with no blocked countries can earn commissions from all countries

---

## 3. Data Overview

| AffiliateID | CountryID | Trace (ObjectName) | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| 61739 | 85 | UpdateInsertBlockedCountries | 2026-02-18 07:41:32 | 2026-02-18 07:46:44 | Country 85 was blocked for affiliate 61739 for ~5 minutes before being unblocked (test scenario) |
| 61739 | 1 | UpdateInsertBlockedCountries | 2026-02-18 07:41:32 | 2026-02-18 07:46:44 | Country 1 blocked simultaneously - both countries were blocked and unblocked together |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate this country block applies to. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | CountryID | int | NO | - | CODE-BACKED | The country blocked for this affiliate. Customers from this country do not generate commissions for this affiliate while the block is active. |
| 3 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. ObjectName typically "UpdateInsertBlockedCountries". |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this block became active. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this block was removed or modified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Affiliate.BlockedCountries | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate this country block applies to |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on Affiliate.BlockedCountries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AffiliateBlockedCountries (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate.BlockedCountries | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_AffiliateBlockedCountries | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View blocked country history for an affiliate
```sql
SELECT AffiliateID, CountryID, ValidFrom, ValidTo
FROM Affiliate.BlockedCountries FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 61739
ORDER BY ValidFrom
```

### 8.2 Check which countries were blocked at a specific date
```sql
SELECT AffiliateID, CountryID
FROM Affiliate.BlockedCountries FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 61739
```

### 8.3 Find recently unblocked countries
```sql
SELECT AffiliateID, CountryID, ValidFrom, ValidTo
FROM History.AffiliateBlockedCountries WITH (NOLOCK)
WHERE ValidTo > DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AffiliateBlockedCountries | Type: Table | Source: fiktivo/History/Tables/History.AffiliateBlockedCountries.sql*
