# Trade.FnGetCloseFixPerLot

> Resolves the fixed-per-lot close fee for a position by looking up fee configuration with a three-tier priority: instrument-specific, then instrument group, then instrument type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with single column `FeeValue` (decimal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetCloseFixPerLot resolves the fixed-per-lot fee charged when closing a trading position. Unlike the percentage-based fee (FnGetCloseFeeInPercentage), this is a flat monetary amount per lot - independent of the position's value. The two fee components (percentage + fixed-per-lot) are combined by FnGetCloseFee to calculate the total close fee.

This function exists because some instruments or instrument types charge a per-lot commission in addition to (or instead of) a percentage spread. For example, US stocks might charge $0.01 per share (lot) as a fixed commission component. The three-tier priority system (instrument > group > type) allows flexible configuration at different granularity levels.

The function is consumed by Trade.FnGetCloseFee and Trade.FnGetCloseFeeOnOpen (which combine both fee components), and indirectly by OpenPositionEndOfDay views. It reads from Trade.FixPerLotConfigurations (configuration table), Trade.InstrumentMetaData (for instrument type lookup), and Trade.InstrumentGroups (for group membership).

---

## 2. Business Logic

### 2.1 Three-Tier Fee Resolution Priority

**What**: Fixed-per-lot fee configuration is resolved through the same priority chain as percentage fees, ensuring the most specific configuration wins.

**Columns/Parameters Involved**: `@InstrumentID`, `@IsSettled`, `Trade.FixPerLotConfigurations.FeeValue`, `ConfigBy`

**Rules**:
- **Priority 1 (ConfigBy=1)**: Configuration by InstrumentID - exact instrument match in FixPerLotConfigurations
- **Priority 2 (ConfigBy=2)**: Configuration by Group - matches any GroupID the instrument belongs to (via Trade.InstrumentGroups). MAX(FeeValue) used when instrument is in multiple groups
- **Priority 3 (ConfigBy=3)**: Configuration by InstrumentType - matches the instrument's InstrumentTypeID from InstrumentMetaData
- First non-NULL FeeValue in priority order wins (ORDER BY ConfigBy ASC, TOP 1)
- FeeOperationTypeID filter: only rows with 2 (Close) or 3 (All) are considered
- IsSettled filter: matches exact @IsSettled value OR config row has IsSettled=NULL (applies to both)

**Diagram**:
```
@InstrumentID, @IsSettled
       |
       v
  Priority 1: FixPerLotConfigurations WHERE InstrumentID = @InstrumentID
       |                               AND FeeOperationTypeID IN (2=Close, 3=All)
       | found? -> return FeeValue (fixed $ per lot)
       | not found? -> continue
       v
  Priority 2: InstrumentGroups + FixPerLotConfigurations WHERE GroupID matches
       |       -> MAX(FeeValue) if multiple groups
       | found? -> return FeeValue
       | not found? -> continue
       v
  Priority 3: InstrumentMetaData + FixPerLotConfigurations WHERE InstrumentTypeID matches
       | found? -> return FeeValue
       | not found? -> NULL (no fixed fee configured)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The trading instrument for which to resolve the close fixed-per-lot fee. Looked up in InstrumentMetaData (for type) and InstrumentGroups (for group membership). |
| 2 | @IsSettled | bit | NO | - | VERIFIED | Settlement type: 1 = real stock, 0 = CFD. Fee configs can be settlement-specific or universal (config.IsSettled=NULL). See [Settlement Type](_glossary.md#settlement-type). |
| 3 | FeeValue (return) | decimal(16,8) | YES | - | CODE-BACKED | The resolved fixed-per-lot close fee (monetary amount per lot). NULL if no configuration exists. Combined with percentage fee in FnGetCloseFee: total = (pct_fee * amount) + (fixed_fee * lots). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | JOIN | Lookups for InstrumentTypeID (Priority 3) |
| @InstrumentID | Trade.InstrumentGroups | JOIN | Lookups for GroupID membership (Priority 2) |
| config | Trade.FixPerLotConfigurations | JOIN | Fee configuration values at all three tiers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnGetCloseFee | CROSS APPLY | Function call | Combines fixed-per-lot fee with percentage fee for total close fee |
| Trade.FnGetCloseFeeOnOpen | CROSS APPLY | Function call | Projects close fee at position open time |
| Trade.OpenPositionEndOfDay variants | CROSS APPLY | View reference | EOD fee projections |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetCloseFixPerLot (function)
  ├── Trade.InstrumentMetaData (table)
  ├── Trade.FixPerLotConfigurations (table)
  └── Trade.InstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | JOIN for InstrumentTypeID lookup (Priority 3) |
| Trade.FixPerLotConfigurations | Table | JOIN for fee values at all three priority tiers |
| Trade.InstrumentGroups | Table | JOIN for group membership lookup (Priority 2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCloseFee | Function | CROSS APPLY for fixed-per-lot component of total close fee |
| Trade.FnGetCloseFeeOnOpen | Function | CROSS APPLY for projected close fee at open |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning single FeeValue column |
| WITH (NOLOCK) | Read hint | All table reads use NOLOCK |
| UNION ALL + ORDER BY ConfigBy | Logic | Three CTEs for three priority tiers, ordered 1 > 2 > 3 |
| FeeOperationTypeID IN (3, 2) | Filter | Only Close (2) and All (3) operation types |

---

## 8. Sample Queries

### 8.1 Look up fixed-per-lot close fee for a specific instrument

```sql
SELECT  fee.FeeValue AS CloseFixPerLot
FROM    Trade.FnGetCloseFixPerLot(1001, 1) fee;
```

### 8.2 Compare fixed fee for CFD vs real settlement

```sql
SELECT  'CFD' AS Type, cfd.FeeValue
FROM    Trade.FnGetCloseFixPerLot(1001, 0) cfd
UNION ALL
SELECT  'REAL', real_fee.FeeValue
FROM    Trade.FnGetCloseFixPerLot(1001, 1) real_fee;
```

### 8.3 Show both fee components for all open positions

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        pct.FeeValue AS PctFee,
        fix.FeeValue AS FixPerLotFee
FROM    Trade.PositionTbl p WITH (NOLOCK)
        OUTER APPLY Trade.FnGetCloseFeeInPercentage(p.InstrumentID, p.IsSettled) pct
        OUTER APPLY Trade.FnGetCloseFixPerLot(p.InstrumentID, p.IsSettled) fix
WHERE   p.CID = 12345678
        AND p.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Fee configuration logic documented in Trade.FixPerLotConfigurations table doc.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetCloseFixPerLot | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetCloseFixPerLot.sql*
