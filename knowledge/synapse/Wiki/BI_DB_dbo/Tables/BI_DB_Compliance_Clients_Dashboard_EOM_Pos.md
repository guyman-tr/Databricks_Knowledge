# BI_DB_dbo.BI_DB_Compliance_Clients_Dashboard_EOM_Pos

> 150,063-row cumulative end-of-month compliance snapshot aggregating positions opened on the last trading day of each month, segmented by regulation, country, instrument type, and trading behaviour — powers the compliance client dashboard for monthly regulatory reporting.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Fact_SnapshotCustomer + Dim_Customer via SP_Compliance_BI_Clients_Dashboard |
| **Refresh** | Incremental — DELETE WHERE DateID = @DateID + INSERT; only runs on last-day-of-month dates |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Unknown (SP undated; MAS regulation added 2025-12-03) |

---

## 1. Business Meaning

This table is a **monthly compliance snapshot of end-of-month position openings**. Each row represents one aggregation bucket: a unique combination of EOM date, regulation, customer country, trading style (MirrorType), direction (IsBuyType), settlement type, instrument type, and detailed settlement category. For each bucket, the table stores the count of customers, count of new customers (FTD ≤ 60 days), and aggregate USD volume.

The SP runs on End-of-Month (EOM) dates only — if invoked on a non-EOM date, the `INNER JOIN DWH_dbo.Dim_Date ON IsLastDayOfMonth = 'Y'` returns no rows and nothing is inserted. Data accumulates over time (one EOM slice per month-end run) with re-runs for a given date overwriting that date's slice.

Data covers positions opened ON the EOM date (not positions that were already open). `PositionType = 'Opened_EOD'` is hardcoded for all rows.

**CRITICAL GOTCHA**: The column `RealCID` contains `COUNT(RealCID)` — it is a **customer count**, not a customer identifier. The column name is misleading.

As of 2026-04-13: **150,063 rows** across **51 end-of-month dates** from 2022-01-31 to 2026-03-31. IsSettledTypeDetailed distribution: CFD FX 43.8% (65,754), CFD Stocks ETF 24.4% (36,559), Real Stocks ETF 16.7% (25,123), Real Crypto 9.7% (14,620), CFD Crypto 5.3% (7,899), N/A 0.1% (108). Regulation distribution: CySEC 33.4%, FCA 25.2%, FSA Seychelles 18.9%, ASIC & GAML 17.5%, ASIC 3.4%, FSRA 1.5%, others <1%.

---

## 2. Business Logic

### 2.1 EOM Date Gate

**What**: The SP only inserts data when @Date is the last day of a calendar month.
**Columns Involved**: `Date`, `DateID`
**Rules**:
- Gate: `INNER JOIN DWH_dbo.Dim_Date dd ON dd.DateKey = @DateID AND dd.IsLastDayOfMonth = 'Y'`
- If @Date is not a last-day-of-month, the #positio_pop temp table is empty → no INSERT
- Incremental load: `DELETE FROM BI_DB_Compliance_Clients_Dashboard_EOM_Pos WHERE DateID = @DateID` then INSERT — re-run safe for a given EOM date

### 2.2 Position Filter

**What**: Only positions opened on @Date by valid depositor customers are included.
**Columns Involved**: `Volume`, `RealCID`, `New_Customers`
**Rules**:
- Source: `DWH_dbo.Dim_Position WHERE OpenDateID = @DateID`
- Customer filter: `Fact_SnapshotCustomer.IsValidCustomer = 1 AND IsDepositor = 1`
- DateRangeID effective window: `Dim_Range.FromDateID <= @DateID AND @DateID <= ToDateID`
- Excludes: demo accounts, non-depositors, invalid customers

### 2.3 New Customer Definition

**What**: A customer is "new" if their first deposit was within 60 days of the EOM date.
**Columns Involved**: `New_Customers`
**Rules**:
- `DATEDIFF(DAY, CONVERT(CHAR(10), Dim_Customer.FirstDepositDate, 112), @Date) <= 60 → New_Customer_Ind = 1`
- Applied as `MAX()` per RealCID within the group (a customer is new or not, regardless of how many positions)
- Then `SUM(New_Customer_Ind)` in outer aggregation → count of new customers in bucket

### 2.4 Settlement and Instrument Classification

**What**: Positions are classified by settlement type (Real vs CFD) and instrument category for compliance dimension analysis.
**Columns Involved**: `IsSettledType`, `IsSettledTypeDetailed`, `InstrumentType`
**Rules**:
- **IsSettledType**: 'Real' (IsSettled=1), 'CFD' (IsSettled=0)
- **IsSettledTypeDetailed** (full 6-way split):
  - `InstrumentTypeID IN (5,6) AND IsSettled=1` → 'Real Stocks ETF'
  - `InstrumentTypeID=10 AND IsSettled=1` → 'Real Crypto'
  - `InstrumentTypeID IN (5,6) AND IsSettled=0` → 'CFD Stocks ETF'
  - `InstrumentTypeID=10 AND IsSettled=0` → 'CFD Crypto'
  - `InstrumentTypeID IN (1,2,4) AND IsSettled=0` → 'CFD FX'
  - all others → 'N/A'
- **InstrumentType**: Dim_Instrument.InstrumentType text label (ETL-computed: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID. Filtering by DateID (or Date) uses the clustered index efficiently. Cross-date analysis requires full scan. No colocation with other HASH-distributed tables — use this table for aggregated reporting only.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Monthly volumes by regulation | `SELECT Date, Regulation, SUM(Volume) GROUP BY Date, Regulation ORDER BY Date, SUM(Volume) DESC` |
| New vs existing customers by instrument | `SELECT Date, IsSettledTypeDetailed, SUM(New_Customers), SUM(RealCID) AS total_customers GROUP BY Date, IsSettledTypeDetailed` |
| Latest EOM snapshot | `SELECT * WHERE DateID = (SELECT MAX(DateID) FROM ...)` |
| CFD vs Real split over time | `SELECT Date, IsSettledType, SUM(RealCID), SUM(Volume) GROUP BY Date, IsSettledType ORDER BY Date` |

### 3.3 Common JOINs

No standard JOINs — this is an aggregated reporting table. Individual-level analysis should use Dim_Position + Fact_SnapshotCustomer directly.

### 3.4 Gotchas

- **RealCID is NOT a customer identifier**: `RealCID` contains `COUNT(RealCID)` from the aggregation — the total number of customers in the bucket. Do not use this column in JOINs or as a FK.
- **EOM-only data**: Each Date is a last-day-of-month. There are no intra-month dates in this table.
- **Positions opened ON the EOM date only**: This captures new openings on the EOM date, not all open positions as of month-end. Positions opened before the EOM date but still open are NOT included.
- **N/A in IsSettledTypeDetailed**: 108 rows with 'N/A' represent instrument types that don't match any of the 5 classification rules (unusual instruments or combinations).
- **ASIC and ASIC & GAML are separate**: Unlike the sister table `BI_DB_Compensation_Activity_Data_Regulation`, this table does NOT merge ASIC and ASIC&GAML — they appear as distinct Regulation values from Dim_Regulation.Name.
- **UpdateDate is the run timestamp**: All rows for a given @Date share the same UpdateDate from that ETL run.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (no transformation) |
| Tier 2 | Derived from ETL SP code, DWH wiki, or staging DDL |
| Tier 3 | Inferred from column name, data pattern, or business context |
| Tier 4 | Best available — no source traceable |
| Propagation | ETL infrastructure column (GETDATE(), row metadata) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | End-of-month date for this snapshot partition. Must be the last calendar day of a month — non-EOM dates are rejected by SP gate. Range: 2022-01-31 to 2026-03-31 (51 months). (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 2 | DateID | int | YES | YYYYMMDD integer representation of Date. Clustered index key. Filter on DateID for best performance. (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 3 | Regulation | varchar(50) | YES | Regulatory jurisdiction name from Dim_Regulation.Name. Observed values: CySEC, FCA, FSA Seychelles, ASIC, ASIC & GAML (separate), FSRA, FinCEN, FinCEN+FINRA, NYDFS+FINRA, BVI, MAS, eToroUS, None. NULL for unregistered customers. (Tier 1 — Dim_Regulation wiki, Dictionary.Regulation) |
| 4 | Country | varchar(50) | YES | Customer's registered country name from Dim_Country.Name. NULL for country mismatches. (Tier 1 — Dim_Country wiki, Dictionary.Country) |
| 5 | MirrorType | varchar(6) | NO | Position source: 'Manual' (Dim_Position.MirrorID IS NULL or =0) or 'Copy' (non-null, non-zero MirrorID — copy-trading position). (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 6 | IsBuyType | varchar(5) | NO | Position direction: 'Long' (IsBuy=1, profit when price rises) or 'Short' (IsBuy=0). (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 7 | IsSettledType | varchar(4) | NO | Settlement classification: 'Real' (IsSettled=1, real asset ownership) or 'CFD' (IsSettled=0, contract for difference). (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 8 | PositionType | varchar(10) | NO | Always 'Opened_EOD' for all rows — hardcoded literal in SP indicating positions opened on the end-of-day/end-of-month date. (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 9 | InstrumentType | varchar(50) | NO | Instrument category text label from Dim_Instrument.InstrumentType. DWH-computed via CASE on InstrumentTypeID: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies. (Tier 2 — Dim_Instrument wiki) |
| 10 | IsSettledTypeDetailed | varchar(15) | NO | 6-way classification combining InstrumentTypeID and IsSettled: 'Real Stocks ETF', 'Real Crypto', 'CFD Stocks ETF', 'CFD Crypto', 'CFD FX', 'N/A'. See §2.4 for full CASE logic. (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 11 | RealCID | int | YES | **MISLEADING NAME**: This column holds COUNT(RealCID) — the number of customers in this aggregation bucket. It is NOT an individual customer identifier. Do not JOIN on this column. (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 12 | New_Customers | int | YES | Count of customers in this bucket whose first deposit date (Dim_Customer.FirstDepositDate) was within 60 days before the EOM Date. 0 when no new customers in bucket. (Tier 2 — SP_Compliance_BI_Clients_Dashboard) |
| 13 | Volume | money | YES | Total USD volume for positions in this bucket. Sum of Dim_Position.Volume — an ETL-computed approximation: ROUND(AmountInUnitsDecimal × InitForexRate × USD conversion factor, 0). (Tier 2 — Dim_Position wiki) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when this partition was last refreshed. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | SP input | @Date | EOM gate check; passthrough |
| DateID | SP input | @DateID | YYYYMMDD integer |
| Regulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN via Fact_SnapshotCustomer.RegulationID |
| Country | DWH_dbo.Dim_Country | Name | LEFT JOIN via Fact_SnapshotCustomer.CountryID |
| MirrorType | DWH_dbo.Dim_Position | MirrorID | CASE: NULL/0='Manual', else='Copy' |
| IsBuyType | DWH_dbo.Dim_Position | IsBuy | CASE: 1='Long', 0='Short' |
| IsSettledType | DWH_dbo.Dim_Position | IsSettled | CASE: 1='Real', 0='CFD' |
| PositionType | SP literal | — | Hardcoded 'Opened_EOD' |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| IsSettledTypeDetailed | DWH_dbo.Dim_Position + Dim_Instrument | IsSettled + InstrumentTypeID | 6-way CASE |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | COUNT(RealCID) — customer count |
| New_Customers | DWH_dbo.Dim_Customer | FirstDepositDate | SUM of DATEDIFF ≤ 60 indicator |
| Volume | DWH_dbo.Dim_Position | Volume | SUM |
| UpdateDate | ETL | GETDATE() | Runtime timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (OpenDateID = @DateID)
  + DWH_dbo.Dim_Instrument (InstrumentType, InstrumentTypeID)
  + DWH_dbo.Dim_Date (IsLastDayOfMonth = 'Y' — EOM gate)
    → #positio_pop (CID-level positions with type flags, volume)

  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1, IsDepositor=1)
  + DWH_dbo.Dim_Range (effective DateRangeID for @DateID)
  + DWH_dbo.Dim_Customer (FirstDepositDate → New_Customer_Ind)
  + DWH_dbo.Dim_Country (Country name)
  + DWH_dbo.Dim_Regulation (Regulation name)
    → #aggEOMpop (aggregated by all dimensions)
    |-- SP_Compliance_BI_Clients_Dashboard (@Date) DELETE(@DateID)+INSERT ---|
    v
BI_DB_dbo.BI_DB_Compliance_Clients_Dashboard_EOM_Pos (150,063 rows, 51 EOM dates)
    |-- UC: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date / DateID | DWH_dbo.Dim_Date | EOM gate (IsLastDayOfMonth filter) |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name lookup |
| Country | DWH_dbo.Dim_Country | Country name lookup |
| Position data | DWH_dbo.Dim_Position | Source of Volume, IsSettled, IsBuy, MirrorID |
| Instrument classification | DWH_dbo.Dim_Instrument | InstrumentType, InstrumentTypeID for IsSettledTypeDetailed |
| Customer eligibility | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer, IsDepositor, RegulationID, CountryID |
| New customer flag | DWH_dbo.Dim_Customer | FirstDepositDate for 60-day new customer logic |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in SSDT (compliance reporting export table).

---

## 7. Sample Queries

### Monthly volume by regulation for the most recent EOM date

```sql
SELECT Date,
       Regulation,
       SUM(RealCID) AS customer_count,
       SUM(Volume) AS total_volume_usd
FROM [BI_DB_dbo].[BI_DB_Compliance_Clients_Dashboard_EOM_Pos]
WHERE DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_Compliance_Clients_Dashboard_EOM_Pos])
GROUP BY Date, Regulation
ORDER BY total_volume_usd DESC;
```

### New customer activity by instrument type over all months

```sql
SELECT Date,
       IsSettledTypeDetailed,
       SUM(New_Customers) AS new_customers,
       SUM(RealCID) AS total_customers,
       CAST(SUM(New_Customers) AS FLOAT) / NULLIF(SUM(RealCID), 0) AS new_customer_rate
FROM [BI_DB_dbo].[BI_DB_Compliance_Clients_Dashboard_EOM_Pos]
GROUP BY Date, IsSettledTypeDetailed
ORDER BY Date DESC, new_customers DESC;
```

### CFD vs Real volume trend by month

```sql
SELECT Date,
       IsSettledType,
       SUM(RealCID) AS customer_count,
       SUM(Volume) AS volume_usd
FROM [BI_DB_dbo].[BI_DB_Compliance_Clients_Dashboard_EOM_Pos]
GROUP BY Date, IsSettledType
ORDER BY Date DESC, IsSettledType;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this object.

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 2 T1, 11 T2, 0 T3, 0 T4, 1 Propagation | Elements: 14/14, Logic: 9/10*
*Object: BI_DB_dbo.BI_DB_Compliance_Clients_Dashboard_EOM_Pos | Type: Table | Production Source: SP_Compliance_BI_Clients_Dashboard*
