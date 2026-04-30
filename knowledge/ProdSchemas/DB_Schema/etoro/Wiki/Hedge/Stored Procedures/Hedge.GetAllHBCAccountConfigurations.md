# Hedge.GetAllHBCAccountConfigurations

> Returns all HBC account configuration entries (LiquidityAccountID, InstrumentID, UseExecutionRateWithSpread) from the full configuration table - a bulk read used for loading the entire HBC configuration at once.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all rows from Hedge.HBCAccountConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the subset of HBC (Hedge Bot Controller) configuration needed for spread rate decisions - specifically, which accounts and instruments use execution rate with spread applied. It returns three columns from `Hedge.HBCAccountConfiguration`: the account, instrument, and the `UseExecutionRateWithSpread` flag.

According to the `Hedge.HBCAccountConfiguration` table documentation, this procedure was "created but never approved for production use - would return ~228K rows if `HBCAccountConfiguration` were fully populated." The production reader for HBC configuration is `Hedge.GetHBCAccountConfiguration(@LiquidityAccountID)` which filters by account.

**Important**: The SP selects only 3 of the 12 columns in `HBCAccountConfiguration`. It does NOT return order timing parameters (`MaxTimeMS`, `MaxRejectRetries`), size thresholds (`ThresholdInEToroUnits`, `MaxOrderSizeInEToroUnits`), or slippage parameters. This suggests it was designed for a specific use case focused only on the spread rate flag.

---

## 2. Business Logic

### 2.1 Spread Rate Configuration Retrieval

**What**: Returns the per-account, per-instrument flag controlling whether hedge orders should use the execution rate with spread applied.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`, `UseExecutionRateWithSpread`

**Rules**:
- `UseExecutionRateWithSpread`: determines whether the hedge order execution rate should include spread (1=yes, apply spread, 0=no, use raw rate)
- Returns ALL rows from the table (no filter), enabling the caller to load the complete configuration matrix
- WITH (NOLOCK) applied for read performance

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns all rows from `Hedge.HBCAccountConfiguration` with only the 3 spread-rate-related columns. Full HBC configuration including timing and size parameters is available via `Hedge.GetHBCAccountConfiguration(@LiquidityAccountID)`. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| LiquidityAccountID | Hedge.HBCAccountConfiguration | The liquidity account this configuration applies to |
| InstrumentID | Hedge.HBCAccountConfiguration | The trading instrument this configuration applies to |
| UseExecutionRateWithSpread | Hedge.HBCAccountConfiguration | Whether to apply spread to the execution rate: 1=use rate with spread, 0=use raw execution rate |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.HBCAccountConfiguration | Direct read (SELECT) | Source of HBC spread rate configuration data |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Note: this procedure was reportedly not approved for production use per the HBCAccountConfiguration documentation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAllHBCAccountConfigurations (procedure)
└── Hedge.HBCAccountConfiguration (table) - SELECT source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCAccountConfiguration | Table | SELECT 3 columns (LiquidityAccountID, InstrumentID, UseExecutionRateWithSpread) - all rows, no filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No filter | Design | Returns ALL rows - intended for full configuration bulk load. May return large result sets (33,705 rows currently) |
| WITH (NOLOCK) | Isolation | Applied to Hedge.HBCAccountConfiguration - dirty reads accepted for configuration data |
| Limited columns | Design | Returns only 3 of 12 HBCAccountConfiguration columns - spread rate focus only |

---

## 8. Sample Queries

### 8.1 Check spread rate configuration for a specific account

```sql
SELECT LiquidityAccountID, InstrumentID, UseExecutionRateWithSpread
FROM Hedge.HBCAccountConfiguration WITH (NOLOCK)
WHERE LiquidityAccountID = 1
ORDER BY InstrumentID
```

### 8.2 Count instruments using spread vs raw rate per account

```sql
SELECT LiquidityAccountID,
       SUM(CASE WHEN UseExecutionRateWithSpread = 1 THEN 1 ELSE 0 END) AS WithSpread,
       SUM(CASE WHEN UseExecutionRateWithSpread = 0 THEN 1 ELSE 0 END) AS WithoutSpread
FROM Hedge.HBCAccountConfiguration WITH (NOLOCK)
GROUP BY LiquidityAccountID
ORDER BY LiquidityAccountID
```

### 8.3 Compare with GetHBCAccountConfiguration (the production per-account reader)

```sql
SELECT LiquidityAccountID, InstrumentID, UseExecutionRateWithSpread,
       MaxTimeMS, MaxRejectRetries, MaxOrderSizeInEToroUnits
FROM Hedge.HBCAccountConfiguration WITH (NOLOCK)
WHERE LiquidityAccountID = 1
ORDER BY InstrumentID, ThresholdInEToroUnits
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAllHBCAccountConfigurations | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAllHBCAccountConfigurations.sql*
