# Trade.InstrumentToFeeConfigType

> TVP type for bulk updates of overnight and end-of-week fee rates per instrument (leveraged vs non-leveraged, buy vs sell).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries fee configuration per instrument: overnight (swap) and end-of-week fees for leveraged and non-leveraged positions, and buy vs sell. It models the domain concept of "what the platform charges for holding positions open" by direction and leverage type.

The type exists to support Trade.UpdateInstrumentToFeeConfigTable, which persists fee rates. Admin or config services populate the TVP and pass it to the procedure when fee schedules change.

Services populate the TVP with InstrumentID and the eight fee columns (plus NonLeveragedBuyCFDOverNightFee), pass it to the procedure, and the procedure applies updates to the instrument-fee configuration table.

---

## 2. Business Logic

InstrumentID + fee column group pattern. Each row represents one instrument with its fee rates: end-of-week and overnight fees for leveraged/non-leveraged buy/sell, plus non-leveraged CFD overnight. The procedure applies these in bulk to the instrument fee config table.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier; references Trade.Instrument |
| 2 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for non-leveraged sell |
| 3 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for non-leveraged buy |
| 4 | NonLeveragedBuyOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee for non-leveraged buy |
| 5 | NonLeveragedSellOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee for non-leveraged sell |
| 6 | LeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for leveraged sell |
| 7 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for leveraged buy |
| 8 | LeveragedBuyOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee for leveraged buy |
| 9 | LeveragedSellOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee for leveraged sell |
| 10 | NonLeveragedBuyCFDOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | CFD overnight fee for non-leveraged buy |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentToFeeConfigTable | @FeeValuesTbl | Parameter (TVP) | Bulk update of instrument fee configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentToFeeConfigTable | Stored Procedure | READONLY parameter for fee config updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to update procedure
```sql
DECLARE @Fee Trade.InstrumentToFeeConfigType;
INSERT INTO @Fee (InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee, 
    NonLeveragedSellOverNightFee, LeveragedSellOverNightFee,
    NonLeveragedBuyEndOfWeekFee, LeveragedBuyEndOfWeekFee,
    NonLeveragedSellEndOfWeekFee, LeveragedSellEndOfWeekFee, NonLeveragedBuyCFDOverNightFee)
VALUES (12345, 0.0001, 0.0002, 0.0001, 0.0002, 0.0003, 0.0004, 0.0003, 0.0004, 0.0001);
EXEC Trade.UpdateInstrumentToFeeConfigTable @FeeValuesTbl = @Fee;
```

### 8.2 Bulk fee update from table
```sql
DECLARE @Fee Trade.InstrumentToFeeConfigType;
INSERT INTO @Fee
SELECT InstrumentID, 0.0001, 0.0001, 0.0001, 0.0001, 0.0002, 0.0002, 0.0002, 0.0002, 0.0001
FROM Trade.Instrument WHERE IndustryID = 1;
EXEC Trade.UpdateInstrumentToFeeConfigTable @FeeValuesTbl = @Fee;
```

### 8.3 Single instrument fee change
```sql
DECLARE @Fee Trade.InstrumentToFeeConfigType;
INSERT INTO @Fee VALUES (999, 0.0001, 0.0001, 0.00005, 0.00005, 0.0002, 0.0002, 0.0001, 0.0001, 0.00005);
EXEC Trade.UpdateInstrumentToFeeConfigTable @FeeValuesTbl = @Fee;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentToFeeConfigType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentToFeeConfigType.sql*
