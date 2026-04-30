# Trade.FuturesInstrumentRiskSettings

> Per-instrument risk buffer settings for futures contracts, defining the percentage buffer added to stop-loss and take-profit levels for futures instruments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table stores risk management parameters specific to futures instruments. Each row defines the stop-loss and take-profit percentage buffers applied to a specific futures instrument. These buffers provide a safety margin beyond the exact SL/TP levels, accommodating the higher volatility and price gaps typical of futures markets.

The table exists because futures contracts have different risk characteristics than equities or forex - they often trade with significant overnight gaps and lower liquidity periods. The percentage buffers ensure that SL/TP orders are set with appropriate distance from the current price, preventing premature triggering due to normal futures volatility.

Settings are managed through `Trade.UpsertFuturesInstrumentRiskSettings` (which inserts or updates settings) and `Trade.UpdateFuturesOpsConfigurations` (which handles bulk operations configuration). The temporal versioning provides a full audit trail of all configuration changes, including who made the change (DbLoginName) and from which application (AppLoginName via CONTEXT_INFO).

---

## 2. Business Logic

### 2.1 Futures Risk Buffer Configuration

**What**: Each futures instrument has individually calibrated SL/TP buffers reflecting its risk profile.

**Columns/Parameters Involved**: `InstrumentID`, `StopLossPercentageBuffer`, `TakeProfitPercentageBuffer`

**Rules**:
- StopLossPercentageBuffer: minimum distance (as percentage) that a stop-loss must be set from the current price for this futures instrument
- TakeProfitPercentageBuffer: minimum distance (as percentage) that a take-profit must be set from the current price
- Values vary significantly by instrument: from 1-3% for liquid futures (e.g., major indices) up to 30% for volatile/illiquid contracts
- These buffers are applied on top of any standard platform-wide risk rules

### 2.2 Dual Audit Trail

**What**: Changes are tracked both by database login and application login for full traceability.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- DbLoginName captures the Windows/SQL login via SUSER_NAME()
- AppLoginName captures the application-level identity via CONTEXT_INFO() - set by the calling application before executing the stored procedure
- The INSERT trigger forces temporal versioning to capture the initial state

---

## 3. Data Overview

| InstrumentID | StopLossPercentageBuffer | TakeProfitPercentageBuffer | Meaning |
|-------------|-------------------------|--------------------------|---------|
| 18 | 3.00 | 3.00 | Moderate volatility futures instrument - 3% buffer on both SL and TP, suggesting a well-traded contract |
| 27 | 2.00 | 2.00 | Lower volatility instrument - tighter 2% buffers, likely a highly liquid major index future |
| 481 | 2.00 | 1.00 | Asymmetric buffers - tighter TP (1%) vs SL (2%), allowing closer profit-taking while providing more crash protection |
| 482 | 10.50 | 11.50 | High-volatility futures contract - very wide buffers reflecting significant price swings or low liquidity |
| 484 | 30.00 | 30.00 | Extremely volatile or illiquid contract - 30% buffer required, likely a thinly traded commodity or specialty future |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument identifier for the futures contract. References Trade.Instrument. One row per futures instrument with custom risk settings. |
| 2 | StopLossPercentageBuffer | decimal(10,2) | NO | - | CODE-BACKED | Minimum percentage distance required between the current price and a stop-loss order for this futures instrument. Higher values = more conservative risk buffer. Range observed: 1.00 to 30.00. |
| 3 | TakeProfitPercentageBuffer | decimal(10,2) | NO | - | CODE-BACKED | Minimum percentage distance required between the current price and a take-profit order for this futures instrument. Can differ from SL buffer for asymmetric risk management. Range observed: 1.00 to 30.00. |
| 4 | DbLoginName | AS (suser_name()) | NO | Computed | VERIFIED | Computed column capturing the Windows/SQL login that made the change. Audit trail for database-level identity. |
| 5 | AppLoginName | AS (CONVERT(varchar(500), context_info())) | NO | Computed | VERIFIED | Computed column capturing the application-level login via CONTEXT_INFO(). Set by the calling application before executing the configuration stored procedure. |
| 6 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | VERIFIED | System-managed temporal column marking when this configuration version became effective. |
| 7 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | VERIFIED | System-managed temporal column marking when this configuration version was superseded. 9999-12-31 = current active version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Futures instrument these risk settings apply to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpsertFuturesInstrumentRiskSettings | - | Writer | Inserts or updates risk settings |
| Trade.UpdateFuturesOpsConfigurations | - | Writer | Bulk operations configuration update |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpsertFuturesInstrumentRiskSettings | Stored Procedure | Upserts risk settings for instruments |
| Trade.UpdateFuturesOpsConfigurations | Stored Procedure | Bulk configuration management |
| History.FuturesInstrumentRiskSettings | History Table | Temporal history of all changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FuturesInstrumentRiskSettings | CLUSTERED PK | InstrumentID ASC | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FuturesInstrumentRiskSettings | PRIMARY KEY | One row per instrument |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | Tracks row validity period |
| SYSTEM_VERSIONING | TEMPORAL | History tracked in History.FuturesInstrumentRiskSettings |
| Tr_T_FuturesInstrumentRiskSettings_INSERT | TRIGGER (FOR INSERT) | Self-update to trigger temporal versioning on initial insert |

---

## 8. Sample Queries

### 8.1 Get risk settings for a specific instrument
```sql
SELECT InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer
FROM   Trade.FuturesInstrumentRiskSettings WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
```

### 8.2 Find instruments with the widest risk buffers
```sql
SELECT InstrumentID,
       StopLossPercentageBuffer,
       TakeProfitPercentageBuffer
FROM   Trade.FuturesInstrumentRiskSettings WITH (NOLOCK)
ORDER BY StopLossPercentageBuffer DESC
```

### 8.3 View configuration change history
```sql
SELECT InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM   History.FuturesInstrumentRiskSettings WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
ORDER BY SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FuturesInstrumentRiskSettings | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FuturesInstrumentRiskSettings.sql*
