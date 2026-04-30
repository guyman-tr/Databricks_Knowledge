# Dictionary.RiskEventStatus

> Lookup table defining 3 customer risk event lifecycle states — On, InProcess, and Off — with an IsActive flag controlling whether the risk event is currently active.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskEventStatusID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RiskEventStatus defines the lifecycle states of customer risk events (flags). When a risk flag is raised on a customer account (e.g., suspicious activity, chargebacks, fraud indicators), the flag has a status that determines whether it is actively affecting the account.

This table is consumed by BackOffice.CustomerRisk (stores risk events per customer), managed by BackOffice.SetRiskStatus and BackOffice.CustomerSetRiskStatus (modify risk event status), read by BackOffice.GetCustomerRisks, BackOffice.GetRiskHistoryByCID, BackOffice.GetHistoryBackOfficeCustomer, and BackOffice.FreazCustomer (freeze account based on active risks). Also used in BackOffice.NewRiskAlertsPCIVersion for automated risk detection and BackOffice.GetUserRisksByCID functions for risk aggregation.

---

## 2. Business Logic

### 2.1 Risk Event States

**What**: Each status defines whether a risk event is actively applied to a customer account.

**Columns/Parameters Involved**: `RiskEventStatusID`, `Name`, `IsActive`

**Rules**:
- **1 = On** (IsActive=true) — Risk event is actively applied. The customer's account may have restrictions (deposit blocks, trading restrictions, withdrawal holds) depending on the risk type.
- **2 = InProcess** (IsActive=true) — Risk event is being investigated by the compliance team. The event is active during investigation to protect the platform.
- **3 = Off** (IsActive=false) — Risk event has been resolved or dismissed. No longer affects the customer's account.
- The IsActive flag is used for filtering in BackOffice.GetCustomerRisks and BackOffice.GetUserRisksByCID to determine effective risks.
- BackOffice.FreazCustomer checks for active risk events (IsActive=true) before freezing accounts.

**Diagram**:
```
Risk Event Lifecycle
1 (On) ←──▶ 2 (InProcess)
   │              │
   └──────┬───────┘
          ▼
      3 (Off)

IsActive: On=true, InProcess=true, Off=false
```

---

## 3. Data Overview

| RiskEventStatusID | Name | IsActive | Meaning |
|---|---|---|---|
| 1 | On | true | Risk event is active — customer account has active risk restrictions. |
| 2 | InProcess | true | Risk event is under investigation — active restrictions during review. |
| 3 | Off | false | Risk event resolved or dismissed — no longer affecting the account. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskEventStatusID | int | NO | - | VERIFIED | Primary key. 1=On, 2=InProcess, 3=Off. Referenced by BackOffice.CustomerRisk and History.CustomerRisk. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status label. Displayed in BackOffice risk management screens and customer risk history. |
| 3 | IsActive | bit | NO | - | VERIFIED | Controls whether this status represents an active risk. 1=risk is active (On, InProcess), 0=risk is resolved (Off). Used for filtering in risk queries and account freezing logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerRisk | RiskEventStatusID | Implicit | Active risk events per customer |
| BackOffice.CustomerRisk_Updated_2308 | RiskEventStatusID | Implicit | Updated risk event records |
| History.CustomerRisk | RiskEventStatusID | Implicit | Historical risk event audit trail |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerRisk | Table | Stores risk event status per customer |
| BackOffice.CustomerRisk_Updated_2308 | Table | Updated risk records |
| History.CustomerRisk | Table | Historical audit trail |
| BackOffice.SetRiskStatus | Stored Procedure | Modifier — changes risk event status |
| BackOffice.CustomerSetRiskStatus | Stored Procedure | Modifier — sets customer risk status |
| BackOffice.GetCustomerRisks | Stored Procedure | Reader — retrieves active risks for a customer |
| BackOffice.GetRiskHistoryByCID | Stored Procedure | Reader — risk event history |
| BackOffice.GetHistoryBackOfficeCustomer | Stored Procedure | Reader — full customer history |
| BackOffice.FreazCustomer | Stored Procedure | Reader — checks active risks before freezing |
| BackOffice.NewRiskAlertsPCIVersion | Stored Procedure | Reader — automated risk detection |
| BackOffice.GetUserRisksByCID | Function | Reader — risk aggregation by CID |
| BackOffice.GetUserRisksByCID_V2 | Function | Reader — V2 risk aggregation |
| BackOffice.GetUserRisksByCID_AGG | Function | Reader — aggregated risk view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryRiskEventStatus | CLUSTERED PK | RiskEventStatusID ASC | - | - | Active (FF=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryRiskEventStatus | PRIMARY KEY | Unique status identifier |

---

## 8. Sample Queries

### 8.1 List all risk event statuses
```sql
SELECT  RiskEventStatusID,
        Name,
        IsActive
FROM    [Dictionary].[RiskEventStatus] WITH (NOLOCK)
ORDER BY RiskEventStatusID;
```

### 8.2 Count active risk events per customer
```sql
SELECT  cr.CID,
        COUNT(*) AS ActiveRiskCount
FROM    [BackOffice].[CustomerRisk] cr WITH (NOLOCK)
JOIN    [Dictionary].[RiskEventStatus] res WITH (NOLOCK) ON cr.RiskEventStatusID = res.RiskEventStatusID
WHERE   res.IsActive = 1
GROUP BY cr.CID
ORDER BY ActiveRiskCount DESC;
```

### 8.3 Find customers with risks being investigated
```sql
SELECT  cr.CID,
        rs.Name AS RiskStatus
FROM    [BackOffice].[CustomerRisk] cr WITH (NOLOCK)
JOIN    [Dictionary].[RiskEventStatus] rs WITH (NOLOCK) ON cr.RiskEventStatusID = rs.RiskEventStatusID
WHERE   rs.RiskEventStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RiskEventStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskEventStatus.sql*
