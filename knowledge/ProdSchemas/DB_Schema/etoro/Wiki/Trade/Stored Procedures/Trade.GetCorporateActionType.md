# Trade.GetCorporateActionType

> Resolves a terminal ID to its corresponding corporate action type and description by looking up the mapping table and joining to the Dictionary.CorporateAction reference.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CorporateActionID and Description via OUTPUT parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Corporate actions (dividends, stock splits, mergers, etc.) are processed through specific terminal IDs in the trading system. This procedure resolves a terminal ID to the type of corporate action it handles, returning both the numeric action type ID and a human-readable description. This mapping allows the system to determine what kind of corporate action is being processed based on the terminal context.

Without this procedure, the system would not know which corporate action type corresponds to a given terminal, making it impossible to apply the correct processing rules for dividends, splits, or other corporate events.

Data flow: Corporate action processing service provides a TerminalID -> procedure looks up Trade.TerminalIDToCorporateAction and joins to Dictionary.CorporateAction -> returns the action type ID and description via OUTPUT parameters.

---

## 2. Business Logic

### 2.1 Terminal-to-Corporate-Action Mapping

**What**: Maps trading terminal IDs to corporate action types.

**Columns/Parameters Involved**: `@TerminalID`, `CorporateActionTypeID`, `Description`

**Rules**:
- Uses TOP 1 - a terminal may have multiple mappings, but only the first is returned
- LEFT JOIN to Dictionary.CorporateAction means the procedure still returns a result even if the dictionary entry is missing (though Description would be NULL)
- Both values are returned as OUTPUT parameters, not as a result set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TerminalID | VARCHAR(100) | NO | - | CODE-BACKED | Terminal identifier to look up. Matches Trade.TerminalIDToCorporateAction.TerminalID. |
| 2 | @CorporateActionID | INT | NO | - (OUTPUT) | CODE-BACKED | OUTPUT: The corporate action type ID resolved from the terminal mapping. References Dictionary.CorporateAction.CorporateActionTypeID. |
| 3 | @Description | VARCHAR(100) | NO | - (OUTPUT) | CODE-BACKED | OUTPUT: Human-readable description of the corporate action type (e.g., "Dividend", "Stock Split"). From Dictionary.CorporateAction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TerminalID | Trade.TerminalIDToCorporateAction | Lookup | Maps terminal ID to corporate action type |
| CorporateActionTypeID | Dictionary.CorporateAction | Lookup | Resolves action type ID to description |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Corporate Action Processing | EXEC | Caller | Resolves terminal context to corporate action type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCorporateActionType (procedure)
├── Trade.TerminalIDToCorporateAction (table)
└── Dictionary.CorporateAction (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TerminalIDToCorporateAction | Table | Terminal-to-action mapping source |
| Dictionary.CorporateAction | Table | LEFT JOINed for action type description |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Corporate Action Processing | External | Terminal context resolution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses TOP 1 without ORDER BY - non-deterministic if multiple mappings exist for a terminal

---

## 8. Sample Queries

### 8.1 Execute for a specific terminal

```sql
DECLARE @ActionID INT, @Desc VARCHAR(100);
EXEC Trade.GetCorporateActionType
    @TerminalID = 'DIV_PROCESSING',
    @CorporateActionID = @ActionID OUTPUT,
    @Description = @Desc OUTPUT;
SELECT @ActionID AS CorporateActionID, @Desc AS Description;
```

### 8.2 View all terminal-to-action mappings

```sql
SELECT tca.TerminalID, tca.CorporateActionTypeID, ca.Description
FROM Trade.TerminalIDToCorporateAction tca WITH (NOLOCK)
LEFT JOIN Dictionary.CorporateAction ca WITH (NOLOCK) ON ca.CorporateActionTypeID = tca.CorporateActionTypeID
ORDER BY tca.TerminalID;
```

### 8.3 List all corporate action types

```sql
SELECT CorporateActionTypeID, Description
FROM Dictionary.CorporateAction WITH (NOLOCK)
ORDER BY CorporateActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCorporateActionType | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCorporateActionType.sql*
