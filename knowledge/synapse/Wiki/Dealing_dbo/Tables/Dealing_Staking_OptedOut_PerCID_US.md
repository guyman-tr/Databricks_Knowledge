# Dealing_dbo.Dealing_Staking_OptedOut_PerCID_US

> US staking daily client-level opt-in/out snapshot — one row per CID per instrument per day, showing each eligible US client's holdings and current opt-in status for US crypto staking monitoring. US counterpart to Dealing_Staking_OptedOut_PerCID.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Staking_DailyPool_US (also writes OptedOut_US and DailyPool_US) |
| **Refresh** | Daily via SB_Daily (Priority 0) |
| **Row Count** | ~10.1M (2025-08-20 to present; 4 instruments × ~23K clients/day) |
| **Temporal Coverage** | 2025-08-20 — present (active) |
| **Instruments** | ADA (100017), ETH (100001), SOL (100063), SUI (100340) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |

---

## 1. Business Meaning

This is the **per-client daily monitoring table** for US staking. It tracks every eligible US client's holdings and opt-in/out status per instrument each day, enabling:
- Detection of opt-out spikes that would breach the LiquidityBuffer threshold
- CS investigation of individual client opt-in history
- Finance tracking of holdings available for staking

**Eligibility criteria** (applied by SP_Staking_DailyPool_US):
- FinCEN+FINRA (RegulationID=8) — verified Level 3 identity
- CountryID=219 (US)
- State not in excluded list: CA, MD, NJ, WI, WA, NY, NV, HI

**Note**: The `Country` column contains **US state names** (e.g., "Massachusetts", "Texas") — the column is named `Country` for legacy reasons but stores state-level data.

---

## 2. Columns

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Reporting date (Tier 2 — SP parameter) |
| CID | int | Customer ID (Tier 1 — DWH_dbo.Dim_Customer) |
| GCID | int | Global Customer ID (Tier 2 — DWH_dbo.Dim_Customer) |
| InstrumentID | int | Staking instrument ID (ADA=100017, ETH=100001, SOL=100063, SUI=100340) (Tier 4 — Parameters_US) |
| Currency | varchar(100) | Asset ticker (ADA/ETH/SOL/SUI) (Tier 4 — Parameters_US) |
| USD_Rate | decimal(16,4) | Spot USD price of the asset on this date (Tier 2 — DWH_dbo.Fact_CurrencyPriceWithSplit) |
| Regulation | varchar(50) | Regulation classification; always FinCEN+FINRA for eligible clients (Tier 1 — DWH_dbo.Dim_Regulation) |
| EligibleUnits | decimal(32,4) | Total open non-copy settled position units in this asset for this CID (Tier 2 — BI_DB_PositionPnL) |
| EligibleValue | decimal(32,4) | EligibleUnits × USD_Rate (Tier 2 — computed) |
| IsOptedIn | int | 1 = client opted in for staking on this date; 0 = opted out. Non-ETH: default 1 (must opt OUT). ETH: default 0 (must opt IN) (Tier 2 — External_USABroker enrollment tables) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — GETDATE()) |
| Country | varchar(50) | US state name (mislabeled as Country — stores state e.g. "Massachusetts", "Ohio", "Texas") (Tier 1 — DWH_dbo.Dim_State_and_Province) |

---

## 3. Usage Notes

- **Country = US state**: Despite the column name, this holds the US state name, not country. Use for state-level analysis or CS investigations.
- **4 instruments** vs 3 in Summary: SUI was added 2026-02-26; first distribution expected 2026-04-01. SUI appears in OptedOut tracking before any distribution occurs.
- **ETH opt-in rate is very low**: On 2026-03-10, only 1,160 of 26,084 eligible ETH clients (4.4%) are opted in. Default is opt-OUT for ETH.
- **ADA opt-out rate is very low**: On 2026-03-10, only 168 of 23,068 eligible ADA clients (0.7%) are opted out. Default is opt-IN for ADA/SOL/SUI.

---

## 4. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| Daily aggregate | Dealing_Staking_OptedOut_US | Date + InstrumentID | Roll-up of this table |
| Pool tracking | Dealing_Staking_DailyPool_US | Date + InstrumentID | Daily pool size summary |
| US parameters | Dealing_Staking_Parameters_US | InstrumentID | LiquidityBuffer, IntroDays |
| Global counterpart | Dealing_Staking_OptedOut_PerCID | Date + CID + InstrumentID | Non-US equivalent |
