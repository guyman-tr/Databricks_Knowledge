# History.FeeCalculationTypes

> SQL Server system-versioned temporal history table for Dictionary.FeeCalculationTypes, recording every change to the two-entry lookup that defines overnight fee calculation methods (exposure-based vs. loan-based).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (FeeCalculationTypeID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [DICTIONARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Dictionary.FeeCalculationTypes`, a two-row lookup table that defines the methods by which overnight/holding fees are calculated on eToro positions. SQL Server's system-versioning manages this table transparently: any UPDATE or DELETE on `Dictionary.FeeCalculationTypes` causes the previous row state to be written here with SysStartTime/SysEndTime bracketing the validity window.

`Dictionary.FeeCalculationTypes` defines two fee calculation methods: `ExposureFormula` (0) where fee config values represent dollars per unit of exposure, and `LoanFormula` (1) where fee config values represent daily interest as a percentage. These types are referenced by `Trade.InstrumentToFeeConfig` and `Trade.InstrumentToFeeConfigV2` to determine how to interpret the fee rate values stored per instrument. The choice of calculation method fundamentally changes how overnight fees are computed for a position.

With only 8 history rows for 2 entries since September 2025, this history table reflects system provisioning events (initial data loads) rather than operational changes. The content of the lookup itself (type names and descriptions) is stable; changes here would indicate dictionary restructuring rather than routine operations.

---

## 2. Business Logic

### 2.1 Fee Calculation Method Dichotomy

**What**: The two fee calculation types represent fundamentally different overnight/holding fee mathematics applied to positions.

**Columns/Parameters Involved**: `FeeCalculationTypeID`, `FeeCalculationTypeName`, `Description`

**Rules**:
- **0 = ExposureFormula**: Fee configuration values in `Trade.InstrumentToFeeConfigV2` are denominated in $/unit. The fee is calculated as: `ExposureInUnits * FeeRate` where FeeRate is in USD per unit. Used for instruments where holding cost scales with position size in units.
- **1 = LoanFormula**: Fee configuration values are daily interest rates expressed as a percentage. Fee calculated as: `PositionValue * (DailyInterestRate / 100)`. Used for instruments where holding cost is a loan on the notional value (e.g., leveraged positions where the broker effectively lends capital).
- The type is stored on the instrument fee configuration row (Trade.InstrumentToFeeConfigV2.FeeCalculationTypeID), so different instruments can use different calculation methods
- Procedures `Trade.CalcOverNightFeeRates` and `Trade.CalculatePositionOvernightFee` branch on this value to apply the correct formula

### 2.2 SQL Server System-Versioned Temporal Table Pattern

**What**: Dictionary.FeeCalculationTypes is system-versioned, providing a full change history of the lookup definition itself, useful if type names or descriptions are ever updated.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`

**Rules**:
- Standard temporal history pattern: CLUSTERED index on (SysEndTime, SysStartTime)
- No INSERT trigger on the source table (unlike Trade-schema temporal tables) - INSERTs are not separately captured
- All 8 history rows stem from system provisioning/migration events in Sept-Nov 2025, confirming this dictionary is highly stable
- DbLoginName and AppLoginName are computed columns in Dictionary.FeeCalculationTypes, materialized here at version creation

---

## 3. Data Overview

| FeeCalculationTypeID | FeeCalculationTypeName | Description | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|
| 0 | ExposureFormula | Exposure calculation. Values are $/unit | 2025-09-01 | 2025-09-01 | First version (initial load). Short window (66s) before a re-provisioning event on the same day. |
| 1 | LoanFormula | Loan calculation. Values are dailyInterest (%) | 2025-09-01 | 2025-09-01 | First version for LoanFormula, same provisioning batch. |
| 0 | ExposureFormula | Exposure calculation. Values are $/unit | 2025-10-27 | 2025-11-13 | Third version: recharged during Oct 2025 migration. Stable for ~17 days before another system update. |

*Current dictionary (Dictionary.FeeCalculationTypes): 0=ExposureFormula, 1=LoanFormula. Both have been stable since 2025-11-16.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeeCalculationTypeID | tinyint | NO | - | CODE-BACKED | Fee calculation method identifier. Matches Dictionary.FeeCalculationTypes PK. Values in the current dictionary: 0=ExposureFormula ($/unit fee rates), 1=LoanFormula (daily interest % fee rates). tinyint supports up to 255 types, though only 2 are currently defined. Multiple rows with the same FeeCalculationTypeID represent successive name/description versions. |
| 2 | FeeCalculationTypeName | varchar(50) | NO | - | CODE-BACKED | Short identifier name for the calculation method. Current values: "ExposureFormula" and "LoanFormula". Referenced in procedure logic to label fee types. Stable - name changes here would require corresponding application changes. |
| 3 | Description | varchar(max) | NO | - | CODE-BACKED | Human-readable explanation of the calculation method and the units of the fee values. Current values: "Exposure calculation. Values are $/unit" and "Loan calculation. Values are dailyInterest (%)". The description encodes the units expected in Trade.InstrumentToFeeConfigV2 fee rate columns. Stored in TEXTIMAGE_ON [DICTIONARY] due to varchar(max) type. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) of the session that made the change. Computed column in Dictionary.FeeCalculationTypes, materialized at version creation. Observed: "TRAD\bonniegr", "TRAD\eladav" in history rows - DBA provisioning events. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level login from context_info() at time of change. Computed as CONVERT(varchar(500), context_info()). NULL in all observed history rows - changes were direct SQL sessions without context_info set. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version of the lookup row became active in Dictionary.FeeCalculationTypes. GENERATED ALWAYS AS ROW START in the source table. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. GENERATED ALWAYS AS ROW END. CLUSTERED index leading column. SysEndTime='9999-12-31' in current Dictionary rows (not this history table). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Temporal history tables carry no FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.FeeCalculationTypes | SYSTEM_VERSIONING | Temporal history source | All superseded row versions from the source lookup are automatically routed here by SQL Server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FeeCalculationTypes (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FeeCalculationTypes | Table | Source temporal table - routes superseded versions here automatically |
| Trade.InstrumentToFeeConfigV2 | Table | FK to Dictionary.FeeCalculationTypes.FeeCalculationTypeID; this history table audits changes to the lookup those rows reference |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FeeCalculationTypes | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [DICTIONARY] filegroup) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, CHECK, UNIQUE, or DEFAULT constraints.

---

## 8. Sample Queries

### 8.1 What were the fee calculation types defined on a specific date?

```sql
SELECT
    fct.FeeCalculationTypeID,
    fct.FeeCalculationTypeName,
    fct.Description
FROM Dictionary.FeeCalculationTypes FOR SYSTEM_TIME AS OF '2025-10-01T00:00:00' fct WITH (NOLOCK)
ORDER BY fct.FeeCalculationTypeID;
```

### 8.2 Full change history of the fee calculation type definitions

```sql
SELECT
    h.FeeCalculationTypeID,
    h.FeeCalculationTypeName,
    h.Description,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSeconds
FROM History.FeeCalculationTypes h WITH (NOLOCK)
ORDER BY h.FeeCalculationTypeID, h.SysStartTime;
```

### 8.3 Find all instrument fee configs using each calculation type

```sql
SELECT
    fct.FeeCalculationTypeID,
    fct.FeeCalculationTypeName,
    fct.Description,
    COUNT(cfg.InstrumentID) AS InstrumentCount
FROM Dictionary.FeeCalculationTypes fct WITH (NOLOCK)
LEFT JOIN Trade.InstrumentToFeeConfigV2 cfg WITH (NOLOCK)
    ON cfg.FeeCalculationTypeID = fct.FeeCalculationTypeID
GROUP BY fct.FeeCalculationTypeID, fct.FeeCalculationTypeName, fct.Description
ORDER BY fct.FeeCalculationTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.CalcOverNightFeeRates, Trade.CalculatePositionOvernightFee) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FeeCalculationTypes | Type: Table | Source: etoro/etoro/History/Tables/History.FeeCalculationTypes.sql*
