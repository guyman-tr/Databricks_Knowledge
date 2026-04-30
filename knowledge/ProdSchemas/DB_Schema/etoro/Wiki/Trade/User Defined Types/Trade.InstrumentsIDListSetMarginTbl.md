# Trade.InstrumentsIDListSetMarginTbl

> TVP for bulk updates of initial and stop-loss margin amounts per instrument (futures and ops API).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries InstrumentID plus InitialMarginInAssetCurrency and StopLossMarginInAssetCurrency for each instrument. It models margin requirements in asset currency for both initial position opening and stop-loss collateral.

The type exists to support bulk margin configuration for futures and other instruments. Trade.SetInstrumentMarginsForFutures and Trade.UpdateFuturesTradingConfigurations accept it to set margin amounts that drive margin calculations and risk checks.

Services or ops tools build the table, pass it as READONLY, and the procedures JOIN it against instrument/margin config tables to apply the new values.

---

## 2. Business Logic

InstrumentID + InitialMarginInAssetCurrency + StopLossMarginInAssetCurrency triplets for bulk instrument margin configuration. dtPrice is a custom scalar type alias (likely decimal) for price/margin values.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the margin config. |
| 2 | InitialMarginInAssetCurrency | dbo.dtPrice | YES | - | CODE-BACKED | Initial margin required in asset currency when opening a position. Underlying type likely decimal. |
| 3 | StopLossMarginInAssetCurrency | dbo.dtPrice | YES | - | CODE-BACKED | Additional margin reserved for stop-loss in asset currency. Underlying type likely decimal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetInstrumentMarginsForFutures | @Instruments_NewMargin | Parameter (TVP) | Sets initial and stop-loss margins for futures instruments. |
| Trade.UpdateFuturesTradingConfigurations | @Instruments_NewMargin | Parameter (TVP) | Bulk-updates margin amounts as part of futures trading config. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

Uses dbo.dtPrice (scalar type alias). No table dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetInstrumentMarginsForFutures | Stored Procedure | READONLY parameter for futures margin updates |
| Trade.UpdateFuturesTradingConfigurations | Stored Procedure | READONLY parameter for futures config updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to SetInstrumentMarginsForFutures
```sql
DECLARE @Margin Trade.InstrumentsIDListSetMarginTbl;
INSERT INTO @Margin (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
VALUES (12345, 1000.00, 500.00), (12346, 2000.00, 1000.00);
EXEC Trade.SetInstrumentMarginsForFutures @Instruments_NewMargin = @Margin;
```

### 8.2 Pass to UpdateFuturesTradingConfigurations
```sql
DECLARE @Margin Trade.InstrumentsIDListSetMarginTbl;
INSERT INTO @Margin (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
SELECT InstrumentID, 1500.00, 750.00 FROM Trade.Instrument WHERE Symbol LIKE 'ES%';
EXEC Trade.UpdateFuturesTradingConfigurations @Instruments_NewMargin = @Margin, ...;
```

### 8.3 Partial update (one margin null)
```sql
DECLARE @Margin Trade.InstrumentsIDListSetMarginTbl;
INSERT INTO @Margin (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
VALUES (99999, 3000.00, NULL);
EXEC Trade.SetInstrumentMarginsForFutures @Instruments_NewMargin = @Margin;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsIDListSetMarginTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsIDListSetMarginTbl.sql*
