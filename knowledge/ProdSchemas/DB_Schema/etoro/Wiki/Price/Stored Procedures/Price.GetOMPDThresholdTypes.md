# Price.GetOMPDThresholdTypes

> Returns all OMPD threshold type definitions (ThresholdTypeID + Name) from Dictionary.OMPDThresholdType - the reference data lookup for the OMPD threshold type enumeration.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full dictionary |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetOMPDThresholdTypes returns the complete list of OMPD (Order Management Price Deviation) threshold type definitions. This is the reference data lookup for the OMPD threshold system - it tells callers what the valid ThresholdType values mean.

Currently, OMPD supports two threshold types:
- **ThresholdType=1** (Pips): threshold expressed as an absolute price deviation in pips
- **ThresholdType=2** (Percentage): threshold expressed as a percentage price deviation

This procedure exists so that pricing configuration UIs can populate dropdown menus for threshold type selection without hardcoding the enum values. It also provides the human-readable names to display alongside numeric type IDs.

---

## 2. Business Logic

### 2.1 Full Dictionary Read

**What**: Unconditionally returns all rows from Dictionary.OMPDThresholdType.

**Rules**:
- No filters, no parameters
- No NOLOCK hint - reads with default isolation level (shared locks, brief)
- Result is ordered by the clustered index order of Dictionary.OMPDThresholdType
- Currently 2 rows: ThresholdTypeID=1 (Pips) and ThresholdTypeID=2 (Percentage)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Returns all threshold type definitions. |

**Result set columns** (2 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | ThresholdTypeID | The numeric type identifier. Currently: 1=Pips, 2=Percentage. Used in Price.OMPDThresholdValues.ThresholdType and Price.OMPDActiveThreshold.ThresholdType. |
| 2 | Name | Human-readable type name (e.g., "Pips", "Percentage"). Displayed in the configuration UI threshold type dropdown. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ThresholdTypeID | Dictionary.OMPDThresholdType | READER | Full-table read of the OMPD threshold type enumeration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (OMPD configuration UI) | - | CALLER | Called to populate threshold type dropdown/enumeration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetOMPDThresholdTypes (procedure)
+-- Dictionary.OMPDThresholdType (table) - threshold type reference data
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OMPDThresholdType | Table | FROM source - all threshold type definitions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (OMPD configuration API / UI) | External | Calls to retrieve valid threshold type options |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON. No NOLOCK. No error handling. Minimal procedure - purely a Dictionary table read. The companion read procedures in the OMPD family are: GetInstrumentsOMPDThresholdByExchangeIds (threshold values by exchange), GetInstrumentsOMPDThresholdByInstrumentIds (threshold values by instrument), GetActiveOMPDThresholdByInstrumentIds (active threshold per instrument).

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Price.GetOMPDThresholdTypes;
-- Returns: 1='Pips', 2='Percentage'
```

### 8.2 Equivalent manual query

```sql
SELECT [ThresholdTypeID], [Name]
FROM Dictionary.OMPDThresholdType WITH (NOLOCK)
ORDER BY ThresholdTypeID;
```

### 8.3 Join threshold values with type names

```sql
SELECT TV.InstrumentID, TV.ThresholdType, OTT.Name AS TypeName, TV.Value
FROM Price.OMPDThresholdValues TV WITH (NOLOCK)
JOIN Dictionary.OMPDThresholdType OTT WITH (NOLOCK)
    ON OTT.ThresholdTypeID = TV.ThresholdType
ORDER BY TV.InstrumentID, TV.ThresholdType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetOMPDThresholdTypes | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetOMPDThresholdTypes.sql*
