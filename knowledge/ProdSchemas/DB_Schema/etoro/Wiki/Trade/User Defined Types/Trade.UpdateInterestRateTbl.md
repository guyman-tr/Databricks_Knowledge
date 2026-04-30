# Trade.UpdateInterestRateTbl

> TVP for bulk updates of base interest rates (buy/sell rates and markups per instrument type).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentTypeID (int), InterestRateID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UpdateInterestRateTbl carries base interest rate data for bulk update: InstrumentTypeID and InterestRateID identify the rate record, plus InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell. It models overnight or swap interest rates at the instrument-type level (not instrument-specific overrides).

This type exists to support batch updates of base interest rate configuration. Admin or sync services populate the TVP and pass it to Trade.UpdateInterestRate.

The type flows from config services into Trade.UpdateInterestRate. The procedure JOINs the TVP against the interest rate table and updates the buy/sell rates and markups.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. InstrumentTypeID + InterestRateID identify the record; InterestRateBuy/Sell and MarkupBuy/Sell are paired values.

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

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentTypeID and InterestRateID semantically reference Trade.InstrumentType and interest rate tables but no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInterestRate | @UpdateInterestRateTbl | Parameter (TVP) | Bulk update of base interest rates per instrument type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInterestRate | Stored Procedure | READONLY parameter for bulk interest rate updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk update single instrument type
```sql
DECLARE @UpdateInterestRateTbl Trade.UpdateInterestRateTbl;
INSERT INTO @UpdateInterestRateTbl (InstrumentTypeID, InterestRateID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (1, 10, 0.05, 0.05, 0.01, 0.01);
EXEC Trade.UpdateInterestRate @UpdateInterestRateTbl = @UpdateInterestRateTbl;
```

### 8.2 Multi-row batch update
```sql
DECLARE @UpdateInterestRateTbl Trade.UpdateInterestRateTbl;
INSERT INTO @UpdateInterestRateTbl (InstrumentTypeID, InterestRateID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (1, 10, 0.05, 0.05, 0.01, 0.01),
       (2, 20, 0.04, 0.04, 0.015, 0.015);
EXEC Trade.UpdateInterestRate @UpdateInterestRateTbl = @UpdateInterestRateTbl;
```

### 8.3 Build from existing table
```sql
DECLARE @UpdateInterestRateTbl Trade.UpdateInterestRateTbl;
INSERT INTO @UpdateInterestRateTbl (InstrumentTypeID, InterestRateID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
SELECT InstrumentTypeID, InterestRateID, 0.05, 0.05, 0.01, 0.01 FROM Trade.InterestRate WHERE InterestRateID < 100;
EXEC Trade.UpdateInterestRate @UpdateInterestRateTbl = @UpdateInterestRateTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRateTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UpdateInterestRateTbl.sql*
