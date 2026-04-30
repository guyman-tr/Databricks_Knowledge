# Trade.GetInstrumentGroupsDictionary

> Returns all instrument group definitions (GroupID + GroupName) from the dictionary table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | GroupID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete dictionary of trading instrument groups. Instrument groups are logical classifications used to organize instruments for display, filtering, and rule application in the trading UI (e.g., "Top Stocks", "Crypto", "ETFs", "Popular Instruments"). They are distinct from InstrumentTypeID (asset class) - groups are marketing/UX categories while types are financial classifications.

The procedure exists to provide the group name lookup for Trade.InstrumentGroups, which maps instruments to one or more groups. The trading API loads this dictionary to translate GroupIDs into display names.

Data flow: no parameters. Reads Dictionary.TradingInstrumentGroups and returns all GroupID + GroupName pairs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple dictionary table read. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID (output) | INT | NO | - | CODE-BACKED | Instrument group identifier. PK of Dictionary.TradingInstrumentGroups. Referenced by Trade.InstrumentGroups. |
| 2 | GroupName (output) | VARCHAR | NO | - | CODE-BACKED | Display name of the instrument group (e.g., "Top Stocks", "Crypto", "Popular Instruments"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.TradingInstrumentGroups | FROM | Source of group definitions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentGroupsDictionary (procedure)
+-- Dictionary.TradingInstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TradingInstrumentGroups | Table | FROM - reads all group definitions |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to get all groups

```sql
EXEC Trade.GetInstrumentGroupsDictionary;
```

### 8.2 Find instruments in a specific group

```sql
SELECT  ig.InstrumentID, tig.GroupName
FROM    Trade.InstrumentGroups ig WITH (NOLOCK)
JOIN    Dictionary.TradingInstrumentGroups tig WITH (NOLOCK) ON ig.GroupID = tig.GroupID
WHERE   tig.GroupName = 'Top Stocks';
```

### 8.3 Count instruments per group

```sql
SELECT  tig.GroupID, tig.GroupName, COUNT(ig.InstrumentID) AS InstrumentCount
FROM    Dictionary.TradingInstrumentGroups tig WITH (NOLOCK)
LEFT JOIN Trade.InstrumentGroups ig WITH (NOLOCK) ON tig.GroupID = ig.GroupID
GROUP BY tig.GroupID, tig.GroupName
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentGroupsDictionary | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentGroupsDictionary.sql*
