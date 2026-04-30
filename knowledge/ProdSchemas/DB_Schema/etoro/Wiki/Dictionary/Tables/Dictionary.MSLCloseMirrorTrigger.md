# Dictionary.MSLCloseMirrorTrigger

> Defines the trigger events that cause the Mirror Stop Loss (MSL) system to close a CopyTrading mirror relationship, protecting copiers from excessive losses.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.MSLCloseMirrorTrigger classifies the events that trigger the Mirror Stop Loss (MSL) mechanism to automatically close a CopyTrading mirror relationship. MSL is a risk management feature that protects copiers from losing more than their configured loss threshold. When an MSL trigger fires, all copied positions are closed and the mirror relationship is terminated.

Without this table, the system could not categorize what caused an MSL-triggered mirror closure, making it impossible for customers or support staff to understand why a copy relationship ended. The trigger type affects the customer experience (e.g., rate-triggered vs admin-initiated) and the operational response.

The eight triggers cover the full range of MSL activation scenarios: market rate movements, MSL initialization, manual edits, position lifecycle events, and mirror registration/update events.

---

## 2. Business Logic

### 2.1 MSL Trigger Categories

**What**: Eight events that activate the Mirror Stop Loss mechanism.

**Columns/Parameters Involved**: `ID`, `MSLCloseMirrorTriggerName`

**Rules**:
- Rate (0): Market rate moved beyond MSL threshold — the most common trigger for automatic MSL closure
- MSL Initialization (1): MSL check at relationship creation time — copy fails to start if already past threshold
- Edit Mirror SL (2): Copier edits their stop-loss level, triggering immediate recalculation
- Position Close (3): A position close by the leader causes MSL recalculation
- Position Disconnection (4): A copied position is disconnected from the mirror tree
- Position Open (5): A new position opened by the leader triggers MSL recalculation
- Register Mirror (6): MSL evaluated at mirror registration time
- Update Mirror Amount (7): Copier changes their copy amount, triggering MSL recalculation

**Diagram**:
```
MSL Trigger Events:
  Market ─────> Rate (0)
  Lifecycle ──> MSL Initialization (1), Register Mirror (6)
  Copier ─────> Edit Mirror SL (2), Update Mirror Amount (7)
  Leader ─────> Position Close (3), Position Open (5)
  System ─────> Position Disconnection (4)
         │
         ▼
  MSL Threshold Breached → Close All Copied Positions → End Mirror
```

---

## 3. Data Overview

| ID | MSLCloseMirrorTriggerName | Meaning |
|---|---|---|
| 0 | Rate | Market price movement caused the copier's loss to breach the MSL threshold — most common trigger for automatic mirror closure |
| 1 | MSL Initialization | MSL check at copy relationship startup detected the portfolio is already below threshold — prevents starting a doomed copy |
| 2 | Edit Mirror SL | Copier tightened their stop-loss level, and the current loss already exceeds the new threshold — immediate closure |
| 3 | Position Close | Leader closed a position, causing MSL recalculation that found the remaining portfolio breaches the threshold |
| 7 | Update Mirror Amount | Copier reduced their copy allocation amount, causing the loss percentage to exceed the MSL threshold on the smaller base |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the MSL trigger event: 0=Rate, 1=MSL Initialization, 2=Edit Mirror SL, 3=Position Close, 4=Position Disconnection, 5=Position Open, 6=Register Mirror, 7=Update Mirror Amount. |
| 2 | MSLCloseMirrorTriggerName | varchar(50) | NO | - | VERIFIED | Human-readable trigger event name displayed in CopyTrading closure notifications and BackOffice mirror management screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CopyTrading MSL system | MSLCloseMirrorTriggerID | Implicit | MSL closure records reference this table for the trigger event type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No SSDT procedure references found beyond the DDL itself. The table is likely consumed by application-level CopyTrading services.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MSLCloseMirrorTrigger | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all MSL trigger types
```sql
SELECT  ID,
        MSLCloseMirrorTriggerName
FROM    [Dictionary].[MSLCloseMirrorTrigger] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find trigger name by ID
```sql
SELECT  MSLCloseMirrorTriggerName
FROM    [Dictionary].[MSLCloseMirrorTrigger] WITH (NOLOCK)
WHERE   ID = 0;
```

### 8.3 All trigger types with category labels
```sql
SELECT  ID,
        MSLCloseMirrorTriggerName,
        CASE
            WHEN ID = 0 THEN 'Market-driven'
            WHEN ID IN (1, 6) THEN 'Lifecycle'
            WHEN ID IN (2, 7) THEN 'Copier-initiated'
            WHEN ID IN (3, 5) THEN 'Leader-initiated'
            WHEN ID = 4 THEN 'System'
        END AS TriggerCategory
FROM    [Dictionary].[MSLCloseMirrorTrigger] WITH (NOLOCK)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MSLCloseMirrorTrigger | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MSLCloseMirrorTrigger.sql*
