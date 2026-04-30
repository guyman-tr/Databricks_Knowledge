# Dictionary.AccountLiquidationActionType

> Lookup table classifying how an account liquidation was initiated — either manually by BackOffice or automatically by the BSL (Business Safety Layer) system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AccountLiquidationActionType defines the two ways an account liquidation can be triggered. When the platform needs to close all positions and liquidate a customer's account — whether due to margin call, regulatory action, or risk management — the system records whether the liquidation was initiated manually by BackOffice staff or automatically by the Business Safety Layer (BSL) system.

This distinction is critical for audit trails and compliance. Manual liquidations typically follow human review, escalated decisions, or regulatory mandates. BSL-initiated liquidations occur when automated risk thresholds are breached (e.g., margin exhaustion, negative balance). Both paths end in the same outcome (account closure), but the initiation source drives reporting, incident analysis, and regulatory disclosure.

Data flows from this table into Trade.AccountLiquidationSaga and Trade.CIDsInLiquidation via the `AccountLiquidationAcionTypeID` column (note the typo in the referencing column name). Trade.PersistAccountLiquidationSaga accepts `@AccountLiquidationActionTypeID` and MERGEs into AccountLiquidationSaga, persisting the chosen action type for each liquidation saga.

---

## 2. Business Logic

### 2.1 Liquidation Initiation Classification

**What**: The binary classification of who triggered the account liquidation.

**Columns/Parameters Involved**: `ActionTypeID`, `Description`

**Rules**:
- **Manual (1)**: Liquidation initiated by BackOffice staff. Used when a human decision is required — e.g., compliance action, dispute resolution, regulatory order, or escalated customer request. The saga records this so auditors can trace the decision to a manual process.
- **BSL (2)**: Liquidation initiated automatically by the Business Safety Layer. Used when automated risk thresholds are breached — e.g., margin call failure, negative balance, or other real-time risk triggers. The BSL system closes positions and liquidates the account without human intervention.

**Diagram**:
```
Account Liquidation Trigger Flow:

  ┌─────────────────┐                    ┌───────────────────────────────┐
  │ BackOffice Staff │ ─── Manual (1) ──► │ Trade.AccountLiquidationSaga  │
  └─────────────────┘                    │ Trade.CIDsInLiquidation       │
                                         └───────────────────────────────┘
  ┌─────────────────┐                   
  │ BSL (Automated) │ ─── BSL (2) ─────► 
  └─────────────────┘                   
```

---

## 3. Data Overview

| ActionTypeID | Description | Meaning |
|---|---|---|
| 1 | Manual | Liquidation triggered by BackOffice staff after human review. Used for compliance actions, regulatory orders, disputes, or escalated requests. Persisted in AccountLiquidationSaga via Trade.PersistAccountLiquidationSaga when @AccountLiquidationActionTypeID=1. |
| 2 | BSL | Liquidation triggered automatically by the Business Safety Layer when risk thresholds (e.g., margin call, negative balance) are breached. No human intervention. Persisted when @AccountLiquidationActionTypeID=2. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | VERIFIED | Primary key identifying the liquidation initiation source. 1=Manual (BackOffice), 2=BSL (Business Safety Layer). Referenced by Trade.AccountLiquidationSaga and Trade.CIDsInLiquidation via FK from AccountLiquidationAcionTypeID (typo in column name). Passed as @AccountLiquidationActionTypeID to Trade.PersistAccountLiquidationSaga. |
| 2 | Description | varchar(50) | NO | - | VERIFIED | Human-readable label: 'Manual' or 'BSL'. Used for reporting, UI display, and audit logs when resolving ActionTypeID to a readable value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AccountLiquidationSaga | AccountLiquidationAcionTypeID | FK | Records the liquidation initiation type for each saga |
| Trade.CIDsInLiquidation | AccountLiquidationAcionTypeID | FK | Tracks liquidation type per CID in liquidation |
| Trade.PersistAccountLiquidationSaga | @AccountLiquidationActionTypeID | Parameter | MERGEs into AccountLiquidationSaga with the action type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AccountLiquidationSaga | Table | FK — stores ActionTypeID per liquidation saga |
| Trade.CIDsInLiquidation | Table | FK — stores action type per CID |
| Trade.PersistAccountLiquidationSaga | Stored Procedure | MERGEs AccountLiquidationActionTypeID into saga |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AccountLiquidationActionType | CLUSTERED PK | ActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AccountLiquidationActionType | PRIMARY KEY | Unique ActionTypeID. FILLFACTOR 95. |

---

## 8. Sample Queries

### 8.1 List all liquidation action types
```sql
SELECT  ActionTypeID,
        Description
FROM    Dictionary.AccountLiquidationActionType WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Resolve saga liquidation type to human-readable name
```sql
SELECT  als.CID,
        als.InitialRequestGuid,
        alat.Description AS LiquidationType
FROM    Trade.AccountLiquidationSaga als WITH (NOLOCK)
JOIN    Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
        ON als.AccountLiquidationAcionTypeID = alat.ActionTypeID
ORDER BY als.CreateTime DESC;
```

### 8.3 Count liquidations by initiation type
```sql
SELECT  alat.Description       AS LiquidationType,
        COUNT(*)               AS SagaCount
FROM    Trade.AccountLiquidationSaga als WITH (NOLOCK)
JOIN    Dictionary.AccountLiquidationActionType alat WITH (NOLOCK)
        ON als.AccountLiquidationAcionTypeID = alat.ActionTypeID
GROUP BY alat.Description
ORDER BY SagaCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountLiquidationActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AccountLiquidationActionType.sql*
