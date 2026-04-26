# BI_DB_dbo.BI_DB_Demo_CID_Panel

> 4.55M-row per-CID demo account trading panel tracking each user's first demo trade date, first action product type, first instrument, and number of positions opened within 14 days of demo activation — spanning registrations from September 2007 to January 2025 (4.43M distinct CIDs), refreshed daily via SP_Demo_CID_Panel with incremental INSERT for new CIDs and UPDATE for changed position counts (author: Eti, 2025-01-27 rewrite).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.External_Marketing_Acquisition_Demo via SP_Demo_CID_Panel |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE recent 3 months + INSERT new CIDs (WHERE NOT EXISTS) + UPDATE position counts |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX([Reg_YearMonth] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Demo_CID_Panel is a marketing acquisition analytics table that tracks demo account usage per customer. Each row represents one CID with their demo account trading behavior: when they first registered, when (and if) they opened their first demo position, what product type that first position was, and how many demo positions they opened within the first 14 days of demo activity.

The table contains 4.55M rows with 4.43M distinct CIDs spanning registration months from September 2007 to January 2025. All current rows have IsTradedDemo = 1 (everyone who has a row has traded demo).

The ETL is incremental: new CIDs from External_Marketing_Acquisition_Demo are inserted (LEFT JOIN WHERE NULL), and existing CIDs get their OpenPositions14days updated if the count changed. The SP also deletes the most recent 3 months and re-inserts to capture late-arriving registration data.

The FirstAction classification uses InstrumentTypeID to categorize the first demo trade: Real Stocks/ETFs (InstrumentTypeID 5,6 + IsBuy=1 + Leverage=1), Fx/Comm/Ind (types 1,2,4), CFD Stocks/ETFs (types 5,6 with leverage or short), Crypto (type 10), Copy (type 0).

---

## 2. Business Logic

### 2.1 First Action Classification

**What**: Categorizes the user's first demo trade by product type using instrument and position characteristics.
**Columns Involved**: FirstAction, FirstInstrument
**Rules**:
- Real Stocks/ETFs: InstrumentID IN (5,6) AND IsBuy=1 AND Leverage=1 (non-leveraged buy)
- Fx/Comm/Ind: InstrumentTypeID IN (1,2,4) — forex, commodities, indices
- CFD Stocks/ETFs: InstrumentTypeID IN (5,6) — leveraged or short stock positions
- Crypto: InstrumentTypeID = 10
- Copy: InstrumentTypeID = 0 — copy trading
- Other: catch-all for unclassified

### 2.2 14-Day Engagement Window

**What**: Tracks early engagement by counting positions opened within 14 days of first demo trade.
**Columns Involved**: OpenPositions14days, FirstDemoTrade
**Rules**:
- Sourced from External_Marketing_Acquisition_Demo.Pos14Days
- Updated daily if the count changes (may increase as positions within the 14-day window are back-filled)
- Higher counts indicate more engaged demo users

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN
- **Clustered Index**: Reg_YearMonth ASC — filter by registration cohort

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Demo-to-real conversion funnel | JOIN BI_DB_CIDFirstDates ON CID to get real account FTD |
| First action distribution by cohort | `GROUP BY Reg_YearMonth, FirstAction` |
| 14-day engagement by product | `AVG(OpenPositions14days) GROUP BY FirstAction` |
| Demo users who never traded real | LEFT JOIN Dim_Customer WHERE IsDepositor=0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer profile, conversion status |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID | Real account dates for conversion analysis |
| DWH_dbo.Dim_Instrument | ON FirstInstrument = InstrumentID | First instrument details |

### 3.4 Gotchas

- **IsTradedDemo = 1 for ALL rows** — currently no rows with IsTradedDemo=0, so it has no filtering value
- **Reg_YearMonth can be NULL** — some CIDs have registration data missing from the source
- **Max Reg_YearMonth is 2025-01** — data stops at the rewrite date (Eti, 2025-01-27). Newer cohorts may not be populated if External_Marketing_Acquisition_Demo has a lag
- **FirstAction classification uses InstrumentID 5,6 for Real vs CFD** — InstrumentID, not InstrumentTypeID. This likely means specific instruments (BTC/ETH?), not types. The SP comment says InstrumentTypeID but the CASE uses InstrumentID IN (5,6)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code / ETL logic analysis | High |
| Tier 3 | Live data observation + schema inference | Medium |
| Tier 4 | Inferred from naming / context | Lower |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. One row per CID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Reg_YearMonth | char(7) | YES | Registration year-month in YYYY-MM format. CONVERT(VARCHAR(7), Registered, 126). Range: 2007-09 to 2025-01. NULL for some CIDs with missing registration data. Clustered index column. (Tier 2 — SP_Demo_CID_Panel) |
| 3 | FDT_YearMonth | char(7) | YES | First Demo Trade year-month in YYYY-MM format. CONVERT(VARCHAR(7), FirstDemoTrade, 126). NULL if the user never traded demo. (Tier 2 — SP_Demo_CID_Panel) |
| 4 | FirstDemoTrade | date | YES | Date of the user's first demo account trade. From External_Marketing_Acquisition_Demo.FirstDemoTrade. NULL if the user registered but never opened a demo position. (Tier 2 — SP_Demo_CID_Panel) |
| 5 | FirstAction | varchar(50) | YES | Product type of the user's first demo trade. Classified from InstrumentID/InstrumentTypeID/IsBuy/Leverage: 'Real Stocks/ETFs', 'Fx/Comm/Ind', 'CFD Stocks/ETFs', 'Crypto', 'Copy', 'Other'. (Tier 2 — SP_Demo_CID_Panel) |
| 6 | FirstInstrument | bigint | YES | InstrumentID of the user's first demo trade. FK to DWH_dbo.Dim_Instrument.InstrumentID for instrument details. (Tier 2 — SP_Demo_CID_Panel) |
| 7 | IsTradedDemo | tinyint | YES | Whether the user has traded on demo. 1 = traded, 0 = registered but never traded. Currently all rows are 1 (only traded users are present). (Tier 2 — SP_Demo_CID_Panel) |
| 8 | OpenPositions14days | int | YES | Number of demo positions opened within 14 days of the first demo trade. From External_Marketing_Acquisition_Demo.Pos14Days. Updated daily if count changes. Higher = more engaged. (Tier 2 — SP_Demo_CID_Panel) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT or UPDATE time. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | External_Marketing_Acquisition_Demo | CID | Passthrough |
| Reg_YearMonth | External_Marketing_Acquisition_Demo | Registered | CONVERT to YYYY-MM |
| FirstDemoTrade | External_Marketing_Acquisition_Demo | FirstDemoTrade | Passthrough |
| FirstAction | External_Marketing_Acquisition_Demo | InstrumentID + IsBuy + Leverage + InstrumentTypeID | CASE classification |
| OpenPositions14days | External_Marketing_Acquisition_Demo | Pos14Days | Passthrough (updated) |

### 5.2 ETL Pipeline

```
BI_DB_dbo.External_Marketing_Acquisition_Demo (external table — marketing demo data)
  |-- DELETE recent 3 months + INSERT new CIDs (LEFT JOIN WHERE NULL) ---|
  |-- UPDATE OpenPositions14days WHERE changed ---|
  v
BI_DB_dbo.BI_DB_Demo_CID_Panel (4.55M rows, ROUND_ROBIN, CI(Reg_YearMonth))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| FirstInstrument | DWH_dbo.Dim_Instrument.InstrumentID | First demo instrument |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Marketing acquisition analytics dashboards |

---

## 7. Sample Queries

### 7.1 Demo-to-Real Conversion by First Action

```sql
SELECT dp.FirstAction,
       COUNT(*) AS demo_users,
       SUM(CASE WHEN dc.IsDepositor = 1 THEN 1 ELSE 0 END) AS converted,
       CAST(SUM(CASE WHEN dc.IsDepositor = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS conversion_rate
FROM [BI_DB_dbo].[BI_DB_Demo_CID_Panel] dp
JOIN [DWH_dbo].[Dim_Customer] dc ON dp.CID = dc.RealCID
WHERE dp.Reg_YearMonth >= '2024-01'
GROUP BY dp.FirstAction
ORDER BY conversion_rate DESC;
```

### 7.2 14-Day Engagement Distribution

```sql
SELECT CASE WHEN OpenPositions14days = 0 THEN '0'
            WHEN OpenPositions14days BETWEEN 1 AND 5 THEN '1-5'
            WHEN OpenPositions14days BETWEEN 6 AND 20 THEN '6-20'
            ELSE '20+' END AS engagement_bucket,
       COUNT(*) AS users
FROM [BI_DB_dbo].[BI_DB_Demo_CID_Panel]
WHERE Reg_YearMonth >= '2024-01'
GROUP BY CASE WHEN OpenPositions14days = 0 THEN '0'
              WHEN OpenPositions14days BETWEEN 1 AND 5 THEN '1-5'
              WHEN OpenPositions14days BETWEEN 6 AND 20 THEN '6-20'
              ELSE '20+' END;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 1 T1, 7 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Demo_CID_Panel | Type: Table | Production Source: External_Marketing_Acquisition_Demo via SP_Demo_CID_Panel*
