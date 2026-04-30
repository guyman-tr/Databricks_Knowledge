# Trade.FuturesInstrumentsInitialMarginByProviderMapping

> Per-instrument-per-provider initial margin requirements for futures contracts, defining the cash margin needed to open a futures position with each liquidity provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + ProviderID (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table stores the initial margin requirements for each futures instrument per liquidity provider. Initial margin is the cash deposit required to open a futures position - it varies by instrument (based on contract volatility and size) and by provider (each provider sets its own margin requirements). This per-provider mapping is essential because eToro routes trades through multiple liquidity providers, each with different margin schedules.

Without this table, the platform could not validate whether a customer has sufficient margin to open a futures position, or correctly calculate the margin requirements displayed to users. The margin amounts must match the provider's requirements to avoid rejected trades or margin calls.

Settings are managed through `Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping` (updates existing mappings) and `Trade.UpdateFuturesOpsConfigurations` (bulk operations). Temporal versioning provides full audit trail of margin changes, critical for regulatory compliance in futures trading.

---

## 2. Business Logic

### 2.1 Provider-Specific Margin Requirements

**What**: The same futures instrument can have different margin requirements depending on which liquidity provider executes the trade.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`, `InitialMargin`

**Rules**:
- Each InstrumentID + ProviderID combination has exactly one InitialMargin value
- InitialMargin is expressed in the instrument's currency (dollars for US futures)
- Values range widely: from $6 for highly liquid instruments to $1,200+ for expensive contracts
- When a customer opens a futures position, the system looks up the margin for the instrument and the selected provider

### 2.2 Dual Audit Trail

**What**: Changes are tracked both by database login and application login for regulatory compliance.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- DbLoginName captures the database-level identity via SUSER_NAME()
- AppLoginName captures the application-level identity via CONTEXT_INFO()
- Temporal versioning tracks all historical margin values - essential for resolving disputes about margin requirements at time of trade

---

## 3. Data Overview

| InstrumentID | ProviderID | InitialMargin | Meaning |
|-------------|-----------|---------------|---------|
| 1 | 99 | 6.00 | Very low margin for a highly liquid instrument - likely a micro/mini futures contract |
| 2 | 99 | 20.00 | Low-margin instrument via provider 99 |
| 3 | 99 | 1,200.00 | High-margin instrument - likely a standard-size commodity or index futures contract |
| 481 | 99 | 165.00 | Mid-range margin for a specialty futures instrument |
| 482 | 99 | 61.11 | Moderate margin - non-round number suggests external provider-set requirement |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument identifier for the futures contract. References Trade.Instrument. Part of composite PK. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider that sets this margin requirement. References Trade.Provider. Part of composite PK. Each provider has its own margin schedule. |
| 3 | InitialMargin | decimal(10,2) | NO | - | CODE-BACKED | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Range: $6 to $1,200+. |
| 4 | DbLoginName | AS (suser_name()) | NO | Computed | VERIFIED | Computed column capturing the Windows/SQL login that made the change. Database-level audit trail. |
| 5 | AppLoginName | AS (CONVERT(varchar(500), context_info())) | NO | Computed | VERIFIED | Computed column capturing the application-level login via CONTEXT_INFO(). Application-level audit trail. |
| 6 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | VERIFIED | System-managed temporal column marking when this margin configuration became effective. |
| 7 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | VERIFIED | System-managed temporal column marking when this margin configuration was superseded. 9999-12-31 = current active version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Futures instrument these margin requirements apply to |
| ProviderID | Trade.Provider | Implicit | Liquidity provider setting the margin requirement |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | - | Writer | Updates margin values |
| Trade.UpdateFuturesOpsConfigurations | - | Writer | Bulk operations margin configuration |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | - | Reader | Retrieves current margin mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | Stored Procedure | Updates margin requirements |
| Trade.UpdateFuturesOpsConfigurations | Stored Procedure | Bulk configuration management |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | Stored Procedure | Reads current margin data |
| History.FuturesInstrumentsInitialMarginByProviderMapping | History Table | Temporal history of all margin changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FuturesInstrumentsInitialMarginByProviderMapping | CLUSTERED PK | InstrumentID, ProviderID | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FuturesInstrumentsInitialMarginByProviderMapping | PRIMARY KEY | One row per instrument-provider combination |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | Tracks row validity period |
| SYSTEM_VERSIONING | TEMPORAL | History tracked in History.FuturesInstrumentsInitialMarginByProviderMapping |
| Tr_T_FuturesInstrumentsInitialMarginByProviderMapping_INSERT | TRIGGER (FOR INSERT) | Self-update to trigger temporal versioning on initial insert |

---

## 8. Sample Queries

### 8.1 Get margin requirements for a specific instrument across all providers
```sql
SELECT InstrumentID, ProviderID, InitialMargin
FROM   Trade.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
```

### 8.2 Find instruments with highest margin requirements
```sql
SELECT TOP 20 InstrumentID, ProviderID, InitialMargin
FROM   Trade.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
ORDER BY InitialMargin DESC
```

### 8.3 View margin change history for an instrument
```sql
SELECT InstrumentID, ProviderID, InitialMargin,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM   History.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
ORDER BY SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FuturesInstrumentsInitialMarginByProviderMapping | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FuturesInstrumentsInitialMarginByProviderMapping.sql*
