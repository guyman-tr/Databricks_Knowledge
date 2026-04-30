# Trade.FnGetCloseFee

> Calculates the total close fee by combining the fixed-per-lot fee and percentage-based fee components, with per-lot taking priority over percentage when both exist.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with FeeType (varchar) and FeeValue (decimal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetCloseFee computes the total close fee for a position by combining two fee calculation methods: fixed-per-lot and percentage-based. The per-lot method takes priority (if configured) because it provides more predictable fees for the customer. If no per-lot fee exists, the percentage fee is used instead.

This function is the final fee resolution step in the close fee chain. It calls FnGetCloseFixPerLot and FnGetCloseFeeInPercentage (which each resolve their own three-tier priority), then computes the actual monetary fee using position parameters (units, lots, rate, conversion rate).

---

## 2. Business Logic

### 2.1 Fee Priority and Calculation

**What**: Per-lot fee overrides percentage fee. Each type uses a different formula.

**Columns/Parameters Involved**: `@InstrumentID`, `@IsSettled`, `@Units`, `@Lots`, `@Rate`, `@ConversionRate`

**Rules**:
- **Priority 1 - FeePerLot**: `ROUND(@Lots * perLot.FeeValue, 2)` - flat fee per lot
- **Priority 2 - FeeInPercentage**: `ROUND(@Units * @Rate * @ConversionRate * per.FeeValue / 100, 2)` - percentage of position value
- First non-NULL result wins (ORDER BY Priority ASC, TOP 1)
- Returns both FeeType (identifies which method was used) and FeeValue (the calculated fee amount)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. Passed to inner fee functions for configuration lookup. |
| 2 | @IsSettled | bit | NO | - | VERIFIED | Settlement type: 1=real, 0=CFD. Affects fee configuration lookup. |
| 3 | @Units | decimal(16,6) | NO | - | CODE-BACKED | Position units. Used in percentage fee formula: Units * Rate * ConvRate * Pct / 100. |
| 4 | @Lots | decimal(16,6) | NO | - | CODE-BACKED | Position lots. Used in per-lot fee formula: Lots * FeePerLot. |
| 5 | @Rate | decimal(18,8) | NO | - | CODE-BACKED | Current closing rate. Used in percentage fee formula to compute position value. |
| 6 | @ConversionRate | decimal(18,8) | NO | - | CODE-BACKED | Currency conversion rate. Used in percentage fee formula to convert to account currency. |
| 7 | FeeType (return) | varchar | NO | - | CODE-BACKED | Which fee method was used: 'FeePerLot' or 'FeeInPercentage'. |
| 8 | FeeValue (return) | decimal | YES | - | CODE-BACKED | Calculated fee amount in account currency, rounded to 2 decimal places. NULL if no fee configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID, @IsSettled | Trade.FnGetCloseFixPerLot | Function call | Gets per-lot fee configuration |
| @InstrumentID, @IsSettled | Trade.FnGetCloseFeeInPercentage | Function call | Gets percentage fee configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OpenPositionEndOfDay variants | CROSS APPLY | View reference | EOD close fee calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetCloseFee (function)
  ├── Trade.FnGetCloseFixPerLot (function)
  │     ├── Trade.InstrumentMetaData (table)
  │     ├── Trade.FixPerLotConfigurations (table)
  │     └── Trade.InstrumentGroups (table)
  └── Trade.FnGetCloseFeeInPercentage (function)
        ├── Trade.InstrumentMetaData (table)
        ├── Trade.FeeInPercentageConfigurations (table)
        └── Trade.InstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCloseFixPerLot | Function | Called for per-lot fee value |
| Trade.FnGetCloseFeeInPercentage | Function | Called for percentage fee value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenPositionEndOfDay variants | Views | CROSS APPLY for EOD fee |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning FeeType + FeeValue |
| ROUND(..., 2) | Precision | Fee amounts rounded to 2 decimal places |

---

## 8. Sample Queries

### 8.1 Calculate close fee for a specific position

```sql
SELECT  fee.FeeType, fee.FeeValue
FROM    Trade.FnGetCloseFee(1001, 0, 100.0, 1.0, 155.75, 1.0) fee;
```

### 8.2 Show close fees for all open positions

```sql
SELECT  p.PositionID, p.InstrumentID,
        fee.FeeType, fee.FeeValue
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnGetCurrentClosingRate(p.IsBuy, p.IsSettled, p.InstrumentID, 0) cr
        CROSS APPLY Trade.FnGetCloseFee(p.InstrumentID, p.IsSettled, p.AmountInUnitsDecimal, ISNULL(p.LotCountDecimal, 0), cr.CurrentClosingRate, 1.0) fee
WHERE   p.CID = 12345678 AND p.StatusID = 1;
```

### 8.3 Compare per-lot vs percentage fee for an instrument

```sql
SELECT  'PerLot' AS Method, perLot.FeeValue AS ConfiguredRate
FROM    Trade.FnGetCloseFixPerLot(1001, 0) perLot
UNION ALL
SELECT  'Percentage', pct.FeeValue
FROM    Trade.FnGetCloseFeeInPercentage(1001, 0) pct;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetCloseFee | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetCloseFee.sql*
