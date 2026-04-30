# Trade.GetCashingTerminalIDs

> Returns all terminal IDs that are associated with corporate action processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TerminalID list from Trade.TerminalIDToCorporateAction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the list of terminal IDs (trading server endpoints) that are designated for corporate action processing. Corporate actions (dividends, stock splits, mergers) require specific processing terminals to handle the financial adjustments. This list identifies which terminals handle these "cashing" operations.

The procedure exists to allow the system to identify and route corporate action processing to the correct terminals. Terminal IDs in this list receive special handling for dividend payouts and other corporate events.

Data is a simple full read from `Trade.TerminalIDToCorporateAction` - a small configuration table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct read of the terminal-to-corporate-action mapping table. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TerminalID | INT | NO | - | CODE-BACKED | Terminal/server identifier designated for corporate action processing. Used for routing corporate action operations to the correct processing endpoint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.TerminalIDToCorporateAction | SELECT FROM | Configuration table mapping terminals to corporate actions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCashingTerminalIDs (procedure)
+-- Trade.TerminalIDToCorporateAction (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TerminalIDToCorporateAction | Table | SELECT FROM - terminal configuration |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetCashingTerminalIDs;
```

### 8.2 View the mapping table directly
```sql
SELECT  TerminalID
FROM    Trade.TerminalIDToCorporateAction WITH (NOLOCK);
```

### 8.3 Check if a specific terminal is a corporate action terminal
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1 FROM Trade.TerminalIDToCorporateAction WITH (NOLOCK) WHERE TerminalID = 5
        ) THEN 'Yes' ELSE 'No' END AS IsCorporateActionTerminal;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCashingTerminalIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCashingTerminalIDs.sql*
