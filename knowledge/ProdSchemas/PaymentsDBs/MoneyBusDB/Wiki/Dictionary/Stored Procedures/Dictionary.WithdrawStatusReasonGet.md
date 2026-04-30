# Dictionary.WithdrawStatusReasonGet

> Stored procedure that returns all withdrawal status reasons for application-level caching by the withdrawal executor service.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Dictionary.WithdrawStatusReasons |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.WithdrawStatusReasonGet is a simple data-retrieval procedure that returns the complete set of withdrawal status reasons from Dictionary.WithdrawStatusReasons. It serves as the API layer for application services to load the withdrawal status reason lookup table into memory for status resolution and display.

This procedure exists to provide a controlled access point for the withdrawal status reasons lookup data. Rather than having application services query the Dictionary table directly, this procedure encapsulates the access and allows permission grants to be managed at the procedure level. The EXECUTE permission is granted to the withdrawal executor managed service identities (prod-mbwithdrawex-msi-ne, prod-mbwithdrawex-msi-we) for both North Europe and West Europe deployments.

Data flow: Called by the withdrawal executor service (MoneyBus Withdraw Executor) at startup or periodically to cache the status reasons mapping. Returns all 15 withdrawal status reasons with their ID, Name, and WithdrawStatusID. The application uses this data to resolve numeric StatusReasonID values to human-readable names and to determine the parent status category for each reason.

---

## 2. Business Logic

No complex multi-column business logic patterns. This is a straightforward SELECT procedure with no parameters, no filtering, no conditional logic, and no data modification. See the underlying table [Dictionary.WithdrawStatusReasons](../Tables/Dictionary.WithdrawStatusReasons.md) for the business logic behind the status reason hierarchy.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It returns the following result set columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (output) | NO | - | VERIFIED | Withdrawal status reason identifier. Maps to Dictionary.WithdrawStatusReasons.ID. Values: 1=Created, 2=Success, 3=HoldInitiated, 4=HoldApproved, 5=HoldDeclined, 6=AuthorizeInitiated, 7=AuthorizeApproved, 8=AuthorizeDeclined, 9=PayoutInitiated, 10=PayoutApproved, 11=PayoutDeclined, 12=AbortInitiated, 13=AbortCompleted, 14=AbortFailed, 15=RiskManualReview. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason). |
| 2 | Name | nvarchar(100) (output) | NO | - | VERIFIED | Human-readable label for the withdrawal status reason. Application caches these for display in withdrawal tracking UIs and operational dashboards. |
| 3 | WithdrawStatusID | int (output) | NO | - | VERIFIED | Parent withdrawal status ID. Maps each reason to its top-level outcome: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. Application uses this to determine terminal vs non-terminal states. See [Withdraw Status](../../_glossary.md#withdraw-status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.WithdrawStatusReasons | SELECT FROM | Reads all rows from the withdrawal status reasons lookup table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| prod-mbwithdrawex-msi-ne | GRANT EXECUTE | Permission | Withdrawal executor service identity (North Europe) |
| prod-mbwithdrawex-msi-we | GRANT EXECUTE | Permission | Withdrawal executor service identity (West Europe) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WithdrawStatusReasonGet (procedure)
└── Dictionary.WithdrawStatusReasons (table) [SELECT FROM]
    └── Dictionary.WithdrawStatuses (table) [via WithdrawStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WithdrawStatusReasons | Table | SELECT ID, Name, WithdrawStatusID FROM |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| prod-mbwithdrawex-msi-ne | Service Identity | GRANT EXECUTE - calls this procedure for status reason caching |
| prod-mbwithdrawex-msi-we | Service Identity | GRANT EXECUTE - calls this procedure for status reason caching |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Dictionary.WithdrawStatusReasonGet
```

### 8.2 Verify procedure output matches the source table
```sql
-- The procedure should return the same data as:
SELECT ID, Name, WithdrawStatusID
FROM Dictionary.WithdrawStatusReasons WITH (NOLOCK)
ORDER BY ID
```

### 8.3 Check permissions for the procedure
```sql
SELECT dp.name AS Principal, p.permission_name, p.state_desc
FROM sys.database_permissions p WITH (NOLOCK)
INNER JOIN sys.database_principals dp WITH (NOLOCK) ON dp.principal_id = p.grantee_principal_id
WHERE p.major_id = OBJECT_ID('Dictionary.WithdrawStatusReasonGet')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawStatusReasonGet | Type: Stored Procedure | Source: MoneyBusDB/Dictionary/Stored Procedures/Dictionary.WithdrawStatusReasonGet.sql*
