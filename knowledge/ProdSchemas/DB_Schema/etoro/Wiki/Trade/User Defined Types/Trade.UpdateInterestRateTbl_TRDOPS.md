# Trade.UpdateInterestRateTbl_TRDOPS

> TRDOPS variant TVP for bulk updates of base interest rates with settlement type and overnight fee pattern - used in Trade operations layer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentTypeID (int), InterestRateID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UpdateInterestRateTbl_TRDOPS extends UpdateInterestRateTbl with SettlementTypeID and OverNightFeePatternID. It carries the same interest rate data (InstrumentTypeID, InterestRateID, InterestRateBuy/Sell, MarkupBuy/Sell) plus settlement type and overnight fee pattern for the TRDOPS (Trade Operations) layer.

This type exists to support interest rate updates where settlement type and overnight fee pattern must be specified. The _TRDOPS suffix indicates it is used by trade operations procedures with extended attributes.

The type flows from config services into Trade.UpdateInterestRates_TRDOPS. The procedure merges TVP rows into the interest rate tables with settlement type and fee pattern handling.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Same as UpdateInterestRateTbl plus SettlementTypeID and OverNightFeePatternID for TRDOPS-specific scope.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | CODE-BACKED | Instrument type identifier |
| 2 | InterestRateID | int | NO | - | CODE-BACKED | Interest rate record identifier |
| 3 | InterestRateBuy | decimal(16,8) | NO | - | CODE-BACKED | Buy-side interest rate |
| 4 | InterestRateSell | decimal(16,8) | NO | - | CODE-BACKED | Sell-side interest rate |
| 5 | MarkupBuy | decimal(16,8) | NO | - | CODE-BACKED | Buy-side markup |
| 6 | MarkupSell | decimal(16,8) | NO | - | CODE-BACKED | Sell-side markup |
| 7 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | Settlement type identifier |
| 8 | OverNightFeePatternID | tinyint | NO | - | CODE-BACKED | Overnight fee pattern identifier |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentTypeID, InterestRateID, SettlementTypeID, OverNightFeePatternID semantically reference domain tables but no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInterestRates_TRDOPS | @UpdateInterestRateTbl | Parameter (TVP) | Bulk update of base interest rates with settlement/fee pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInterestRates_TRDOPS | Stored Procedure | READONLY parameter for bulk interest rate updates (TRDOPS) |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk update with settlement and fee pattern
```sql
DECLARE @UpdateInterestRateTbl Trade.UpdateInterestRateTbl_TRDOPS;
INSERT INTO @UpdateInterestRateTbl (InstrumentTypeID, InterestRateID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, SettlementTypeID, OverNightFeePatternID)
VALUES (1, 10, 0.05, 0.05, 0.01, 0.01, 1, 1);
EXEC Trade.UpdateInterestRates_TRDOPS @UpdateInterestRateTbl = @UpdateInterestRateTbl;
```

### 8.2 Multi-row batch
```sql
DECLARE @UpdateInterestRateTbl Trade.UpdateInterestRateTbl_TRDOPS;
INSERT INTO @UpdateInterestRateTbl (InstrumentTypeID, InterestRateID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, SettlementTypeID, OverNightFeePatternID)
VALUES (1, 10, 0.05, 0.05, 0.01, 0.01, 1, 1),
       (2, 20, 0.04, 0.04, 0.015, 0.015, 1, 2);
EXEC Trade.UpdateInterestRates_TRDOPS @UpdateInterestRateTbl = @UpdateInterestRateTbl;
```

### 8.3 Build from existing rates
```sql
DECLARE @UpdateInterestRateTbl Trade.UpdateInterestRateTbl_TRDOPS;
INSERT INTO @UpdateInterestRateTbl (InstrumentTypeID, InterestRateID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, SettlementTypeID, OverNightFeePatternID)
SELECT InstrumentTypeID, InterestRateID, 0.05, 0.05, 0.01, 0.01, 1, 1 FROM Trade.InterestRate WHERE InterestRateID < 50;
EXEC Trade.UpdateInterestRates_TRDOPS @UpdateInterestRateTbl = @UpdateInterestRateTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRateTbl_TRDOPS | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UpdateInterestRateTbl_TRDOPS.sql*
