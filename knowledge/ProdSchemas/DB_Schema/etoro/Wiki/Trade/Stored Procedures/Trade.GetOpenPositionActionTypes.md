# Trade.GetOpenPositionActionTypes

> Returns the full lookup table of position-open action types from Dictionary.OpenPositionActionType - all IDs and their human-readable names that classify WHY a position was opened.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenPositionActionTypes` is a simple lookup-fetch procedure that returns the entire `Dictionary.OpenPositionActionType` table. It provides the enumeration of all reasons a position can be opened in the system - from a customer manually opening a trade (ID=0) to automated operations like stock dividends, corporate actions, or administrative adjustments.

**WHY:** The `OpenActionType` column in `Trade.PositionTbl`, `Trade.OrderForOpen`, and `Trade.OpenExecutionPlan` stores an integer ID. This SP provides the reference data needed to translate those IDs into human-readable labels for display in applications, operational dashboards, or reports.

**HOW:** Called from application code whenever the full list of open action types is needed (e.g., to populate a dropdown, to decode a stored ID, or to bootstrap application enumerations). Returns all 18 rows from the dictionary - no filtering, no pagination.

---

## 2. Business Logic

### 2.1 Open Action Type Value Map

**What:** Each ID represents a distinct reason a position was opened. The action type is set at position creation and does not change. It is used for reporting, fee calculation, and operational analysis.

**Columns/Parameters Involved:** `ID`, `OpenPositionActionName`

**Rules:**
- ID is the value stored in `Trade.PositionTbl.OpenActionType`, `Trade.OrderForOpen.OpenActionType`, `Trade.OpenExecutionPlan.OpenActionType`
- ID=-1 is a sentinel "Undefined" value used when action type was not set or is unknown
- ID=0 ("Customer") is the most common - normal user-initiated position open
- ID=1 ("Hierarchical Open") - copy-trade propagated open (child position in copy tree)
- ID=2 ("Reopen") - position reopened after a partial close
- ID=3 ("Open Open") - an open within another open operation
- ID=4 ("Stock Dividend") - position opened as a stock dividend (shares received)
- ID=5 ("Corporate Action") - position opened due to a corporate action event
- ID=6 ("Technical Issue") - opened by system to correct a technical problem
- ID=7 ("Operational position adjustment") - back-office operational adjustment
- ID=8 ("Add Funds") - position opened on behalf of an add-funds flow
- ID=9 ("Reinvestment") - position opened via reinvestment of proceeds
- ID=10 ("Admin") - administratively opened by operations team
- ID=11 ("Stacking") - position opened via stacking/layering strategy
- ID=12 ("Promotion") - promotional position (e.g., bonus credit trade)
- ID=13 ("ACATS_IN") - position transferred in via ACATS (US brokerage transfer)
- ID=14 ("ReedemForNFT") - position opened as part of an NFT redemption flow
- ID=15 ("Technical") - technical/system-initiated open
- ID=16 ("Alignment") - position opened during mirror alignment process
- ID=17 ("Recurring Investment") - position opened via recurring investment schedule

---

## 3. Data Overview

N/A for Stored Procedure. (The full lookup table is the return value - see Business Logic 2.1 for all 18 values.)

---

## 4. Elements

This procedure has no input parameters.

**Return Columns (from Dictionary.OpenPositionActionType):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | ID | int | NO | - | VERIFIED | The action type identifier. Stored in Trade.PositionTbl.OpenActionType, Trade.OrderForOpen.OpenActionType, Trade.OpenExecutionPlan.OpenActionType. -1=Undefined, 0=Customer (normal), 1=Hierarchical Open (copy trade), 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational position adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. |
| R2 | OpenPositionActionName | varchar | NO | - | VERIFIED | Human-readable label for the action type. Used for display in operational tools and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all rows) | Dictionary.OpenPositionActionType | Direct query | SELECT ID, OpenPositionActionName - full table fetch |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application code | N/A | CALLER | Called to populate UI dropdowns and decode OpenActionType IDs |
| Trade.PositionTbl | OpenActionType | Lookup consumer | Stores ID from this lookup |
| Trade.OrderForOpen | OpenActionType | Lookup consumer | Stores ID from this lookup |
| Trade.OpenExecutionPlan | OpenActionType | Lookup consumer | Stores ID from this lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionActionTypes (procedure)
└── Dictionary.OpenPositionActionType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OpenPositionActionType | Table | SELECT ID, OpenPositionActionName - returns full dictionary |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application code | External | Bootstraps OpenActionType enumeration at startup or on demand |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Uses `WITH(NOLOCK)` - safe for a static dictionary table.

---

## 8. Sample Queries

### 8.1 Get all open position action types
```sql
EXEC Trade.GetOpenPositionActionTypes
```

### 8.2 Decode action types on open positions
```sql
SELECT p.PositionID,
       p.CID,
       p.InstrumentID,
       p.OpenActionType,
       oat.OpenPositionActionName
FROM   Trade.Position p WITH (NOLOCK)
       LEFT JOIN Dictionary.OpenPositionActionType oat WITH (NOLOCK)
           ON p.OpenActionType = oat.ID
WHERE  p.StatusID = 1  -- open positions
ORDER  BY p.PositionID DESC
```

### 8.3 Count open positions by action type
```sql
SELECT oat.OpenPositionActionName,
       COUNT(*) AS PositionCount
FROM   Trade.Position p WITH (NOLOCK)
       INNER JOIN Dictionary.OpenPositionActionType oat WITH (NOLOCK)
           ON p.OpenActionType = oat.ID
WHERE  p.StatusID = 1
GROUP  BY oat.OpenPositionActionName
ORDER  BY PositionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; live data queried for Phase 2)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositionActionTypes | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenPositionActionTypes.sql*
