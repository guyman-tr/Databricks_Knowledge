# Dealing_dbo.Dealing_Staking_OptedOut_US

> US staking daily aggregate opt-in/out table — one row per instrument per day, summarising how many US clients and how many units are opted in vs opted out, along with available-for-staking units after the liquidity buffer. US counterpart to Dealing_Staking_OptedOut.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Staking_DailyPool_US (also writes OptedOut_PerCID_US and DailyPool_US) |
| **Refresh** | Daily via SB_Daily (Priority 0) |
| **Row Count** | ~Daily rows × 4 instruments (active since 2025-08-20) |
| **Temporal Coverage** | 2025-08-20 — present (active) |
| **Instruments** | ADA (100017), ETH (100001), SOL (100063), SUI (100340) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |

---

## 1. Business Meaning

This is the **daily staking operations monitoring table** for the US program. Finance and operations use it to ensure that the opt-out ratio does not breach the liquidity buffer threshold — i.e., that eToro retains enough opted-in units to meet its staking commitments.

**Key metric**: `Units_AvailableForStaking = OptedInUnits × LiquidityBuffer`

If too many clients opt out in a given day, `Units_AvailableForStaking` drops and eToro may need to adjust its staking commitments to the blockchain network.

**As of 2026-03-10 snapshot**:
- ADA: 23,068 eligible, 22,900 opted in (99.3%), 16.3M units available for staking
- ETH: 26,084 eligible, 1,160 opted in (4.4%), 1,129 units available — ETH opt-out is expected and normal (default is opt-out)
- SOL: 970 eligible, 933 opted in (96.2%)
- SUI: 175 eligible, 163 opted in (93.1%) — new program, Feb 2026

---

## 2. Columns

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Reporting date (Tier 2 — SP parameter) |
| InstrumentID | int | Staking instrument ID (Tier 4 — Dealing_Staking_Parameters_US) |
| Currency | varchar(100) | Asset ticker (ADA/ETH/SOL/SUI) (Tier 4 — Parameters_US) |
| LiquidityBuffer | decimal(16,4) | Fraction of opted-in units reserved for staking: ADA=0.9, ETH=1.0, SOL=0.8, SUI=0.9 (Tier 4 — Parameters_US) |
| USD_Rate | decimal(16,4) | Spot price of asset in USD on this date (Tier 2 — Fact_CurrencyPriceWithSplit) |
| Regulation | varchar(50) | Always FinCEN+FINRA in this table (Tier 1 — Dim_Regulation) |
| EligibleClients | decimal(32,4) | Count of eligible US clients with positions in this instrument (Tier 2 — computed) |
| EligibleUnits | decimal(32,4) | Total units held by all eligible clients (Tier 2 — BI_DB_PositionPnL) |
| EligibleValue | decimal(32,4) | EligibleUnits × USD_Rate (Tier 2 — computed) |
| OptedInClients | decimal(32,4) | Count of clients currently opted in (Tier 2 — computed) |
| OptedInUnits | decimal(32,4) | Total units for opted-in clients (Tier 2 — computed) |
| OptedInValue | decimal(32,4) | OptedInUnits × USD_Rate (Tier 2 — computed) |
| OptedOutClients | decimal(32,4) | Count of clients currently opted out (Tier 2 — computed) |
| OptedOutUnits | decimal(32,4) | Total units for opted-out clients (Tier 2 — computed) |
| OptedOutValue | decimal(32,4) | OptedOutUnits × USD_Rate (Tier 2 — computed) |
| Units_AvailableForStaking | decimal(32,4) | OptedInUnits × LiquidityBuffer — units eToro can commit to the blockchain staking network (Tier 2 — computed) |
| Value_AvailableForStaking | decimal(32,4) | Units_AvailableForStaking × USD_Rate (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — GETDATE()) |

---

## 3. Usage Notes

- **EligibleClients + OptedInClients + OptedOutClients**: EligibleClients = OptedInClients + OptedOutClients.
- **ETH opt-out dominance is normal**: Default for ETH is opt-OUT. Large OptedOutClients for ETH does not indicate a problem.
- **LiquidityBuffer < 1.0**: Means eToro can only commit a fraction of opted-in holdings to staking. ETH buffer=1.0 means all opted-in ETH is available (eToro doesn't need an ETH liquidity reserve).
- **SUI DailyPool_StartDate = 2026-02-26**: SUI tracking started Feb 2026; distribution starts 2026-04-01.

---

## 4. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| CID detail | Dealing_Staking_OptedOut_PerCID_US | Date + InstrumentID | Per-client breakdown |
| Pool tracking | Dealing_Staking_DailyPool_US | Date + InstrumentID | Monthly pool progress |
| US parameters | Dealing_Staking_Parameters_US | InstrumentID | LiquidityBuffer config |
| Global counterpart | Dealing_Staking_OptedOut | Date + InstrumentID | Non-US equivalent |
