# Dictionary.AuditActionType

> Comprehensive lookup table of 358 BackOffice audit action types — every auditable operation performed by operators and system processes, from deposit processing to account status changes to compliance actions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AuditActionTypeID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AuditActionType is the master registry of every auditable action that can be performed through the BackOffice system. Each row represents a specific operation type (deposit rollback, status change, document verification, etc.) that is logged in the audit trail when a BackOffice operator or automated process performs it.

This table is the foundation of the platform's audit and compliance infrastructure. Every action taken on a customer account by BackOffice operators is logged with its AuditActionTypeID, creating a complete, searchable audit trail. Regulators, compliance teams, and internal auditors use these logs to verify that customer accounts are being managed according to policy.

The audit trail is written by BackOffice.AuditActionAdd and BackOffice.AuditActionAdd_V2 (which accept the AuditActionTypeID as a parameter). BackOffice.GetAuditHistory retrieves the audit trail with resolved type names. Risk classification procedures (RiskCalculation.SetRiskClassificationForCySec, BackOffice.SetRiskClassificationNew) also reference specific audit action types when logging their operations.

---

## 2. Business Logic

### 2.1 Audit Action Categories

**What**: Classification of the 358 auditable operations by business domain.

**Columns/Parameters Involved**: `AuditActionTypeID`, `AuditActionTypeName`

**Rules**:
- **Financial operations (1-12, 20, 46, 50, 66, 68, etc.)**: Deposit processing, cashout management, bonus operations, withdrawal reversals, payment matching
- **Customer management (3, 15-17, 21, 32-35, 52, 62, etc.)**: Status changes, verified status, account type, guru status, player level, acceptance status, regulation changes
- **Risk & Compliance (19, 29-31, 39, 90, 106, 116, etc.)**: Risk status changes, risk classification, world check, document management, KYC operations
- **Security operations (27-28, 93, 144, 149-152, etc.)**: Login/logout, 2FA management, session kills, password resets, blocking/unblocking
- **Reporting & Read operations (131, 134-136, 165, 168, etc.)**: Customer lookups, position views, report generation — logged for access auditing
- **IDs 194-358**: Newer audit types added over time for expanded feature coverage

**Diagram**:
```
Audit Action Domain Map:

  Financial          Customer          Risk/Compliance      Security
  ─────────          ────────          ───────────────      ────────
  1-12: Core ops     21: Status        19: Risk status      27-28: BO login
  20: Add money      32: Account type  29: Doc add          93: WebTrader
  46: Bonus          34: Guru status   30: Risk class       144: Set 2FA
  50: Withdraw rev   35: Player level  31: Risk status      149-150: Block
  66: Withdraw add   52: Demography    39: WorldCheck       152: Kill session
  68: Amount add     62: Set status    90: Acceptance       183: Block user
  ...                116: Regulation   106: Blacklist        ...
```

---

## 3. Data Overview

| AuditActionTypeID | AuditActionTypeName | Meaning |
|---|---|---|
| 1 | Rollback Deposit/Cancel Rollback | Operator reverses a deposit or cancels a previous reversal. Financial reconciliation action logged for audit compliance. |
| 21 | Change Customer Status | Operator changes a customer's account status (active, suspended, closed). Major compliance event requiring audit trail for regulatory review. |
| 30 | BackOffice.CustomerSetRiskClassification | Risk classification change by compliance operator. Triggers different monitoring levels and may restrict trading or deposit limits. |
| 74 | Trade.PositionClose | Administrative position close by operator. Logged when BackOffice intervenes to close a customer's trading position (e.g., for risk management). |
| 149 | BackOffice.DoBlock | Operator blocks a customer's account. Prevents login, trading, and withdrawals. Requires paired unblock (150) for reinstatement. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AuditActionTypeID | int | NO | - | VERIFIED | Primary key identifying the auditable action. Values 1-358 (with gaps). Written to audit log by BackOffice.AuditActionAdd and AuditActionAdd_V2. Read by BackOffice.GetAuditHistory to resolve action names. Each value represents a specific BackOffice operation that requires audit tracking. |
| 2 | AuditActionTypeName | varchar(max) | YES | - | VERIFIED | Descriptive name of the audit action, often matching the stored procedure name that performs the operation (e.g., 'BackOffice.CustomerSetRiskClassification', 'Billing.WithdrawRequestAdd'). Nullable but all current rows have values. VARCHAR(MAX) accommodates long procedure-style names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AuditActionAdd | @AuditActionTypeID | Parameter INSERT | Core audit logging — writes audit entries with this type |
| BackOffice.AuditActionAdd_V2 | @AuditActionTypeID | Parameter INSERT | V2 audit logging with additional context |
| BackOffice.GetAuditHistory | AuditActionTypeID | JOIN | Retrieves and resolves audit trail for display |
| BackOffice.SetRiskClassificationNew | AuditActionTypeID | Hardcoded | Logs risk classification changes with specific type IDs |
| RiskCalculation.SetRiskClassificationForCySec | AuditActionTypeID | Hardcoded | Logs CySEC regulation risk classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditActionAdd | Stored Procedure | Writer — core audit logging |
| BackOffice.AuditActionAdd_V2 | Stored Procedure | Writer — V2 audit logging |
| BackOffice.GetAuditHistory | Stored Procedure | Reader — audit trail display |
| BackOffice.SetRiskClassificationNew | Stored Procedure | Reader — risk audit types |
| RiskCalculation.SetRiskClassificationForCySec | Stored Procedure | Reader — regulatory audit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | AuditActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (unnamed) | PRIMARY KEY | Unique audit action type identifier on PRIMARY filegroup. TEXTIMAGE_ON [PRIMARY] for varchar(max) overflow. |

---

## 8. Sample Queries

### 8.1 List all audit action types
```sql
SELECT  AuditActionTypeID,
        AuditActionTypeName
FROM    Dictionary.AuditActionType WITH (NOLOCK)
ORDER BY AuditActionTypeID;
```

### 8.2 Search for deposit-related audit types
```sql
SELECT  AuditActionTypeID,
        AuditActionTypeName
FROM    Dictionary.AuditActionType WITH (NOLOCK)
WHERE   AuditActionTypeName LIKE '%Deposit%'
   OR   AuditActionTypeName LIKE '%deposit%'
ORDER BY AuditActionTypeID;
```

### 8.3 Find audit types for customer status changes
```sql
SELECT  AuditActionTypeID,
        AuditActionTypeName
FROM    Dictionary.AuditActionType WITH (NOLOCK)
WHERE   AuditActionTypeName LIKE '%Status%'
   OR   AuditActionTypeName LIKE '%Block%'
   OR   AuditActionTypeName LIKE '%Close Account%'
ORDER BY AuditActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AuditActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AuditActionType.sql*
