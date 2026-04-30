# Price.OMPDThresholdValues

> Per-instrument threshold value store for OMPD (Order Management Price Deviation), holding both the Pips and Percentage threshold values for each instrument so the active type can be switched without data loss.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, ThresholdType) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

OMPDThresholdValues is the value store for the two-table OMPD system. While `Price.OMPDActiveThreshold` acts as the selector (which type is active per instrument), this table stores the actual numeric threshold values for both threshold types. The composite PK `(InstrumentID, ThresholdType)` means each instrument can have up to two rows - one for Pips (ThresholdType=1) and one for Percentage (ThresholdType=2).

This design allows administrators to pre-configure both threshold types for an instrument and freely switch between them by updating `OMPDActiveThreshold.ThresholdType` without touching this table. For example, instrument 1 (EUR/USD) has both a Pips value (40) and a Percentage value (50%) stored - switching the active type from Pips to Percentage is a single UPDATE to OMPDActiveThreshold.

The table uses temporal versioning (SYSTEM_VERSIONING) to track all changes to threshold values in `History.OMPDThresholdValues`. Unusually, the computed audit column is named `UserName` (using `suser_name()`) rather than the more common `DbLoginName` pattern seen in other Price schema tables. Also notable: InstrumentID has NO explicit FK constraint (unlike OMPDActiveThreshold which FKs to Trade.InstrumentMetaData), likely for performance given the high-volume insert/update pattern.

The CRUD API spans 9 stored procedures covering create, read (with pagination, by instrument IDs, by exchange IDs), update, delete, and the active-threshold-driven update operations.

---

## 2. Business Logic

### 2.1 Dual Threshold Value Storage per Instrument

**What**: Each instrument stores threshold values for both threshold types simultaneously. Only one type is "active" at any time (per OMPDActiveThreshold), but both values are preserved.

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdType`, `Value`

**Rules**:
- Composite PK (InstrumentID, ThresholdType) enforces at most one value per (instrument, type) pair
- An instrument can have 0, 1, or 2 rows: one for Pips only, one for Percentage only, or both
- `CreateInstrumentOMPDThresholdByInstrumentId` validates: (1) ThresholdType exists in Dictionary.OMPDThresholdType, (2) InstrumentID exists in Trade.InstrumentMetaData, (3) (InstrumentID, ThresholdType) combination does not already exist - then inserts
- No FK on InstrumentID in this table (unlike OMPDActiveThreshold) - allows faster bulk operations
- Value is decimal(20,2) - supports very large pips values (e.g., 40.00 pips) and percentage values (e.g., 50.00%)

### 2.2 Active-Type Value Resolution

**What**: The active threshold value for an instrument is the row where ThresholdType matches OMPDActiveThreshold.ThresholdType.

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdType`, `Value`

**Rules**:
- Join pattern: `OMPDActiveThreshold AT JOIN OMPDThresholdValues TV ON AT.InstrumentID = TV.InstrumentID AND AT.ThresholdType = TV.ThresholdType`
- Only the active type's row is returned; the inactive type's value remains in the table unused (but preserved)
- `GetActiveOMPDThresholdByInstrumentIds` accepts optional @ThresholdType filter, @PageNumber, @PageSize, @SortOrder for bulk retrieval with pagination

### 2.3 Threshold Value Update

**What**: Values can be updated independently of type switching.

**Columns/Parameters Involved**: `InstrumentID`, `ThresholdType`, `Value`

**Rules**:
- `UpdateInstrumentOMPDThresholdByInstrumentId` updates Value for an (InstrumentID, ThresholdType) combination
- `UpdateInstrumentThresholdsWithActiveThreshold` performs a broader update using active threshold logic
- Temporal versioning means all previous values are preserved in History.OMPDThresholdValues with SysStartTime/SysEndTime

---

## 3. Data Overview

| InstrumentID | ThresholdType | Value | Meaning |
|---|---|---|---|
| 1 (EUR/USD) | 1 (Pips) | 40.00 | EUR/USD Pips threshold: deviation beyond 40 pips triggers OMPD protection |
| 1 (EUR/USD) | 2 (Percentage) | 50.00 | EUR/USD also has a 50% percentage threshold configured (inactive - active is Pips per OMPDActiveThreshold) |
| 2 | 2 (Percentage) | (value) | Instrument 2 uses Percentage type (active per OMPDActiveThreshold.ThresholdType=2) |

Note: Both threshold types are stored per instrument. OMPDActiveThreshold determines which value is enforced.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. The instrument for which this threshold value applies. NOTE: No explicit FK constraint in DDL (unlike OMPDActiveThreshold) - InstrumentID validity is enforced by the insert procedure (checks Trade.InstrumentMetaData), not the DB constraint layer. |
| 2 | ThresholdType | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. FK to Dictionary.OMPDThresholdType. The threshold unit type for this value row: 1=Pips (absolute price deviation in pips), 2=Percentage (proportional price deviation). One row per (instrument, type) combination. (Dictionary.OMPDThresholdType) |
| 3 | Value | decimal(20,2) | NOT NULL | - | VERIFIED | The numeric threshold amount. Interpretation depends on ThresholdType: if Pips, represents an absolute deviation in pips (e.g., 40.00 = 40 pips); if Percentage, represents a percentage deviation (e.g., 50.00 = 50%). Orders are flagged or rejected if the price deviates beyond this value from the order-time price. |
| 4 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. Use FOR SYSTEM_TIME AS OF to query historical threshold configurations. |
| 5 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Active rows have '9999-12-31...'. Historical versions in History.OMPDThresholdValues. |
| 6 | UserName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Named UserName (not DbLoginName as in other Price tables). No AppLoginName or HostName computed columns present in this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ThresholdType | Dictionary.OMPDThresholdType | FK (FK_ThresholdType) | The threshold unit type: 1=Pips, 2=Percentage |
| InstrumentID | Trade.InstrumentMetaData | Procedural (no FK constraint) | Procedure-enforced: CreateInstrumentOMPDThresholdByInstrumentId validates against Trade.InstrumentMetaData before INSERT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetActiveOMPDThresholdByInstrumentIds | InstrumentID, ThresholdType | JOIN (with OMPDActiveThreshold) | Returns active threshold value per instrument via join on (InstrumentID, ThresholdType) |
| Price.GetInstrumentsOMPDThresholdByInstrumentIds | InstrumentID, ThresholdType | READER | Returns all threshold rows (both types) for specified instruments with pagination |
| Price.GetInstrumentsOMPDThresholdByExchangeIds | InstrumentID | READER | Returns all threshold rows for instruments belonging to specified exchanges |
| Price.CreateInstrumentOMPDThresholdByInstrumentId | InstrumentID, ThresholdType | WRITER | Inserts new threshold value with validation |
| Price.UpdateInstrumentOMPDThresholdByInstrumentId | InstrumentID, ThresholdType | MODIFIER | Updates Value for an existing (instrument, type) row |
| Price.DeleteOMPDThresholdByInstrumentID | InstrumentID | DELETER | Removes all threshold values for an instrument |
| Price.UpdateInstrumentThresholdsWithActiveThreshold | InstrumentID | MODIFIER | Updates thresholds based on active threshold logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.OMPDThresholdValues (table)
|- Dictionary.OMPDThresholdType (table, FK target: ThresholdTypeID=1 Pips, ThresholdTypeID=2 Percentage)
|- Trade.InstrumentMetaData (table, procedural dependency - no FK constraint)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OMPDThresholdType | Table | FK target - ThresholdType must reference a valid type (1=Pips, 2=Percentage) |
| Trade.InstrumentMetaData | Table | Procedural dependency - insert proc validates InstrumentID exists here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetActiveOMPDThresholdByInstrumentIds | Stored Procedure | JOIN source - returns active threshold value per instrument |
| Price.GetInstrumentsOMPDThresholdByInstrumentIds | Stored Procedure | READER - returns all threshold rows by instrument list |
| Price.GetInstrumentsOMPDThresholdByExchangeIds | Stored Procedure | READER - returns all threshold rows by exchange filter |
| Price.CreateInstrumentOMPDThresholdByInstrumentId | Stored Procedure | WRITER - inserts new (instrument, type, value) row |
| Price.UpdateInstrumentOMPDThresholdByInstrumentId | Stored Procedure | MODIFIER - updates Value for existing row |
| Price.DeleteOMPDThresholdByInstrumentID | Stored Procedure | DELETER - removes rows for an instrument |
| Price.UpdateInstrumentThresholdsWithActiveThreshold | Stored Procedure | MODIFIER - updates thresholds using active threshold logic |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OMPDThresholdValues | CLUSTERED PK | InstrumentID ASC, ThresholdType ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_OMPDThresholdValues | PRIMARY KEY | Composite PK - one value per (instrument, threshold type) pair |
| FK_ThresholdType | FK | ThresholdType -> Dictionary.OMPDThresholdType(ThresholdTypeID) |
| DF_OMPDThresholdValues_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_OMPDThresholdValues_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.OMPDThresholdValues |

---

## 8. Sample Queries

### 8.1 View all threshold values with type names

```sql
SELECT
    TV.InstrumentID,
    TV.ThresholdType,
    OTT.Name AS TypeName,
    TV.Value,
    TV.SysStartTime AS ConfiguredSince
FROM Price.OMPDThresholdValues TV WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = TV.ThresholdType
ORDER BY TV.InstrumentID, TV.ThresholdType;
```

### 8.2 Get both threshold values alongside the active type designation

```sql
SELECT
    TV.InstrumentID,
    TV.ThresholdType,
    OTT.Name AS TypeName,
    TV.Value,
    CASE WHEN AT.ThresholdType = TV.ThresholdType THEN 'ACTIVE' ELSE 'inactive' END AS Status
FROM Price.OMPDThresholdValues TV WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = TV.ThresholdType
LEFT JOIN Price.OMPDActiveThreshold AT WITH (NOLOCK)
    ON AT.InstrumentID = TV.InstrumentID
ORDER BY TV.InstrumentID, TV.ThresholdType;
```

### 8.3 View change history for a specific instrument's threshold

```sql
SELECT
    InstrumentID,
    ThresholdType,
    Value,
    UserName,
    SysStartTime,
    SysEndTime
FROM Price.OMPDThresholdValues
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1
ORDER BY ThresholdType, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.OMPDThresholdValues | Type: Table | Source: etoro/etoro/Price/Tables/Price.OMPDThresholdValues.sql*
