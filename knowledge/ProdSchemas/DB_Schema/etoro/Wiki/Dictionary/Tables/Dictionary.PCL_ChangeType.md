# Dictionary.PCL_ChangeType

> Lookup table defining 15 position change log (PCL) event types — tracking every modification to a position from open through close, including SL/TP edits, fee charges, mirror operations, partial closes, and data fixes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ChangeTypeID (TINYINT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PCL_ChangeType defines the types of changes that can occur on a trading position throughout its lifecycle. The Position Change Log (PCL) system tracks every modification to a position — from initial open through final close — and each change event is classified by its ChangeTypeID.

This table exists because position audit trails must capture not just that a change happened, but what kind of change it was. Regulatory requirements, P&L calculations, and dispute resolution all depend on understanding the sequence and type of position modifications.

The ChangeTypeID is used by Trade.PostDetachOperation (and its old variant) to classify detach-related changes, by Trade.DetachPositionsFromMirror and Trade.PostDetachPositionFromMirror for CopyTrading operations, by Trade.GetPositionsChangesForDataApi for API reporting, and by several SSRS failure dashboard reports.

---

## 2. Business Logic

### 2.1 Position Change Categories

**What**: The 15 change types organize into distinct categories covering the full position lifecycle.

**Columns/Parameters Involved**: `ChangeTypeID`, `ChangeTypeName`

**Rules**:
- **Lifecycle Events**: Open Position (0), Close Position (6) — the bookend events.
- **Risk Management Edits**: Edit Stop Loss (1), Edit Take Profit (2), Enable/Disable TSL (7) — client or system adjusting risk parameters.
- **Weekend/Fee Events**: Edit Over Weekend (3), EOW Fee (4) — weekend rollover and associated fee charges.
- **CopyTrading Events**: Detach from Mirror (5) — position detached from CopyTrading relationship.
- **Redemption Events**: PositionRedeemCancel (8), PositionRedeemPending (9), PositionRedeemClose (10) — CopyTrading redemption lifecycle.
- **Partial Close Events**: Partial close (11), Edit due to partial close (12) — position size reduction and consequent adjustments.
- **Settlement/Data Events**: Edit Is Settled (13), Data Fix (14) — settlement type changes and manual corrections.

**Diagram**:
```
Position Change Log Types
├── Lifecycle
│   ├── 0  = Open Position
│   └── 6  = Close Position
├── Risk Edits
│   ├── 1  = Edit Stop Loss
│   ├── 2  = Edit Take Profit
│   └── 7  = Enable/Disable TSL
├── Weekend/Fees
│   ├── 3  = Edit Over Weekend
│   └── 4  = EOW Fee
├── CopyTrading
│   ├── 5  = Detach from Mirror
│   ├── 8  = RedeemCancel
│   ├── 9  = RedeemPending
│   └── 10 = RedeemClose
├── Partial Close
│   ├── 11 = Partial close
│   └── 12 = Edit due to partial close
└── Data
    ├── 13 = Edit Is Settled
    └── 14 = Data Fix
```

---

## 3. Data Overview

| ChangeTypeID | ChangeTypeName | Meaning |
|---|---|---|
| 0 | Open Position | Initial position creation event. Logged when a trade is first executed and the position record is created. |
| 1 | Edit Stop Loss | Client or system modified the stop-loss rate on the position. Risk parameter adjustment. |
| 5 | Detach from Mirror | Position was detached from a CopyTrading mirror relationship. The position continues independently of the copied trader. |
| 11 | Partial close | A portion of the position was closed (units reduced). Creates a new close record while the remaining position stays open. |
| 14 | Data Fix | Manual correction applied to the position data by operations team. Used for reconciliation fixes and error corrections. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChangeTypeID | tinyint | NO | - | VERIFIED | Primary key identifying the PCL change type. 0=Open Position, 1=Edit Stop Loss, 2=Edit Take Profit, 3=Edit Over Weekend, 4=EOW Fee, 5=Detach from Mirror, 6=Close Position, 7=Enable/Disable TSL, 8=PositionRedeemCancel, 9=PositionRedeemPending, 10=PositionRedeemClose, 11=Partial close, 12=Edit due to partial close, 13=Edit Is Settled, 14=Data Fix. Used in Trade.PostDetachOperation, Trade.GetPositionsChangesForDataApi, and failure dashboards. |
| 2 | ChangeTypeName | varchar(50) | NO | - | VERIFIED | Human-readable description of the change type. Displayed in position audit reports, API responses, and SSRS dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PostDetachOperation | ChangeTypeID | Implicit | Classifies changes during position detach operations |
| Trade.PostDetachOperation_Old | ChangeTypeID | Implicit | Legacy variant of detach operation tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PostDetachOperation | Table | Stores ChangeTypeID per detach operation |
| Trade.PostDetachOperation_Old | Table | Legacy detach operation table |
| Trade.DetachPositionsFromMirror | Stored Procedure | Uses change types during mirror detach |
| Trade.PostDetachPositionFromMirror | Stored Procedure | Uses change types post-detach |
| Trade.GetPositionsChangesForDataApi | Stored Procedure | Reader — returns changes with type labels for API |
| Trade.Report_PositionsFailSummary | Stored Procedure | Reader — failure summary report |
| dbo.PR_Report_FailDashbord | Stored Procedure | Reader — SSRS failure dashboard |
| dbo.PR_Report_FailDashbordNew | Stored Procedure | Reader — updated failure dashboard |
| dbo.PR_Report_FailDashbordTest | Stored Procedure | Reader — test failure dashboard |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPCL_ChangeType | CLUSTERED PK | ChangeTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPCL_ChangeType | PRIMARY KEY | Unique PCL change type identifier |

---

## 8. Sample Queries

### 8.1 List all position change types
```sql
SELECT  ChangeTypeID,
        ChangeTypeName
FROM    [Dictionary].[PCL_ChangeType] WITH (NOLOCK)
ORDER BY ChangeTypeID;
```

### 8.2 Find CopyTrading-related change types
```sql
SELECT  ChangeTypeID,
        ChangeTypeName
FROM    [Dictionary].[PCL_ChangeType] WITH (NOLOCK)
WHERE   ChangeTypeName LIKE '%Mirror%' OR ChangeTypeName LIKE '%Redeem%'
ORDER BY ChangeTypeID;
```

### 8.3 Group change types by category
```sql
SELECT  CASE WHEN ChangeTypeID IN (0, 6) THEN 'Lifecycle'
             WHEN ChangeTypeID IN (1, 2, 7) THEN 'Risk Edits'
             WHEN ChangeTypeID IN (3, 4) THEN 'Weekend/Fees'
             WHEN ChangeTypeID IN (5, 8, 9, 10) THEN 'CopyTrading'
             WHEN ChangeTypeID IN (11, 12) THEN 'Partial Close'
             ELSE 'Data Management'
        END AS Category,
        ChangeTypeID,
        ChangeTypeName
FROM    [Dictionary].[PCL_ChangeType] WITH (NOLOCK)
ORDER BY ChangeTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PCL_ChangeType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PCL_ChangeType.sql*
