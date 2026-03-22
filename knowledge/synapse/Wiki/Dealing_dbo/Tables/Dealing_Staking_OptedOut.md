# Dealing_dbo.Dealing_Staking_OptedOut

> Daily snapshot of staking pool participation by instrument and regulatory jurisdiction — eligible vs opted-in vs opted-out clients, units, and USD values, plus the liquidity-buffered amount eToro can commit to on-chain staking. One row per (date, instrument, regulation). Used by the Staking PM team to monitor daily participation rates.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (analytical — daily fact) |
| **Production Source** | Derived — SP_Staking_DailyPool from BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo customer/regulation data + waiver/opt-in tables |
| **Refresh** | Daily — SP_Staking_DailyPool (same run as Dealing_Staking_DailyPool) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |
| **Row Count** | 30,231 (as of Mar 2026) |
| **Date Range** | 2024-05-01 – 2026-03-10 |
| **Instruments** | 13 |
| **Granularity** | Daily per (Date, InstrumentID, Regulation) |
| **Last Updated** | 2026-03-11 |

---

## 1. Business Meaning

This is the **Staking PM's primary monitoring table** — it answers: *"How many clients are eligible for staking? Of those, how many opted in vs out? And how much can eToro actually commit to on-chain staking?"*

The table provides the breakdown by **regulatory jurisdiction** (FCA, CySEC, FSA Seychelles, etc.), which is critical because eligibility rules differ by regulation — not all regulations allow all crypto instruments, and some regulatory changes (e.g., FCA exclusion for certain coins in specific months) affect opt-in rates overnight.

**Key business metric: Units_AvailableForStaking** — this is the amount eToro can actually stake on behalf of clients, subject to two constraints:
1. **LiquidityBuffer**: eToro must keep a fraction (0.60–1.00 per instrument, from Dealing_Staking_Parameters) available for client withdrawals
2. **Recon Buffer**: An additional 5% (10% for ETH) safety margin on opted-in units, computed as `LEAST(EligibleUnits * LiquidityBuffer, OptedInUnits * 0.95)`

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Snapshot date. CLUSTERED INDEX key. Daily from May 2024. (Tier 3 — SP @Date) |
| InstrumentID | int | Crypto instrument FK to DWH_dbo.Dim_Instrument. One row per instrument/regulation per day. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| Currency | varchar(100) | Crypto ticker. Includes EUR pairs (ETHEUR, ADAEUR, SOLEUR). (Tier 3 — Fivetran_google_sheets) |
| LiquidityBuffer | decimal(16,4) | Fraction of eligible units that must remain available for client withdrawals (from Dealing_Staking_Parameters). E.g., 0.60 = only 60% of eligible units can be committed to staking. (Tier 3 — Dealing_Staking_Parameters) |
| USD_Rate | decimal(16,4) | Exchange rate: how many USD per 1 unit of this crypto at snapshot time. Used to compute Value columns. (Tier 3 — external rate source) |
| Regulation | varchar(50) | eToro regulatory jurisdiction name (e.g., "FCA", "CySEC", "FSA Seychelles", "ASIC"). Defines eligibility rules for this specific crypto. Derived from DWH_dbo.Dim_Customer. (Tier 1 — DWH_dbo) |
| EligibleClients | decimal(32,4) | Count of clients past the intro period with eligible positions in this instrument under this regulation. (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL eligible population) |
| EligibleUnits | decimal(32,4) | Total crypto units held by all eligible clients (opted-in AND opted-out combined). (Tier 3 — BI_DB_dbo.BI_DB_PositionPnL) |
| EligibleValue | decimal(32,4) | USD value of all eligible holdings (EligibleUnits × USD_Rate). (Tier 3 — computed) |
| OptedInClients | decimal(32,4) | Count of clients who actively opted INTO staking for this instrument. (Tier 3 — waiver/opt-in tables) |
| OptedInUnits | decimal(32,4) | Total units held by opted-in clients only. (Tier 3 — computed) |
| OptedInValue | decimal(32,4) | USD value of opted-in holdings. (Tier 3 — computed) |
| OptedOutClients | decimal(32,4) | Count of clients who opted OUT (EligibleClients - OptedInClients). (Tier 3 — computed) |
| OptedOutUnits | decimal(32,4) | Units held by opted-out clients. (Tier 3 — computed) |
| OptedOutValue | decimal(32,4) | USD value of opted-out holdings. (Tier 3 — computed) |
| Units_AvailableForStaking | decimal(32,4) | **The amount eToro can commit on-chain**. Computed as: `LEAST(EligibleUnits × LiquidityBuffer, OptedInUnits × 0.95)` (ETH uses 0.90 instead of 0.95). The minimum of two safety caps: the liquidity buffer (ensuring enough for withdrawals) and the recon buffer (5-10% safety margin on opted-in units). (Tier 3 — computed from SP_Staking_DailyPool logic) |
| Value_AvailableForStaking | decimal(32,4) | USD value of Units_AvailableForStaking. `LEAST(EligibleValue × LiquidityBuffer, OptedInValue × 0.95)`. (Tier 3 — computed) |
| UpdateDate | datetime | ETL run timestamp from SP_Staking_DailyPool. (Tier 4 — ETL metadata) |

---

## 3. Business Logic

### 3.1 Opt-In Mechanics

Staking opt-in is governed by a waiver system. Clients are either:
- **Default opted-in** (most non-ETH assets) — participate automatically unless they explicitly opt out
- **ETH**: requires active opt-in due to 60-day intro period and bonding risks

The `IsOptedIn` flag per client is determined from waiver tables (Fivetran Google Sheets + API-based waivers).

### 3.2 Liquidity Buffer Formula

```
Units_AvailableForStaking = LEAST(
    EligibleUnits * LiquidityBuffer,         -- raw liquidity cap
    OptedInUnits * (0.90 if ETH else 0.95)   -- recon safety margin
)
```

ETH gets a tighter 10% safety margin (vs 5% for others) due to its longer bonding/unbonding period on the Ethereum beacon chain.

### 3.3 Regulation Granularity

The regulation breakdown is critical because:
- Regulatory changes can suddenly exclude an entire jurisdiction (e.g., "FCA clients excluded for ATOM in Apr 2025")
- The Staking PM team monitors by regulation to understand the impact of regulatory changes on the available pool
- Some regulations have zero eligible clients for certain instruments (e.g., US clients excluded from non-US instruments)

### 3.4 Data Starts May 2024

Coverage begins May 2024 (not September 2023 like DailyPool). This was added to the SP in a later version — the detailed regulation/opt-in breakdown was added after the initial launch.

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_DailyPool` | Co-written by same SP — DailyPool is the aggregate, this table is the regulation breakdown |
| `Dealing_dbo.Dealing_Staking_OptedOut_PerCID` | Also co-written — per-client detail underlying this aggregate |
| `Dealing_dbo.Dealing_Staking_Parameters` | LiquidityBuffer source |

---

## 5. Notes & Caveats

- **Decimal client counts**: EligibleClients, OptedInClients, etc. are stored as DECIMAL(32,4) — they will always show .0000. This is a schema design quirk (count stored as decimal instead of int).
- **Not US-specific**: This table covers non-US clients. There is no US equivalent of Dealing_Staking_OptedOut.
- **Historical gap**: No data before May 2024. Prior to this, the regulation-level breakdown was not tracked.
