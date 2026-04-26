# BI_DB_dbo.Dealing_CryptoRebate

> Monthly crypto rebate calculation for Diamond and Platinum Plus club members — realized trading volumes across a 3-tier bracket structure, producing a USD rebate payable at month-end.

---

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Computed (no direct production source) |
| **Refresh** | Monthly (P20 — runs after club membership snapshot is available) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (MonthEndDate ASC) |
| **Rows** | ~210K (49 months × ~4,300 members/month avg) |
| **Date Range** | 2022-03-31 to present (rebate program inception: 2022-03-08) |

---

## 1. Business Meaning

`Dealing_CryptoRebate` stores the **realized** crypto trading rebate calculation for Diamond and Platinum Plus eToro Club members. Each row represents one club member's crypto activity for one calendar month — their trading volumes, bracket classifications, and the USD rebate earned.

The rebate program rewards high-volume crypto traders in the two premium club tiers with cash-back on spreads. Eligibility is determined at the **end of the reporting month**: only Diamond (PlayerLevelID=7) or Platinum Plus (PlayerLevelID=6) customers who are NOT active Popular Investors (GuruStatusID NOT IN 2,3,4,5,6) and are NOT in excluded EU countries qualify.

As of March 2026: **5,853 members** participate (802 Diamond, 5,051 Platinum Plus). Of these, ~26% of Diamond and ~9% of Platinum Plus members earn a positive rebate. Average Diamond rebate is ~$111/month; Platinum Plus ~$11/month. Data spans from 2022-03-31 (program inception) to present across 49 months.

The companion table `BI_DB_dbo.Dealing_Unrealized_CryptoRebate` stores the same calculation for positions still **open** at month-end (using end-of-month prices). Both are populated in the same SP execution.

---

## 2. Business Logic

### 2.1 Club Member Eligibility

Eligible members are identified from `DWH_dbo.Fact_SnapshotCustomer` at the last day of the month (via `Dim_Range` for the time-bounded SCD2 snapshot). Inclusion criteria:

- `PlayerLevelID IN (6, 7)` — Platinum Plus or Diamond only
- `IsValidCustomer = 1`
- `GuruStatusID NOT IN (2,3,4,5,6)` — excludes active Popular Investors from the rebate
- Country NOT IN: Austria, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, United Kingdom

German BaFin customers are flagged via `BI_DB_dbo.V_GermanBaFin` (stored in `IsGermanBaFin` in the companion unrealized table only).

### 2.2 Volume Calculation (Realized)

Only **realized** positions are included here (settled positions that closed during the reporting month):

- Position filters: `IsSettled=1`, `IsDiscounted=0`, `IsBuy=1` (long only), `MirrorID=0`, `Leverage=1`
- Instrument filter: `InstrumentTypeID=10` (crypto instruments only)
- Date filter: `CloseDateID BETWEEN @MonthStartDateID AND @MonthEndDateID`
- Hardcoded inception filter: `OpenDateID >= 20220308` (rebate program start date)

```
OpenedVolume = SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1))
ClosedVolume = SUM(AmountInUnitsDecimal × ISNULL(EndForexRate,1) × ISNULL(LastOpConversionRate,1))
TotalVolume  = OpenedVolume + ClosedVolume
```

**Note**: `TotalVolume` double-counts each position (once at open rate, once at close rate). This is intentional by the rebate design — it captures total turnover exposure.

### 2.3 Tiered Rebate Brackets

The rebate is computed on the CID's monthly `TotalVolume` across three brackets:

```
Below $50K           → no rebate (below minimum threshold)
$50K   → $1M (B1)   → 0.15% rebate on volume in this range  (max $950K × 0.15% = $1,425)
$1M    → $5M (B2)   → 0.25% rebate on volume in this range  (max $4M  × 0.25% = $10,000)
Above  $5M   (B3)   → 0.50% rebate on volume in this range  (uncapped)
```

Volume boundary assignments:
```
Bracket1_Volume = CASE WHEN TotalVolume BETWEEN 50K AND 1M   THEN TotalVolume - 50K
                       WHEN TotalVolume > 1M                  THEN 950,000
                       ELSE 0 END
Bracket2_Volume = CASE WHEN TotalVolume BETWEEN 1M AND 5M    THEN TotalVolume - 1M
                       WHEN TotalVolume > 5M                  THEN 4,000,000
                       ELSE 0 END
Bracket3_Volume = CASE WHEN TotalVolume > 5M                  THEN TotalVolume - 5M
                       ELSE 0 END
```

Rebate rates:
```
Bracket1_Rebate = Bracket1_Volume × 0.15 / 100
Bracket2_Rebate = Bracket2_Volume × 0.25 / 100
Bracket3_Rebate = Bracket3_Volume × 0.50 / 100
TotalRebate     = IF (B1+B2+B3 < $5) THEN 0 ELSE B1+B2+B3   ← minimum threshold
```

`Markup` = `TotalVolume × 0.01` (spread-proxy; informational, not used in rebate math).

### 2.4 ETL Pattern (DELETE + INSERT)

Monthly ETL: the SP deletes all existing rows for `@MonthEndDate` then inserts the freshly calculated results. This allows re-runs (e.g., data corrections) without duplicates.

```
SP_M_CryptoRebateDiamond(@Date)
  → #club_members: eligible Diamond/Platinum Plus at @MonthEndDate (from Fact_SnapshotCustomer)
  → #volumeonopen:  OpenedVolume per CID (Dim_Position, closed this month, using open rate)
  → #volumeonclose: ClosedVolume per CID (Dim_Position, closed this month, using close rate)
  → #monthlytable:  joined volumes per CID
  → #finaltable:    filter TotalVolume > 0
  → #BracketsVolume: bracket volume splits per CID
  → #BracketsRebate: rebate calculations
  → #TotalRebate:    apply $5 minimum
  DELETE FROM Dealing_CryptoRebate WHERE MonthEndDate = @MonthEndDate
  INSERT INTO Dealing_CryptoRebate
  → (then continues to compute unrealized → Dealing_Unrealized_CryptoRebate)
```

---

## 3. Query Advisory

### 3.1 Grain

One row per **(CID, MonthEndDate)**. `Club`, `Regulation`, and `Country` are attributes, not grain dimensions — each CID has exactly one club tier and regulation at month-end.

### 3.2 Common Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total rebate paid in a month | `SUM(TotalRebate) WHERE MonthEndDate = '2026-03-31' AND TotalRebate > 0` |
| Diamond vs Platinum Plus split | `GROUP BY Club, MonthEndDate` |
| Members earning a rebate (bracket qualification) | `WHERE Bracket1_Volume + Bracket2_Volume + Bracket3_Volume > 0` |
| High-tier earners | `WHERE Bracket3_Volume > 0` (crossed the $5M threshold) |
| Regulation-level rebate analysis | `GROUP BY Regulation, MonthEndDate` |
| Trend over time | `GROUP BY MonthEndDate, Club ORDER BY MonthEndDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `BI_DB_dbo.Dealing_Unrealized_CryptoRebate` | ON CID = CID AND MonthEndDate = MonthEndDate | Total (realized + unrealized) rebate per member |
| `DWH_dbo.Fact_SnapshotCustomer` | RealCID = CID, date-bounded | Additional customer attributes |

### 3.4 Gotchas

- **TotalVolume ≠ position volume**: It double-counts each position (open rate + close rate). Do not compare directly to position-level USD volumes from `Dim_Position`.
- **$5 minimum threshold**: `TotalRebate = 0` does NOT mean no volume — it may mean bracket rebate was below $5. Check `Bracket1_Rebate + Bracket2_Rebate + Bracket3_Rebate` directly if needed.
- **Markup is NOT the rebate**: `Markup` (1% of TotalVolume) is a spread proxy stored for reference. The actual rebate is `TotalRebate`.
- **Hardcoded inception date**: Positions opened before 2022-03-08 are excluded even if closed in the reporting month. This affects early months.
- **No FCA/UK customers**: UK customers are excluded (country exclusion list). FCA rows present are non-UK FCA customers.
- **GuruStatus exclusion**: Active Popular Investors (GuruStatusID 2–6) are excluded — they have a separate commission structure.
- **`UPdatedate` typo**: The column name uses 'UP' capitalization (`UPdatedate`) — a typo in the original DDL. Use exact case when referencing.

---

## 4. Elements

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_M_CryptoRebateDiamond) |
| ** | Tier 3 - inferred from context | (Tier 3 - inferred) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MonthEndDate | date | YES | Last calendar day of the reporting month. Grain key: one row per CID per month. Set to `EOMONTH(@MonthStartDate)` where `@MonthStartDate = DATEADD(month, DATEDIFF(month, 0, @Date), 0)`. Used as the DELETE/INSERT key for monthly refresh. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 2 | Club | varchar(100) | YES | eToro Club loyalty tier of the member at month-end. Values: "1 Diamond" (PlayerLevelID=7) or "1 Platinum Plus" (PlayerLevelID=6). Only these two premium tiers qualify for the crypto rebate program. 2 distinct values. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 3 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| 4 | GuruStatus_ID | int | YES | Customer's Popular Investor (Guru) program status at month-end, from `Fact_SnapshotCustomer.GuruStatusID`. Only customers with status NOT IN (2,3,4,5,6) are eligible — i.e., non-active Popular Investors are included; active PIs are excluded from the rebate program. FK to `Dim_GuruStatus`. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 5 | Country | varchar(100) | YES | Customer's country of residence at month-end (`Dim_Country.Name` via `Fact_SnapshotCustomer.CountryID`). Excludes: Austria, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, United Kingdom. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 6 | Region | varchar(100) | YES | Geographic region grouping for the customer, sourced from `Fact_SnapshotCustomer.Region`. Groups countries into business regions (e.g., "Spain", "North Europe", "Arabic GCC", "French"). (Tier 2 - SP_M_CryptoRebateDiamond) |
| 7 | Regulation | varchar(100) | YES | Customer's regulatory jurisdiction at month-end (`Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`). Top values in 2025: CySEC (~62%), FCA (~16%), FSA Seychelles (~10%), ASIC & GAML (~6%), FSRA (~4%). 12 distinct values total. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 8 | OpenedVolume | float | YES | Total USD value of crypto positions opened and settled (closed) in the reporting month, valued at the **open-side** rate. Formula: `SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1))`. Filters: InstrumentTypeID=10 (crypto), IsBuy=1 (long only), Leverage=1, MirrorID=0, IsDiscounted=0, CloseDateID in month, OpenDateID ≥ 20220308. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 9 | ClosedVolume | float | YES | Total USD value of those same positions valued at the **close-side** rate. Formula: `SUM(AmountInUnitsDecimal × ISNULL(EndForexRate,1) × ISNULL(LastOpConversionRate,1))`. Same position filters as OpenedVolume. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 10 | TotalVolume | float | YES | Combined turnover: `OpenedVolume + ClosedVolume`. Intentionally double-counts each position (open + close sides). This aggregate is the input to the bracket rebate calculation. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 11 | Markup | float | YES | Spread proxy: `TotalVolume × 0.01` (1% of total turnover). Stored as a reference metric to approximate spread revenue. **Not used in rebate calculation**. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 12 | Bracket1_Volume | float | YES | Volume falling in the first rebate tier ($50K–$1M): `CASE WHEN TotalVolume BETWEEN 50K AND 1M THEN TotalVolume−50K; WHEN TotalVolume > 1M THEN 950,000; ELSE 0`. Maximum contribution per CID: $950,000. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 13 | Bracket2_Volume | float | YES | Volume in the second rebate tier ($1M–$5M): `CASE WHEN TotalVolume BETWEEN 1M AND 5M THEN TotalVolume−1M; WHEN TotalVolume > 5M THEN 4,000,000; ELSE 0`. Maximum contribution: $4,000,000. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 14 | Bracket3_Volume | float | YES | Volume in the top rebate tier (above $5M): `CASE WHEN TotalVolume > 5M THEN TotalVolume−5M; ELSE 0`. Uncapped — high-volume Diamond members drive this bracket. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 15 | Bracket1_Rebate | float | YES | Rebate earned in Bracket 1: `Bracket1_Volume × 0.15 / 100` (0.15% rate). Maximum per CID: $1,425. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 16 | Bracket2_Rebate | float | YES | Rebate earned in Bracket 2: `Bracket2_Volume × 0.25 / 100` (0.25% rate). Maximum per CID: $10,000. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 17 | Bracket3_Rebate | float | YES | Rebate earned in Bracket 3: `Bracket3_Volume × 0.50 / 100` (0.50% rate — highest tier). Uncapped. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 18 | TotalRebate | float | YES | Final payable rebate: `Bracket1_Rebate + Bracket2_Rebate + Bracket3_Rebate`, with a minimum threshold applied — if sum < $5, set to 0 (suppresses trivial payments). This is the actionable output of the rebate calculation. (Tier 2 - SP_M_CryptoRebateDiamond) |
| 19 | UPdatedate | datetime | YES | ETL metadata: timestamp when this row was written. Set to `GETDATE()` on insert. Note: column name contains a capitalization typo (`UPdatedate` instead of `UpdateDate`) — use exact case in queries. (Tier 2 - SP_M_CryptoRebateDiamond) |

---

## 5. Lineage

### 5.1 Source → Target Column Map

| Synapse Column | Source Object | Source Column | Transform |
|---------------|---------------|---------------|-----------|
| MonthEndDate | ETL parameter | @Date | `EOMONTH(DATEADD(month, DATEDIFF(month, 0, @Date), 0))` |
| Club | DWH_dbo.Dim_PlayerLevel | PlayerLevelID / Name | `CASE 7→'1 Diamond', 6→'1 Platinum Plus'` |
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | passthrough |
| GuruStatus_ID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | passthrough |
| Country | DWH_dbo.Dim_Country | Name | via FSC.CountryID → Dim_Country.CountryID |
| Region | DWH_dbo.Fact_SnapshotCustomer | Region | passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | via FSC.RegulationID → Dim_Regulation.DWHRegulationID |
| OpenedVolume | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, InitForex_USDConversionRate | `SUM(units × ISNULL(InitForex,1) × ISNULL(InitUSD,1))` |
| ClosedVolume | DWH_dbo.Dim_Position | AmountInUnitsDecimal, EndForexRate, LastOpConversionRate | `SUM(units × ISNULL(EndForex,1) × ISNULL(LastOpConv,1))` |
| TotalVolume | ETL-computed | OpenedVolume + ClosedVolume | addition |
| Markup | ETL-computed | TotalVolume | `TotalVolume × 0.01` |
| Bracket1_Volume | ETT-computed | TotalVolume | CASE bracket split ($50K–$1M cap $950K) |
| Bracket2_Volume | ETL-computed | TotalVolume | CASE bracket split ($1M–$5M cap $4M) |
| Bracket3_Volume | ETL-computed | TotalVolume | CASE bracket split (>$5M uncapped) |
| Bracket1_Rebate | ETL-computed | Bracket1_Volume | `× 0.15 / 100` |
| Bracket2_Rebate | ETL-computed | Bracket2_Volume | `× 0.25 / 100` |
| Bracket3_Rebate | ETL-computed | Bracket3_Volume | `× 0.50 / 100` |
| TotalRebate | ETL-computed | B1+B2+B3 Rebate | `IF sum < $5 THEN 0 ELSE sum` |
| UPdatedate | ETL-computed | — | `GETDATE()` |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer  ─────────────────────┐
DWH_dbo.Dim_Range               (time-bounded SCD2)  │
DWH_dbo.Dim_PlayerLevel         (club tier lookup)   ├─→ #club_members (Diamond/Platinum Plus)
DWH_dbo.Dim_Country             (country name)       │
DWH_dbo.Dim_Regulation          (regulation name)    │
BI_DB_dbo.V_GermanBaFin         (BaFin flag)        ─┘
                                                       │
DWH_dbo.Dim_Position ──────────────────────────────── │─→ #volumeonopen / #volumeonclose
DWH_dbo.Dim_Instrument          (InstrumentTypeID=10) │    (crypto, long, settled, this month)
                                                       │
SP_M_CryptoRebateDiamond(@Date) ──────────────────────▼
  → bracket volume splits → rebate calc → $5 threshold
  → DELETE FROM Dealing_CryptoRebate WHERE MonthEndDate = @MonthEndDate
  → INSERT INTO BI_DB_dbo.Dealing_CryptoRebate       ← THIS TABLE
  → (continues) → INSERT INTO Dealing_Unrealized_CryptoRebate
```

### 5.3 Unity Catalog Target

**UC Target**: _Not_Migrated — no Unity Catalog mapping found in the generic pipeline mapping.

---

## 6. Relationships

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer.CustomerStatic (via etoroDB) | Source customer identifier |
| CID | DWH_dbo.Fact_SnapshotCustomer | Club membership and demographics at month-end |
| Club | DWH_dbo.Dim_PlayerLevel | PlayerLevelID 6=Platinum Plus, 7=Diamond |
| GuruStatus_ID | DWH_dbo.Dim_GuruStatus | Popular Investor status codes (2–6 excluded) |
| Country | DWH_dbo.Dim_Country | Country name via CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name via DWHRegulationID |
| MonthEndDate | BI_DB_dbo.Dealing_Unrealized_CryptoRebate | Same CID/month for unrealized counterpart |
| CID | BI_DB_dbo.BI_DB_PositionPnL | Open position snapshot used in unrealized calc |
| (positions) | DWH_dbo.Dim_Position | Crypto position volumes (settled) |
| (instruments) | DWH_dbo.Dim_Instrument | InstrumentTypeID=10 filter (crypto) |

---

## 7. Sample Queries

### 7.1 Monthly rebate summary by club tier

```sql
SELECT
    MonthEndDate,
    Club,
    COUNT(*)                                    AS member_count,
    SUM(CASE WHEN TotalRebate > 0 THEN 1 END)  AS members_with_rebate,
    SUM(TotalRebate)                            AS total_rebate_usd,
    AVG(TotalVolume)                            AS avg_volume_usd
FROM [BI_DB_dbo].[Dealing_CryptoRebate]
WHERE MonthEndDate >= '2025-01-31'
GROUP BY MonthEndDate, Club
ORDER BY MonthEndDate DESC, Club;
```

### 7.2 Top earners in a given month

```sql
SELECT TOP 20
    CID,
    Club,
    Country,
    Regulation,
    TotalVolume,
    Bracket3_Volume,
    TotalRebate
FROM [BI_DB_dbo].[Dealing_CryptoRebate]
WHERE MonthEndDate = '2026-03-31'
  AND TotalRebate > 0
ORDER BY TotalRebate DESC;
```

### 7.3 Total (realized + unrealized) rebate per member

```sql
SELECT
    r.CID,
    r.MonthEndDate,
    r.Club,
    r.TotalRebate                               AS RealizedRebate,
    ISNULL(u.TotalRebate, 0)                    AS UnrealizedRebate,
    r.TotalRebate + ISNULL(u.TotalRebate, 0)    AS CombinedRebate
FROM [BI_DB_dbo].[Dealing_CryptoRebate] r
LEFT JOIN [BI_DB_dbo].[Dealing_Unrealized_CryptoRebate] u
    ON r.CID = u.CID AND r.MonthEndDate = u.MonthEndDate
WHERE r.MonthEndDate = '2026-03-31'
  AND r.TotalRebate + ISNULL(u.TotalRebate, 0) > 0
ORDER BY CombinedRebate DESC;
```

### 7.4 Bracket distribution analysis

```sql
SELECT
    MonthEndDate,
    SUM(CASE WHEN TotalVolume = 0 THEN 1 ELSE 0 END)          AS no_volume,
    SUM(CASE WHEN TotalVolume BETWEEN 0 AND 50000 THEN 1 END)  AS below_min,
    SUM(CASE WHEN Bracket1_Volume > 0
              AND Bracket2_Volume = 0 THEN 1 END)              AS bracket1_only,
    SUM(CASE WHEN Bracket2_Volume > 0
              AND Bracket3_Volume = 0 THEN 1 END)              AS bracket2_only,
    SUM(CASE WHEN Bracket3_Volume > 0 THEN 1 END)              AS bracket3_reached
FROM [BI_DB_dbo].[Dealing_CryptoRebate]
WHERE MonthEndDate >= '2025-01-31'
GROUP BY MonthEndDate
ORDER BY MonthEndDate DESC;
```

---

## 8. Atlassian / Open Questions

No Confluence pages found. Open questions:

- **Rebate exclusion list changes**: The country exclusion list is hardcoded in the SP. France was added 2025-10-20. Is this list subject to regulatory review?
- **Bracket tier thresholds**: The $50K/$1M/$5M thresholds and 0.15%/0.25%/0.50% rates appear hardcoded. Where are these defined in product/business terms?
- **GuruStatus exclusion rationale**: Active Popular Investors (GuruStatusID 2–6) are excluded — presumably because they have a separate commission structure. Worth documenting formally.

---

*Generated: 2026-04-23 | Quality: 9.0/10 (****) | Phases: 11/14*
*Tiers: 1 T1, 17 T2, 0 T3, 0 T4, 1 T5 | Elements: 19/19, Logic: 10/10, Relationships: 9/10, Sources: 9/10*
*Object: BI_DB_dbo.Dealing_CryptoRebate | Type: Table | Writer SP: SP_M_CryptoRebateDiamond (P20)*
