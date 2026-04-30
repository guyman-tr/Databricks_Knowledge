# Trade.SetInstrumentMarginsForFutures

> Updates futures instrument margin parameters in Trade.ProviderToInstrument for a batch of instruments, accepting new InitialMarginInAssetCurrency and StopLossMarginInAssetCurrency values and deriving Leverage1MaintenanceMargin as (1 - SL/Initial) * 100.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Instruments_NewMargin TVP - batch of InstrumentIDs with new margin values |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Futures instruments require periodic margin requirement updates reflecting changes in underlying asset volatility and exchange margin calls. This procedure is the write interface for updating futures margin parameters in `Trade.ProviderToInstrument`.

It accepts a batch of instruments with their new margin values and applies them. Three columns are updated:
- **InitialMarginInAssetCurrency**: The upfront margin required to open a futures position (in the asset's currency)
- **StopLossMarginInAssetCurrency**: The equity level at which a stop-loss is triggered (maintenance margin in asset currency)
- **Leverage1MaintenanceMargin**: Derived field - the maintenance margin as a percentage of initial margin, calculated as `(1 - SL/Initial) * 100`

The TVP supports **partial updates**: NULL values in the TVP are replaced with the existing value using `ISNULL(src, dest)` - only explicitly provided values are changed.

The `@AppLoginName` parameter injects the ops user identity into `CONTEXT_INFO` for SQL Server audit trail purposes.

---

## 2. Business Logic

### 2.1 Validation

**What**: Prevents invalid margin configurations from being applied.

**Columns/Parameters Involved**: `src.InitialMarginInAssetCurrency`, `src.StopLossMarginInAssetCurrency`

**Rules**:
- RAISERROR(60202) if any instrument row has BOTH StopLossMargin and InitialMargin as NULL (no values to update)
- RAISERROR(60202) if the effective InitialMarginInAssetCurrency would be 0 after applying ISNULL (division by zero in derived column)

### 2.2 Margin Parameter Update with Derived Column

**What**: Updates three margin columns, with Leverage1MaintenanceMargin automatically derived.

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.StopLossMarginInAssetCurrency`, `InitialMarginInAssetCurrency`, `Leverage1MaintenanceMargin`

**Rules**:
- StopLossMarginInAssetCurrency = ISNULL(src.StopLossMarginInAssetCurrency, dest.StopLossMarginInAssetCurrency)
- InitialMarginInAssetCurrency = ISNULL(src.InitialMarginInAssetCurrency, dest.InitialMarginInAssetCurrency)
- Leverage1MaintenanceMargin = (1 - effective_SL / effective_Initial) * 100 (derived, always recalculated)
- NULL TVP values fall back to existing column values

**Example**:
```
InitialMargin = 10%, StopLossMargin = 8%
Leverage1MaintenanceMargin = (1 - 8/10) * 100 = 20%
Meaning: stop-loss triggers when 20% of initial margin is consumed
```

### 2.3 Context Info for Audit Trail

**What**: Embeds the ops user identity into the SQL Server session context for audit tracking.

**Rules**:
- If @AppLoginName != '' -> CAST(@AppLoginName AS VARBINARY(128)) -> SET CONTEXT_INFO
- Context info can be read by triggers or audit processes via CONTEXT_INFO() function

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instruments_NewMargin | Trade.InstrumentsIDListSetMarginTbl READONLY | NO | - | CODE-BACKED | TVP containing InstrumentID + new margin values. NULL for a margin column means "keep existing value". Must have at least one non-NULL margin value per row, and InitialMargin must not be 0. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | The Ops API user login name. If provided, set into CONTEXT_INFO for SQL audit trail. Empty string means no context info is set. |

**Trade.InstrumentsIDListSetMarginTbl columns (UDT):**

| Column | Type | Confidence | Description |
|--------|------|------------|-------------|
| InstrumentID | INT | CODE-BACKED | The futures instrument to update |
| InitialMarginInAssetCurrency | DECIMAL/FLOAT | CODE-BACKED | New initial margin amount in asset currency (NULL = keep existing) |
| StopLossMarginInAssetCurrency | DECIMAL/FLOAT | CODE-BACKED | New SL margin amount in asset currency (NULL = keep existing) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP type | Trade.InstrumentsIDListSetMarginTbl | UDT | Table type defining input structure |
| Validation + UPDATE | Trade.ProviderToInstrument | Modifier | Validates and updates three margin columns |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by Ops API for futures margin management.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetInstrumentMarginsForFutures (procedure)
|- Trade.InstrumentsIDListSetMarginTbl (UDT - TVP type)
|- Trade.ProviderToInstrument (table - validation source + update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsIDListSetMarginTbl | User Defined Type | TVP type for batch instrument margin input |
| Trade.ProviderToInstrument | Table | Validation check and UPDATE target for three margin columns |

### 6.2 Objects That Depend On This

No dependents found - called by Ops API for futures margin updates.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Non-null validation | Validation | RAISERROR(60202) if both margins are NULL in TVP row |
| Non-zero initial | Validation | RAISERROR(60202) if effective InitialMargin = 0 (prevents division by zero) |
| Derived column | Logic | Leverage1MaintenanceMargin always recalculated from the effective SL and Initial margin values |
| Partial update | Logic | ISNULL(src, dest) pattern - NULL TVP values preserve existing column values |
| Context info audit | Audit | @AppLoginName set into CONTEXT_INFO for session-level identity tracking |

---

## 8. Sample Queries

### 8.1 Update margins for a batch of futures instruments

```sql
DECLARE @MarginUpdates Trade.InstrumentsIDListSetMarginTbl
INSERT INTO @MarginUpdates (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
VALUES
    (5001, 500.00, 400.00),   -- Both margins updated
    (5002, 750.00, NULL)       -- Only initial margin updated

EXEC Trade.SetInstrumentMarginsForFutures
    @Instruments_NewMargin = @MarginUpdates,
    @AppLoginName = 'ops_user@etoro.com'
```

### 8.2 Check current futures margins

```sql
SELECT InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency,
    Leverage1MaintenanceMargin
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID IN (5001, 5002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetInstrumentMarginsForFutures | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetInstrumentMarginsForFutures.sql*
