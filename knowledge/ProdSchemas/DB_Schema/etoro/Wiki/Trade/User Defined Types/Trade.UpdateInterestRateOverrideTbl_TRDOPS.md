# Trade.UpdateInterestRateOverrideTbl_TRDOPS

> TRDOPS variant TVP for bulk updates of interest rate overrides with settlement type and overnight fee pattern - used in Trade operations layer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InterestRateOverrideID (int), InstrumentID (int), ExchangeID (int), InstrumentTypeID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UpdateInterestRateOverrideTbl_TRDOPS extends UpdateInterestRateOverrideTbl with OverNightFeePatternID and SettlementTypeID. It carries the same interest rate override data (InterestRateBuy/Sell, MarkupBuy/Sell) plus settlement and overnight fee pattern identifiers for the TRDOPS (Trade Operations) layer.

This type exists to support interest rate override updates where settlement type and overnight fee pattern must be specified. The _TRDOPS suffix indicates it is used by trade operations procedures with extended attributes.

The type flows from config services into Trade.UpdateInterestRateOverride_TRDOPS. The procedure merges TVP rows into the interest rate override tables with settlement type and fee pattern handling.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Same as UpdateInterestRateOverrideTbl plus SettlementTypeID and OverNightFeePatternID for TRDOPS-specific scope.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateOverrideID | int | YES | - | CODE-BACKED | Override record ID for updates; NULL for inserts |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Instrument scope |
| 3 | ExchangeID | int | YES | - | CODE-BACKED | Exchange scope |
| 4 | InstrumentTypeID | int | YES | - | CODE-BACKED | Instrument type scope |
| 5 | InterestRateBuy | decimal(18,8) | NO | - | CODE-BACKED | Buy-side interest rate |
| 6 | InterestRateSell | decimal(18,8) | NO | - | CODE-BACKED | Sell-side interest rate |
| 7 | MarkupBuy | decimal(18,8) | NO | - | CODE-BACKED | Buy-side markup |
| 8 | MarkupSell | decimal(18,8) | NO | - | CODE-BACKED | Sell-side markup |
| 9 | OverNightFeePatternID | tinyint | YES | - | CODE-BACKED | Overnight fee pattern identifier |
| 10 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | Settlement type identifier |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID, ExchangeID, InstrumentTypeID, OverNightFeePatternID, SettlementTypeID semantically reference domain tables but no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInterestRateOverride_TRDOPS | @UpdateInterestRateOverrideTbl | Parameter (TVP) | Bulk upsert of interest rate overrides with settlement/fee pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInterestRateOverride_TRDOPS | Stored Procedure | READONLY parameter for bulk interest rate override updates (TRDOPS) |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk insert with settlement type and fee pattern
```sql
DECLARE @UpdateInterestRateOverrideTbl Trade.UpdateInterestRateOverrideTbl_TRDOPS;
INSERT INTO @UpdateInterestRateOverrideTbl (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, OverNightFeePatternID, SettlementTypeID)
VALUES (NULL, NULL, NULL, 1, 0.05, 0.05, 0.01, 0.01, 1, 1);
EXEC Trade.UpdateInterestRateOverride_TRDOPS @UpdateInterestRateOverrideTbl = @UpdateInterestRateOverrideTbl;
```

### 8.2 Update existing override
```sql
DECLARE @UpdateInterestRateOverrideTbl Trade.UpdateInterestRateOverrideTbl_TRDOPS;
INSERT INTO @UpdateInterestRateOverrideTbl (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, OverNightFeePatternID, SettlementTypeID)
VALUES (100, NULL, NULL, 1, 0.06, 0.06, 0.02, 0.02, 2, 1);
EXEC Trade.UpdateInterestRateOverride_TRDOPS @UpdateInterestRateOverrideTbl = @UpdateInterestRateOverrideTbl;
```

### 8.3 Multi-row batch
```sql
DECLARE @UpdateInterestRateOverrideTbl Trade.UpdateInterestRateOverrideTbl_TRDOPS;
INSERT INTO @UpdateInterestRateOverrideTbl (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell, OverNightFeePatternID, SettlementTypeID)
SELECT NULL, NULL, NULL, InstrumentTypeID, 0.05, 0.05, 0.01, 0.01, 1, 1 FROM Trade.InstrumentType WHERE InstrumentTypeID IN (1,2,3);
EXEC Trade.UpdateInterestRateOverride_TRDOPS @UpdateInterestRateOverrideTbl = @UpdateInterestRateOverrideTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRateOverrideTbl_TRDOPS | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UpdateInterestRateOverrideTbl_TRDOPS.sql*
