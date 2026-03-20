# DWH_dbo.Dim_MirrorType

> 4-row reference table mapping MirrorTypeID to the type of copy-trading relationship -- distinguishing Regular copy relationships, CopyMe (CopyPortfolio/influencer) copies, Social Indexes, and Funds on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.MirrorType (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (MirrorTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (4 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_MirrorType` classifies the type of "mirror" (copy-trading) relationship on the eToro social trading platform. A "mirror" represents a follower copying a leader's portfolio -- when the leader opens/closes positions, the follower's account mirrors those trades proportionally.

The 4 types:

| ID | Name | Meaning |
|----|------|---------|
| 1 | Regular | Standard CopyTrader relationship -- one customer automatically copies another customer's trades |
| 2 | CopyMe | The "Popular Investor" or CopyPortfolio leader is a public figure/influencer; followers copy en masse |
| 3 | Social Index | A Smart Portfolio (formerly CopyPortfolio) -- a curated basket of assets with algorithmic rebalancing |
| 4 | Fund | An eToro-managed fund product |

This table is the type lookup for `DWH_dbo.Dim_Mirror` (the mirror relationship dimension), where each active/historical copy relationship carries a MirrorTypeID.

---

## 2. Business Logic

### 2.1 Mirror Type Hierarchy

**What**: The four types represent different levels of the eToro social investing ecosystem, from peer-to-peer copying to managed products.

**Rules**:
- **Regular (1)**: The most common type. Customer A (copier) selects Customer B (copied person) and allocates a copy amount. Positions open/close automatically in sync with B's trades.
- **CopyMe (2)**: Used for Popular Investors (PIs) -- vetted traders with a public profile. The copied person is a "star" trader; their CopyMe count is tracked as a key performance metric.
- **Social Index (3)**: Smart Portfolios -- algorithmically managed thematic portfolios (e.g., "Big Tech", "Crypto Portfolio"). Users invest a lump sum; the portfolio auto-rebalances.
- **Fund (4)**: eToro's own managed fund products, distinct from Social Indexes.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get mirror type name | `JOIN Dim_MirrorType ON MirrorTypeID; SELECT MirrorTypeName` |
| Find all regular copy relationships | `WHERE MirrorTypeID = 1` |
| Find Popular Investor copy relationships | `WHERE MirrorTypeID = 2` |
| Analyze Smart Portfolio (index) flows | `WHERE MirrorTypeID = 3` |

### 3.2 Gotchas

- **No MirrorTypeID=0 sentinel**: Unlike most DWH dictionaries, Dim_MirrorType starts at 1. Check if fact tables handle NULLs or use 0 as a missing-type sentinel.
- **UpdateDate is GETDATE() at load**: Does not reflect production modification.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — Dictionary (upstream wiki) | `(Tier 1 — Dictionary.MirrorType)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MirrorTypeID | int | NO | Primary key identifying the copy relationship type. 1=Regular (standard copy), 2=CopyMe (legacy), 3=Social Index (algorithmic), 4=Fund (managed). (Tier 1 — Dictionary.MirrorType) |
| 2 | MirrorTypeName | varchar | YES | Short code name used in code branching and API responses. (Tier 1 — Dictionary.MirrorType) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| MirrorTypeID | etoro.Dictionary.MirrorType | MirrorTypeID | passthrough |
| MirrorTypeName | etoro.Dictionary.MirrorType | MirrorTypeName | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.MirrorType  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_MirrorType
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_MirrorType  (4 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_MirrorType/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Mirror | MirrorTypeID | Each copy-trading relationship (Mirror) has a type |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 Get copy-trading volume by type

```sql
SELECT
    mt.MirrorTypeID,
    mt.MirrorTypeName,
    COUNT(DISTINCT m.MirrorID) AS MirrorCount
FROM [DWH_dbo].[Dim_Mirror] m
JOIN [DWH_dbo].[Dim_MirrorType] mt ON m.MirrorTypeID = mt.MirrorTypeID
GROUP BY mt.MirrorTypeID, mt.MirrorTypeName
ORDER BY MirrorCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 3/3, Logic: 8/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_MirrorType | Type: Table | Production Source: etoro.Dictionary.MirrorType*
