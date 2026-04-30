# Trade.FnIsRealPosition

> Determines whether a trading position represents real asset ownership (actual shares held) versus a derivative contract (CFD), accounting for the crypto exception where ownership is never classified as "real" in the trading engine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with single column `IsRealPosition` (BIT-like INT: 0 or 1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnIsRealPosition is a critical business classification function that determines whether a position represents real asset ownership (the customer owns actual shares) or a derivative contract (CFD, TRS, etc.). This distinction drives fundamental differences in PnL calculation, fee structures, tax treatment, dividend processing, and regulatory reporting across the platform.

This function exists because the raw `IsSettled` flag on PositionTbl is insufficient for determining real ownership. Crypto assets (InstrumentTypeID=10) are always treated as derivative-like in the trading engine regardless of the IsSettled flag, because crypto "ownership" has different settlement mechanics than traditional equity. Without this function, the system would incorrectly classify crypto positions as "real" when IsSettled=1, leading to wrong PnL formulas, incorrect fee calculations, and regulatory misreporting.

The function is consumed extensively via CROSS APPLY by PnL calculation functions (FnGetCurrentClosingRate, FnGetCurrentConversionRate), close position procedures (ClosePositionAtPriceRateID), dividend queries (GetPayedDividendsAndPositions), fee processes (GetPositionsForFeeBulkGeneral), and end-of-day snapshot views (OpenPositionEndOfDay). It reads from Trade.InstrumentMetaData to look up the instrument's asset class.

---

## 2. Business Logic

### 2.1 Crypto Exception Rule

**What**: Crypto instruments are never classified as "real positions" in the trading engine, regardless of the IsSettled flag value.

**Columns/Parameters Involved**: `@InstrumentID`, `InstrumentMetaData.InstrumentTypeID`

**Rules**:
- When InstrumentTypeID = 10 (Crypto), the function returns 0 (not real) unconditionally
- This overrides IsSettled=1 for crypto assets
- Crypto ownership uses different settlement and custody mechanics that are handled outside the "real position" classification

### 2.2 Real Position Classification

**What**: Non-crypto instruments are classified based on the legacy IsSettled flag.

**Columns/Parameters Involved**: `@IsSettled`, `@InstrumentID`, `InstrumentMetaData.InstrumentTypeID`

**Rules**:
- If instrument is NOT crypto (InstrumentTypeID != 10) AND @IsSettled = 1: position is real (customer owns shares)
- If instrument is NOT crypto AND @IsSettled = 0: position is a CFD (derivative)
- This maps directly to the PositionTbl.IsSettled legacy flag, where 1 = real stock, 0 = CFD

**Diagram**:
```
@InstrumentID -> Lookup InstrumentMetaData.InstrumentTypeID
                    |
                    v
              InstrumentTypeID = 10 (Crypto)?
              /                      \
           YES                        NO
            |                          |
            v                          v
    Return 0                  @IsSettled = 1?
    (never real)              /             \
                           YES               NO
                            |                 |
                            v                 v
                      Return 1           Return 0
                      (real stock)       (CFD/derivative)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsSettled | BIT | NO | - | VERIFIED | LEGACY settlement flag from PositionTbl. 1 = real stock position (actual share ownership), 0 = CFD. NOT "settlement complete." This is the raw input; the function applies the crypto exception before returning the final classification. See [Settlement Type](_glossary.md#settlement-type). |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. Looked up in Trade.InstrumentMetaData to determine InstrumentTypeID (asset class). Crypto instruments (TypeID=10) always return IsRealPosition=0 regardless of @IsSettled. |
| 3 | IsRealPosition (return) | int | NO | - | VERIFIED | Final classification result: 1 = real stock position (customer owns actual shares, non-crypto, IsSettled=1), 0 = derivative/CFD/crypto position. Used by PnL functions to select the correct calculation formula, by fee processes to determine fee structure, and by close procedures for settlement routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | FROM/WHERE | Looks up InstrumentTypeID to determine asset class. Crypto (10) triggers the override that prevents "real" classification. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnGetCurrentClosingRate | CROSS APPLY | Function call | Determines whether to use ask/bid or settlement closing rate |
| Trade.FnGetCurrentConversionRate | CROSS APPLY | Function call | Determines conversion rate logic for real vs CFD positions |
| Trade.OpenPositionEndOfDay | CROSS APPLY | Function call | End-of-day PnL snapshot classification |
| Trade.ClosePositionAtPriceRateID | CROSS APPLY | Procedure call | Close position settlement routing |
| Trade.GetPayedDividendsAndPositions | CROSS APPLY | Procedure call | Dividend eligibility (only real positions receive dividends) |
| Trade.GetPositionsForFeeBulkGeneral | CROSS APPLY | Procedure call | Fee process - real vs CFD fee structures differ |
| Trade.GetPositionsForFeeProcess | CROSS APPLY | Procedure call | Fee calculation routing |
| Trade.IsMSLRatesEqualsToEndForexRate | CROSS APPLY | Procedure call | MSL rate validation |
| Trade.ManualPositionClose_Crisis | CROSS APPLY | Procedure call | Emergency close with real position handling |
| Trade.OmeCheck | CROSS APPLY | Procedure call | Order Management Engine validation |
| History.ClosePositionEndOfDay | CROSS APPLY | View call | Historical end-of-day close position classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnIsRealPosition (function)
  └── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM with WHERE on InstrumentID to look up InstrumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCurrentClosingRate | Function | CROSS APPLY for real/CFD closing rate logic |
| Trade.FnGetCurrentConversionRate | Function | CROSS APPLY for real/CFD conversion rate logic |
| Trade.OpenPositionEndOfDay | View | CROSS APPLY for PnL classification |
| Trade.ClosePositionAtPriceRateID | Procedure | CROSS APPLY for close settlement |
| Trade.GetPayedDividendsAndPositions | Procedure | CROSS APPLY for dividend eligibility |
| Trade.GetPositionsForFeeBulkGeneral | Procedure | CROSS APPLY for fee structure |
| Trade.GetPositionsForFeeProcess | Procedure | CROSS APPLY for fee routing |
| Trade.IsMSLRatesEqualsToEndForexRate | Procedure | CROSS APPLY for rate validation |
| Trade.ManualPositionClose_Crisis | Procedure | CROSS APPLY for emergency close |
| Trade.ManualRenlance | Procedure | CROSS APPLY for rebalance logic |
| Trade.OmeCheck | Procedure | CROSS APPLY for OME validation |
| History.ClosePositionEndOfDay | View | CROSS APPLY for historical classification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning single-column `IsRealPosition` via SELECT TOP 1 |
| WITH (NOLOCK) | Read hint | Uses NOLOCK on InstrumentMetaData read for performance |

---

## 8. Sample Queries

### 8.1 Check if a specific position is a real stock position

```sql
SELECT  p.PositionID,
        p.CID,
        p.InstrumentID,
        p.IsSettled,
        rp.IsRealPosition
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnIsRealPosition(p.IsSettled, p.InstrumentID) rp
WHERE   p.PositionID = 12345;
```

### 8.2 Count real vs CFD open positions per customer

```sql
SELECT  p.CID,
        SUM(CASE WHEN rp.IsRealPosition = 1 THEN 1 ELSE 0 END) AS RealPositions,
        SUM(CASE WHEN rp.IsRealPosition = 0 THEN 1 ELSE 0 END) AS CFDPositions
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnIsRealPosition(p.IsSettled, p.InstrumentID) rp
WHERE   p.StatusID = 1
GROUP BY p.CID
ORDER BY RealPositions DESC;
```

### 8.3 Find crypto positions that have IsSettled=1 but are still classified as non-real

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        imd.InstrumentDisplayName,
        p.IsSettled,
        rp.IsRealPosition
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnIsRealPosition(p.IsSettled, p.InstrumentID) rp
        JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON p.InstrumentID = imd.InstrumentID
WHERE   p.IsSettled = 1
        AND rp.IsRealPosition = 0
        AND imd.InstrumentTypeID = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object directly. Business context inherited from Trade.InstrumentMetaData documentation (InstrumentTypeID=10 is Crypto) and Settlement Type glossary entry.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnIsRealPosition | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnIsRealPosition.sql*
