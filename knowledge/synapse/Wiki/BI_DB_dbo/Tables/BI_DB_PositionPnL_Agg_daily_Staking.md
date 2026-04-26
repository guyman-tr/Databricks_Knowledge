# BI_DB_dbo.BI_DB_PositionPnL_Agg_daily_Staking

> Daily aggregated staking position P&L for Cardano (ADA, InstrumentID 100017) and TRON (TRX, InstrumentID 100026) — the only two crypto staking instruments on the eToro platform. 3.01M rows from 2021-11-01 to 2026-04-12, segmented by date, instrument, country, regulation, settlement status, and copy flag. Includes a UK-specific `TotalAmount_UK_prohibited` column isolating FCA-regulated UK customers (CountryID=218, RegulationID=2) registered on or after 2022-02-08 in response to FCA crypto restrictions. Written daily by `SP_PositionPnL_Agg_daily_Staking` from `BI_DB_PositionPnL`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (via SP_PositionPnL_Agg_daily_Staking) |
| **Refresh** | Daily incremental — deletes last DateID then re-inserts from MAX(DateID) forward |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PositionPnL_Agg_daily_Staking` is a daily aggregation table tracking staking position exposure for the two crypto staking instruments offered on the eToro platform: **Cardano (ADA, InstrumentID=100017)** and **TRON (TRX, InstrumentID=100026)**. Each row represents the total staking position amount (in instrument units) for a unique combination of date, instrument, country of residence, regulatory regime, settlement status (real vs. CFD), and copy flag (portfolio or solo trade).

The table contains **3.01 million rows** spanning **2021-11-01 to 2026-04-12**, covering 164 countries, 14 regulatory regimes, and 4 combinations of IsSettled × IsCopy. The dominant segment is IsSettled=1/IsCopy=0 (settled solo positions, 37.5%), followed by IsSettled=1/IsCopy=1 (settled copy positions, 28.1%).

The `TotalAmount_UK_prohibited` column is a compliance-driven sub-aggregate: it sums staking units only for customers registered under UK FCA regulation (RegulationID=2), resident in the UK (CountryID=218), who registered on or after **2022-02-08** — the date the FCA ban on retail crypto derivatives and products took effect. This column supports regulatory reporting of prohibited UK staking exposure.

The SP uses an incremental delete-insert pattern: it deletes the latest `DateID` currently in the table and re-inserts from that date forward, so the most recent day is always refreshed.

---

## 2. Business Logic

### 2.1 Staking Instrument Filter

**What**: Only the two crypto staking instruments are included in this table.
**Columns Involved**: InstrumentID
**Rules**:
- InstrumentID = 100017 → Cardano (ADA)
- InstrumentID = 100026 → TRON (TRX)
- All other instruments in `BI_DB_PositionPnL` are excluded (WHERE InstrumentID IN (100017, 100026))

### 2.2 UK Prohibition Exposure Calculation

**What**: `TotalAmount_UK_prohibited` isolates staking amounts attributable to UK FCA retail customers who are subject to the FCA crypto restrictions.
**Columns Involved**: TotalAmount_UK_prohibited, CountryID, RegulationID, (Dim_Customer.RegisteredReal)
**Rules**:
- Amount is included in TotalAmount_UK_prohibited ONLY when ALL three conditions are met:
  1. CountryID = 218 (United Kingdom)
  2. RegulationID = 2 (FCA)
  3. Dim_Customer.RegisteredReal >= '2022-02-08' (FCA ban effective date)
- Otherwise SUM resolves to 0 (effectively excluded via CASE)
- Used for regulatory exposure monitoring

### 2.3 IsCopy Derivation

**What**: Binary flag converting the MirrorID from `BI_DB_PositionPnL` into a 0/1 copy indicator.
**Columns Involved**: IsCopy, (BI_DB_PositionPnL.MirrorID)
**Rules**:
- IsCopy = 1 when MirrorID ≠ 0 (position is within a copy-trading relationship)
- IsCopy = 0 when MirrorID = 0 (solo/direct trade)

### 2.4 Customer Regulatory Snapshot Join

**What**: CountryID and RegulationID are resolved to the customer's regulatory status as of the position snapshot date, not current status.
**Columns Involved**: CountryID, RegulationID
**Rules**:
- Joined from DWH_dbo.Fact_SnapshotCustomer via CID = RealCID
- Date-bounded using DWH_dbo.Dim_Range: DateRangeID matches where DateID is BETWEEN FromDateID AND ToDateID
- This is a slowly-changing dimension — a customer who moved regulatory regimes appears under the correct regulation for each historical date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Aspect | Detail |
|--------|--------|
| **Distribution** | ROUND_ROBIN — no natural skew correction. Works for this narrow table (2 instruments). |
| **Clustered Index** | DateID ASC — range queries on DateID are efficient. |
| **Filter recommendation** | Always add DateID filter; scanning all rows is 3M but can be slow with aggregation. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| UK prohibited staking exposure on a specific date | `WHERE DateID = YYYYMMDD AND TotalAmount_UK_prohibited > 0` |
| ADA vs TRON daily volume comparison | `GROUP BY DateID, InstrumentID` on `TotalAmountInUnitsDecimal` |
| Settled vs open position staking exposure | `GROUP BY DateID, IsSettled` on `TotalAmountInUnitsDecimal` |
| Exposure by regulation for compliance reporting | `GROUP BY DateID, RegulationID` with Dim_Regulation join |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name (Cardano / TRON) |
| DWH_dbo.Dim_Regulation | RegulationID = DWHRegulationID | Resolve regulation name (FCA, CySEC, etc.) |
| DWH_dbo.Dim_Country | CountryID = CountryID | Resolve country name |

### 3.4 Gotchas

- `TotalAmount_UK_prohibited` is 0 (not NULL) for non-prohibited rows — filter `> 0` rather than `IS NOT NULL`.
- `UpdateDate` is NULL for recently inserted rows (not set in SP); only legacy rows (pre-migration) have a populated value. Do not rely on it for freshness checks.
- Only 2 instruments exist in this table — do not expect other crypto staking instruments to appear without a SP code change.
- IsCopy is derived from MirrorID snap at position level, not the daily aggregation date — it reflects the copy relationship at position open, not at the snapshot date.
- 14 regulation IDs observed but RegulationID=0 (None) can appear; join to Dim_Regulation.ID to resolve.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki or DWH_dbo wiki (exact copy, no paraphrase) |
| Tier 2 | Derived from SP code and writer stored procedure analysis |
| Tier 3 | ETL metadata or system-generated columns confirmed from SP |
| Tier 4 | Inferred from context, sample data, or naming convention |
| Tier 5 | Expert review required — uncertain semantics |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NO | Snapshot date as YYYYMMDD integer; partition key. Passthrough from BI_DB_PositionPnL.DateID. (Tier 2 — SP_PositionPnL_Agg_daily_Staking, BI_DB_PositionPnL.DateID) |
| 2 | Date | date | YES | Snapshot calendar date. Passthrough from BI_DB_PositionPnL.Date. (Tier 2 — SP_PositionPnL_Agg_daily_Staking, BI_DB_PositionPnL.Date) |
| 3 | InstrumentID | int | NO | Staking instrument identifier. Always 100017 (Cardano/ADA) or 100026 (TRON/TRX) — hard-coded IN filter in SP. (Tier 2 — SP_PositionPnL_Agg_daily_Staking, BI_DB_PositionPnL.InstrumentID) |
| 4 | CountryID | int | YES | Customer's country of residence as of the snapshot date, resolved from DWH_dbo.Fact_SnapshotCustomer via SCD date-range join. (Tier 2 — SP_PositionPnL_Agg_daily_Staking, DWH_dbo.Fact_SnapshotCustomer.CountryID) |
| 5 | IsSettled | int | YES | 1 = real/settled asset position; 0 = CFD position. Passthrough from BI_DB_PositionPnL.IsSettled. (Tier 2 — SP_PositionPnL_Agg_daily_Staking, BI_DB_PositionPnL.IsSettled) |
| 6 | IsCopy | int | NO | 1 = copy-trading position (MirrorID ≠ 0); 0 = solo/direct position. ETL-computed: CASE WHEN BI_DB_PositionPnL.MirrorID <> 0 THEN 1 ELSE 0. (Tier 2 — SP_PositionPnL_Agg_daily_Staking) |
| 7 | TotalAmountInUnitsDecimal | numeric(38,6) | YES | Total staking position size in instrument units (ADA or TRX) for this date/instrument/country/regulation/settled/copy combination. SUM(BI_DB_PositionPnL.AmountInUnitsDecimal). (Tier 2 — SP_PositionPnL_Agg_daily_Staking) |
| 8 | TotalAmount_UK_prohibited | numeric(16,6) | YES | Subset of TotalAmountInUnitsDecimal attributable to UK FCA-regulated customers (CountryID=218, RegulationID=2) registered on or after 2022-02-08. 0 for all non-UK-prohibited rows. FCA crypto restrictions compliance column. (Tier 2 — SP_PositionPnL_Agg_daily_Staking) |
| 9 | RegulationID | int | YES | Customer's regulatory regime as of the snapshot date, resolved from DWH_dbo.Fact_SnapshotCustomer. FK to DWH_dbo.Dim_Regulation.ID (0=None, 1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, etc.). (Tier 2 — SP_PositionPnL_Agg_daily_Staking, DWH_dbo.Fact_SnapshotCustomer.RegulationID) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. EXCEPTION: NULL for rows inserted after SP refactor (SP does not SET UpdateDate); only legacy rows (pre-migration) have a populated value. Do not use for freshness monitoring. (Tier 3 — SP_PositionPnL_Agg_daily_Staking) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough |
| Date | BI_DB_dbo.BI_DB_PositionPnL | Date | Passthrough |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Filter: IN (100017, 100026) |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | SCD date-range JOIN |
| IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Passthrough |
| IsCopy | BI_DB_dbo.BI_DB_PositionPnL | MirrorID | CASE WHEN ≠ 0 THEN 1 ELSE 0 |
| TotalAmountInUnitsDecimal | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM GROUP BY 6 dims |
| TotalAmount_UK_prohibited | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM WHERE UK FCA + reg date |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | SCD date-range JOIN |
| UpdateDate | ETL metadata | — | Not SET in SP; NULL on new inserts |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL
  (daily position P&L snapshot, InstrumentID IN (100017 Cardano, 100026 TRON) only)
  + DWH_dbo.Fact_SnapshotCustomer  (CountryID, RegulationID — SCD range join)
  + DWH_dbo.Dim_Range              (DateRangeID → FromDateID/ToDateID)
  + DWH_dbo.Dim_Customer           (RegisteredReal for UK FCA threshold)
    |-- SP_PositionPnL_Agg_daily_Staking (Daily, Priority 21, SB_Daily) ---|
    v
BI_DB_dbo.BI_DB_PositionPnL_Agg_daily_Staking
  (3.01M rows | 2021-11-01 → 2026-04-12 | ROUND_ROBIN | 2 staking instruments)
    |-- UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolves to instrument name (Cardano / TRON) |
| CountryID | DWH_dbo.Dim_Country | Resolves to country name and region |
| RegulationID | DWH_dbo.Dim_Regulation | Resolves to regulation name (FCA, CySEC, ASIC, etc.) |

### 6.2 Referenced By (other objects point to this)

| Object | Reference | Purpose |
|--------|-----------|---------|
| BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp | Reads this table | UK compliance professional opt-up eligibility enrichment (Batch 12 #4) |
| BI_DB_dbo.SP_Staking_Daily_Email_for_labs | Reads this table | Daily staking monitoring email to Labs team |

---

## 7. Sample Queries

### UK FCA Prohibited Staking Exposure by Instrument (Latest Date)

```sql
SELECT 
    InstrumentID,
    SUM(TotalAmountInUnitsDecimal)    AS total_units,
    SUM(TotalAmount_UK_prohibited)    AS uk_prohibited_units
FROM [BI_DB_dbo].[BI_DB_PositionPnL_Agg_daily_Staking]
WHERE DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_PositionPnL_Agg_daily_Staking])
GROUP BY InstrumentID
```

### Daily Staking Exposure Trend by Regulation

```sql
SELECT 
    DateID,
    r.Name          AS Regulation,
    SUM(TotalAmountInUnitsDecimal) AS total_units
FROM [BI_DB_dbo].[BI_DB_PositionPnL_Agg_daily_Staking] s
JOIN [DWH_dbo].[Dim_Regulation] r ON s.RegulationID = r.DWHRegulationID
WHERE DateID >= 20250101
GROUP BY DateID, r.Name
ORDER BY DateID DESC, total_units DESC
```

### Copy vs Solo Staking Breakdown

```sql
SELECT 
    DateID,
    InstrumentID,
    IsCopy,
    IsSettled,
    SUM(TotalAmountInUnitsDecimal) AS total_units
FROM [BI_DB_dbo].[BI_DB_PositionPnL_Agg_daily_Staking]
WHERE DateID >= 20260101
GROUP BY DateID, InstrumentID, IsCopy, IsSettled
ORDER BY DateID DESC, total_units DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object. See parent table wiki for general staking context: [BI_DB_dbo.BI_DB_PositionPnL](BI_DB_PositionPnL.md).

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 10/14*
*Tiers: 0 T1, 8 T2, 2 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, ETL: confirmed*
*Object: BI_DB_dbo.BI_DB_PositionPnL_Agg_daily_Staking | Type: Table | Production Source: BI_DB_PositionPnL via SP_PositionPnL_Agg_daily_Staking*
