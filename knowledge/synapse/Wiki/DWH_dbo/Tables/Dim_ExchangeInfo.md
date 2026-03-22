# DWH_dbo.Dim_ExchangeInfo

> Financial exchange and instrument market category dimension - maps exchange IDs to descriptive labels covering global stock exchanges, forex, crypto, and commodity markets.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.ExchangeInfo |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ExchangeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_ExchangeInfo` is a 51-row dictionary mapping integer `ExchangeID` codes to descriptive labels for financial exchanges and broad market categories. The descriptions cover global stock exchanges (Nasdaq, NYSE, LSE, Euronext Paris, Bolsa De Madrid, Borsa Italiana, SIX, TYO, Oslo, Stockholm, etc.) as well as broad asset class categories (FX, Commodity, CFD, Digital Currency). This dimension represents the marketplace or market type where a financial instrument is traded.

The data originates from `etoro.Dictionary.ExchangeInfo` on the production etoroDB-REAL server. It is exported via the Generic Pipeline to the DWH staging layer as `DWH_staging.etoro_Dictionary_ExchangeInfo`, then loaded to DWH by `SP_Dictionaries_DL_To_Synapse`.

**Important**: As of the last pipeline analysis, `ExchangeID` appears to have been removed (commented out) from `Dim_Instrument` and `SP_Fact_CustomerUnrealized_PnL`. This means `Dim_ExchangeInfo` is currently **not actively referenced as a foreign key** by any DWH table. It is maintained as a loaded reference dictionary but is an orphaned dimension in the current DWH schema.

`SP_Dictionaries_DL_To_Synapse` runs TRUNCATE + INSERT from staging daily. `UpdateDate = GETDATE()` at load time. Last refresh: 2026-03-11 (~8 days stale as of 2026-03-19, consistent with a known SP_Dictionaries scheduling lag).

---

## 2. Business Logic

### 2.1 Exchange Type Categories

**What**: ExchangeInfo covers two types of lookups: (1) named global stock exchanges, and (2) broad asset class market types.

**Columns Involved**: `ExchangeID`, `ExchangeDescription`

**Rules**:
- IDs 1-3 are generic market types: 1=FX, 2=Commodity, 3=CFD
- IDs 4-5 are major US exchanges: 4=Nasdaq, 5=NYSE
- IDs 6+ are international stock exchanges and alternative markets
- ID 8 = Digital Currency (cryptocurrency market)

**Diagram**:
```
ExchangeID categories:
  [1] FX          - Forex (currency pairs)
  [2] Commodity   - Commodity markets
  [3] CFD         - Contract for Difference (generic)
  [4] Nasdaq      - US technology exchange
  [5] NYSE        - US equities exchange
  [6] FRA         - Frankfurt Stock Exchange (XETRA)
  [7] LSE         - London Stock Exchange
  [8] Digital Currency - Cryptocurrency
  [9] Euronext Paris
  [10] Bolsa De Madrid
  [11] Borsa Italiana
  [12] SIX        - Swiss Exchange
  [13] TYO        - Tokyo Stock Exchange
  ... (51 total exchanges)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (51 rows - ideal). CLUSTERED INDEX on `ExchangeID` supports efficient point lookups. Joins from any large table incur no data movement due to replication.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, exported to Gold layer. With 51 rows, no partitioning needed. Broadcast join is automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode ExchangeID in instrument data | `LEFT JOIN DWH_dbo.Dim_ExchangeInfo ON ExchangeID` |
| List all exchanges with instrument counts | Join to instrument table if ExchangeID becomes active |
| Find all crypto instruments | Filter `ExchangeDescription = 'Digital Currency'` (ExchangeID=8) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Future: DWH_dbo.Dim_Instrument | ON Dim_Instrument.ExchangeID = Dim_ExchangeInfo.ExchangeID | Decode exchange for instruments (ExchangeID currently commented out of Dim_Instrument ETL) |

### 3.4 Gotchas

- **Orphaned dimension**: As of 2026-03-19, `ExchangeID` is commented out of `SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse`. No active DWH table contains an `ExchangeID` FK to this table. The dimension is maintained but currently has no consumers.
- **No ID=0 placeholder**: Unlike many SP_Dictionaries tables, Dim_ExchangeInfo does not have an ID=0 "N/A" row. Joins using LEFT JOIN may produce NULLs for any instrument without a valid exchange mapping.
- **Mixed categories**: ExchangeInfo contains both specific named exchanges AND broad asset-class categories (FX, Commodity, CFD). These are conceptually different but share the same dimension.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ExchangeID | int | YES | Primary key. Exchange identifier. Production values 1-56; test values 99+. (Tier 1 — Dictionary.ExchangeInfo) |
| 2 | ExchangeDescription | varchar(50) | YES | Exchange name or abbreviation. (Tier 1 — Dictionary.ExchangeInfo) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Does not reflect production data update time. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ExchangeID | etoro.Dictionary.ExchangeInfo | ExchangeID | None (passthrough) |
| ExchangeDescription | etoro.Dictionary.ExchangeInfo | ExchangeDescription | None (passthrough) |
| UpdateDate | - | - | ETL-computed: GETDATE() at SP execution time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.ExchangeInfo -> Generic Pipeline -> DWH_staging.etoro_Dictionary_ExchangeInfo -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_ExchangeInfo
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.ExchangeInfo | Exchange/market category dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/ExchangeInfo/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_ExchangeInfo | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_ExchangeInfo | 51-row REPLICATE dictionary. Daily refresh. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references to other DWH objects. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (None active) | ExchangeID | ExchangeID was commented out of SP_Fact_CustomerUnrealized_PnL. No active FK references as of 2026-03-19. |

---

## 7. Sample Queries

### 7.1 List all exchange descriptions

```sql
SELECT ExchangeID, ExchangeDescription
FROM DWH_dbo.Dim_ExchangeInfo
ORDER BY ExchangeID
```

### 7.2 Find exchange IDs for US markets

```sql
SELECT ExchangeID, ExchangeDescription
FROM DWH_dbo.Dim_ExchangeInfo
WHERE ExchangeDescription IN ('Nasdaq', 'NYSE')
```

### 7.3 Future: Decode exchange for instruments (when ExchangeID is re-enabled)

```sql
-- Template for when ExchangeID is re-added to Dim_Instrument
SELECT
    i.InstrumentID,
    i.InstrumentName,
    ex.ExchangeDescription
FROM DWH_dbo.Dim_Instrument i
LEFT JOIN DWH_dbo.Dim_ExchangeInfo ex ON i.ExchangeID = ex.ExchangeID
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [EtoroOps Configuration Screens List](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/14053015561/EtoroOps+Configuration+Screens+List) | Confluence | Documents **Exchange** fields and **ExchangeID** usage alongside instrument metadata; **Market Hours Defaults** scope is ExchangeID or InstrumentID (mutually exclusive). |
| [Market Hours & 24/7 Trading](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137312575/Market+Hours+24+7+Trading) | Confluence | Instruments trade only when relevant markets are open; major exchanges (e.g. NYSE/Nasdaq) referenced for market-hours context. |
| [eToro OPS DBs related to Asset Insertion](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/14043185200/eToro+OPS+DBs+related+to+Asset+Insertion) | Confluence | Exchange timezone, closing price source, and instrument grouping per exchange—operational meaning of “exchange” when onboarding instruments. |

---

*Generated: 2026-03-19 | Quality: 7.4/10 (***) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 8/10*
*Object: DWH_dbo.Dim_ExchangeInfo | Type: Table | Production Source: etoro.Dictionary.ExchangeInfo*
