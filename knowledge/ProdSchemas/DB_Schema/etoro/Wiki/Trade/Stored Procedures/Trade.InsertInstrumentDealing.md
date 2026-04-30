# Trade.InsertInstrumentDealing

> Provisions a new instrument's dealing/hedging configuration in a single atomic transaction: inserts rows into Hedge.InstrumentConfiguration, Hedge.AccountInstrumentConfiguration (multi-account), Trade.LiquidityProviderContracts, Hedge.InstrumentGroupsMapping, and Hedge.HBCAccountConfiguration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT (all inserts keyed to this instrument) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentDealing is the **instrument dealing setup SP** - a single atomic provisioning call that sets up all hedging and dealing configuration required when a new instrument is onboarded to the trading platform. In one transaction it configures: the instrument's hedging parameters (circuit breakers, deal size thresholds), per-account execution configuration for multiple liquidity accounts, liquidity provider contract mappings, instrument group memberships, and HBC (High Book Capacity) account configuration.

This SP exists because onboarding a new instrument requires consistent, all-or-nothing setup across multiple cross-schema tables. Without it, operators would need to issue five separate INSERT statements manually with the risk of partial failure leaving the instrument in an inconsistent state. By wrapping everything in a transaction with ROLLBACK on failure, the SP guarantees that either the instrument is fully configured or nothing is changed.

The commented-out `Hedge.OrderTypeConfiguration` INSERT suggests that order type configuration was originally planned as part of this SP but was removed or deferred.

---

## 2. Business Logic

### 2.1 Transaction Boundary (All-or-Nothing)

**What**: All five INSERT statements execute within a single explicit transaction. Any error rolls back all changes.

**Rules**:
- `BEGIN TRAN` before first INSERT
- `COMMIT` after last INSERT
- `BEGIN CATCH ... ROLLBACK; THROW END CATCH` ensures partial failure rolls back everything
- No partial instrument configuration can persist

### 2.2 AccountID Parsing (Comma-Separated String)

**What**: The @AccountIDs parameter accepts a comma-separated list of liquidity account IDs, enabling configuration for multiple accounts in one call.

**Columns/Parameters Involved**: `@AccountIDs VARCHAR(100)`, `@AccountIDTable`

**Rules**:
- `STRING_SPLIT(@AccountIDs, ',')` splits the string into individual values
- Each value is `TRIM`-ed and `CAST`-ed to INT
- Results are stored in a local table variable `@AccountIDTable (AccountID INT)`
- The same accounts are used for both `Hedge.AccountInstrumentConfiguration` (step 2.3) and `Hedge.HBCAccountConfiguration` (step 2.6) inserts

### 2.3 Hedge Instrument Configuration

**What**: Inserts the core instrument-level hedging parameters.

**Target**: `Hedge.InstrumentConfiguration`

**Mapped Values**:
- `InstrumentID` = @InstrumentID
- `MinOrderSizeForExecutionInEToroUnits` = 0 (hardcoded default)
- `HBCDealSizeThresholdAlertInEToroUnits` = @HBCDealSizeThresholdAlertInEToroUnits
- `HBCMaxDealSizeThresholdRejectInEToroUnits` = @HBCDealSizeThresholdAlertInEToroUnits (same as alert threshold)
- `ManualMaxDealSizeInEToroUnits` = @ManualMaxDealSizeInEToroUnits
- `SpreadReturnFactor` = 1 (hardcoded default)
- `CircuitBreakerLimit` = @CircuitBreakerLimit
- `CircuitBreakerWarningLimit` = @CircuitBreakerWarningLimit

### 2.4 Per-Account Instrument Configuration

**What**: Inserts execution parameters for each liquidity account in @AccountIDs.

**Target**: `Hedge.AccountInstrumentConfiguration`

**Mapped Values**:
- `AccountID` = each value from @AccountIDTable
- `InstrumentID` = @InstrumentID
- `LimitRoundPrecision` = @LimitRoundPrecision
- `MaxExecutionUnitsThreshold`, `MaxExecutionUnitsUpperBound`, `MaxExecutionUnitsLowerBound`, `ExecutionUnitsStep`, `MaxRequestedPerInterval`, `IntervalPeriodSeconds` = all 0 (default placeholders)

### 2.5 Liquidity Provider Contracts

**What**: Inserts one contract record per LP provider in the TVP.

**Target**: `Trade.LiquidityProviderContracts`

**Columns/Parameters Involved**: `@LiquidityProviderContracts Trade.LiquidityProviderContractTableType`

**Rules**:
- `@FromDate = GETUTCDATE()` (current UTC time as contract start)
- `@ToDate = '2100-01-01'` (far-future date as contract end = effectively indefinite)
- TVP provides: LiquidityProviderID, Ticker, ExchangeID, RateConversionFactor
- InstrumentID is @InstrumentID (all contracts for this instrument)

### 2.6 Instrument Group Mappings

**What**: Assigns the instrument to one or more hedge instrument groups.

**Target**: `Hedge.InstrumentGroupsMapping`

**Columns/Parameters Involved**: `@GroupIDs Hedge.InstrumentGroupsMapping READONLY`

**Rules**:
- TVP provides GroupID and IsActive for each group assignment
- Allows instrument to belong to multiple hedge groups (e.g., for reporting or hedging strategies)

### 2.7 HBC Account Configuration

**What**: Sets up HBC (High Book Capacity) parameters for each account.

**Target**: `Hedge.HBCAccountConfiguration`

**Rules**:
- One row per AccountID from @AccountIDTable
- InstrumentID = @InstrumentID
- `ThresholdInEToroUnits`, `MaxTimeMS`, `MaxRejectRetries`, `MinOrderSizeInEToroUnits`, `MaxOrderSizeInEToroUnits`, `UseExecutionRateWithSpread`, `MinOrderSizeUSDForHBC` = all 0 (initial placeholder defaults; configured post-insert by ops)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being onboarded. Used as the FK key in all five INSERT statements across the hedging and dealing configuration tables. |
| 2 | @HBCDealSizeThresholdAlertInEToroUnits | INT | NO | - | CODE-BACKED | HBC (High Book Capacity) alert threshold in eToro units. Inserted as both HBCDealSizeThresholdAlertInEToroUnits and HBCMaxDealSizeThresholdRejectInEToroUnits in Hedge.InstrumentConfiguration (alert and reject thresholds set to the same initial value). |
| 3 | @ManualMaxDealSizeInEToroUnits | INT | NO | - | CODE-BACKED | Maximum deal size for manual (non-HBC) dealing in eToro units. Defines the ceiling for individual trade order size outside of HBC routing. |
| 4 | @CircuitBreakerLimit | DECIMAL(14,4) | NO | - | CODE-BACKED | Hard circuit breaker limit. If position exposure exceeds this, the circuit breaker trips and further dealing is blocked to prevent runaway risk. |
| 5 | @CircuitBreakerWarningLimit | DECIMAL(12,4) | NO | - | CODE-BACKED | Warning threshold for the circuit breaker. Alerts are raised before the hard limit is reached, giving time to intervene. |
| 6 | @AccountIDs | VARCHAR(100) | NO | - | CODE-BACKED | Comma-separated list of liquidity account IDs (e.g., '101,102,103'). Parsed via STRING_SPLIT + TRIM + CAST. Each account gets rows in Hedge.AccountInstrumentConfiguration and Hedge.HBCAccountConfiguration. |
| 7 | @LimitRoundPrecision | SMALLINT | NO | - | CODE-BACKED | Decimal precision for order limit rounding for this instrument's accounts. Stored in Hedge.AccountInstrumentConfiguration.LimitRoundPrecision. Ensures order prices are rounded to the correct number of decimal places per exchange/instrument rules. |
| 8 | @LiquidityProviderContracts | Trade.LiquidityProviderContractTableType | NO | - | CODE-BACKED | TVP (READONLY) of liquidity provider contracts to assign to this instrument. Each row provides LiquidityProviderID, Ticker, ExchangeID, RateConversionFactor. Inserted into Trade.LiquidityProviderContracts with open-ended date range (now to 2100-01-01). |
| 9 | @GroupIDs | Hedge.InstrumentGroupsMapping | NO | - | CODE-BACKED | TVP (READONLY) of hedge instrument group assignments. Each row provides GroupID and IsActive. Inserted into Hedge.InstrumentGroupsMapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (inserts into) | Hedge.InstrumentConfiguration | WRITER (cross-schema) | Core instrument hedging parameters |
| (inserts into) | Hedge.AccountInstrumentConfiguration | WRITER (cross-schema) | Per-account execution parameters for each AccountID |
| (inserts into) | Trade.LiquidityProviderContracts | WRITER | LP contract mappings for this instrument |
| (inserts into) | Hedge.InstrumentGroupsMapping | WRITER (cross-schema) | Instrument group assignments |
| (inserts into) | Hedge.HBCAccountConfiguration | WRITER (cross-schema) | HBC configuration per account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations tooling (external) | EXEC Trade.InsertInstrumentDealing | Caller | Called by ops/admin tooling when onboarding a new instrument to the dealing system; no internal SP callers found |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentDealing (procedure)
|- Hedge.InstrumentConfiguration (table - cross-schema)
|- Hedge.AccountInstrumentConfiguration (table - cross-schema)
|- Trade.LiquidityProviderContracts (table)
|- Hedge.InstrumentGroupsMapping (table - cross-schema)
|- Hedge.HBCAccountConfiguration (table - cross-schema)
|- Trade.LiquidityProviderContractTableType (UDT, TVP type)
`-- Hedge.InstrumentGroupsMapping UDT (TVP type, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentConfiguration | Table (cross-schema) | Insert: instrument hedging config |
| Hedge.AccountInstrumentConfiguration | Table (cross-schema) | Insert: per-account execution config |
| Trade.LiquidityProviderContracts | Table | Insert: LP contract mappings |
| Hedge.InstrumentGroupsMapping | Table (cross-schema) | Insert: group assignments |
| Hedge.HBCAccountConfiguration | Table (cross-schema) | Insert: HBC config per account |
| Trade.LiquidityProviderContractTableType | UDT | TVP type for LP contracts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations/admin tooling | Application | Calls this SP to fully provision a new instrument's dealing config |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | BEGIN TRAN / COMMIT / ROLLBACK | All five INSERTs are atomic; partial failure rolls back everything |
| STRING_SPLIT parsing | TRIM + CAST | @AccountIDs parsed at runtime; invalid (non-integer) values will cause CAST error and rollback |
| HBCMaxDealSizeThresholdRejectInEToroUnits | Hardcoded | Set to same value as HBCDealSizeThresholdAlertInEToroUnits (ops can update post-insert) |
| LP contract dates | Hardcoded | FromDate = GETUTCDATE(), ToDate = 2100-01-01 (effectively indefinite) |
| Zero defaults | Hardcoded | AccountInstrumentConfiguration and HBCAccountConfiguration limits set to 0 (placeholder, require post-insert configuration) |

---

## 8. Sample Queries

### 8.1 Verify instrument dealing configuration after insert

```sql
-- Check hedge instrument config
SELECT * FROM Hedge.InstrumentConfiguration WITH (NOLOCK) WHERE InstrumentID = @InstrumentID

-- Check account configurations
SELECT * FROM Hedge.AccountInstrumentConfiguration WITH (NOLOCK) WHERE InstrumentID = @InstrumentID

-- Check LP contracts
SELECT * FROM Trade.LiquidityProviderContracts WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers (ops tooling external) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentDealing | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentDealing.sql*
