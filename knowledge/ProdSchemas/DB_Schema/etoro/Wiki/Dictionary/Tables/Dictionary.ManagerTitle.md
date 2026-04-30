# Dictionary.ManagerTitle

> Defines the job role titles for BackOffice managers who are assigned to customer accounts, distinguishing between sales, account management, and customer success roles.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.ManagerTitle classifies the job roles of BackOffice managers. When a manager is assigned to a customer account, their title indicates their organizational function — whether they are part of the sales team, an individual sales representative, an account management team lead, an individual account manager, or a customer success agent.

Without this table, the platform could not categorize managers by role for reporting, assignment routing, and CRM integration. It enables the system to match customers with the appropriate manager type based on the customer's lifecycle stage (acquisition vs retention vs success).

Referenced by BackOffice.Manager (TitleID column) and read by BackOffice.GetManagers procedure for manager listings and assignment screens.

---

## 2. Business Logic

### 2.1 Manager Role Hierarchy

**What**: Five distinct roles covering the customer lifecycle from acquisition through retention.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Sales Team (1) and Sales Representative (2) handle customer acquisition
- Account Management Team (3) and Account Manager (4) handle ongoing customer relationship management
- Customer Success Agent (5) handles proactive customer retention and satisfaction
- Teams (1, 3) are group-level roles; individuals (2, 4, 5) are person-level roles

**Diagram**:
```
Customer Lifecycle:
  Acquisition ──> Sales Team (1) / Sales Representative (2)
  Management  ──> Account Management Team (3) / Account Manager (4)
  Retention   ──> Customer Success Agent (5)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 1 | Sales Team | Group-level role for the inbound/outbound sales organization that acquires new customers and handles initial onboarding |
| 2 | Sales Representative | Individual sales agent who directly contacts and converts prospective customers |
| 3 | Account Management Team | Group-level role for the team managing ongoing customer relationships post-acquisition |
| 4 | Account Manger | Individual account manager assigned to specific customer portfolios for personalized service (note: "Manger" is a known typo in production) |
| 5 | Customer Success Agent | Proactive retention-focused role that monitors customer health metrics and intervenes to prevent churn |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the manager title: 1=Sales Team, 2=Sales Representative, 3=Account Management Team, 4=Account Manager, 5=Customer Success Agent. Referenced by BackOffice.Manager.TitleID. |
| 2 | Name | nvarchar(255) | NO | - | VERIFIED | Human-readable role title displayed in BackOffice manager screens. Uses nvarchar to support internationalized role names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Manager | TitleID | Implicit | Each manager record references a title defining their organizational role |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | TitleID column references this table |
| BackOffice.GetManagers | Stored Procedure | Reads manager titles for display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManagerTitle | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all manager titles
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[ManagerTitle] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find all managers with their titles
```sql
SELECT  m.*,
        mt.Name AS TitleName
FROM    [BackOffice].[Manager] m WITH (NOLOCK)
JOIN    [Dictionary].[ManagerTitle] mt WITH (NOLOCK)
        ON m.TitleID = mt.ID
ORDER BY mt.Name;
```

### 8.3 Count managers per role type
```sql
SELECT  mt.Name AS Title,
        COUNT(*) AS ManagerCount
FROM    [BackOffice].[Manager] m WITH (NOLOCK)
JOIN    [Dictionary].[ManagerTitle] mt WITH (NOLOCK)
        ON m.TitleID = mt.ID
GROUP BY mt.Name
ORDER BY ManagerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ManagerTitle | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ManagerTitle.sql*
