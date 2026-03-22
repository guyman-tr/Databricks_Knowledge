# Dealing_dbo.Dealing_JP_Credit_Risk

## 1. Overview
Daily credit risk exposure report for stocks/ETFs hedged through JP Morgan. Calculates client vs LP net exposure per instrument per hedge server and models potential losses under 10 price-move scenarios (±15% to ±50%).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~6M |
| **Date Range** | 2021-02-01 → present |
| **Grain** | One row per Date × InstrumentID × HedgeServerID |
| **Refresh** | Daily, via SP_JP_Credit_Risk |

## 2. Business Context
JP Morgan is one of eToro's liquidity providers for CFD Stocks and ETFs. Unlike the GS variant (which hardcodes HS=101), this SP dynamically identifies JPM hedge servers from the `External_Fivetran_dealing_active_hs_mappings` table where `liquidity_provider LIKE '%JPM%'`. This table also includes a HedgeServerID column because JPM spans multiple hedge servers. The credit risk model is identical to the GS variant — effective leverage, buffer, and 10 scenario stress tests.

**Author**: Adar Cahlon (created 2021-03-03). SR-325735 (2025-08-04) added automated Fivetran HS lookup.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Business date for the risk snapshot | T2 | SP_JP_Credit_Risk: `@Date` parameter |
| InstrumentID | int | Yes | eToro instrument identifier | T2 | SP_JP_Credit_Risk: from Dim_Instrument |
| InstrumentType | varchar(20) | Yes | Asset class — Stocks or ETF (InstrumentTypeID IN 5,6) | T2 | SP_JP_Credit_Risk: `di.InstrumentType` |
| InstrumentName | varchar(max) | Yes | Internal instrument name | T2 | SP_JP_Credit_Risk: `di.Name` |
| InstrumentDisplayName | varchar(max) | Yes | Client-facing display name | T2 | SP_JP_Credit_Risk: `di.InstrumentDisplayName` |
| OPLong | money | Yes | Total client long position value (USD). Formula: `SUM(CASE WHEN IsBuy=1 THEN ABS(Clients_NOP) ELSE 0 END)` | T2 | SP_JP_Credit_Risk |
| EffLevLong | decimal(16,6) | Yes | Weighted-average effective leverage for longs. Formula: `SUM(ABS(NOP)*EffLev)/SUM(ABS(NOP))` | T2 | SP_JP_Credit_Risk |
| OPShort | money | Yes | Total client short position value (USD) | T2 | SP_JP_Credit_Risk |
| EffLevShort | decimal(16,6) | Yes | Weighted-average effective leverage for shorts | T2 | SP_JP_Credit_Risk |
| Clients_NOP | money | Yes | Net client open position (USD, signed) | T2 | SP_JP_Credit_Risk |
| LP_NOP | money | Yes | JP Morgan LP net open position (USD, signed). Uses `(2*IsBuy-1)` sign convention with multi-step FX conversion | T2 | SP_JP_Credit_Risk |
| NetExposure(Clients-LP) | money | Yes | Unhedged exposure gap. Formula: `Clients_NOP - LP_NOP`. Uses FULL OUTER JOIN to capture instruments with LP-only or client-only exposure | T2 | SP_JP_Credit_Risk |
| Buffer_Long | decimal(16,6) | Yes | Price-drop buffer for longs. Formula: `1/EffLevLong` (0 if EffLev=0) | T2 | SP_JP_Credit_Risk |
| Buffer_Short | decimal(16,6) | Yes | Price-rise buffer for shorts. Formula: `1/EffLevShort` | T2 | SP_JP_Credit_Risk |
| Scenario_1_-15% | money | Yes | Loss if price drops 15%. Formula: `CASE WHEN Buffer_Long>0.15 THEN 0 ELSE OPLong*(0.15-Buffer_Long) END` | T2 | SP_JP_Credit_Risk |
| Scenario_2_-20% | money | Yes | Loss if price drops 20% | T2 | SP_JP_Credit_Risk |
| Scenario_3_-25% | money | Yes | Loss if price drops 25% | T2 | SP_JP_Credit_Risk |
| Scenario_4_-30% | money | Yes | Loss if price drops 30% | T2 | SP_JP_Credit_Risk |
| Scenario_5_15% | money | Yes | Loss if price rises 15% (shorts) | T2 | SP_JP_Credit_Risk |
| Scenario_6_20% | money | Yes | Loss if price rises 20% (shorts) | T2 | SP_JP_Credit_Risk |
| Scenario_7_25% | money | Yes | Loss if price rises 25% (shorts) | T2 | SP_JP_Credit_Risk |
| Scenario_8_30% | money | Yes | Loss if price rises 30% (shorts) | T2 | SP_JP_Credit_Risk |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_JP_Credit_Risk: `GETDATE()` |
| Scenario_9_-50% | money | Yes | Loss if price drops 50% (added 2021-08-11) | T2 | SP_JP_Credit_Risk |
| Scenario_10_50% | money | Yes | Loss if price rises 50% (shorts) | T2 | SP_JP_Credit_Risk |
| HedgeServerID | int | Yes | JP Morgan hedge server identifier — dynamically resolved from Fivetran mapping | T2 | SP_JP_Credit_Risk: from `#Fivetran` temp table |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Dim_Instrument | Lookup | InstrumentID, InstrumentTypeID IN (5,6) |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Price source | InstrumentID, OccurredDateID |
| BI_DB_dbo.BI_DB_PositionPnL | Client positions | InstrumentID, DateID, IsSettled=0, HedgeServerID IN JPM set |
| DWH_dbo.Dim_Customer | Customer filter | RealCID, IsValidCustomer=1 |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | JPM HS lookup | liquidity_provider LIKE '%JPM%' |
| Dealing_staging.etoro_History_Netting_History | LP positions (historical SCD2) | HedgeServerID IN JPM set |
| Dealing_staging.etoro_Hedge_Netting | LP positions (current) | HedgeServerID IN JPM set |
| Dealing_dbo.Dealing_GS_Credit_Risk | Sibling table | Same pattern for Goldman Sachs (HS=101) |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_JP_Credit_Risk` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Key Differences from GS variant** | 1) Dynamic HS lookup from Fivetran mapping instead of hardcoded HS=101. 2) Has HedgeServerID column. 3) Uses FULL OUTER JOIN between client and LP data (GS uses inner). 4) Client positions filtered by `HedgeServerID IN (SELECT hs_dealing_desk FROM #Fivetran)`. |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Partitioning**: None

## 7. Known Gaps
- Fivetran mapping is date-versioned — uses latest `update_date <= @Date` with DENSE_RANK()
- If Fivetran sync fails, the SP may not find JPM hedge servers

## 8. Quality Score
**7.5/10** — Strong lineage from SP code. Key structural differences from GS variant documented. All scenario formulas traced.
