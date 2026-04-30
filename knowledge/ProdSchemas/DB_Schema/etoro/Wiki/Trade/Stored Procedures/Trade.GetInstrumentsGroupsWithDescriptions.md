# Trade.GetInstrumentsGroupsWithDescriptions

> Returns all instrument group definitions with their descriptions from the dictionary, enabling ops tools to display and manage the full group catalog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GroupID + GroupName + Description from Dictionary.TradingInstrumentGroups |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsGroupsWithDescriptions is a parameterless getter procedure that returns the complete catalog of instrument group definitions from Dictionary.TradingInstrumentGroups. Each row is a group classification (e.g., "US Stocks", "Crypto", "Popular") with its human-readable description explaining what the group represents and which instruments it contains.

This procedure exists to support the Trading Ops Tool and OpsFlow API group management screens. Operators need the full group list with descriptions to understand what each group means when assigning instruments to groups. It complements Trade.GetInstrumentsAndInstrumentsGroups, which returns the actual instrument-group assignments.

Called by trading-opstool-api and OpsFlowAPI.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct dictionary lookup returning all groups.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | GroupID | int | Dictionary.TradingInstrumentGroups.GroupID | CODE-BACKED | Group identifier. PK. Used in Trade.InstrumentGroups to assign instruments to groups. |
| R2 | GroupName | nvarchar | Dictionary.TradingInstrumentGroups.GroupName | CODE-BACKED | Short group name (e.g., "US Stocks", "Crypto", "Popular Investors"). Used as display label in ops tools. |
| R3 | Description | nvarchar | Dictionary.TradingInstrumentGroups.Description | CODE-BACKED | Human-readable description of the group's purpose and contents (e.g., "Instruments listed on US exchanges including NYSE, NASDAQ"). Displayed in ops tool group management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.TradingInstrumentGroups | Read (SELECT) | Dictionary table containing all instrument group definitions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| trading-opstool-api | EXECUTE | Permission | Ops tool for group management |
| OpsFlowAPI | EXECUTE | Permission | Operations flow API |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsGroupsWithDescriptions (procedure)
+-- Dictionary.TradingInstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TradingInstrumentGroups | Table | SELECT - returns all group definitions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| trading-opstool-api | DB User | EXECUTE permission |
| OpsFlowAPI | DB User | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all group definitions

```sql
EXEC Trade.GetInstrumentsGroupsWithDescriptions;
```

### 8.2 Count instruments per group with descriptions

```sql
SELECT  dtg.GroupID,
        dtg.GroupName,
        dtg.Description,
        COUNT(ig.InstrumentID) AS InstrumentCount
FROM    Dictionary.TradingInstrumentGroups dtg WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentGroups ig WITH (NOLOCK) ON dtg.GroupID = ig.GroupID
GROUP BY dtg.GroupID, dtg.GroupName, dtg.Description
ORDER BY InstrumentCount DESC;
```

### 8.3 Find empty groups with no instruments

```sql
SELECT  dtg.GroupID, dtg.GroupName, dtg.Description
FROM    Dictionary.TradingInstrumentGroups dtg WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentGroups ig WITH (NOLOCK) ON dtg.GroupID = ig.GroupID
WHERE   ig.GroupID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsGroupsWithDescriptions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsGroupsWithDescriptions.sql*
