# Dictionary.OverNightFeePattern

> System-versioned lookup table defining the overnight fee calculation patterns that control how rollover/swap fees are applied to positions held past market close.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (System-Versioned / Temporal) |
| **Key Identifier** | OverNightFeePatternID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **History Table** | History.OverNightFeePattern |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.OverNightFeePattern defines the calculation strategies used to compute overnight (rollover/swap) fees on trading positions held past market close. Each instrument is assigned one of these patterns, which determines how the platform calculates the daily financing charge applied to open CFD positions.

Overnight fees are a core revenue mechanism for CFD brokers — they represent the cost of financing a leveraged position overnight. The pattern assigned to an instrument determines whether the standard fee calculation applies, whether non-leveraged buy positions also incur fees, or whether fees must be set manually by the trading operations team.

This table is referenced by `Dictionary.InterestRate` (which stores the actual rate values per instrument/currency) and consumed by `Trade.CalcOverNightFeeRates` and related procedures that compute the nightly fee amounts. Being system-versioned, all changes to fee patterns are audited via `History.OverNightFeePattern`. The INSERT trigger ensures the Description column is populated correctly during row creation.

---

## 2. Business Logic

### 2.1 Fee Calculation Strategy Selection

**What**: Each overnight fee pattern determines which calculation algorithm the trading engine uses when computing daily financing charges.

**Columns/Parameters Involved**: `OverNightFeePatternID`, `OverNightFeePatternName`, `Description`

**Rules**:
- **Regular (0)**: Standard overnight fee — applies to leveraged positions only. Non-leveraged buy positions (1x leverage, real stock) are exempt from overnight fees. This is the default and most common pattern.
- **WithNonLeverageFee (1)**: Extended overnight fee — applies to ALL positions including non-leveraged buys. Used for instruments where even unleveraged ownership incurs financing costs (e.g., certain ETFs or instruments with carrying costs).
- **Manual (2)**: Fees are not calculated programmatically — must be set manually by Trading Operations. Used for exotic instruments or special arrangements where standard formulas don't apply.

### 2.2 Temporal Audit Trail

**What**: All changes to fee patterns are tracked with full version history.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- Every INSERT/UPDATE is automatically versioned by SQL Server temporal tables
- Previous versions are stored in History.OverNightFeePattern with time ranges
- DbLoginName and AppLoginName (computed columns) capture who made the change — critical for regulatory audit of fee configuration changes

**Diagram**:
```
Instrument Configuration
        │
        ▼
  OverNightFeePatternID assigned to instrument
        │
        ├──→ 0 (Regular): Leveraged positions only incur overnight fees
        ├──→ 1 (WithNonLeverageFee): ALL positions incur overnight fees
        └──→ 2 (Manual): Trading Ops sets fee manually
        │
        ▼
  Trade.CalcOverNightFeeRates uses pattern to select calculation path
```

---

## 3. Data Overview

| OverNightFeePatternID | OverNightFeePatternName | Description | Meaning |
|---|---|---|---|
| 0 | Regular | Regular overnight fee pattern which does not consider non-leveraged buy overnight fees | Default pattern for most instruments — only leveraged CFD positions are charged overnight financing. Real stock positions (1x leverage) are exempt. |
| 1 | WithNonLeverageFee | Regular overnight fee pattern which considers non-leveraged overnight fees | Extended fee pattern where even non-leveraged (1x) buy positions incur overnight charges. Applied to instruments with inherent carrying costs. |
| 2 | Manual | Overnight fee pattern that will not be calculated programmatically and must be set manually by the user | Trading Operations manually sets the overnight fee rate. Used for exotic instruments, special client arrangements, or instruments where standard formulas are inadequate. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OverNightFeePatternID | tinyint | NO | - | VERIFIED | Fee calculation pattern identifier: **0**=Regular (leveraged-only fees), **1**=WithNonLeverageFee (all positions incur fees), **2**=Manual (set by Trading Ops). Referenced by Dictionary.InterestRate and Trade.CalcOverNightFeeRates. |
| 2 | OverNightFeePatternName | varchar(50) | NO | - | VERIFIED | Machine-readable pattern name used in trading engine configuration. Values: "Regular", "WithNonLeverageFee", "Manual". |
| 3 | Description | varchar(max) | YES | - | VERIFIED | Human-readable explanation of the fee pattern's behavior. Set via INSERT trigger (TRG_INSERT_OverNightFeePattern). |
| 4 | DbLoginName | computed | NO | - | CODE-BACKED | Computed: `suser_name()`. Captures the SQL Server login that last modified the row. Audit trail for fee configuration changes. |
| 5 | AppLoginName | computed | NO | - | CODE-BACKED | Computed: `CONVERT(varchar(500), context_info())`. Captures the application-level identity from the session's CONTEXT_INFO. Provides application-layer audit when DB login is a service account. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | System-versioning start time — when this version of the row became active. GENERATED ALWAYS AS ROW START. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | System-versioning end time — when this version was superseded. GENERATED ALWAYS AS ROW END. Active rows have 9999-12-31. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.InterestRate | OverNightFeePatternID | Implicit | Interest rate records reference the fee pattern to determine calculation strategy |
| Dictionary.InterestRateOverride | OverNightFeePatternID | Implicit | Override interest rates also reference the fee pattern |
| Trade.CalcOverNightFeeRates | OverNightFeePatternID | Read | Procedure selects calculation algorithm based on fee pattern |
| Trade.CalcOverNightFeeRates_TRDOPS | OverNightFeePatternID | Read | Trading operations version of overnight fee calculation |
| Trade.GetAllInterestRates | OverNightFeePatternID | Read | Returns all interest rates including their fee pattern |
| Trade.GetInstrumentInterestRates | OverNightFeePatternID | Read | Returns instrument-specific interest rates with pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.OverNightFeePattern (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRate | Table | References OverNightFeePatternID for fee calculation strategy |
| Dictionary.InterestRateOverride | Table | References OverNightFeePatternID for override rates |
| History.OverNightFeePattern | Table | Temporal history of all fee pattern changes |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reads pattern to select calculation algorithm |
| Trade.CalcOverNightFeeRates_TRDOPS | Stored Procedure | Trading Ops version of fee calculation |
| Trade.GetAllInterestRates | Stored Procedure | Returns rates with pattern info |
| Trade.GetAllInterestRates_TRDOPS | Stored Procedure | Trading Ops version |
| Trade.GetInstrumentInterestRates | Stored Procedure | Per-instrument rate lookup |
| Trade.GetInstrumentInterestRates_TRDOPS | Stored Procedure | Trading Ops version |
| Trade.GetEnumMappings_TRDOPS | Stored Procedure | Enum dictionary loading |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DONFP | CLUSTERED PK | OverNightFeePatternID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DONFP | PRIMARY KEY | Unique fee pattern identifier |
| SYSTEM_TIME PERIOD | TEMPORAL | SysStartTime to SysEndTime — enables automatic versioning |
| TRG_INSERT_OverNightFeePattern | TRIGGER (FOR INSERT) | Re-applies Description on INSERT to ensure computed audit columns capture correct context |

---

## 8. Sample Queries

### 8.1 List all overnight fee patterns with descriptions
```sql
SELECT  OverNightFeePatternID,
        OverNightFeePatternName,
        Description
FROM    Dictionary.OverNightFeePattern WITH (NOLOCK)
ORDER BY OverNightFeePatternID;
```

### 8.2 Find instruments using non-standard fee patterns
```sql
SELECT  ir.InstrumentID,
        c.SymbolFull,
        onfp.OverNightFeePatternName,
        onfp.Description
FROM    Dictionary.InterestRate ir WITH (NOLOCK)
JOIN    Dictionary.OverNightFeePattern onfp WITH (NOLOCK)
        ON ir.OverNightFeePatternID = onfp.OverNightFeePatternID
JOIN    Dictionary.Currency c WITH (NOLOCK)
        ON ir.InstrumentID = c.InstrumentID
WHERE   ir.OverNightFeePatternID <> 0;
```

### 8.3 View fee pattern change history
```sql
SELECT  OverNightFeePatternID,
        OverNightFeePatternName,
        Description,
        SysStartTime,
        SysEndTime
FROM    Dictionary.OverNightFeePattern
FOR SYSTEM_TIME ALL
ORDER BY OverNightFeePatternID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OverNightFeePattern | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OverNightFeePattern.sql*
