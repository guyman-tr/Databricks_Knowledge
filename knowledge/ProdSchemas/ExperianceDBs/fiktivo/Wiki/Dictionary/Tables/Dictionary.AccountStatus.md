# Dictionary.AccountStatus

> Lookup table defining the lifecycle states of a customer trading account, controlling whether the account holder can trade, access funds, or has been permanently terminated.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountStatusID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AccountStatus defines the finite set of lifecycle states a customer's trading account can be in. Each state controls the customer's ability to trade, deposit, withdraw, and access platform services. This is a core reference table in the affiliate management domain.

Without this table, the system would have no standard vocabulary for account states. All affiliate reporting, commission eligibility checks, and admin tooling depend on consistent account status classification.

Rows in this table are static reference data - they are not created or modified by application procedures at runtime. The table is read by admin/reporting procedures (e.g., AffiliateAdmin.GetGeneralAffiliateResource) to populate dropdown lists and decode status IDs in result sets.

---

## 2. Business Logic

### 2.1 Account Lifecycle States

**What**: Five distinct states governing what an account holder can and cannot do on the platform.

**Columns/Parameters Involved**: `AccountStatusID`, `AccountStatusName`

**Rules**:
- ID=1 (Activated) is the only fully operational state - customer can trade and access all services
- ID=2 (Deactivated) is a reversible suspension - the account may be reactivated
- ID=0 (Terminated) is a permanent, generic termination - the account cannot be reopened
- ID=3 (TerminatedRequirements) and ID=4 (TerminatedCompliance) are permanent terminations with specific legal/regulatory reasons recorded

**Diagram**:
```
[Activated (1)] --deactivate--> [Deactivated (2)] --reactivate--> [Activated (1)]
      |                                |
      |--terminate-->  [Terminated (0)]
      |--fail KYC-->   [TerminatedRequirements (3)]
      |--compliance--> [TerminatedCompliance (4)]
```

---

## 3. Data Overview

| AccountStatusID | AccountStatusName | Meaning |
|---|---|---|
| 0 | Terminated | Account permanently closed by the platform or user - generic termination with no specific regulatory reason attached |
| 1 | Activated | Account is fully operational - the customer can trade, deposit, withdraw, and access all platform services |
| 2 | Deactivated | Account is temporarily suspended - may be reactivated by admin action. Customer cannot trade but data is preserved |
| 3 | TerminatedRequirements | Account permanently terminated because the customer failed to meet regulatory or KYC (Know Your Customer) requirements within the required timeframe |
| 4 | TerminatedCompliance | Account permanently terminated due to a compliance violation, fraud detection, or regulatory enforcement action |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountStatusID | int | NO | - | VERIFIED | Primary key identifying the account lifecycle state. Values: 0=Terminated, 1=Activated, 2=Deactivated, 3=TerminatedRequirements, 4=TerminatedCompliance. See [Account Status](../../_glossary.md#account-status) for full business definitions. |
| 2 | AccountStatusName | varchar(50) | NO | - | VERIFIED | Human-readable label for the account status. Used in admin UI dropdowns and reporting displays. Matches the business term exactly (e.g., "TerminatedCompliance" indicates compliance-driven termination). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.GetGeneralAffiliateResource | SELECT AccountStatusID, AccountStatusName | Lookup | Returns all account statuses for admin UI resource loading (dropdown population) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.GetGeneralAffiliateResource | Stored Procedure | READER - returns all rows for admin UI resource loading |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.AccountStatus | CLUSTERED PK | AccountStatusID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all account statuses
```sql
SELECT AccountStatusID, AccountStatusName
FROM Dictionary.AccountStatus WITH (NOLOCK)
ORDER BY AccountStatusID
```

### 8.2 Find active/operational statuses only
```sql
SELECT AccountStatusID, AccountStatusName
FROM Dictionary.AccountStatus WITH (NOLOCK)
WHERE AccountStatusID = 1
```

### 8.3 Categorize statuses by permanence
```sql
SELECT
    AccountStatusID,
    AccountStatusName,
    CASE
        WHEN AccountStatusID = 1 THEN 'Operational'
        WHEN AccountStatusID = 2 THEN 'Suspended (reversible)'
        ELSE 'Terminated (permanent)'
    END AS StatusCategory
FROM Dictionary.AccountStatus WITH (NOLOCK)
ORDER BY AccountStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly documenting this object. One tangentially related page was found but contained no information specific to Dictionary.AccountStatus.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountStatus | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.AccountStatus.sql*
