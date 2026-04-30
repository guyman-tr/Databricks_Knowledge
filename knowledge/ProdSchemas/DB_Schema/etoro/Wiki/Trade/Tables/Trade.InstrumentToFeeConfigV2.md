# Trade.InstrumentToFeeConfigV2

> Version 2 of instrument-to-fee mapping with SettlementTypeID and FeeCalculationTypeID; system-versioned. Primary source for overnight and weekend fee rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID, SettlementTypeID (composite PK) |
| **Partition** | None; on PRIMARY |
| **Indexes** | 2 (PK clustered, IX_SettlementTypeID) |

---

## 1. Business Meaning

**WHAT**: Trade.InstrumentToFeeConfigV2 maps each (InstrumentID, SettlementTypeID) pair to percentage-based overnight and weekend fee rates. Each row holds eight fee percentages: NonLeveraged vs Leveraged, Buy vs Sell, OverNight vs EndOfWeek. SettlementTypeID distinguishes CFD (0), REAL (1), TRS (2), CMT (3), REAL_FUTURES (4), MARGIN_TRADE (5). FeeCalculationTypeID selects ExposureFormula (0, $/unit) or LoanFormula (1, daily interest %).

**WHY**: Different settlement types have different fee structures. CFD positions charge overnight/weekend fees; real stock positions may have different rates. The legacy Trade.InstrumentToFeeConfig had one row per instrument; V2 adds SettlementTypeID so the same instrument can have different rates for CFD vs real vs futures. Trade.GetPositionsForFeeProcess and Trade.CalculatePositionOvernightFee use this table.

**HOW**: Trade.UpdateInstrumentToFeeConfigTableV2 and Trade.UpdateInstrumentToFeeConfigurations_TRDOPS MERGE rows from TVPs. Trade.CalcOverNightFeeRates, Trade.SplitHoldingFees, Trade.InsertInstrumentRealTable, Trade.CheckValidInstruments populate or update configs. The table is system-versioned; History.InstrumentToFeeConfigV2 preserves prior versions. Trade.RolloverFeesAlertIfNeeded compares current vs previous values for alerts.

---

## 2. Business Logic

### 2.1 Fee Rate Layout

Columns: NonLeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee, NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee; LeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee, LeveragedSellOverNightFee. Values are percentages or $/unit per FeeCalculationTypeID. Leverage=1 uses NonLeveraged*; Leverage>1 uses Leveraged*.

### 2.2 Settlement Type Scope

SettlementTypeID from Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. GetPositionsForFeeProcess joins on TPOS.SettlementTypeID = TITFC.SettlementTypeID.

### 2.3 Fee Calculation Type

FeeCalculationTypeID: 0=ExposureFormula ($/unit), 1=LoanFormula (daily interest %). Trade.CalculatePositionOvernightFee receives these values and applies the appropriate formula.

---

## 3. Data Overview

| InstrumentID | SettlementTypeID | FeeCalculationTypeID | NonLeveragedBuyOverNightFee | LeveragedBuyOverNightFee | Occurred |
|--------------|------------------|----------------------|-----------------------------|--------------------------|----------|
| 1 | 0 | 0 | 0 | 0.0720194 | 2026-02-24 11:05 |
| 1 | 1 | 0 | 0.01012 | 0.074666 | 2026-03-12 14:49 |
| 2 | 0 | 0 | 0.00006468 | -1 | 2026-02-03 10:48 |
| 3 | 0 | 0 | 0.00004894 | 0.00004894 | 2026-01-27 12:18 |
| 4 | 0 | 0 | -0.00001358 | -0.00001358 | 2026-02-24 10:05 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | PK; FK to Trade.Instrument. |
| 2 | SettlementTypeID | tinyint | NO | 0 | VERIFIED | 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. |
| 3 | FeeCalculationTypeID | tinyint | NO | 0 | VERIFIED | 0=ExposureFormula, 1=LoanFormula. |
| 4 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee for non-leveraged sell. |
| 5 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee for non-leveraged buy. |
| 6 | NonLeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for non-leveraged buy. |
| 7 | NonLeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for non-leveraged sell. |
| 8 | LeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee for leveraged sell. |
| 9 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee for leveraged buy. |
| 10 | LeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for leveraged buy. |
| 11 | LeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for leveraged sell. |
| 12 | Occurred | datetime | NO | - | VERIFIED | When config was last changed. |
| 13 | UpdatedByUser | varchar(50) | YES | - | CODE-BACKED | User/system that updated. |
| 14 | BeginTime | datetime2(7) | NO | (generated) | VERIFIED | Temporal row start. |
| 15 | EndTime | datetime2(7) | NO | (generated) | VERIFIED | Temporal row end. |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Key | Relationship |
|------------------|-----|--------------|
| Trade.Instrument | InstrumentID | Instrument mapping |
| Dictionary.SettlementTypes | SettlementTypeID | Settlement type |

### 5.2 Referenced By

| Object | Usage |
|--------|-------|
| Trade.GetPositionsForFeeProcess | JOIN for fee rates |
| Trade.GetPositionsForFeeBulkGeneral_Aus | JOIN |
| Trade.UpdateInstrumentToFeeConfigTableV2 | MERGE target |
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | MERGE target |
| Trade.GetInstrumentToFeeConfiguration | SELECT |
| Trade.GetCalculatedFeesConfig_TRDOPS | SELECT |
| Trade.CalcOverNightFeeRates | Update |
| Trade.SplitHoldingFees | Read and update |
| Trade.InsertInstrumentRealTable | INSERT |
| Trade.CheckValidInstruments | Existence check; copy from |
| Trade.RolloverFeesAlertIfNeeded | Compare current vs prev |
| Trade.InstrumentToFeeConfig (view) | Source for legacy shape |
| History.InstrumentToFeeConfigV2 | Temporal history |

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.Instrument, Dictionary.SettlementTypes -> Trade.InstrumentToFeeConfigV2
Trade.InstrumentToFeeConfigV2 -> Trade.GetPositionsForFeeProcess, Trade.CalculatePositionOvernightFee

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Trade.Instrument | Table | InstrumentID |
| Dictionary.SettlementTypes | Table | SettlementTypeID (implicit) |
| Dictionary.FeeCalculationTypes | Table | FeeCalculationTypeID (implicit) |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.GetPositionsForFeeProcess | Procedure | Fee rates for overnight/weekend |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Procedure | Update |
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | Procedure | Bulk update |
| Trade.GetInstrumentToFeeConfiguration | Procedure | Read |
| History.InstrumentToFeeConfigV2 | Table | Temporal history |

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Key Columns | Purpose |
|-----|------|-------------|---------|
| PK_InstrumentToFeeConfigV2 | Clustered PK | InstrumentID, SettlementTypeID | Primary key |
| IX_InstrumentToFeeConfigV2_SettlementTypeID | Nonclustered | SettlementTypeID | Lookup by settlement type |

### 7.2 Constraints

| Name | Type | Definition |
|-----|------|------------|
| PK_InstrumentToFeeConfigV2 | PRIMARY KEY | InstrumentID, SettlementTypeID |
| DF SettlementTypeID | DEFAULT | 0 |
| DF FeeCalculationTypeID | DEFAULT | 0 |
| SYSTEM_VERSIONING | - | History.InstrumentToFeeConfigV2 |

---

## 8. Sample Queries

```sql
-- Config for instrument and settlement type
SELECT InstrumentID, SettlementTypeID, FeeCalculationTypeID,
       NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee
FROM Trade.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE InstrumentID = 1 AND SettlementTypeID = 0;

-- Distribution by SettlementTypeID
SELECT SettlementTypeID, FeeCalculationTypeID, COUNT(*) AS Cnt
FROM Trade.InstrumentToFeeConfigV2 WITH (NOLOCK)
GROUP BY SettlementTypeID, FeeCalculationTypeID;

-- Temporal history for an instrument
SELECT InstrumentID, SettlementTypeID, NonLeveragedBuyOverNightFee,
       Occurred, BeginTime, EndTime
FROM History.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY BeginTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.9/10 | Sources: DDL, MCP live data, Trade.UpdateInstrumentToFeeConfigTableV2, Trade.GetPositionsForFeeProcess, Dictionary.FeeCalculationTypes*
