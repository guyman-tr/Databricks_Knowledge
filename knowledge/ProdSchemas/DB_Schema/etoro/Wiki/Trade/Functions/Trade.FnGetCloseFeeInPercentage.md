# Trade.FnGetCloseFeeInPercentage

> Resolves the percentage-based close fee for a position by looking up fee configuration with a three-tier priority: instrument-specific, then instrument group, then instrument type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with single column `FeeValue` (decimal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetCloseFeeInPercentage resolves the percentage-based fee charged when closing a trading position. The fee amount varies by instrument, settlement type, and configuration tier. This function implements the fee resolution priority logic: instrument-specific overrides beat group-level defaults, which beat instrument-type-level defaults.

This function exists because fee structures must be configurable at multiple granularity levels - a specific instrument (e.g., AAPL) can have a unique fee, a group of instruments (e.g., "US Tech Stocks") can share a fee, or an entire instrument type (e.g., all Stocks) can have a default fee. The three-tier priority system allows ops teams to configure broad defaults and then override for specific instruments without touching the base configuration.

The function is consumed by Trade.FnGetCloseFee and Trade.FnGetCloseFeeOnOpen (which combine percentage and fixed-per-lot fees), and indirectly by OpenPositionEndOfDay views for end-of-day fee projections. It reads from Trade.FeeInPercentageConfigurations (configuration table), Trade.InstrumentMetaData (for instrument type lookup), and Trade.InstrumentGroups (for group membership).

---

## 2. Business Logic

### 2.1 Three-Tier Fee Resolution Priority

**What**: Fee configuration is resolved through a strict priority chain ensuring the most specific configuration wins.

**Columns/Parameters Involved**: `@InstrumentID`, `@IsSettled`, `Trade.FeeInPercentageConfigurations.FeeValue`, `ConfigBy`

**Rules**:
- **Priority 1 (ConfigBy=1)**: Configuration by InstrumentID - looks for a FeeInPercentageConfigurations row matching the exact InstrumentID
- **Priority 2 (ConfigBy=2)**: Configuration by Group - looks for a row matching any GroupID that the instrument belongs to (via Trade.InstrumentGroups). If the instrument belongs to multiple groups with fees, MAX(FeeValue) is used
- **Priority 3 (ConfigBy=3)**: Configuration by InstrumentType - looks for a row matching the instrument's InstrumentTypeID from InstrumentMetaData
- First non-NULL FeeValue in priority order wins (ORDER BY ConfigBy ASC, TOP 1)
- FeeOperationTypeID filter: only rows with 2 (Close) or 3 (All) are considered
- IsSettled filter: matches exact @IsSettled value OR config row has IsSettled=NULL (applies to both)

**Diagram**:
```
@InstrumentID, @IsSettled
       |
       v
  Priority 1: FeeInPercentageConfigurations WHERE InstrumentID = @InstrumentID
       |                                     AND FeeOperationTypeID IN (2=Close, 3=All)
       |                                     AND (IsSettled IS NULL OR = @IsSettled)
       | found? -> return FeeValue
       | not found? -> continue
       v
  Priority 2: InstrumentGroups + FeeInPercentageConfigurations WHERE GroupID matches
       |       -> MAX(FeeValue) if multiple groups
       | found? -> return FeeValue
       | not found? -> continue
       v
  Priority 3: InstrumentMetaData + FeeInPercentageConfigurations WHERE InstrumentTypeID matches
       | found? -> return FeeValue
       | not found? -> NULL (no fee configured)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The trading instrument for which to resolve the close fee. Looked up in InstrumentMetaData (for type) and InstrumentGroups (for group membership). |
| 2 | @IsSettled | bit | NO | - | VERIFIED | Settlement type of the position: 1 = real stock, 0 = CFD. Fee configurations can be settlement-specific or universal (config.IsSettled=NULL). See [Settlement Type](_glossary.md#settlement-type). |
| 3 | FeeValue (return) | decimal(16,8) | YES | - | CODE-BACKED | The resolved percentage-based close fee. Example: 4.0 means 4%. NULL if no fee configuration exists for this instrument/settlement combination. Consumed by FnGetCloseFee to compute the total close fee. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | JOIN | Lookups for InstrumentTypeID (Priority 3) |
| @InstrumentID | Trade.InstrumentGroups | JOIN | Lookups for GroupID membership (Priority 2) |
| config | Trade.FeeInPercentageConfigurations | JOIN | Fee configuration values at all three tiers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnGetCloseFee | CROSS APPLY | Function call | Combines percentage fee with fixed-per-lot fee for total close fee |
| Trade.FnGetCloseFeeOnOpen | CROSS APPLY | Function call | Projects close fee at position open time |
| Trade.OpenPositionEndOfDay variants | CROSS APPLY | View reference | EOD fee projections |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetCloseFeeInPercentage (function)
  ├── Trade.InstrumentMetaData (table)
  ├── Trade.FeeInPercentageConfigurations (table)
  └── Trade.InstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | JOIN for InstrumentTypeID lookup (Priority 3) |
| Trade.FeeInPercentageConfigurations | Table | JOIN for fee values at all three priority tiers |
| Trade.InstrumentGroups | Table | JOIN for group membership lookup (Priority 2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCloseFee | Function | CROSS APPLY for percentage component of total close fee |
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

### 8.1 Look up close fee percentage for a specific instrument

```sql
SELECT  fee.FeeValue AS CloseFeePct
FROM    Trade.FnGetCloseFeeInPercentage(1001, 1) fee;
```

### 8.2 Compare close fee for CFD vs real settlement

```sql
SELECT  'CFD' AS Type, cfd.FeeValue
FROM    Trade.FnGetCloseFeeInPercentage(1001, 0) cfd
UNION ALL
SELECT  'REAL', real_fee.FeeValue
FROM    Trade.FnGetCloseFeeInPercentage(1001, 1) real_fee;
```

### 8.3 Show close fee for all open positions of a customer

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        i.SymbolFull,
        p.IsSettled,
        fee.FeeValue AS CloseFeePct
FROM    Trade.PositionTbl p WITH (NOLOCK)
        JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
        OUTER APPLY Trade.FnGetCloseFeeInPercentage(p.InstrumentID, p.IsSettled) fee
WHERE   p.CID = 12345678
        AND p.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Fee configuration logic documented in Trade.FeeInPercentageConfigurations table doc.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetCloseFeeInPercentage | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetCloseFeeInPercentage.sql*
