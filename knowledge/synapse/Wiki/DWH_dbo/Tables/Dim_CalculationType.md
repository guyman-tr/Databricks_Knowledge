# DWH_dbo.Dim_CalculationType

> Lookup of cost calculation methods used in the HistoryCosts domain — defines how trading costs (spreads, commissions, fees) are computed (e.g., fixed per unit, percentage of trade, pips per unit).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CalculationTypeId (int, CLUSTERED INDEX) |
| **Row Count** | 8 rows |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX on CalculationTypeId ASC |

---

## 1. Business Meaning

`Dim_CalculationType` is a small lookup table from the HistoryCosts domain that classifies how trading costs are calculated. Each row represents a different cost computation method used to determine trading fees, spreads, and commissions.

The eight calculation types cover the full spectrum of fee models:
- **Fixed methods**: `FixPerUnit` (per-unit flat fee), `FixPerTrade` (per-trade flat fee), `FixPerLot` (per-lot flat fee)
- **Percentage methods**: `PercentOfTrade` (% of trade value), `PercentOfMarketDataMarkup` (% of market data markup), `PercentOfFees` (% of total fees)
- **Rate-based**: `PipsPerUnit` (pip-based calculation per unit)
- **Special**: `Override` (manual/override calculation)

---

## 2. Business Logic

### 2.1 Cost Calculation Classification

**What**: Each CalculationTypeId maps to a formula used to compute a specific trading cost.

**Columns Involved**: `CalculationTypeId`, `CalculationType`

**Rules**:
- IDs 1–8 are sequential with no gaps
- The `CalculationType` string is a PascalCase identifier used programmatically

---

## 3. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | HistoryCosts database, `Dictionary.CalculationType` table |
| **Staging Table** | `DWH_staging.HistoryCosts_Dictionary_CalculationType` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 1 renamed (`Id` → `CalculationTypeId`), 1 passthrough (`CalculationType`), 1 ETL-generated (`UpdateDate`) |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | ROUND_ROBIN — unusual for a small dimension; consider REPLICATE for better JOIN performance |
| **Clustered Index** | CalculationTypeId ASC |
| **Typical JOINs** | `Fact_*.CalculationTypeId = Dim_CalculationType.CalculationTypeId` |

---

## 5. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CalculationTypeId | int | YES | Tier 2 | Primary identifier for the calculation method. Renamed from source `Id`. Sequential IDs 1–8. |
| 2 | CalculationType | nvarchar(max) | YES | Tier 2 | PascalCase name of the calculation method (e.g., "FixPerUnit", "PercentOfTrade"). Used programmatically and in reports. |
| 3 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — set to `GETDATE()` by SP_Dictionaries_DL_To_Synapse. |

---

## 6. Sample Data

| CalculationTypeId | CalculationType |
|-------------------|-----------------|
| 1 | FixPerUnit |
| 2 | PipsPerUnit |
| 3 | FixPerTrade |
| 4 | PercentOfTrade |
| 5 | PercentOfMarketDataMarkup |
| 6 | PercentOfFees |
| 7 | Override |
| 8 | FixPerLot |

---

*Generated: 2026-03-18 | Quality: 7.5/10 (Elements: 7/10, Logic: 8/10, Relationships: 6/10, Sources: 7/10)*
*Confidence: 0 Tier 1, 3 Tier 2, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,9b,11*
*Upstream Wiki: None available for HistoryCosts.Dictionary.CalculationType*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CalculationType.sql*
