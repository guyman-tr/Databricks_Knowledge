# Trade.FeeUpdateList

> TVP for bulk-updating overnight fee charges per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FeeUpdateList is a table-valued parameter used to bulk-update overnight fee charges stored in Trade.ProviderToInstrument. Each row represents one instrument and its associated BuyCharge (overnight fee for long positions) and SellCharge (overnight fee for short positions). The type is consumed by Trade.UpdateProviderToInstrumentOverNightFee via the parameter @instrumetFeeUpdtaeList (typo in procedure parameter name).

This TVP enables batch updates of provider-to-instrument fee data, typically after fee schedule changes or overnight rate adjustments. InstrumentID references Trade.Instrument and identifies which instrument's fees are being modified. NULL in BuyCharge or SellCharge may indicate no change or a cleared value depending on procedure logic.

---

## 2. Business Logic

### 2.1 Overnight Fee Assignment
**What**: Associates overnight fee amounts with instruments for long (BuyCharge) and short (SellCharge) positions.
**Columns/Parameters Involved**: InstrumentID, BuyCharge, SellCharge.
**Rules**: InstrumentID must reference Trade.Instrument. BuyCharge and SellCharge are money amounts; NULL allowed per column definition. Used to update Trade.ProviderToInstrument fee columns.

---

## 3. Data Overview
N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements
| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | High | Instrument; references Trade.Instrument |
| 2 | BuyCharge | money | NULL | - | High | Overnight fee for long positions |
| 3 | SellCharge | money | NULL | - | High | Overnight fee for short positions |

---

## 5. Relationships
### 5.1 References To
Trade.Instrument, Trade.ProviderToInstrument
### 5.2 Referenced By
Trade.UpdateProviderToInstrumentOverNightFee (parameter @instrumetFeeUpdtaeList)

---

## 6. Dependencies
### 6.0 Dependency Chain
This object has no dependencies.
### 6.1 Objects This Depends On
No dependencies.
### 6.2 Objects That Depend On This
Trade.UpdateProviderToInstrumentOverNightFee

---

## 7. Technical Details
### 7.1 Indexes
None.
### 7.2 Constraints
None.

---

## 8. Sample Queries
### 8.1 Update Single Instrument Overnight Fees
```sql
DECLARE @instrumetFeeUpdtaeList Trade.FeeUpdateList;
INSERT INTO @instrumetFeeUpdtaeList (InstrumentID, BuyCharge, SellCharge)
VALUES (5001, 0.50, -0.25);
EXEC Trade.UpdateProviderToInstrumentOverNightFee @instrumetFeeUpdtaeList = @instrumetFeeUpdtaeList;
```
### 8.2 Batch Update from Source Data
```sql
DECLARE @instrumetFeeUpdtaeList Trade.FeeUpdateList;
INSERT INTO @instrumetFeeUpdtaeList (InstrumentID, BuyCharge, SellCharge)
SELECT InstrumentID, NewBuyFee, NewSellFee FROM #OvernightFeeSchedule;
EXEC Trade.UpdateProviderToInstrumentOverNightFee @instrumetFeeUpdtaeList = @instrumetFeeUpdtaeList;
```
### 8.3 Update Buy-Only Fee
```sql
DECLARE @instrumetFeeUpdtaeList Trade.FeeUpdateList;
INSERT INTO @instrumetFeeUpdtaeList (InstrumentID, BuyCharge)
VALUES (5002, 1.00);
EXEC Trade.UpdateProviderToInstrumentOverNightFee @instrumetFeeUpdtaeList = @instrumetFeeUpdtaeList;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FeeUpdateList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FeeUpdateList.sql*
