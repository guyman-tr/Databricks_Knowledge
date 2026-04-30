# Dictionary.HedgeManualRequestType

> Lookup table defining the eight types of manual hedge requests — custom orders, exposure adjustments, netting moves, and queue management operations that hedge operators can submit outside the automated hedging flow.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RequestTypeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeManualRequestType classifies the types of manual interventions that hedge operations staff can perform on the hedge server. While eToro's hedge system operates automatically — opening and closing hedge positions in response to customer trades — certain situations require manual override: correcting exposure mismatches, routing orders directly to liquidity providers, or clearing queued orders during system issues.

This table exists because manual hedge operations carry elevated risk and require full audit trail classification. Each manual action is logged with its request type so that risk management can review what was done, why, and by whom. Without this classification, manual interventions would be opaque in audit logs.

The RequestTypeID is stored in the Hedge.ManualOrderExecutionLog table, which records every manual hedge operation performed by the trading operations team.

---

## 2. Business Logic

### 2.1 Manual Hedge Operation Categories

**What**: Manual requests fall into three categories: direct orders, exposure management, and queue operations.

**Columns/Parameters Involved**: `RequestTypeID`, `Name`

**Rules**:
- **Direct orders (0, 3)**: Fully custom or specific trade-level exposure requests
  - Custom Request (0): Freeform manual order — operator specifies exact parameters
  - SetTradeExposure (3): Adjust exposure for a specific trade
- **Exposure management (1, 2, 4)**: Adjust overall hedge exposure levels
  - Set Hedge Exposure (1): Override the target hedge exposure for an instrument
  - Settle Requested Exposure (2): Force settlement of pending exposure adjustments
  - Manual Exposure (4): Direct manual exposure entry bypassing automated calculations
- **Queue operations (5, 6, 7)**: Manage the hedge order queue
  - Custom Update Queued (5): Modify a queued order before execution
  - Clear Queued (6): Remove all pending queued orders (emergency action)
  - Move Netting (7): Redistribute netting positions between hedge accounts

**Diagram**:
```
Manual Hedge Request Types:
├── Direct Orders
│     ├── Custom Request (0)       — Freeform manual order
│     └── SetTradeExposure (3)     — Trade-level adjustment
│
├── Exposure Management
│     ├── Set Hedge Exposure (1)   — Override target exposure
│     ├── Settle Requested (2)     — Force settle pending
│     └── Manual Exposure (4)      — Direct manual entry
│
└── Queue Operations
      ├── Custom Update Queued (5) — Modify queued order
      ├── Clear Queued (6)         — Emergency queue clear
      └── Move Netting (7)        — Redistribute netting
```

---

## 3. Data Overview

| RequestTypeID | Name | Meaning |
|---|---|---|
| 0 | Custom Request | Freeform manual hedge order where the operator specifies all parameters directly. Used for ad-hoc corrections or unusual market situations where automated rules don't apply. |
| 1 | Set Hedge Exposure | Override the automated hedge exposure target for a specific instrument. Used when the operations team determines the automatic calculation is incorrect or needs temporary adjustment. |
| 4 | Manual Exposure | Direct manual exposure entry that bypasses the automated exposure calculation entirely. More drastic than Set Hedge Exposure — used for emergency corrections. |
| 6 | Clear Queued | Remove all pending queued hedge orders. Emergency action used during system issues when queued orders could execute at stale prices or in incorrect volumes. |
| 7 | Move Netting | Redistribute netting positions between hedge accounts. Used during account rebalancing or when moving exposure between liquidity providers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestTypeID | int | NO | - | VERIFIED | Primary key identifying the manual request type. 0=Custom Request, 1=Set Hedge Exposure, 2=Settle Requested Exposure, 3=SetTradeExposure, 4=Manual Exposure, 5=Custom Update Queued, 6=Clear Queued, 7=Move Netting. Stored in Hedge.ManualOrderExecutionLog for audit. |
| 2 | Name | varchar(30) | NO | - | VERIFIED | Human-readable label for the request type. Displayed in manual hedge operation logs and audit reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ManualOrderExecutionLog | RequestTypeID | Implicit FK | Logs every manual hedge operation with its request type for audit and review |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ManualOrderExecutionLog | Table | References RequestTypeID to classify manual operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_HedgeManualRequestType | CLUSTERED PK | RequestTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_HedgeManualRequestType | PRIMARY KEY | Unique manual request type identifier |

---

## 8. Sample Queries

### 8.1 List all manual request types
```sql
SELECT  RequestTypeID,
        Name
FROM    [Dictionary].[HedgeManualRequestType] WITH (NOLOCK)
ORDER BY RequestTypeID;
```

### 8.2 Join to manual execution log
```sql
SELECT  mel.LogID,
        mel.InstrumentID,
        mrt.Name AS RequestType,
        mel.CreatedDate
FROM    [Hedge].[ManualOrderExecutionLog] mel WITH (NOLOCK)
JOIN    [Dictionary].[HedgeManualRequestType] mrt WITH (NOLOCK)
        ON mel.RequestTypeID = mrt.RequestTypeID
ORDER BY mel.CreatedDate DESC;
```

### 8.3 Count manual operations by type
```sql
SELECT  mrt.Name AS RequestType,
        COUNT(*) AS OperationCount
FROM    [Hedge].[ManualOrderExecutionLog] mel WITH (NOLOCK)
JOIN    [Dictionary].[HedgeManualRequestType] mrt WITH (NOLOCK)
        ON mel.RequestTypeID = mrt.RequestTypeID
GROUP BY mrt.Name
ORDER BY OperationCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeManualRequestType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeManualRequestType.sql*
