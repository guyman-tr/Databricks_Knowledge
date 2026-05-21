# DWH_dbo.Fact_History_Cost

> Granular record of every cost (fee, commission, spread cost, overnight fee) charged on trading operations — capturing the cost value in both account and asset currencies, the calculation method, and links to the position/order/credit that triggered it.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact — transactional) |
| **Row Count** | Hundreds of millions (one row per cost event) |
| **Production Source** | `HistoryCosts.History.Costs` via `DWH_staging.HistoryCosts_History_Costs` |
| **Refresh** | Daily — DELETE for date + INSERT from staging |
| | |
| **Synapse Distribution** | HASH(CostID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Synapse PK** | (DateID, CostID, CID) NOT ENFORCED |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Fact_History_Cost` is the cost/fee ledger for the eToro trading platform. Every time a cost is incurred on a trading operation — spreads, overnight fees (swap fees), commissions, currency conversion costs — a row is recorded here. The table provides the financial backbone for:

- **Revenue analysis** — understanding fee revenue by cost type, instrument, customer
- **Cost attribution** — linking costs to specific positions, orders, or credit events
- **Multi-currency tracking** — costs stored in both account currency and asset currency with the conversion rate
- **Cost configuration auditing** — tracking which cost configuration rule was applied and how it was calculated

### Key Business Concepts

- **CostType vs CostSubType**: CostTypeID classifies the high-level category (e.g., spread, overnight, commission). CostSubTypeID provides finer granularity (e.g., overnight buy vs. overnight sell)
- **ValueInAccountCurrency vs ValueInAssetCurrency**: Same cost expressed in two currencies — the customer's account currency and the underlying asset's currency
- **IsIncludedInTransactionValue**: Whether the cost was embedded in the transaction price (e.g., spread) or charged separately (e.g., commission)
- **CalculationTypeID**: How the cost was computed (e.g., flat fee, percentage, per-unit)

Created: 2025-05-15 by Daniel Kaplan.

---

## 2. Business Logic

### 2.1 ETL Pattern — Simple Staging Import

**Pattern**: TRUNCATE ext → INSERT from staging → DELETE fact for date → INSERT from ext

```
SP_Fact_History_Cost_DL_To_Synapse(@dt):
  1. TRUNCATE Ext_History_Cost
  2. INSERT INTO Ext_History_Cost SELECT * FROM DWH_staging.HistoryCosts_History_Costs
     + DateID = CONVERT(INT, Occurred in YYYYMMDD)
     + UpdateDate = GETDATE()
  3. EXEC SP_Fact_History_Cost @dt
     → DELETE from Fact_History_Cost WHERE DateID = @dateID
     → INSERT from Ext_History_Cost
```

No transformations beyond DateID computation and UpdateDate stamping. All columns pass through from staging.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CostID) distributes data by the unique cost identifier. CLUSTERED COLUMNSTORE INDEX provides excellent compression for analytical scans. Filter on DateID for date-range queries. JOINs on CID require data movement — consider pre-aggregating.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily cost revenue by type | `GROUP BY DateID, CostTypeID` |
| Costs for a specific position | `WHERE PositionID = @posId AND DateID BETWEEN @from AND @to` |
| Customer total fees | `WHERE CID = @cid GROUP BY CostTypeID` |
| Overnight fee totals | `WHERE CostTypeID = @overnightType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer details |
| DWH_dbo.Dim_CostType | ON CostTypeID = CostTypeID | Cost type name |
| DWH_dbo.Dim_CostSubtype | ON CostSubTypeID = CostSubTypeID | Cost subtype name |
| DWH_dbo.Dim_CostConfigurationId | ON CostConfigurationID = CostConfigurationID | Configuration details |
| DWH_dbo.Dim_CalculationType | ON CalculationTypeID = CalculationTypeID | Calculation method |
| DWH_dbo.Dim_Currency | ON CostCurrencyID / BalanceCurrencyID / AssetCurrencyID = CurrencyID | Currency names |
| DWH_dbo.Dim_Instrument | ON PositionID → Fact_Position → InstrumentID | Instrument (indirect) |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes |

### 3.4 Gotchas

- **decimal(38,18)**: Financial values have extreme precision — be careful with aggregation overflow
- **CostID distribution**: HASH on CostID — JOINs on CID or PositionID will cause data movement
- **PartitionCol**: Purpose not evident from SP code — likely an application-level partitioning field
- **No WHERE filter on staging**: The DL_To_Synapse SP imports ALL rows from staging (the commented-out `WHERE [Timestamp] = @Yesterday` suggests a planned but not implemented date filter)

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CostID | bigint | NO | Unique identifier for this cost event. Distribution key. PK component. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 2 | CID | int | NO | Customer ID (Real account) who was charged this cost. PK component. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 3 | PartitionCol | int | YES | Application-level partition column from source system. (Tier 4 — inferred from staging passthrough) |
| 4 | MirrorID | int | YES | Copy trading mirror relationship ID if cost is related to a copy trade. NULL if direct trade. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 5 | CostConfigurationID | bigint | YES | Reference to the cost configuration rule that generated this charge. JOINs to Dim_CostConfigurationId. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 6 | ValueInAccountCurrency | decimal(38,18) | YES | Cost amount in the customer's account currency. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 7 | ValueInAssetCurrency | decimal(38,18) | YES | Cost amount in the underlying asset's currency. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 8 | ConversionRate | decimal(38,18) | YES | Exchange rate used to convert between asset currency and account currency. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 9 | CalculationTypeID | int | YES | Method used to compute the cost (e.g., flat, percentage, per-unit). JOINs to Dim_CalculationType. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 10 | CostConfigValue | decimal(38,18) | YES | Configuration parameter value used in the cost calculation (e.g., fee percentage, flat fee amount). (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 11 | IsIncludedInTransactionValue | bit | YES | Whether the cost was embedded in the transaction price (1=included, e.g., spread) or charged separately (0=standalone, e.g., commission). (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 12 | TransactionUnits | decimal(38,18) | YES | Number of units (shares, lots) involved in the transaction that triggered this cost. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 13 | CostCurrencyID | int | YES | Currency in which the cost was originally calculated. JOINs to Dim_Currency. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 14 | BalanceCurrencyID | int | YES | Customer's account balance currency. JOINs to Dim_Currency. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 15 | AssetCurrencyID | int | YES | Currency of the underlying asset. JOINs to Dim_Currency. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 16 | ActionTypeID | int | YES | Type of customer action that triggered this cost. JOINs to Dim_ActionType. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 17 | OperationTypeID | int | YES | Operation type within the action. JOINs to Dim_ExecutionOperationType. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 18 | CostTypeID | int | YES | High-level cost category (spread, overnight, commission). JOINs to Dim_CostType. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 19 | CostSubTypeID | int | YES | Detailed cost sub-category. JOINs to Dim_CostSubtype. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 20 | PositionID | bigint | YES | Position that generated this cost. JOINs to Fact_Position. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 21 | OrderID | bigint | YES | Order that generated this cost. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 22 | CreditID | bigint | YES | Credit/bonus event that generated this cost. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 23 | Occurred | datetime2(7) | YES | Timestamp when the cost event occurred. Business event time. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) |
| 24 | DateID | int | NO | Date of the cost event in YYYYMMDD integer format. Computed as CONVERT(INT, CONVERT(VARCHAR(10), Occurred, 112)). PK component. (Tier 2 — SP_Fact_History_Cost_DL_To_Synapse) |
| 25 | UpdateDate | datetime | NO | ETL load timestamp — GETDATE() during SP execution. (Tier 2 — SP_Fact_History_Cost) |

---

## 5. Lineage

### 5.1 Pipeline

```
HistoryCosts.History.Costs (production)
    → Data Lake
    → DWH_staging.HistoryCosts_History_Costs
    → SP_Fact_History_Cost_DL_To_Synapse
        → Ext_History_Cost (staging)
        → SP_Fact_History_Cost
            → Fact_History_Cost
```

All columns are passthrough from staging. Only DateID (computed from Occurred) and UpdateDate (GETDATE()) are DWH-added.

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer charged |
| CostConfigurationID | DWH_dbo.Dim_CostConfigurationId | Cost config rule |
| CostTypeID | DWH_dbo.Dim_CostType | Cost category |
| CostSubTypeID | DWH_dbo.Dim_CostSubtype | Cost subcategory |
| CalculationTypeID | DWH_dbo.Dim_CalculationType | Calculation method |
| CostCurrencyID, BalanceCurrencyID, AssetCurrencyID | DWH_dbo.Dim_Currency | Currencies |
| ActionTypeID | DWH_dbo.Dim_ActionType | Action type |
| OperationTypeID | DWH_dbo.Dim_ExecutionOperationType | Operation type |
| PositionID | DWH_dbo.Fact_Position | Related position |
| DateID | DWH_dbo.Dim_Date | Calendar date |

---

## 7. Sample Queries

### 7.1 Daily cost revenue by type

```sql
SELECT
    f.DateID,
    ct.CostTypeName,
    SUM(f.ValueInAccountCurrency) AS TotalCostValue,
    COUNT(*) AS CostCount
FROM DWH_dbo.Fact_History_Cost f
JOIN DWH_dbo.Dim_CostType ct ON f.CostTypeID = ct.CostTypeID
WHERE f.DateID >= 20260301
GROUP BY f.DateID, ct.CostTypeName
ORDER BY f.DateID DESC, TotalCostValue DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [DWH Daily Process Delayed (HistoryCosts.History.Costs) - 2025-07-16](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13279526914/DWH+Daily+Process+Delayed+HistoryCosts.History.Costs+-+2025-07-16) | Confluence | Incident note: DWH daily process tied to `HistoryCosts/History/Costs` feed — operational context for this fact’s upstream pipeline. |
| [Pips Calculation GP](https://etoro-jira.atlassian.net/wiki/spaces/FC/pages/12000297122/Pips+Calculation+GP) | Confluence | Finance doc: PIP-in-USD style calculations across deposits, chargebacks, refunds, cashouts — aligns with cost/fee ledger use cases. |

---

*Generated: 2026-03-19 | Quality: 7.2/10 (★★★☆☆) | Phases: 6/14 (P2,P3 skipped, new table with limited context)*
*Tiers: 0 T1, 24 T2, 0 T3, 1 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10*
*Object: DWH_dbo.Fact_History_Cost | Type: Table | Production Source: HistoryCosts.History.Costs*
