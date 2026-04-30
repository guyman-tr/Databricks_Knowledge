# Hedge.GetHBCAccountConfiguration

> Returns all HBC (Hedge Bot Controller) execution configuration rows for a specific liquidity account: per-instrument, per-size-tier parameters governing order timing, retry limits, and order size bounds.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountID - the liquidity account to load HBC config for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHBCAccountConfiguration loads the HBC execution parameter matrix for a given liquidity account at hedge server startup. The HBC (Hedge Bot Controller) needs to know - per instrument, per order size tier - how long to wait for a fill, how many times to retry on rejection, and what the minimum/maximum order sizes are.

This procedure is the startup config loader for HBC-enabled liquidity accounts. It returns all (InstrumentID, ThresholdInEToroUnits) rows for the account in a single result set, which the hedge server caches in memory for real-time execution decisions. At execution time, the hedge server picks the row whose ThresholdInEToroUnits most closely matches the order size.

The companion procedure Hedge.GetAllHBCAccountConfigurations returns the full table across all accounts (~228K rows) but was never approved for production; this per-account procedure is the production reader.

---

## 2. Business Logic

### 2.1 Tiered Configuration Selection

**What**: Multiple rows may be returned per instrument if tiered configuration exists (different parameters for small vs large orders).

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdInEToroUnits`, `MaxTimeMS`, `MaxRejectRetries`, `MaxOrderSizeInEToroUnits`

**Rules**:
- The caller receives ALL rows for the account, unsorted. The hedge server in-memory logic picks the right tier at execution time.
- Most instruments have a single row with ThresholdInEToroUnits=200,000,000 (the catch-all large tier).
- Instruments with tiered config have additional rows at lower thresholds (5,271 / 110,462 / 1,137,139) with more aggressive parameters for smaller order sizes.
- See Hedge.HBCAccountConfiguration Section 2.1 for full tier logic.

**Diagram**:
```
InstrumentID=1008, LiquidityAccountID=8:
  Row 1: Threshold=5,271     -> MaxTimeMS=1000, MaxRetries=0  (small orders: fast/no retry)
  Row 2: Threshold=200,000,000 -> MaxTimeMS=5000, MaxRetries=3  (large orders: wait longer)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account to retrieve HBC configuration for. References Trade.LiquidityAccounts(LiquidityAccountID). E.g., 8=ZBFX Price1, 10=ZBFX Price2. The hedge server passes its configured liquidity account ID at startup. |

**Output Columns** (returned resultset - all columns from Hedge.HBCAccountConfiguration):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | LiquidityAccountID | int | NO | - | VERIFIED | Echoed from the filter. The liquidity account these parameters apply to. Inherited from Hedge.HBCAccountConfiguration.LiquidityAccountID. |
| 3 | InstrumentID | int | NO | - | VERIFIED | The instrument these execution parameters govern. Implicit FK to Trade.Instrument. Inherited from Hedge.HBCAccountConfiguration.InstrumentID. |
| 4 | ThresholdInEToroUnits | int | NO | - | VERIFIED | Order size tier boundary. The hedge server selects the row with the smallest threshold >= actual order size. 5 distinct values: 0, 5271, 110462, 1137139, 200000000. Inherited from Hedge.HBCAccountConfiguration.ThresholdInEToroUnits. |
| 5 | MaxTimeMS | int | NO | - | VERIFIED | Maximum milliseconds to wait for a fill before timeout. Range: 0-25,000. Inherited from Hedge.HBCAccountConfiguration.MaxTimeMS. |
| 6 | MaxRejectRetries | int | NO | - | VERIFIED | Maximum number of retry attempts on rejection. Range: 0-10. Inherited from Hedge.HBCAccountConfiguration.MaxRejectRetries. |
| 7 | MinOrderSizeInEToroUnits | decimal(19,5) | YES | - | VERIFIED | Minimum order size in eToro units; orders below this floor are not routed. NULL = no minimum. Inherited from Hedge.HBCAccountConfiguration.MinOrderSizeInEToroUnits. |
| 8 | MaxOrderSizeInEToroUnits | int | NO | - | VERIFIED | Maximum single-order size in eToro units; larger orders must be split. Inherited from Hedge.HBCAccountConfiguration.MaxOrderSizeInEToroUnits. |
| 9 | UseExecutionRateWithSpread | bit | NO | - | VERIFIED | Whether execution rate calculation includes the bid-ask spread. 1=include spread, 0=exclude. Inherited from Hedge.HBCAccountConfiguration.UseExecutionRateWithSpread. |
| 10 | MinOrderSizeUSDForHBC | money | NO | 0 | VERIFIED | USD-denominated minimum order size. DEFAULT 0 = no USD floor. Inherited from Hedge.HBCAccountConfiguration.MinOrderSizeUSDForHBC. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityAccountID filter | Hedge.HBCAccountConfiguration | Lookup / Read | Loads all HBC configuration rows for the specified liquidity account. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | LiquidityAccountID | Caller | Called at startup to cache the full HBC config matrix for the account. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHBCAccountConfiguration (procedure)
└── Hedge.HBCAccountConfiguration (table)
      ├── Trade.LiquidityAccounts (table) [FK]
      └── Trade.Instrument (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCAccountConfiguration | Table | SELECT all 9 config columns WHERE LiquidityAccountID = @LiquidityAccountID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server (external) | Application | Calls at startup to load the in-memory HBC configuration cache for its liquidity account. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Load HBC config for a specific account

```sql
EXEC Hedge.GetHBCAccountConfiguration @LiquidityAccountID = 8;
```

### 8.2 Verify the config directly (what the proc returns)

```sql
SELECT LiquidityAccountID, InstrumentID, ThresholdInEToroUnits,
       MaxTimeMS, MaxRejectRetries, MinOrderSizeInEToroUnits,
       MaxOrderSizeInEToroUnits, UseExecutionRateWithSpread, MinOrderSizeUSDForHBC
FROM   Hedge.HBCAccountConfiguration WITH (NOLOCK)
WHERE  LiquidityAccountID = 8
ORDER BY InstrumentID, ThresholdInEToroUnits;
```

### 8.3 Count tiered vs single-tier instruments for an account

```sql
SELECT InstrumentID,
       COUNT(1) AS TierCount,
       MIN(ThresholdInEToroUnits) AS MinTier,
       MAX(ThresholdInEToroUnits) AS MaxTier
FROM   Hedge.HBCAccountConfiguration WITH (NOLOCK)
WHERE  LiquidityAccountID = 8
GROUP  BY InstrumentID
ORDER  BY TierCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHBCAccountConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHBCAccountConfiguration.sql*
