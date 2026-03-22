# Dealing_dbo.Dealing_Staking_OptedOut_PerCID

> Daily per-client staking eligibility and opt-in status — one row per (date, CID, instrument) for all staking-eligible clients. The most granular staking monitoring table: records each client's eligible crypto holdings and whether they opted into staking for each instrument each day. The source for Dealing_Staking_OptedOut aggregations.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (analytical — daily grain CID fact) |
| **Production Source** | Derived — SP_Staking_DailyPool from BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo dimensions + waiver tables |
| **Refresh** | Daily — SP_Staking_DailyPool (co-written with Dealing_Staking_DailyPool and Dealing_Staking_OptedOut) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |
| **Row Count** | ~590,871,151 (as of Mar 2026) — **largest table in Dealing_dbo** |
| **Date Range** | 2024-08-07 – 2026-03-10 |
| **Distinct Clients** | 1,002,912 |
| **Instruments** | 13 |
| **Last Updated** | 2026-03-11 |

---

## 1. Business Meaning

This is the **most granular staking data table** — a daily snapshot of every eligible staking client's position and opt-in status, per instrument. With ~590M rows, it represents approximately 1M clients × 13 instruments × ~580 days (Aug 2024 – Mar 2026).

Primary uses:
1. **Aggregation source**: `Dealing_Staking_OptedOut` (the Staking PM monitoring table) is computed by aggregating this table by regulation
2. **Per-client investigation**: The Staking PM team can look up a specific CID (`--SELECT * FROM Dealing_Staking_OptedOut_PerCID where CID = 19118311`) to understand their staking status on any day
3. **SP_Staking input**: The monthly SP_Staking reads this via `#OptedOut_PerCID` to determine which clients were opted-in during the staking period and with what holdings

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Snapshot date. CLUSTERED INDEX key. Daily from Aug 2024. (Tier 3 — SP @Date) |
| CID | int | Trading account identifier (RealCID). Primary client identifier for staking position tracking. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| GCID | int | Global client identifier. Links to DWH_dbo.Dim_Customer.GCID. One GCID may have multiple CIDs. (Tier 1 — DWH_dbo.Dim_Customer) |
| InstrumentID | int | Crypto instrument FK to DWH_dbo.Dim_Instrument. This is the specific crypto instrument the client holds. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| Currency | varchar(100) | Crypto ticker (e.g., "ADA", "ETH", "SOL"). Includes EUR pairs. (Tier 3 — Fivetran_google_sheets) |
| USD_Rate | decimal(16,4) | Exchange rate: USD per 1 unit of this crypto at snapshot time. Used to compute EligibleValue. (Tier 3 — external rate source) |
| Regulation | varchar(50) | Client's eToro regulatory jurisdiction (e.g., "FCA", "CySEC", "FSA Seychelles"). Derived from DWH_dbo.Dim_Customer. Determines eligibility rules for each crypto. (Tier 1 — DWH_dbo) |
| EligibleUnits | decimal(32,4) | Total crypto units held by this client in eligible staking positions on this date. Derived from BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal, filtered to past-intro-period positions. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| EligibleValue | decimal(32,4) | USD value of EligibleUnits (EligibleUnits × USD_Rate). (Tier 3 — computed) |
| IsOptedIn | int | **1 = opted into staking, 0 = opted out**. Determined from the waiver/opt-in system (Fivetran Google Sheets + API-based waivers). Default is opted-in for most non-ETH assets; ETH requires active opt-in. (Tier 3 — waiver tables) |
| UpdateDate | datetime | ETL run timestamp from SP_Staking_DailyPool. (Tier 4 — ETL metadata) |
| Country | varchar(50) | Client's registered country name (e.g., "Italy", "Denmark"). From DWH_dbo.Dim_Country. Used for regional analysis of staking participation. (Tier 1 — DWH_dbo.Dim_Country) |

---

## 3. Business Logic

### 3.1 Eligibility Criteria (for inclusion in this table)

A client/instrument combination appears here only if:
1. The client has an active position in the instrument (from BI_DB_dbo.BI_DB_PositionPnL)
2. The instrument is in the staking program (from Fivetran_google_sheets_platform_rewards)
3. The client's regulation is eligible for staking (not US — US handled by separate pipeline)
4. The position has been held past the `IntroDays` waiting period (7 days most, 60 for ETH)

### 3.2 Aggregation Hierarchy

```
Dealing_Staking_OptedOut_PerCID (per client, per instrument, per day)
    ↓ aggregated by (InstrumentID, Currency, Regulation)
Dealing_Staking_OptedOut (per regulation, per instrument, per day)
    ↓ aggregated by (InstrumentID, Currency)
Dealing_Staking_DailyPool (total pool, per instrument, per day)
    ↓ monthly average
SP_Staking monthly reward calculation
```

### 3.3 CID vs GCID

Both IDs are stored because:
- **CID**: Trading account ID — used to join to position data (BI_DB_dbo.BI_DB_PositionPnL uses CID)
- **GCID**: Global client ID — used for email notifications and cross-account lookups

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_OptedOut` | Aggregation target — this table's per-client rows roll up to Dealing_Staking_OptedOut's regulation totals |
| `Dealing_dbo.Dealing_Staking_DailyPool` | Higher-level aggregate — total pool only, no regulation or CID detail |
| `Dealing_dbo.Dealing_Staking_Parameters` | Provides IntroDays (eligibility filter) |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source of client position holdings |
| `DWH_dbo.Dim_Customer` | Source of GCID and Regulation |

---

## 5. Notes & Caveats

- **590M rows — performance warning**: This is the largest table in Dealing_dbo. Queries without a Date filter will be extremely slow. Always filter by Date range. The CLUSTERED INDEX on Date supports daily range queries.
- **Daily writes**: Each run deletes and rewrites the day's rows — not an append-only table. Historical rows are permanent once the day's SP run completes.
- **Data starts Aug 2024**: Dealing_Staking_OptedOut starts May 2024 — there is a 3-month gap where the aggregated view exists but the per-CID detail does not.
- **Non-US only**: US clients are in a separate pipeline. No Dealing_Staking_OptedOut_PerCID_US exists.
- **Row count growth**: At ~1M clients × 13 instruments per day, the table grows by ~13M rows daily. Retention policy (if any) not documented in SSDT.
