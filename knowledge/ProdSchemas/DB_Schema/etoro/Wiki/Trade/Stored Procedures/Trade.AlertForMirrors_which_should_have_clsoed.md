# Trade.AlertForMirrors_which_should_have_clsoed

> Detects copy-trading mirrors (CopyTrader relationships) that were deactivated but whose underlying positions remain open despite new prices arriving, and alerts the trading team via email. Supports debug mode.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Recipients, @Copy_Recipients, @debug |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects orphaned mirror (copy-trading) relationships where the mirror has been deactivated (IsActive=0) with a close operation (MirrorOperationID=4) but the copied positions are still open in the trading system. When a copier stops copying a leader, all copied positions should be closed. If prices have been received after the deactivation but positions remain open, something went wrong.

This is a critical business risk alert for the CopyTrader feature. Orphaned mirror positions mean customers are unknowingly holding positions they thought were closed when they stopped copying, potentially accumulating losses.

The procedure first identifies mirrors where: (1) IsActive=0 in Trade.Mirror, (2) MirrorOperationID=4 (close) in History.Mirror, (3) positions still exist in Trade.Position for that MirrorID, (4) CurrencyPrice.Occurred > History.Mirror.ModificationDate (prices arrived after close was requested), and (5) the position is NOT in Trade.DelayedOrderForClose (already queued for delayed closing). It then enriches with fail history and sends an HTML email alert. Debug mode (@debug=1) returns the result set instead of emailing.

---

## 2. Business Logic

### 2.1 Mirror Orphan Detection

**What**: Identifies mirrors that should have closed all positions but didn't.

**Columns/Parameters Involved**: `Trade.Mirror.IsActive`, `History.Mirror.MirrorOperationID`, `Trade.Position.MirrorID`, `Trade.CurrencyPrice.Occurred`

**Rules**:
- Mirror must have IsActive=0 (deactivated)
- History.Mirror must show MirrorOperationID=4 (close operation)
- At least one position for this MirrorID still exists in Trade.Position
- CurrencyPrice.Occurred > History.Mirror.ModificationDate (price arrived after deactivation)
- Positions in Trade.DelayedOrderForClose are excluded (they are already queued for closing, added by Elad on 11/07/2022)
- Fail history is checked within 14 days, excluding ErrorCode 710

**Diagram**:
```
Trade.Mirror (IsActive=0)
    |
    JOIN History.Mirror (MirrorOperationID=4, get ModificationDate)
    |
    JOIN Trade.Position (positions still open for this MirrorID)
    |
    JOIN Trade.CurrencyPrice (Occurred > ModificationDate)
    |
    EXCEPT Trade.DelayedOrderForClose (already queued)
    |
    = Orphaned mirrors requiring investigation
```

### 2.2 Debug vs Email Mode

**What**: Supports two output modes for operational flexibility.

**Columns/Parameters Involved**: `@debug`, `@Recipients`

**Rules**:
- @debug=0 (default): Sends HTML email if orphans found; returns silently if none
- @debug=1: Returns result set to caller even if no orphans found (for investigation)
- Email is only sent if there ARE results AND debug is off

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Recipients | varchar(max) | YES | 'tradingbackend@etoro.com;pinikr@etoro.com;yitzchakwa@etoro.com;' | CODE-BACKED | Email recipients for the alert notification. |
| 2 | @Copy_Recipients | varchar(max) | YES | '' | CODE-BACKED | CC recipients for the alert email. |
| 3 | @debug | BIT | YES | 0 | CODE-BACKED | Debug mode toggle. 0 = send email alert. 1 = return result set for investigation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.Mirror | READER | Active/inactive mirror status |
| CROSS APPLY | History.Mirror | READER | Mirror operation history (MirrorOperationID=4 = close) |
| JOIN | Dictionary.MirrorOperation | READER | Resolves MirrorOperationID to name |
| JOIN | Trade.Position (view) | READER | Open positions for orphaned mirrors |
| JOIN | Trade.CurrencyPrice | READER | Price timestamps to detect post-deactivation price arrivals |
| NOT IN | Trade.DelayedOrderForClose | READER (exclusion) | Positions already queued for delayed closing |
| OUTER APPLY | History.PositionFail | READER | Recent failure reasons (14 days, excluding ErrorCode 710) |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent job) | - | Scheduler | Periodic mirror health check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForMirrors_which_should_have_clsoed (procedure)
+-- Trade.Mirror (table)
+-- History.Mirror (table)
+-- Dictionary.MirrorOperation (table)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.DelayedOrderForClose (table)
+-- History.PositionFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | READER - mirror activation status |
| History.Mirror | Table | READER - mirror operation history |
| Dictionary.MirrorOperation | Table | READER - operation name resolution |
| Trade.Position | View | READER - open positions for mirror |
| Trade.CurrencyPrice | Table | READER - price timestamps |
| Trade.DelayedOrderForClose | Table | READER - exclusion of already-queued positions |
| History.PositionFail | Table | READER - failure reasons within 14 days |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Procedure hint | Forces fresh execution plan on every call |
| ErrorCode <> 710 exclusion | Business filter | Excludes a specific error code from fail history results |

---

## 8. Sample Queries

### 8.1 Run the mirror alert in debug mode

```sql
EXEC Trade.AlertForMirrors_which_should_have_clsoed @debug = 1;
```

### 8.2 Preview deactivated mirrors with open positions

```sql
SELECT  TM.MirrorID, TM.CID, TM.IsActive, TP.PositionID, TP.InstrumentID
FROM    Trade.Mirror TM WITH (NOLOCK)
JOIN    Trade.Position TP WITH (NOLOCK) ON TM.MirrorID = TP.MirrorID
WHERE   TM.IsActive = 0;
```

### 8.3 Check delayed order exclusions

```sql
SELECT  COUNT(*) AS DelayedCloseCount
FROM    Trade.DelayedOrderForClose WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForMirrors_which_should_have_clsoed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForMirrors_which_should_have_clsoed.sql*
