# Hedge.HBCAccountConfiguration

> Tiered HBC (Hedge Bot Controller) execution parameter table storing per-account, per-instrument, per-size-threshold configurations that define order timing, retry, and size constraints for hedge orders routed through each liquidity account.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityAccountID, InstrumentID, ThresholdInEToroUnits) - 3-column composite PK CLUSTERED |
| **Partition** | No (on [PRIMARY] filegroup) |
| **Indexes** | 2 (PK + IX_InstrumentID nonclustered) |
| **Versioning** | None (DML triggers write to History.AuditHistory instead) |

---

## 1. Business Meaning

`Hedge.HBCAccountConfiguration` is the primary configuration table for the HBC (Hedge Bot Controller) subsystem. It defines how hedge orders should be executed - timing constraints, retry limits, order size bounds, and spread rate behavior - parameterized by three dimensions: which account, which instrument, and what order size tier.

The three-column PK enables **tiered configuration**: the same account/instrument pair can have multiple rows with different `ThresholdInEToroUnits` values. The HBC selects the appropriate row based on the actual order size - small orders use the low-threshold row, large orders use the high-threshold row. This allows aggressive parameters for small, easy-to-fill orders and conservative parameters for large, market-moving orders.

**Scale**: 33,705 rows across 14 LiquidityAccountIDs and 10,458 distinct instruments. The vast majority (32,862 rows = 97%) use the maximum threshold of 200,000,000 eToro units - indicating most instruments have a single high-ceiling tier. A subset has additional rows at lower thresholds (110,462 or 5,271) for tiered behavior.

**Note**: `Hedge.GetAllHBCAccountConfigurations` was created but never approved for production use (commented out in the DDL - would return ~228K rows). The production reader is `Hedge.GetHBCAccountConfiguration(@LiquidityAccountID)`, which filters by account.

---

## 2. Business Logic

### 2.1 Tiered Order Configuration by Size

**What**: The composite PK (LiquidityAccountID, InstrumentID, ThresholdInEToroUnits) creates size-tiered rows per account/instrument. The HBC applies the configuration row whose threshold most closely matches the current order size.

**Columns/Parameters Involved**: `ThresholdInEToroUnits`, `MaxTimeMS`, `MaxRejectRetries`, `MaxOrderSizeInEToroUnits`

**Rules**:
- 5 distinct ThresholdInEToroUnits values: 0, 5,271, 110,462, 1,137,139, 200,000,000
- ThresholdInEToroUnits=200,000,000 (32,862 rows): universal "large order" tier for most instruments
- ThresholdInEToroUnits=110,462 (696 rows): mid-tier for specific instruments needing tiered behavior
- ThresholdInEToroUnits=0 (123 rows): entry-level tier / initial configuration
- The HBC picks the row with the smallest threshold >= actual order size (or largest threshold if order exceeds all configured thresholds)
- Per account: different accounts can have different parameters for the same instrument/threshold (14 accounts in current data)

### 2.2 Execution Timing and Retry Parameters

**What**: `MaxTimeMS` and `MaxRejectRetries` control how long and how many times the HBC attempts to fill a hedge order before giving up.

**Columns/Parameters Involved**: `MaxTimeMS`, `MaxRejectRetries`

**Rules**:
- `MaxTimeMS`: maximum milliseconds to wait for an order to fill (range: 0-25,000). 0 = immediate timeout; 25,000 = up to 25 seconds.
- `MaxRejectRetries`: maximum number of retry attempts on rejection (range: 0-10). 0 = no retries; higher = more persistence.
- Both are applied per-tier: small orders may get fewer retries; large orders may get longer wait times.

### 2.3 Order Size Bounds and Spread Behavior

**What**: `MinOrderSizeInEToroUnits`, `MaxOrderSizeInEToroUnits`, and `UseExecutionRateWithSpread` further constrain order routing for this tier.

**Columns/Parameters Involved**: `MinOrderSizeInEToroUnits`, `MaxOrderSizeInEToroUnits`, `UseExecutionRateWithSpread`, `MinOrderSizeUSDForHBC`

**Rules**:
- `MaxOrderSizeInEToroUnits`: cap on single-order execution size within this tier; larger orders must be split
- `MinOrderSizeInEToroUnits`: floor below which orders are not routed (may be NULL = no floor)
- `MinOrderSizeUSDForHBC`: USD-denominated minimum order size (DEFAULT 0 = no USD minimum)
- `UseExecutionRateWithSpread=1` (12,723 rows): execution rate calculation includes the spread
- `UseExecutionRateWithSpread=0` (20,982 rows): execution rate calculated without spread inclusion

---

## 3. Data Overview

| LiquidityAccountID | InstrumentID | ThresholdInEToroUnits | MaxTimeMS | MaxRejectRetries | MaxOrderSize | UseSpread | Meaning |
|---|---|---|---|---|---|---|---|
| (various) | (various) | 200,000,000 | varies | varies | varies | varies | Standard single-tier config for most instruments (32,862 rows) |
| (specific accounts) | (specific instruments) | 110,462 | varies | varies | varies | varies | Mid-tier row for tiered instruments (696 rows) |
| (specific accounts) | (specific instruments) | 0 | varies | varies | varies | varies | Entry-level tier row (123 rows) |

Total rows: 33,705 (14 accounts, 10,458 instruments). 5 distinct threshold tiers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account these execution parameters apply to. Part of 3-column composite PK. 14 distinct accounts configured. |
| 2 | InstrumentID | int | NO | - | VERIFIED | FK to Trade.Instrument(InstrumentID). The instrument these execution parameters apply to. Part of 3-column composite PK. 10,458 distinct instruments configured. |
| 3 | ThresholdInEToroUnits | int | NO | - | VERIFIED | Order size tier boundary (in eToro units). Part of 3-column composite PK enabling tiered config. The HBC selects the row for orders at or below this threshold. 5 distinct values: 0, 5,271, 110,462, 1,137,139, 200,000,000. Most rows (97%) use 200,000,000. |
| 4 | MaxTimeMS | int | NO | - | VERIFIED | Maximum milliseconds to wait for an order to fill before timeout. Range: 0-25,000 in current data. Applied per-tier, per-instrument, per-account. |
| 5 | MaxRejectRetries | int | NO | - | VERIFIED | Maximum number of retry attempts when an order is rejected. Range: 0-10 in current data. Higher values = more persistent execution attempts. |
| 6 | MinOrderSizeInEToroUnits | decimal(19,5) | YES | - | VERIFIED | Minimum order size in eToro units for this account/instrument/tier. Orders below this floor are not routed. NULL = no minimum applied. |
| 7 | MaxOrderSizeInEToroUnits | int | NO | - | VERIFIED | Maximum single-order execution size in eToro units. Orders exceeding this must be split. Controls individual order impact on the market. |
| 8 | UseExecutionRateWithSpread | bit | NO | - | VERIFIED | Whether the execution rate calculation includes the bid-ask spread. 1=include spread (12,723 rows), 0=exclude spread (20,982 rows). Affects pricing calculation for execution rate benchmarking. |
| 9 | MinOrderSizeUSDForHBC | money | NO | 0 | VERIFIED | Minimum order size in USD for HBC routing. DEFAULT 0 = no USD minimum. Provides a USD-denominated floor in addition to the eToro units floor. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_HBCAccountConfiguration_LiquidityAccounts) | Each configuration row targets a specific liquidity account |
| InstrumentID | Trade.Instrument | FK (FK_HBCAccountConfiguration_Instrument) | Each configuration row governs a specific instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetHBCAccountConfiguration | (table ref) | READER | SELECTs all columns WHERE LiquidityAccountID=@param; returns HBC config for a specific account |
| History.AuditHistory | (trigger) | Audit Log | DML triggers (Insert/Update/Delete) write column-level changes to History.AuditHistory |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HBCAccountConfiguration (table)
  ├── Trade.LiquidityAccounts (table) [FK - LiquidityAccountID]
  └── Trade.Instrument (table) [FK - InstrumentID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK_HBCAccountConfiguration_LiquidityAccounts - account must exist |
| Trade.Instrument | Table | FK_HBCAccountConfiguration_Instrument - instrument must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHBCAccountConfiguration | Stored Procedure | READER - returns HBC config for a specific account (filtered by LiquidityAccountID param) |
| History.AuditHistory | Table | Audit log via DML triggers (all 8 data columns tracked) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HBCAccountConfiguration | CLUSTERED PK | LiquidityAccountID ASC, InstrumentID ASC, ThresholdInEToroUnits ASC | - | - | Active |
| IX_InstrumentID | NONCLUSTERED | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HBCAccountConfiguration | PRIMARY KEY | (LiquidityAccountID, InstrumentID, ThresholdInEToroUnits) - tiered config |
| FK_HBCAccountConfiguration_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID must reference Trade.LiquidityAccounts |
| FK_HBCAccountConfiguration_Instrument | FOREIGN KEY | InstrumentID must reference Trade.Instrument |
| DEFAULT MinOrderSizeUSDForHBC | DEFAULT | MinOrderSizeUSDForHBC = 0 |

Note: No SYSTEM_VERSIONING. DML triggers write to History.AuditHistory for all 8 data columns.

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| AuditDelete_Hedge_HBCAccountConfiguration | DELETE | Writes column-level DELETE records to History.AuditHistory for 8 tracked columns |
| AuditInsert_Hedge_HBCAccountConfiguration | INSERT | Writes column-level INSERT records to History.AuditHistory for 8 tracked columns |
| AuditUpdate_Hedge_HBCAccountConfiguration | UPDATE | Writes column-level UPDATE records (old/new values) to History.AuditHistory for changed columns |

---

## 8. Sample Queries

### 8.1 Get HBC configuration for a specific account

```sql
-- Matches Hedge.GetHBCAccountConfiguration(@LiquidityAccountID)
SELECT
    hac.LiquidityAccountID,
    hac.InstrumentID,
    hac.ThresholdInEToroUnits,
    hac.MaxTimeMS,
    hac.MaxRejectRetries,
    hac.MinOrderSizeInEToroUnits,
    hac.MaxOrderSizeInEToroUnits,
    hac.UseExecutionRateWithSpread,
    hac.MinOrderSizeUSDForHBC
FROM Hedge.HBCAccountConfiguration hac WITH (NOLOCK)
WHERE hac.LiquidityAccountID = 10  -- ZBFX Price2
ORDER BY hac.InstrumentID, hac.ThresholdInEToroUnits
```

### 8.2 Find instruments with tiered configuration (multiple threshold rows per account)

```sql
SELECT
    LiquidityAccountID,
    InstrumentID,
    COUNT(*) AS TierCount,
    STRING_AGG(CAST(ThresholdInEToroUnits AS VARCHAR), ' / ')
        WITHIN GROUP (ORDER BY ThresholdInEToroUnits) AS Thresholds
FROM Hedge.HBCAccountConfiguration WITH (NOLOCK)
GROUP BY LiquidityAccountID, InstrumentID
HAVING COUNT(*) > 1
ORDER BY TierCount DESC
```

### 8.3 View audit history for a configuration change

```sql
SELECT AuditDate, UserName, ColumnName, OldValue, NewValue, Operation
FROM History.AuditHistory WITH (NOLOCK)
WHERE SchemaName = 'Hedge'
  AND TableName = 'HBCAccountConfiguration'
  AND PK_Value LIKE '10,%'  -- for LiquidityAccountID=10
ORDER BY AuditDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.HBCAccountConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HBCAccountConfiguration.sql*
