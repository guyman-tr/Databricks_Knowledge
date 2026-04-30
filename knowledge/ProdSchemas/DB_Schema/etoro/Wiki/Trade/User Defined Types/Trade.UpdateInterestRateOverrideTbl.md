# Trade.UpdateInterestRateOverrideTbl

> TVP for bulk updates of interest rate overrides (buy/sell rates and markups per instrument, exchange, or instrument type).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InterestRateOverrideID (int), InstrumentID (int), ExchangeID (int), InstrumentTypeID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UpdateInterestRateOverrideTbl carries interest rate override data for bulk upsert: InterestRateOverrideID (for updates), InstrumentID, ExchangeID, InstrumentTypeID (for insert/identify), plus InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell. It models overnight or swap interest rate overrides that override default interest rates for specific instruments, exchanges, or instrument types.

This type exists to support batch updates of interest rate override configuration. Admin or sync services populate the TVP and pass it to Trade.UpdateInterestRateOverride.

The type flows from config services into Trade.UpdateInterestRateOverride. The procedure merges the TVP rows into the interest rate override table (INSERT for new, UPDATE for existing by InterestRateOverrideID).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. InstrumentID/ExchangeID/InstrumentTypeID identify scope; InterestRateBuy/Sell and MarkupBuy/Sell are paired rate and markup values.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateOverrideID | int | YES | - | CODE-BACKED | Override record ID for updates; NULL for inserts |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Instrument scope; NULL when override is by Exchange/InstrumentType |
| 3 | ExchangeID | int | YES | - | CODE-BACKED | Exchange scope; NULL when override is by Instrument/InstrumentType |
| 4 | InstrumentTypeID | int | YES | - | CODE-BACKED | Instrument type scope; NULL when override is by Instrument/Exchange |
| 5 | InterestRateBuy | decimal(16,8) | NO | - | CODE-BACKED | Buy-side interest rate |
| 6 | InterestRateSell | decimal(16,8) | NO | - | CODE-BACKED | Sell-side interest rate |
| 7 | MarkupBuy | decimal(16,8) | NO | - | CODE-BACKED | Buy-side markup |
| 8 | MarkupSell | decimal(16,8) | NO | - | CODE-BACKED | Sell-side markup |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID, ExchangeID, InstrumentTypeID semantically reference Trade.Instrument, Exchange, InstrumentType but no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInterestRateOverride | @UpdateInterestRateOverrideTbl | Parameter (TVP) | Bulk upsert of interest rate overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInterestRateOverride | Stored Procedure | READONLY parameter for bulk interest rate override updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk insert overrides by instrument type
```sql
DECLARE @UpdateInterestRateOverrideTbl Trade.UpdateInterestRateOverrideTbl;
INSERT INTO @UpdateInterestRateOverrideTbl (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (NULL, NULL, NULL, 1, 0.05, 0.05, 0.01, 0.01);
EXEC Trade.UpdateInterestRateOverride @UpdateInterestRateOverrideTbl = @UpdateInterestRateOverrideTbl;
```

### 8.2 Update existing override by ID
```sql
DECLARE @UpdateInterestRateOverrideTbl Trade.UpdateInterestRateOverrideTbl;
INSERT INTO @UpdateInterestRateOverrideTbl (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (100, NULL, NULL, 1, 0.06, 0.06, 0.02, 0.02);
EXEC Trade.UpdateInterestRateOverride @UpdateInterestRateOverrideTbl = @UpdateInterestRateOverrideTbl;
```

### 8.3 Multi-row batch
```sql
DECLARE @UpdateInterestRateOverrideTbl Trade.UpdateInterestRateOverrideTbl;
INSERT INTO @UpdateInterestRateOverrideTbl (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell)
VALUES (NULL, 12345, NULL, NULL, 0.04, 0.04, 0.01, 0.01),
       (NULL, 12346, NULL, NULL, 0.05, 0.05, 0.015, 0.015);
EXEC Trade.UpdateInterestRateOverride @UpdateInterestRateOverrideTbl = @UpdateInterestRateOverrideTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRateOverrideTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UpdateInterestRateOverrideTbl.sql*
