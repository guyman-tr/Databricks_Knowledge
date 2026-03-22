# DWH_dbo.Dim_WorldCheck

> Lookup dimension for the five Refinitiv World-Check AML/sanctions screening outcomes — Unscreened, Pending, No Match, PEP Match, and Risk Match. Sourced daily from etoro.Dictionary.WorldCheck via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.WorldCheck |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (WorldCheckID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_WorldCheck` is a 5-row reference table defining the possible outcomes of screening customers against the Refinitiv World-Check database — a global sanctions, PEP (Politically Exposed Persons), and adverse media screening tool used for AML compliance.

Every eToro customer undergoes World-Check screening as part of the KYC/AML process. The result is stored per-customer in the `WorldCheckID` column of customer dimension tables and determines the customer's compliance risk tier: clear customers (ID=2) proceed normally; PEP matches (ID=3) trigger Enhanced Due Diligence; Risk matches (ID=4) may result in account restrictions or relationship termination.

Source: `etoro.Dictionary.WorldCheck` on etoroDB-REAL. The Generic Pipeline exports it daily to Bronze, staged into `DWH_staging.etoro_Dictionary_WorldCheck`, and SP_Dictionaries_DL_To_Synapse loads with TRUNCATE + INSERT. ID=0 (unscreened, empty name string) already exists in the source — no ETL placeholder is added.

---

## 2. Business Logic

### 2.1 AML Screening Result States

**What**: Five ordered states tracking where a customer is in the World-Check screening lifecycle.

**Columns Involved**: `WorldCheckID`, `WorldCheckName`

**Rules**:
- 0=(empty name) — unscreened default. Customer registered but not yet submitted to World-Check screening
- 1=Pending WCH — screening submitted, results pending. Operations may be restricted until results arrive
- 2=No Match — clear screening. No sanctions, PEP, or adverse media matches found. Standard platform access
- 3=PEP Match — customer matched a Politically Exposed Person record. Triggers mandatory Enhanced Due Diligence (EDD), ongoing transaction monitoring, and senior management sign-off
- 4=Risk Match — customer matched sanctions lists, terrorist financing databases, or other critical risk indicators. May trigger account freeze, AML team investigation, or relationship termination

**Diagram**:
```
Customer registered → 0=Unscreened (default)
                          |
                          v [Submit to World-Check]
                      1=Pending WCH
                          |
              ┌───────────┼────────────┐
              v           v            v
        2=No Match    3=PEP Match  4=Risk Match
        (clear)       (EDD+monitor) (restrict/freeze)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 5-row table — full local copy on every node, zero data movement on JOINs. Clustered index on `WorldCheckID` supports efficient point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers with PEP/Risk flags | JOIN Dim_Customer ON WorldCheckID, filter IN (3,4) |
| Screening completion rate | COUNT WHERE WorldCheckID > 0 / total customers |
| PEP vs Risk match split | GROUP BY WorldCheckID WHERE WorldCheckID IN (3,4) |

### 3.3 Gotchas

- **ID=0 has empty name**: WorldCheckName is an empty string (not NULL) for WorldCheckID=0. Filter carefully in string comparisons
- **DWH type differs from source**: Source (Dictionary.WorldCheck) uses TINYINT for WorldCheckID; DWH DDL uses INT. No data loss but note for schema alignment

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Dictionary.WorldCheck) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WorldCheckID | int | NOT NULL | Primary key for the World-Check screening outcome. 0=Unscreened/default (empty name), 1=Pending WCH (screening in progress), 2=No Match (clear), 3=PEP Match (Enhanced Due Diligence triggered), 4=Risk Match (sanctions/high-risk, possible freeze). Stored on customer dimension tables to classify each customer's AML screening status. Referenced by risk classification procedures and economic reports. (Tier 1 — upstream wiki, Dictionary.WorldCheck) |
| 2 | WorldCheckName | varchar(50) | NOT NULL | Display label for the screening outcome. ID=0 has an empty string (not NULL). Used in BackOffice UI, PEP reports, and compliance dashboards. Sourced directly from Dictionary.WorldCheck.WorldCheckName. (Tier 1 — upstream wiki, Dictionary.WorldCheck) |
| 3 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| WorldCheckID | etoro.Dictionary.WorldCheck | WorldCheckID | Passthrough (TINYINT → INT widening) |
| WorldCheckName | etoro.Dictionary.WorldCheck | WorldCheckName | Passthrough |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.WorldCheck (etoroDB-REAL, 5 rows)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/WorldCheck/
  |
  v [staging]
DWH_staging.etoro_Dictionary_WorldCheck
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT]
DWH_dbo.Dim_WorldCheck (5 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.WorldCheck | 5-row AML screening classification table (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/WorldCheck/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_WorldCheck | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_WorldCheck | 5 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WorldCheckID | etoro.Dictionary.WorldCheck | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | WorldCheckID | Customer-level AML screening result (primary consumer) |

---

## 7. Sample Queries

### 7.1 List all World-Check screening outcomes

```sql
SELECT WorldCheckID, WorldCheckName
FROM [DWH_dbo].[Dim_WorldCheck]
ORDER BY WorldCheckID
-- Returns: 0=(empty), 1=Pending WCH, 2=No Match, 3=PEP Match, 4=Risk Match
```

### 7.2 Customer count by screening result

```sql
SELECT
    wc.WorldCheckName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_WorldCheck] wc
    ON dc.WorldCheckID = wc.WorldCheckID
GROUP BY wc.WorldCheckName
ORDER BY CustomerCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT WorldCheckID, WorldCheckName, UpdateDate
FROM [DWH_dbo].[Dim_WorldCheck]
ORDER BY WorldCheckID
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — simple-dict fast-path.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4-Inferred | Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 8.0/10*
*Object: DWH_dbo.Dim_WorldCheck | Type: Table | Production Source: etoro.Dictionary.WorldCheck*
