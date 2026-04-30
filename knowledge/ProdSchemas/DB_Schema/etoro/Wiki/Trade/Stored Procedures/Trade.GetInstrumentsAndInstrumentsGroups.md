# Trade.GetInstrumentsAndInstrumentsGroups

> Returns every instrument-to-group assignment with display names and group names, enabling ops tools to present and manage instrument group memberships.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + GroupID with resolved names |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsAndInstrumentsGroups is a parameterless bulk-read procedure that returns the full instrument-to-group membership list with human-readable names. Each row represents one instrument belonging to one group, with the instrument's display name (from Trade.InstrumentMetaData) and the group's name (from Dictionary.TradingInstrumentGroups) resolved via JOINs. An instrument can belong to multiple groups and a group can contain many instruments.

This procedure exists to power the Trading Ops Tool's instrument group management screens. Operators need to see which instruments belong to which groups (e.g., "US Stocks", "Crypto", "Forex Majors") and manage those assignments. Without this procedure, ops tools would need to perform the three-table JOIN client-side.

The procedure is called by trading-opstool-api and OpsFlowAPI. It serves as the read counterpart to group management operations like Trade.DeleteInstrumentGroup.

---

## 2. Business Logic

### 2.1 Instrument Group Membership Resolution

**What**: Resolves the many-to-many relationship between instruments and groups into a flat list with human-readable names.

**Columns/Parameters Involved**: `Trade.InstrumentGroups.InstrumentID`, `Trade.InstrumentGroups.GroupID`, `Trade.InstrumentMetaData.InstrumentDisplayName`, `Dictionary.TradingInstrumentGroups.GroupName`

**Rules**:
- INNER JOINs ensure only valid combinations are returned - instruments must have metadata and groups must exist in the dictionary
- An instrument with no group assignments produces no rows
- A group with no instruments produces no rows
- No ordering is applied; results come in natural table order

**Diagram**:
```
Trade.InstrumentGroups         Dictionary.TradingInstrumentGroups
+---------------+-------+     +--------+-----------------+
| InstrumentID  | GroupID|     | GroupID | GroupName       |
|     1001      |   1   | --> |   1    | US Stocks       |
|     1001      |   3   | --> |   3    | Popular         |
|     1002      |   2   |     |   2    | Crypto          |
+---------------+-------+     +--------+-----------------+
        |
        v
Trade.InstrumentMetaData
+---------------+----------------------+
| InstrumentID  | InstrumentDisplayName|
|     1001      | Apple Inc.           |
|     1002      | Bitcoin              |
+---------------+----------------------+
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.InstrumentGroups.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. Appears once per group membership. |
| R2 | InstrumentDisplayName | nvarchar | Trade.InstrumentMetaData.InstrumentDisplayName | CODE-BACKED | Human-readable display name for the instrument (e.g., "Apple Inc.", "Bitcoin", "EUR/USD"). Resolved from InstrumentMetaData via InstrumentID JOIN. |
| R3 | GroupID | int | Trade.InstrumentGroups.GroupID | CODE-BACKED | Group identifier. FK to Dictionary.TradingInstrumentGroups. Determines which classification group this instrument belongs to. |
| R4 | GroupName | nvarchar | Dictionary.TradingInstrumentGroups.GroupName | CODE-BACKED | Human-readable group name (e.g., "US Stocks", "Crypto", "Popular Investors"). Resolved from Dictionary.TradingInstrumentGroups via GroupID JOIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentGroups | Read (SELECT) | Many-to-many junction table linking instruments to groups |
| JOIN | Dictionary.TradingInstrumentGroups | Lookup | Resolves GroupID to GroupName |
| JOIN | Trade.InstrumentMetaData | Lookup | Resolves InstrumentID to InstrumentDisplayName |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| trading-opstool-api | EXECUTE | Permission | Ops tool for instrument group management |
| OpsFlowAPI | EXECUTE | Permission | Operations flow API |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsAndInstrumentsGroups (procedure)
+-- Trade.InstrumentGroups (table)
+-- Dictionary.TradingInstrumentGroups (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroups | Table | INNER JOIN - source of instrument-group assignments |
| Dictionary.TradingInstrumentGroups | Table | INNER JOIN - resolves GroupID to GroupName |
| Trade.InstrumentMetaData | Table | INNER JOIN - resolves InstrumentID to InstrumentDisplayName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| trading-opstool-api | DB User | EXECUTE permission for ops group management |
| OpsFlowAPI | DB User | EXECUTE permission for operations flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No validation; returns all matching rows.

---

## 8. Sample Queries

### 8.1 Get all instrument-group assignments

```sql
EXEC Trade.GetInstrumentsAndInstrumentsGroups;
```

### 8.2 Find all instruments in a specific group

```sql
SELECT  ig.InstrumentID,
        imd.InstrumentDisplayName,
        dtg.GroupName
FROM    Trade.InstrumentGroups ig WITH (NOLOCK)
        INNER JOIN Dictionary.TradingInstrumentGroups dtg WITH (NOLOCK) ON ig.GroupID = dtg.GroupID
        INNER JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON ig.InstrumentID = imd.InstrumentID
WHERE   dtg.GroupName = 'US Stocks';
```

### 8.3 Count instruments per group

```sql
SELECT  dtg.GroupID,
        dtg.GroupName,
        COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentGroups ig WITH (NOLOCK)
        INNER JOIN Dictionary.TradingInstrumentGroups dtg WITH (NOLOCK) ON ig.GroupID = dtg.GroupID
GROUP BY dtg.GroupID, dtg.GroupName
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsAndInstrumentsGroups | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsAndInstrumentsGroups.sql*
