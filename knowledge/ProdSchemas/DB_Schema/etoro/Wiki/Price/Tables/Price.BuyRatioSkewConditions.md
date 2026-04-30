# Price.BuyRatioSkewConditions

> Per-instrument configuration table defining the minimum eligibility conditions for the price skew algorithm - an instrument must meet both the minimum client position count (MinCIDCount) and minimum USD trading volume (MinVolumeUSD) thresholds before buy/sell ratio-based skewing is activated for it.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK, FK to Trade.Instrument) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

Price.BuyRatioSkewConditions is a guard configuration table for the price skew system. It answers the question: "For which instruments should skewing even be attempted?" Not every instrument warrants active price skewing - low-volume or thinly-traded instruments may have a 90% buy ratio simply because only a handful of clients hold positions. Activating skew in those cases would be unnecessary and potentially harmful.

This table defines, per instrument, the minimum conditions that must be satisfied before the skew algorithm will act:
- **MinCIDCount**: the minimum number of client positions (buy + sell combined) that must exist before skew is triggered. Ensures skew only activates when there is meaningful client exposure.
- **MinVolumeUSD**: the minimum USD trading volume that must be present. Ensures skew only activates when the notional exposure is material enough to warrant intervention.

Both columns default to 0, meaning instruments without a row in this table (or with default values) have no minimum thresholds - skewing can activate regardless of position count or volume.

Data lifecycle: rows are managed manually or via pricing operations tooling. One row per instrument. Changes are fully audited via ASM-generated triggers to History.AuditHistory, and all versions are preserved in History.BuyRatioSkewConditions via SQL Server temporal (system versioning).

---

## 2. Business Logic

### 2.1 Skew Activation Gate

**What**: Before the skew algorithm computes a skew offset, it checks BuyRatioSkewConditions to determine if the instrument qualifies for skewing.

**Columns/Parameters Involved**: `InstrumentID`, `MinCIDCount`, `MinVolumeUSD`

**Rules**:
- MinCIDCount = 0 (default): no minimum position count; skew can activate regardless of how few clients hold the instrument
- MinCIDCount > 0: skew only activates when the total open position count (BuyPositionCount + SellPositionCount in Price.BuyRatio) meets or exceeds this value
- MinVolumeUSD = 0 (default): no minimum volume requirement
- MinVolumeUSD > 0: skew only activates when the USD-denominated trading volume meets or exceeds this value
- Both conditions must be satisfied simultaneously (AND logic): an instrument with sufficient CID count but insufficient volume will not be skewed
- If an instrument has no row in this table: treated as MinCIDCount=0, MinVolumeUSD=0 (no gate)

**Diagram**:
```
Skew Algorithm cycle for instrument X:
  1. Read Price.BuyRatio (latest ratio for instrument X)
  2. Check Price.BuyRatioSkewConditions WHERE InstrumentID = X
       MinCIDCount threshold: BuyPositionCount + SellPositionCount >= MinCIDCount? -> YES/NO
       MinVolumeUSD threshold: current USD volume >= MinVolumeUSD? -> YES/NO
  3. If BOTH pass: proceed to Price.BuyRatioThresholds -> compute Skew -> write Price.ActiveSkew
     If EITHER fails: no skew applied; Price.ActiveSkew.SkewBid/SkewAsk = 0 for this instrument
```

### 2.2 Temporal Auditing

**What**: Every change to this configuration is tracked for compliance and operational traceability.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- System versioning: all historical versions stored in History.BuyRatioSkewConditions
- SysStartTime/SysEndTime: auto-managed by SQL Server temporal table mechanism
- DbLoginName (computed suser_name()): SQL login of last modifier; auto-set by SQL Server
- AppLoginName (computed context_info()): application identity when context_info is set by caller
- ASM audit triggers write MinCIDCount and MinVolumeUSD changes to History.AuditHistory with I/U/D operation codes

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count (this environment) | 0 (read replica / pre-population state) |
| One row per instrument | Yes - InstrumentID is the PK |
| Default values | MinCIDCount=0, MinVolumeUSD=0 (no threshold) |

*Expected data pattern (inferred from schema and defaults):*

| InstrumentID | MinCIDCount | MinVolumeUSD | Meaning |
|---|---|---|---|
| (e.g.) 1 | 0 | 0.00 | EUR/USD: no minimum thresholds - skew activates for any imbalance |
| (e.g.) 100 | 50 | 10000.00 | Equity: must have 50+ positions and $10K+ volume before skewing |
| (e.g.) 500 | 100 | 50000.00 | High-volume instrument: strict eligibility gates before skewing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. CLUSTERED PK. FK to Trade.Instrument (FK_BuyRatioSkewConditions_InstrumentID). One row per instrument defines its skew eligibility conditions. |
| 2 | MinCIDCount | int | NOT NULL | 0 | CODE-BACKED | Minimum total open position count (CID = Client/position Count) that must exist before skew activates for this instrument. DEFAULT 0 = no minimum requirement. When > 0: the sum of BuyPositionCount + SellPositionCount from Price.BuyRatio must meet or exceed this value. Prevents skewing of illiquid instruments with only a handful of client positions. |
| 3 | MinVolumeUSD | money | NOT NULL | 0 | CODE-BACKED | Minimum USD-denominated trading volume required before skew activates. DEFAULT 0 = no minimum. Money type (accurate to 4 decimal places) represents USD notional. Prevents skewing of low-notional instruments where the exposure risk does not justify price adjustment. |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login name of the last row modifier. Auto-set on every DML; cannot be overridden. Used for DB-level audit tracking. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from SQL Server context_info(). Populated when the calling service sets context_info before DML. NULL when not set. Provides app-level audit context alongside DbLoginName. |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start. Auto-managed by SQL Server system versioning. Used for point-in-time queries via FOR SYSTEM_TIME AS OF. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31...' | CODE-BACKED | Temporal row validity end. '9999-12-31...' = currently active. Historical versions stored in History.BuyRatioSkewConditions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_BuyRatioSkewConditions_InstrumentID) | Skew conditions are defined per instrument; FK enforces referential integrity |

### 5.2 Referenced By (other objects point to this)

No objects explicitly reference this table in the SSDT repository. The skew algorithm reads it at runtime (application code).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.BuyRatioSkewConditions (table)
  |-- FK -> Trade.Instrument (instrument must exist)
  |-- Read by: skew algorithm (application code, not in SSDT)
  |-- Sibling: Price.BuyRatioThresholds (threshold values for activated instruments)
  |-- Sibling: Price.BuyRatio (runtime ratio data)
  |-- Output: Price.ActiveSkew (downstream result)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK - instrument must exist before skew conditions can be defined for it |

### 6.2 Objects That Depend On This

No SSDT objects explicitly depend on this table (consumed by application-layer skew algorithm).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BuyRatioSkewConditions | CLUSTERED PK | InstrumentID ASC | - | - | Active, FILLFACTOR=95 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BuyRatioSkewConditions_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| DF (MinCIDCount) | DEFAULT | MinCIDCount = 0 - no minimum client count by default |
| DF (MinVolumeUSD) | DEFAULT | MinVolumeUSD = 0 - no minimum volume by default |
| DF_BuyRatioSkewConditions_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_BuyRatioSkewConditions_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | History in History.BuyRatioSkewConditions |
| AuditDelete_Price_BuyRatioSkewConditions | TRIGGER (DELETE) | Logs MinCIDCount, MinVolumeUSD old values to History.AuditHistory |
| AuditInsert_Price_BuyRatioSkewConditions | TRIGGER (INSERT) | Logs MinCIDCount, MinVolumeUSD new values to History.AuditHistory |
| AuditUpdate_Price_BuyRatioSkewConditions | TRIGGER (UPDATE) | Logs old/new MinCIDCount, MinVolumeUSD when changed |
| TRG_T_BuyRatioSkewConditions | TRIGGER (INSERT) | ASM no-op placeholder: self-update on InstrumentID |

---

## 8. Sample Queries

### 8.1 View all skew eligibility conditions

```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, DbLoginName, SysStartTime
FROM Price.BuyRatioSkewConditions WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.2 Instruments with strict eligibility requirements

```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD
FROM Price.BuyRatioSkewConditions WITH (NOLOCK)
WHERE MinCIDCount > 0 OR MinVolumeUSD > 0
ORDER BY MinVolumeUSD DESC, MinCIDCount DESC;
```

### 8.3 Audit history for a specific instrument's conditions

```sql
SELECT AuditDate, UserName, AppName, ColumnName, OldValue, NewValue, Operation
FROM History.AuditHistory WITH (NOLOCK)
WHERE TableName = 'BuyRatioSkewConditions'
  AND PK_Value = '1'  -- replace with InstrumentID
ORDER BY AuditDate DESC;
```

### 8.4 Point-in-time conditions (temporal query)

```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, SysStartTime, SysEndTime
FROM Price.BuyRatioSkewConditions
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.BuyRatioSkewConditions | Type: Table | Source: etoro/etoro/Price/Tables/Price.BuyRatioSkewConditions.sql*
