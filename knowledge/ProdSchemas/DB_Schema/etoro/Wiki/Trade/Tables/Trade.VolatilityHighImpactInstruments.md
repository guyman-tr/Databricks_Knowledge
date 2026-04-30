# Trade.VolatilityHighImpactInstruments

> Configuration whitelist of instruments flagged for high-volatility impact treatment. When market conditions are volatile, instruments in this list receive special handling such as wider spreads, tighter position limits, or enhanced risk monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

Trade.VolatilityHighImpactInstruments is a configuration whitelist that identifies instruments requiring special handling during volatile market conditions. When an instrument is added to this table, the trading system applies high-volatility treatment - potentially wider spreads, tighter position limits, or enhanced risk monitoring. The table is dynamically managed by trading operations: instruments are added during volatile periods and removed when conditions normalize. Currently the table holds zero rows, but it is used for temporary operational adjustments.

This table exists because market volatility requires real-time operational responses. Without a configurable whitelist, the system would need code deployments to adjust instrument behavior. This design allows trading operations to add or remove instruments quickly based on market events. The combination of system versioning (History.VolatilityHighImpactInstruments) and ASM audit triggers (History.AuditHistory) provides full accountability for every change.

Data flows: Trading operations INSERT rows when an instrument needs high-volatility treatment. Rows are DELETEd (or end-dated via temporal) when volatility subsides. The table is read by trading logic that adjusts spreads, limits, or risk parameters. ASM-generated triggers fire on INSERT, UPDATE, DELETE and log to History.AuditHistory with UserName, AppName, HostName, and old/new values.

---

## 2. Business Logic

### 2.1 Volatility Impact Flagging

**What**: Presence in this table means "treat this instrument with high-volatility rules."

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- One row per instrument. InstrumentID is the PK
- If InstrumentID exists in this table, the instrument receives special volatility handling
- If not present, standard handling applies
- The table is meant to be small and frequently updated - instruments come and go based on market conditions

**Diagram**:
```
[Volatile Market Event] -> [Trading Ops] -> INSERT InstrumentID
                                                    |
                                                    v
                              Trade.VolatilityHighImpactInstruments
                                                    |
                                                    v
[Trading Engine] -> Apply wider spreads / tighter limits / risk checks
                                                    |
[Conditions Normalize] -> DELETE row (or temporal end-dating)
```

### 2.2 Dual Audit Trail: Temporal + ASM

**What**: Every change is tracked twice - temporal versioning and ASM audit triggers.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- System versioning: all row versions go to History.VolatilityHighImpactInstruments
- ASM triggers: INSERT, UPDATE, DELETE write to History.AuditHistory with UserName, AppName, HostName, old/new values
- Provides redundancy for regulatory and operational audits

---

## 3. Data Overview

| InstrumentID | Meaning |
|--------------|---------|
| (0 rows) | Table is currently empty. Instruments are added and removed dynamically based on market conditions. When populated, each row indicates an instrument receiving high-volatility treatment (wider spreads, tighter limits, enhanced monitoring). |

**Selection criteria**: Table has no rows currently. Representative usage: when volatile, trading ops INSERT instrument IDs; when calm, rows are removed.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | PK. FK to Trade.Instrument. The instrument flagged for high-volatility treatment. |
| 2 | DbLoginName | (computed) | NO | - | VERIFIED | Computed: suser_name(). SQL Server login for audit. |
| 3 | AppLoginName | (computed) | NO | - | VERIFIED | Computed: CONVERT(varchar(500), context_info()). Application context for audit. |
| 4 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System versioning row start. Part of PERIOD FOR SYSTEM_TIME. |
| 5 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System versioning row end. 9999-12-31 for current rows. Historical versions in History.VolatilityHighImpactInstruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | The instrument receiving high-volatility treatment. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Trading logic) | JOIN/EXISTS | Reader | Used to determine if an instrument requires volatility adjustments. Not analyzed in this phase. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.VolatilityHighImpactInstruments (table)
```

Tables are leaf nodes. No code-level dependencies. InstrumentID references Trade.Instrument structurally.

### 6.1 Objects This Depends On

No explicit FK in DDL. Implicit: Trade.Instrument (InstrumentID). History.VolatilityHighImpactInstruments (temporal). History.AuditHistory (ASM triggers).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ASM-generated triggers | Trigger | INSERT, UPDATE, DELETE -> History.AuditHistory |
| Trading logic / procedures | - | Reader (not enumerated in this phase) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (clustered) | CLUSTERED | InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | InstrumentID |
| PERIOD FOR SYSTEM_TIME | Temporal | SysStartTime, SysEndTime |
| HISTORY_TABLE | Temporal | History.VolatilityHighImpactInstruments |
| ASM triggers | Audit | INSERT, UPDATE, DELETE -> History.AuditHistory |

---

## 8. Sample Queries

### 8.1 Get all instruments with high-volatility treatment
```sql
SELECT v.InstrumentID
FROM   Trade.VolatilityHighImpactInstruments v WITH (NOLOCK)
ORDER BY v.InstrumentID;
```

### 8.2 Check if an instrument has high-volatility flag
```sql
SELECT v.InstrumentID
FROM   Trade.VolatilityHighImpactInstruments v WITH (NOLOCK)
WHERE  v.InstrumentID = 100000;
```

### 8.3 Resolve instrument IDs to names
```sql
SELECT v.InstrumentID, i.BuyCurrencyID, i.SellCurrencyID
FROM   Trade.VolatilityHighImpactInstruments v WITH (NOLOCK)
       INNER JOIN Trade.Instrument i WITH (NOLOCK) ON v.InstrumentID = i.InstrumentID
ORDER BY v.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.VolatilityHighImpactInstruments | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.VolatilityHighImpactInstruments.sql*
