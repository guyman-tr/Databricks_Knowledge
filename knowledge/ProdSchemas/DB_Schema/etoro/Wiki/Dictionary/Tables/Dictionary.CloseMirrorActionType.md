# Dictionary.CloseMirrorActionType

> Lookup table defining who or what triggered the closing or stopping of a CopyTrading (mirror) relationship. Critical for CopyTrading analytics and compliance auditing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CloseMirrorActionType classifies the *origin* of a CopyTrading mirror close event. When a copier stops copying a leader — whether voluntarily, via Stop Loss, BSL (Business Safety Layer), manual liquidation, BackOffice action, or detach — the system records which mechanism triggered it. This table defines the seven possible action types.

The distinction is essential for analytics and compliance. Customer-initiated closes (0) reflect user choice; Stop Loss (1) and BSL (2) reflect risk controls; Manual Liquidation (3) and BackOffice (4) reflect operational intervention; Customer Detach (5) and BackOffice Detach (6) indicate positions were detached but the mirror relationship may persist differently than a full stop. Each type supports different reporting: churn analysis, risk monitoring, compliance audits, and CopyTrading product metrics.

Data flows when Trade.ChangeMirrorState (or related procs) sets CloseMirrorActionTypeID on Trade.Mirror or History.Mirror. Procedures such as Trade.PostDetachPositionFromMirror, Trade.PostDetachOperation, Trade.MirrorPauseCopy, and dbo.P_MSLMonitoring read or write this type. BackOffice.GetCustomerClosedCopiedTraders and History.GetMirrorOperationDetails surface it for reporting. The dbo.AllDataForML view includes it for machine learning features.

---

## 2. Business Logic

### 2.1 Close Mirror Action Types

**What**: The seven ways a CopyTrading mirror can be closed or stopped.

**Columns/Parameters Involved**: `ID`, `CloseMirrorActionName`

**Rules**:
- **0 (Customer)**: Copier chose to stop copying. User-initiated exit from the mirror relationship.
- **1 (Stop Loss)**: Stop Loss hit — automated risk control triggered close.
- **2 (BSL)**: Business Safety Layer triggered close. System-level risk protection.
- **3 (Manual Liquidation)**: Manual liquidation by operator or system; positions closed.
- **4 (BackOffice)**: BackOffice operator action — compliance, support, or administrative close.
- **5 (Customer Detach)**: Customer requested detach — positions detached from mirror but mirror may remain in a different state.
- **6 (BackOffice Detach)**: BackOffice-initiated detach.

**Diagram**:
```
Mirror Close Flow:

  Customer ──────────────► 0 (Customer) ──────────┐
  Stop Loss hit ─────────► 1 (Stop Loss) ─────────┤
  BSL engine ────────────► 2 (BSL) ──────────────┤
  Manual Liquidation ────► 3 (Manual Liquidation) ┤
  BackOffice operator ──► 4 (BackOffice) ────────┼──► Trade.Mirror
  Customer detach ───────► 5 (Customer Detach) ───┤      (CloseMirrorActionTypeID)
  BackOffice detach ─────► 6 (BackOffice Detach) ─┘
```

### 2.2 Detach vs. Full Close

**What**: Detach (5, 6) differs from full stop (0–4) — positions may be detached from the mirror while the mirror relationship is managed differently.

**Columns/Parameters Involved**: `ID`

**Rules**:
- IDs 0–4: Full close or stop of the copy relationship.
- IDs 5–6: Detach operations; Trade.PostDetachPositionFromMirror and Trade.PostDetachOperation handle these flows.

---

## 3. Data Overview

| ID | CloseMirrorActionName | Meaning |
|---|---|---|
| 0 | Customer | Copier chose to stop copying. User-initiated; no risk system intervention. |
| 1 | Stop Loss | Stop Loss percentage hit; automated close triggered by copier's risk settings. |
| 2 | BSL | Business Safety Layer detected risk condition; system-triggered close. |
| 3 | Manual Liquidation | Manual liquidation process closed the mirror (operator or system). |
| 4 | BackOffice | BackOffice operator closed the mirror for compliance, support, or admin reasons. |
| 5 | Customer Detach | Customer detached positions from mirror; positions closed, mirror state may differ from full stop. |
| 6 | BackOffice Detach | BackOffice detached positions from mirror. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Values 0–6. Referenced by Trade.Mirror and History.Mirror via CloseMirrorActionTypeID. Set by Trade.ChangeMirrorState, Trade.PostDetachPositionFromMirror, and related procs. |
| 2 | CloseMirrorActionName | varchar(50) | NO | - | CODE-BACKED | Human-readable label. Values: Customer, Stop Loss, BSL, Manual Liquidation, BackOffice, Customer Detach, BackOffice Detach. Used in reporting and UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Mirror | CloseMirrorActionTypeID | FK | Current mirror records close action type |
| History.Mirror | CloseMirrorActionTypeID | FK | Historical mirror snapshots |
| Trade.ChangeMirrorState | - | Parameter/logic | Proc sets CloseMirrorActionType |
| Trade.SetMirrorAlignmentStatus | - | Implicit | Proc may set close type in mirror flows |
| Trade.SetMirrorStopLossPercentage | - | Implicit | Stop Loss–related logic |
| Trade.PostDetachPositionFromMirror | - | Logic | Detach proc sets type 5 or 6 |
| Trade.MirrorPauseCopy | - | Implicit | Pause/copy logic |
| Trade.UnRegisterMirrorForMoe | - | Implicit | Unregister logic |
| Trade.ChangeMirrorCalculationType | - | Implicit | Calculation type changes |
| Trade.MirrorsStopLossToBeCompensatedByPercentageDiff | - | Implicit | SL compensation logic |
| Trade.TDAPI_GetLeaderLeavingCopiers | - | Implicit | API proc for leader leaving |
| History.GetMirrorOperationDetails | - | JOIN/SELECT | History proc for mirror details |
| dbo.P_MSLMonitoring | - | Implicit | MSL monitoring proc |
| BackOffice.GetCustomerClosedCopiedTraders | - | JOIN | BO proc for closed copied traders |
| Trade.PostDetachOperation | Table | Implicit | Table in detach flow |
| dbo.AllDataForML | View | Implicit | ML view includes close type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CloseMirrorActionType (table)
```

This object has no dependencies. Tables have no code-level dependencies (no FROM/JOIN in CREATE TABLE).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | FK — records close action type when mirror closes |
| History.Mirror | Table | FK — historical mirror records |
| Trade.ChangeMirrorState | Stored Procedure | Sets CloseMirrorActionTypeID on mirror |
| Trade.PostDetachPositionFromMirror | Stored Procedure | Detach flow; sets type 5 or 6 |
| History.GetMirrorOperationDetails | Stored Procedure | Returns close type for reporting |
| BackOffice.GetCustomerClosedCopiedTraders | Stored Procedure | JOIN for BO display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CloseMirrorActionType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CloseMirrorActionType | PRIMARY KEY | Unique action type identifier. PRIMARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all close mirror action types
```sql
SELECT  ID,
        CloseMirrorActionName
FROM    Dictionary.CloseMirrorActionType WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count closed mirrors by action type
```sql
SELECT  cmat.CloseMirrorActionName     AS CloseAction,
        COUNT(*)                       AS MirrorCount
FROM    Trade.Mirror m WITH (NOLOCK)
JOIN    Dictionary.CloseMirrorActionType cmat WITH (NOLOCK)
        ON m.CloseMirrorActionTypeID = cmat.ID
WHERE   m.CloseMirrorActionTypeID IS NOT NULL
GROUP BY cmat.CloseMirrorActionName
ORDER BY MirrorCount DESC;
```

### 8.3 Find mirrors closed by Stop Loss or BSL (risk triggers)
```sql
SELECT  m.MirrorID,
        m.LeaderID,
        m.CopierID,
        cmat.CloseMirrorActionName
FROM    Trade.Mirror m WITH (NOLOCK)
JOIN    Dictionary.CloseMirrorActionType cmat WITH (NOLOCK)
        ON m.CloseMirrorActionTypeID = cmat.ID
WHERE   m.CloseMirrorActionTypeID IN (1, 2);  -- Stop Loss, BSL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: DDL + MCP live data + Trade.Mirror, ChangeMirrorState, PostDetachPositionFromMirror, History.Mirror, BackOffice procs | Corrections: 0 applied*
*Object: Dictionary.CloseMirrorActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CloseMirrorActionType.sql*
