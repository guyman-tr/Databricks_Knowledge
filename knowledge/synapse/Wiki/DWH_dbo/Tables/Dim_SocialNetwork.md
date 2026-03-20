# DWH_dbo.Dim_SocialNetwork

> Lookup table defining the 4 social network registration channels (N/A, Facebook, Twitter, LinkedIn). Frozen legacy table - 4 static rows with 2013-2014 timestamps. Not refreshed by SP_Dictionaries_DL_To_Synapse. Likely used for customers who registered via social network OAuth.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown - not refreshed by any active ETL SP in SSDT repo |
| **Refresh** | FROZEN - timestamps 2013-2014; no active ETL SP found |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (SocialNetworkID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_SocialNetwork defines the social network platforms through which customers registered on the eToro platform via OAuth / social login. Values: N/A (0=no social registration), Facebook (1), Twitter (2), LinkedIn (3). (Tier 3 - live data; no upstream wiki found)

This table is a frozen legacy artifact. All 4 rows have timestamps from 2013-2014, consistent with an original on-premises DWH migration. No active ETL stored procedure refreshes this table - it is absent from SP_Dictionaries_DL_To_Synapse, and no other DWH_dbo SPs or views reference it in the SSDT repo. The Generic Pipeline exports the current Synapse state daily to UC Gold.

LinkedIn social login and Twitter social login integrations are largely inactive in modern eToro. Facebook OAuth remains in use. The 4-row lookup is complete and stable.

---

## 2. Business Logic

### 2.1 Social Registration Channel

**What**: Identifies how the customer originally authenticated at registration.

**Columns Involved**: `SocialNetworkID`, `Name`

**Values**:
- 0 = N/A: Customer registered via email/password (no social OAuth)
- 1 = Facebook: Registered via Facebook OAuth
- 2 = Twitter: Registered via Twitter OAuth (largely deprecated)
- 3 = LinkedIn: Registered via LinkedIn OAuth (largely deprecated)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on SocialNetworkID. With 4 rows, REPLICATE is optimal.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork` is Parquet. Tiny lookup - read the full table.

### 3.3 Gotchas

- **Frozen table**: Not maintained by any active ETL SP in the DWH_dbo SSDT repo. Timestamps are from 2013-2014. The 4 rows are stable and unlikely to change.
- **No DWH references in SSDT**: No DWH_dbo views, SPs, or other objects reference this table. Join must be built manually from fact tables that carry SocialNetworkID.
- **No upstream wiki**: No DB_Schema wiki page for a Dictionary.SocialNetwork table. Production source is unknown.
- **DWHSocialNetworkID = SocialNetworkID**: Same redundant alias pattern as other Dim_ tables (DWHRegulationID, DWHRiskStatusID, etc.).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★☆☆☆ | Tier 3 - Live data / name inference | `(Tier 3 - live data)` |
| ★☆☆☆☆ | Tier 4 - Inferred [UNVERIFIED] | `(Tier 4 - UNVERIFIED)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SocialNetworkID | int | NO | Primary key. 0=N/A (email registration), 1=Facebook, 2=Twitter, 3=LinkedIn. Stored on customer records to indicate OAuth registration channel. (Tier 3 - live data) |
| 2 | Name | varchar(30) | NO | Social network platform name. Passthrough from source. (Tier 3 - live data) |
| 3 | DWHSocialNetworkID | int | YES | ETL-computed alias of SocialNetworkID - always equals SocialNetworkID. DWH-specific redundant field. Use SocialNetworkID for joins. (Tier 4 - UNVERIFIED; no active SP found) |
| 4 | StatusID | int | YES | Value 1 for all rows, consistent with "Active" pattern from SP_Dictionaries. ETL origin unclear (no active SP found). (Tier 4 - UNVERIFIED) |
| 5 | UpdateDate | datetime | YES | Frozen 2013-2014 timestamps. Not GETDATE() - reflects original migration date. (Tier 3 - live data) |
| 6 | InsertDate | datetime | YES | Frozen 2013-2014 timestamps. Same as UpdateDate. (Tier 3 - live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| SocialNetworkID | Unknown (legacy migration) | Unknown | Unknown |
| Name | Unknown (legacy migration) | Unknown | Unknown |
| DWHSocialNetworkID | - | - | Likely ETL alias = SocialNetworkID (frozen) |
| StatusID | - | - | Hardcoded 1 (frozen) |
| UpdateDate | - | - | 2013-2014 migration timestamp (frozen) |
| InsertDate | - | - | 2013-2014 migration timestamp (frozen) |

No upstream wiki found. No active ETL SP in SSDT refreshes this table.

### 5.2 ETL Pipeline

```
Unknown source (likely legacy Dictionary.SocialNetwork in etoro)
  -> One-time migration (2013-2014)
  -> DWH_dbo.Dim_SocialNetwork (4 frozen rows)
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Unknown | Likely etoro.Dictionary.SocialNetwork - not confirmed |
| ETL | None active | Not in SP_Dictionaries_DL_To_Synapse or any other DWH SP |
| Target | DWH_dbo.Dim_SocialNetwork | 4 frozen rows (2013-2014 timestamps) |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A.

### 6.2 Referenced By (other objects point to this)

No DWH_dbo views or procedures reference this table in the SSDT repo.

---

## 7. Sample Queries

### 7.1 List all social networks
```sql
SELECT
    SocialNetworkID,
    Name
FROM [DWH_dbo].[Dim_SocialNetwork]
ORDER BY SocialNetworkID
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Affiliate Program - eToro Partners](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137312260/Affiliate+Program+-+eToro+Partners) | Confluence | Describes traffic from websites, blogs, and social networks to eToro |
| [Social Activity](https://etoro-jira.atlassian.net/wiki/spaces/REGTECH/pages/11648204975/Social+Activity) | Confluence | Platform social assets (feed, profile) and social-trading abuse monitoring |
| [Trading Basics](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12593397777/Trading+Basics) | Confluence | eToro trading platform context for user acquisition channels |

---

*Generated: 2026-03-19 | Quality: 6.9/10 (★★★☆☆) | Phases: 9/14 (fast-path; Phase 10 applied)*
*Tiers: 0 T1, 0 T2, 4 T3, 2 T4 [UNVERIFIED], 0 T5 | Elements: 7/10, Logic: 6/10, Relationships: 3/10, Sources: 8/10*
*Note: Quality limited by frozen legacy table with no active ETL, no upstream wiki, and no DWH references.*
*Object: DWH_dbo.Dim_SocialNetwork | Type: Table | Production Source: Unknown (legacy migration)*
