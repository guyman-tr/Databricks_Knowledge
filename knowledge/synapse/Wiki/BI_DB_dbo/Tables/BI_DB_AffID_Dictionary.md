# BI_DB_dbo.BI_DB_AffID_Dictionary

> **DORMANT — 0 rows, no active writer.** 4-column affiliate ID lookup table mapping AffiliateID to Region and Channel. Previously used as a JOIN target in SP_Marketing_Cube for resolving campaign names to affiliate IDs, but that logic is now commented out. ROUND_ROBIN with CLUSTERED INDEX on AffiliateID. No active ETL populates this table.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — SP_Marketing_Cube reference is commented out |
| **Refresh** | **DORMANT** — no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (AffiliateID ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AffID_Dictionary` is a **lookup/dictionary table** for affiliates, mapping each AffiliateID to its Region and marketing Channel. It was designed to resolve affiliate identifiers extracted from Google Ads campaign names (using the last 5 digits of campaign_name) to their geographic region and channel classification.

The table is currently **empty (0 rows)**. Its only SP reference (SP_Marketing_Cube) contains the JOIN logic in a commented-out block that was part of a Google Ads cost aggregation query. The commented code shows: `CAST(RIGHT(geo.campaign_name, 5) AS INT) = AD.AffiliateID` — extracting affiliate IDs from campaign naming conventions.

This table appears to have been superseded by other affiliate classification mechanisms or was never populated in Synapse after the cloud migration.

---

## 2. Business Logic

### 2.1 Affiliate-to-Region/Channel Mapping (Inferred)

**What**: Simple lookup from AffiliateID to geographic Region and marketing Channel.
**Columns Involved**: AffiliateID, Region, Channel
**Rules**:
- AffiliateID extracted from campaign names (last 5 chars cast to int)
- Region likely maps to marketing regions (e.g., APAC, EMEA, Americas)
- Channel likely maps to marketing channels (web, social, display)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on AffiliateID — optimized for point lookups by affiliate ID. No performance considerations as table is empty.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Affiliate region/channel info | Table is empty — use alternative sources or the fiktivo affiliate system |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| SP_Marketing_Cube temp tables | AffiliateID = CAST(RIGHT(campaign_name,5) AS INT) | Campaign→affiliate resolution (commented out) |

### 3.4 Gotchas

- **Table is empty**: 0 rows — do not rely on this table for any reporting
- **Commented-out reference**: The only SP usage is in a commented block — table is effectively orphaned
- **varchar(10) Region**: Very short — may have held abbreviations like 'APAC', 'EMEA', 'NA'

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 4 | Inferred from commented SP code and column names | Medium — logic exists but is deactivated |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | YES | Affiliate partner identifier from the fiktivo system. Resolved from Google Ads campaign names via RIGHT(campaign_name, 5). Indexed for lookup performance. (Tier 4 — SP_Marketing_Cube commented code) |
| 2 | Region | varchar(10) | YES | Geographic marketing region classification for the affiliate (likely abbreviated: APAC, EMEA, NA, etc.). (Tier 4 — inferred from column name and type) |
| 3 | Channel | varchar(20) | YES | Marketing channel the affiliate operates in (e.g., web, social, display, email). (Tier 4 — inferred from column name) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated. (Tier 5 — standard ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All columns | Unknown | Unknown | No active ETL exists — only commented-out SP reference |

### 5.2 ETL Pipeline

```
Unknown Production Source (likely fiktivo affiliate system or manual config)
  |-- [NO ACTIVE ETL — SP_Marketing_Cube reference commented out] ---|
  v
BI_DB_dbo.BI_DB_AffID_Dictionary (0 rows — DORMANT)

Historical usage (now commented):
  Google Ads geo_performance_report campaign_name
    → RIGHT(campaign_name, 5) → CAST AS INT → JOIN BI_DB_AffID_Dictionary
    → Resolve to Region + Channel for marketing cost attribution
```

---

## 6. Relationships

### 6.1 References To (this object points to)

No outbound relationships (simple lookup table).

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Context |
|---|---|---|
| AffiliateID | SP_Marketing_Cube | JOIN target for campaign→affiliate resolution (COMMENTED OUT) |

---

## 7. Sample Queries

### 7.1 Verify Table Is Still Empty

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_AffID_Dictionary]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant lookup table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 3 T4, 1 T5 | Elements: 4/4, Logic: 4/10, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_AffID_Dictionary | Type: Table | Production Source: Unknown (dormant)*
