# BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

> DDR framework fact table for **daily trading volumes and invested amounts** — aggregates position-level open/close volumes, cash invested on open/close, transaction counts, and product/context flags per customer (`RealCID`) and reporting day, at the grain produced by `Function_Trading_Volume_PositionLevel` after summing to the SP’s `GROUP BY` dimensions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — daily aggregate) |
| **Production Source** | `BI_DB_dbo.Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)` |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` aggregated sums |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_Trading_Volumes_And_Amounts` stores **how much notional volume** and **how much cash was invested** on **open vs close** events for each customer per day, broken out by a fixed set of analytical dimensions (instrument type, settlement, copy trading, buy direction, leverage, futures, CopyFund, IBAN flows, recurring investment, airdrop, SQF, margin, C2P).

Unlike the revenue fact, this table does **not** store fee revenue — it supports **activity and exposure** analytics (volumes, invested amounts, transaction counts) aligned with the DDR customer-day framework.

`TotalVolume` and `NetInvestedAmount` are **aggregated at the fact grain** from the position-level function after summing; at position level the function exposes `TotalVolume` and `NetInvestedAmount` such that daily totals are the sum of those position values in the SP.

Author: Guy Manova (2025-04-20); `Function_Trading_Volume_PositionLevel` replaced earlier sources per change history (position-level granularity, QA dump to `BI_DB_VolumeQA` when deployed).

---

## 2. Business Logic

### 2.1 Aggregation grain

**What**: One row per unique combination of `DateID`, `RealCID`, and all grouped classification columns.

**Columns**: All dimensions in `GROUP BY` plus summed measures.

**Rules**:
- Measures are **SUM** across positions that share the same dimension bucket on that `DateID`.
- `IsLeverage` is **derived** in the SP as `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END` (table column name `IsLeverage`).

### 2.2 Volume and invested amounts

**What**: Open vs close decomposition and net figures.

**Columns**: `VolumeOpen`, `VolumeClose`, `TotalVolume`, `InvestedAmountOpen`, `InvestedAmountClosed`, `NetInvestedAmount`

**Rules**:
- **Volumes** represent trading volume in **position value** terms as defined in `Function_Trading_Volume_PositionLevel` (Tier 2 — underlying function; exact unit documented there).
- **Invested amounts** are **cash invested** on open and close paths.
- `TotalVolume` and `NetInvestedAmount` are summed like other measures — interpret as **sum of position-level totals** in each bucket, not recomputed from aggregated open/close unless the function guarantees linearity.

### 2.3 Transaction counts

**What**: Counts of open, close, and total transactions in the bucket.

**Columns**: `CountOpenTransactions`, `CountCloseTransactions`, `CountTotalTransactions`

**Rules**: Summed from the position-level function in the same `GROUP BY` grain.

### 2.4 QA auxiliary table

**What**: Optional full **position-level** dump to `BI_DB_dbo.BI_DB_VolumeQA` for the same `@dateID`.

**Columns**: N/A on this table — see `BI_DB_VolumeQA` for QA columns including `ComputedVolumeOpen` / `ComputedVolumeClose`.

**Rules**: Executed only if `OBJECT_ID('BI_DB_dbo.BI_DB_VolumeQA')` is not null — used to diagnose volume discrepancies (per SP comment on timing/data loss).

---

## 3. Query Advisory

### 3.1 Synapse distribution and columnstore

**HASH(RealCID)**: Aligns with customer-centric reporting and joins to `Dim_Customer`.

**CLUSTERED COLUMNSTORE**: Analytical scans — always constrain **`DateID`** (and typically `RealCID` or ranges) to limit scans.

### 3.1b UC (Databricks) storage and partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID | Customer attributes |
| DWH_dbo.Dim_Date | ON DateID | Calendar |
| DWH_dbo.Dim_InstrumentType | ON InstrumentTypeID | Instrument type label |

### 3.3 Gotchas

- **`IsOpenedFromIBAN` is varchar(100)** in the table while similar flags elsewhere are often int — treat as **categorical / label** from the function, not 0/1 unless values prove binary (Tier 4 — [UNVERIFIED] domain values).
- **No downstream objects** were found in the DataPlatform repo — consumers may live in reports or other repos.
- **QA timing**: SP author notes possible **data variance** when re-running at different times — use `BI_DB_VolumeQA` when available for diagnosis.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Reporting day YYYYMMDD. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 2 | Date | date | NULL | Derived from DateID via `CONVERT(DATE, CONVERT(VARCHAR(8), DateID), 112)`. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 3 | RealCID | int | NULL | Customer ID (`CID` from function, aliased RealCID). (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 4 | InstrumentTypeID | int | NULL | Instrument type key. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 5 | IsSettled | int | NULL | Settlement flag from function. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 6 | IsCopy | int | NULL | Copy/mirror trading context. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 7 | IsBuy | int | NULL | Buy/sell direction bucket. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 8 | IsLeverage | int | NULL | 1 if `Leverage > 1` at position level, else 0. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 9 | IsFuture | int | NULL | Futures product flag. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 10 | IsCopyFund | int | NULL | CopyFund programme flag. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 11 | IsOpenedFromIBAN | varchar(100) | NULL | IBAN-related open context from function — **varchar**, not int. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 12 | IsClosedToIBAN | int | NULL | Position closed to IBAN flag. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 13 | IsRecurring | int | NULL | Recurring investment context. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 14 | IsAirDrop | int | NULL | Airdrop context. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 15 | VolumeOpen | bigint | NULL | Sum of open-side trading volume (position value) in bucket. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 16 | VolumeClose | bigint | NULL | Sum of close-side trading volume in bucket. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 17 | InvestedAmountOpen | money | NULL | Sum of cash invested on opens. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 18 | InvestedAmountClosed | money | NULL | Sum of cash invested on closes. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 19 | TotalVolume | bigint | NULL | Sum of position `TotalVolume` in bucket (open + close at position level in source). (Tier 4 — [UNVERIFIED] verify vs VolumeOpen+VolumeClose if needed) |
| 20 | NetInvestedAmount | money | NULL | Sum of position `NetInvestedAmount` in bucket. (Tier 4 — [UNVERIFIED] confirm sign convention in function) |
| 21 | CountOpenTransactions | int | NULL | Sum of open transaction counts. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 22 | CountCloseTransactions | int | NULL | Sum of close transaction counts. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 23 | CountTotalTransactions | int | NULL | Sum of total transaction counts. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 24 | UpdateDate | datetime | NULL | `GETDATE()` on load. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 25 | IsSQF | int | NULL | Spot Quoted Futures flag. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 26 | IsMarginTrade | int | NULL | Margin trade flag. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |
| 27 | IsC2P | int | NULL | Copy to Portfolio flag. (Tier 2 — SP_DDR_Fact_Trading_Volumes_And_Amounts) |

---

## 5. Lineage

### 5.1 Pipeline

```
SP_DDR_Fact_Trading_Volumes_And_Amounts(@date)
  ├─ #data ← Function_Trading_Volume_PositionLevel(@dateID, @dateID, 0)
  ├─ DELETE + INSERT (aggregated)
  └─ Optional BI_DB_VolumeQA position dump
```

### 5.2 Key source tables

| Source | Role |
|--------|------|
| BI_DB_dbo.Function_Trading_Volume_PositionLevel | Sole business source for volumes, amounts, counts, flags |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Customer | RealCID | Customer |
| DWH_dbo.Dim_Date | DateID | Calendar |
| DWH_dbo.Dim_InstrumentType | InstrumentTypeID | Instrument type |

### 6.2 Referenced By (other objects point to this)

| Source Object | Description |
|--------------|-------------|
| _No SSDT references found in DataPlatform repo_ | Downstream usage may be outside cloned scope |

---

*Generated: 2026-03-23 | Object: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts | Writer: SP_DDR_Fact_Trading_Volumes_And_Amounts*
