# Dictionary.MirrorCalculationType

> Lookup table defining the 2 CopyTrading equity calculation methods — RealizedEquity and UnrealizedEquity — controlling how a copier's allocated balance is calculated within a copy relationship.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 2 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MirrorCalculationType defines how the equity within a CopyTrading (Mirror) relationship is calculated. When a copier allocates funds to copy a trader, the system needs to continuously calculate the value of that copy relationship for operations like: copy stop-loss evaluation, balance adjustments, unregistration payouts, and portfolio display.

The two methods are:
- **RealizedEquity (0)**: Only counts realized (closed) gains/losses. The copy balance reflects the original allocation plus/minus profits from positions that have been closed. Open P&L is excluded. This is the conservative/stable calculation — the value doesn't fluctuate with market movements of open positions.
- **UnrealizedEquity (1)**: Includes both realized and unrealized (open) gains/losses. The copy balance fluctuates in real-time with the market value of all open copied positions. This gives a more accurate "current value" but is more volatile.

The calculation type is stored on Trade.Mirror (the main copy relationship table) and is set during copy registration (Trade.RegisterMirror). It can be changed via Trade.ChangeMirrorCalculationType (MirrorOperationID=11). The choice affects how copy stop-loss is evaluated, how balance change requests are processed, and how portfolio values are displayed.

---

## 2. Business Logic

### 2.1 Equity Calculation Methods

**What**: How each calculation method affects copy relationship value.

**Columns/Parameters Involved**: `ID`, `Description`

**Rules**:
- **RealizedEquity (0)**: Copy value = Initial allocation ± closed position P&L ± manual adjustments. Does not include floating P&L from open positions. More stable, less responsive to market. Used for conservative copy relationships.
- **UnrealizedEquity (1)**: Copy value = Initial allocation ± closed P&L ± open (unrealized) P&L ± adjustments. Real-time market value. More accurate but volatile. Used for most modern copy relationships.

**Diagram**:
```
Copy Equity Calculation:

  RealizedEquity (0):
    Copy Value = Allocation + Σ(Closed P&L) + Adjustments
    [Stable — only changes when positions close]

  UnrealizedEquity (1):
    Copy Value = Allocation + Σ(Closed P&L) + Σ(Open P&L) + Adjustments
    [Dynamic — changes with every market tick]
```

### 2.2 Impact on Copy Operations

**What**: How calculation type affects CopyTrading operations.

**Columns/Parameters Involved**: `MirrorCalculationType` (Trade.Mirror column)

**Rules**:
- Copy Stop-Loss evaluation differs: RealizedEquity SL triggers only on realized losses; UnrealizedEquity SL includes floating losses
- Balance edit (Trade.ChangeMirrorAmountForMoe) considers the calculation type when computing available balance
- Unregistration payout calculation uses the appropriate equity method to determine final settlement
- Portfolio display (Trade.GetClientPortfolioForAPI, Trade.GetPortfolioAggregates) shows values based on the active calculation type
- History.MirrorFail tracks `RequiredMirrorCalculationType` when copy operations fail due to calculation type mismatches

---

## 3. Data Overview

| ID | Description | Meaning |
|---|---|---|
| 0 | RealizedEquity | Copy equity calculated using only realized (closed position) gains and losses. Conservative method — copy value is stable and only changes when copied positions are closed. Excludes floating P&L from open positions. |
| 1 | UnrealizedEquity | Copy equity calculated using both realized and unrealized (open position) gains and losses. Dynamic method — copy value fluctuates in real-time with market prices. Provides a more accurate "current value" of the copy relationship. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | - | VERIFIED | Primary key identifying the calculation method. 0=RealizedEquity (closed P&L only), 1=UnrealizedEquity (closed + open P&L). Stored in Trade.Mirror.MirrorCalculationType. Set at copy registration (Trade.RegisterMirror) and changeable via Trade.ChangeMirrorCalculationType. |
| 2 | Description | varchar(100) | YES | - | VERIFIED | Human-readable calculation method name. Nullable. Values: 'RealizedEquity', 'UnrealizedEquity'. Used in procedure logic for branching calculations and in portfolio display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Mirror | MirrorCalculationType | Implicit (column + default) | Active copy relationship stores calculation type |
| History.Mirror | MirrorCalculationType | Implicit | Copy operation history records calculation type |
| History.MirrorFail | RequiredMirrorCalculationType | Implicit | Failed operations track required calculation type |
| Trade.PostDetachOperation | H_M_MirrorCalculationType | Implicit | Position detach records calculation type |
| Trade.Tv_RegisterMirror | H_M_MirrorCalculationType | UDT column | TVP for bulk mirror registration |
| Trade.RegisterMirror | @MirrorCalculationType | Parameter INSERT | Sets type at copy creation |
| Trade.ChangeMirrorCalculationType | @MirrorCalculationType | Parameter UPDATE | Changes type (operation 11) |
| Trade.MirrorReopen | @MirrorCalculationType | Parameter INSERT | Preserves type on reopen |
| Trade.GetMirrorData | MirrorCalculationType | SELECT | Returns type in mirror data |
| Trade.GetMirrorDataWithCIDForAPI | MirrorCalculationType | SELECT | API returns calculation type |
| Trade.GetClientPortfolioForAPI | MirrorCalculationType | SELECT | Portfolio API returns type |
| Trade.GetPortfolioAggregates | MirrorCalculationType | SELECT | Aggregated portfolio includes type |
| History.GetMirrorOperationDetails | MirrorCalculationType | SELECT (aliased) | Operation history shows type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.MirrorCalculationType (table)
  └── stored in Trade.Mirror (MirrorCalculationType column)
  └── stored in History.Mirror, History.MirrorFail
  └── consumed by 25+ Trade/History procedures
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Stores calculation type per copy relationship |
| History.Mirror | Table | Historical copy operation records |
| History.MirrorFail | Table | Failed operation tracking |
| Trade.RegisterMirror | Stored Procedure | Sets type at creation |
| Trade.ChangeMirrorCalculationType | Stored Procedure | Updates calculation type |
| Trade.GetMirrorData | Stored Procedure | Returns type in queries |
| Trade.GetClientPortfolioForAPI | Stored Procedure | Portfolio API |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorCalculationType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MirrorCalculationType | PRIMARY KEY | Unique calculation type identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all calculation types
```sql
SELECT  ID,
        Description
FROM    Dictionary.MirrorCalculationType WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count active copy relationships by calculation type
```sql
SELECT  CASE m.MirrorCalculationType
            WHEN 0 THEN 'RealizedEquity'
            WHEN 1 THEN 'UnrealizedEquity'
        END                 AS CalculationType,
        COUNT(*)            AS CopyCount
FROM    Trade.Mirror m WITH (NOLOCK)
WHERE   m.MirrorStatusID = 1  -- Active
GROUP BY m.MirrorCalculationType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 25+ Trade and History procedures.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 25 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorCalculationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MirrorCalculationType.sql*
