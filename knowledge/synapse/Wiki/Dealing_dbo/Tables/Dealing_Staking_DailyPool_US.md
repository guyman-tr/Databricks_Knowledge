# Dealing_dbo.Dealing_Staking_DailyPool_US

> US-market equivalent of Dealing_Staking_DailyPool — daily aggregate of total crypto units held by opted-in US-regulated staking clients. Covers ADA, SOL, ETH, and SUI. Daily from August 2025.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (analytical — daily fact) |
| **Production Source** | Derived — SP_Staking_DailyPool_US from BI_DB_dbo.BI_DB_PositionPnL (US clients only) |
| **Refresh** | Daily at 11:00 AM — SP_Staking_DailyPool_US (ProcessType 3 SQL&TIME) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Row Count** | 622 (as of Mar 2026) |
| **Date Range** | 2025-08-20 – 2026-03-10 |
| **Instruments** | 4 (ADA=100017, SOL=100063, ETH=100001, SUI=100340) |
| **Last Updated** | 2026-03-11 |

---

## 1. Business Meaning

US-market parallel to `Dealing_Staking_DailyPool`. Records the daily total crypto holdings in the US staking pool, used by `SP_Staking_US` to compute monthly staking rewards for US-regulated clients.

**Key differences from the non-US Dealing_Staking_DailyPool**:
- Only US-regulated clients (DWH_dbo.Dim_Customer.RegulationID IN (6, 7, 8))
- 4 instruments (ADA, SOL, ETH, SUI) vs 13 for non-US
- Started Aug 20, 2025 (pre-staking launch date to build 2-month history before first Oct 2025 distribution)
- COLUMNSTORE INDEX (vs row-store for non-US)
- Scheduled at 11:00 AM daily (ProcessType 3) vs event-driven for non-US

SUI appears here (4 US instruments) but not in the US compensation/club tables (which show only 3). This may reflect that SUI US staking is tracked daily but the first distribution hasn't occurred yet, or that SUI US compensation used different criteria.

---

## 2. Column Descriptions

Identical schema to `Dealing_Staking_DailyPool`. See that table's documentation for full column descriptions. US-specific notes:

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Calendar date. US data starts 2025-08-20. (Tier 3) |
| InstrumentID | int | Instrument ID. US-eligible: 100017 (ADA), 100063 (SOL), 100001 (ETH), 100340 (SUI). (Tier 3) |
| Currency | varchar(100) | Ticker. US values: ADA, SOL, ETH, SUI. No EUR pairs (USD-denominated US market only). (Tier 3) |
| DailyTotalStakingPool | decimal(30,2) | Sum of US client opted-in positions for this instrument/date. (Tier 3) |
| Avg_DailyTotalStakingPool | decimal(30,2) | Running average of US pool size. Used by SP_Staking_US. (Tier 3) |
| UpdateDate | datetime | SP_Staking_DailyPool_US execution timestamp. (Tier 4 — ETL metadata) |

---

## 3. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_DailyPool` | Non-US equivalent — wider currency scope, longer history |
| `Dealing_dbo.Dealing_Staking_Results_US` | Consumer — SP_Staking_US reads Avg_DailyTotalStakingPool for monthly reward calculation |
| `Dealing_dbo.Dealing_Staking_Parameters` | Shared configuration — IntroDays, LiquidityBuffer |

---

## 4. Notes & Caveats

- **SUI in US daily pool**: SUI (100340) appears in the daily pool but NOT in Dealing_Staking_Compensation_US or Dealing_Staking_Club_US. This suggests SUI US staking is tracked but distribution hasn't started yet (or SUI US compensation is 100% airdrop, never cash).
- **No EUR pairs for US**: Unlike non-US (which has ADAEUR, ETHEUR, SOLEUR), US instruments are base currency only — no EUR denomination.
- **Pre-launch tracking**: Data starts Aug 20, 2025 — 6 weeks before the first US staking distribution (Oct 2025). The intro period (7 days for ADA, 60 days for ETH) requires historical pool data to be present before rewards can be computed.
