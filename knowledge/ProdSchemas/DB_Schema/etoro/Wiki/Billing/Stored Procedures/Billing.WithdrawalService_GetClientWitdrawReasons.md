# Billing.WithdrawalService_GetClientWitdrawReasons

> Returns the active predefined reasons a customer can select when submitting a withdrawal request, ordered by display priority.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all active rows from Dictionary.ClientWithdrawReason |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supplies the withdrawal reason dropdown data to the front-end UI. When a customer opens the withdrawal form, the application calls this procedure to obtain the list of structured reasons available for selection - e.g., "Withdrawing profits", "Moving to a competitor", "None of the reasons above." Returning only active rows (IsActive=1) ensures that product teams can retire or add reason options by updating `Dictionary.ClientWithdrawReason` without requiring code deployments.

The procedure exists so that the UI obtains reason data from the database rather than hard-coding it. This is important for analytics and churn tracking: the selected reason is stored in `Billing.Withdraw.ClientWithdrawReasonID` when `Billing.WithdrawalService_WithdrawRequestAdd` processes the submission. BackOffice and SalesForce procedures subsequently join to `Dictionary.ClientWithdrawReason` to display the reason text in reports and CRM integrations.

The procedure was introduced on 21/11/2016 as part of a schema extension to `Billing.Withdraw` that added `ClientWithdrawReasonID` and `ClientWithdrawReasonComment` columns (noted in the DDL header: "DB-Add new columns to Billing.Withdraw").

---

## 2. Business Logic

### 2.1 Active-Only Filtering with UI Order

**What**: Only currently enabled withdrawal reasons are returned, in the order shown in the customer UI.

**Columns/Parameters Involved**: `IsActive` (filter), `DisplayOrder` (sort)

**Rules**:
- `WHERE IsActive = 1` excludes retired reasons so historical data is preserved without polluting the UI
- `ORDER BY DisplayOrder` returns reasons in business-defined order: 1=Withdrawing profits, 2=Fulfill financial commitments, 3=Goals not achieved, 4=Platform not for me, 5=Close account, 6=Moving to a competitor, 7=None of the reasons above
- "None of the reasons above" (DisplayOrder=7) is positioned last to encourage use of structured options first; when selected, a free-text comment is captured in `Billing.Withdraw.ClientWithdrawReasonComment`

**Diagram**:
```
Withdrawal Form Request
  --> WithdrawalService_GetClientWitdrawReasons
        WHERE IsActive=1 ORDER BY DisplayOrder
  --> UI dropdown (7 options)

Customer selects reason
  --> WithdrawalService_WithdrawRequestAdd(@ClientWithdrawReasonID, @ClientWithdrawReasonComment)
        --> Billing.Withdraw (stored with withdrawal record)
              --> BackOffice / SalesForce procs (join for reason display in admin/CRM)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClientWithdrawReasonID | int | NO | - | VERIFIED | Output column. Identifier for the reason option. Values: 1=None of the reasons above, 2=Withdrawing profits, 3=Fulfill financial commitments, 4=Goals not achieved, 5=Close account, 6=Moving to competitor. Stored in Billing.Withdraw.ClientWithdrawReasonID on withdrawal submission. (Source: Dictionary.ClientWithdrawReason) |
| 2 | DisplayOrder | int | NO | - | VERIFIED | Output column. Sort order for UI presentation. Lower numbers appear first: 1=Withdrawing profits, 7=None of the reasons above. (Source: Dictionary.ClientWithdrawReason) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | Dictionary.ClientWithdrawReason | Lookup | Reads all active withdrawal reason options ordered by display priority |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_GetClientWitdrawReasons (procedure)
└── Dictionary.ClientWithdrawReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ClientWithdrawReason | Table | SELECT source - returns ClientWithdrawReasonID and DisplayOrder for active reasons ordered by display priority |

### 6.2 Objects That Depend On This

No direct callers found in the SSDT repo. Referenced in PROD_BIadmins permissions but no procedure calls discovered in Phase 8 search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure to get withdrawal reason options

```sql
EXEC Billing.WithdrawalService_GetClientWitdrawReasons;
```

### 8.2 Equivalent direct query with reason text for verification

```sql
SELECT  ClientWithdrawReasonID,
        Name,
        DisplayOrder
FROM    Dictionary.ClientWithdrawReason WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY DisplayOrder;
```

### 8.3 Show withdrawal counts by reason to understand churn patterns

```sql
SELECT  cwr.Name                AS WithdrawReason,
        COUNT(w.WithdrawID)     AS WithdrawCount
FROM    Dictionary.ClientWithdrawReason cwr WITH (NOLOCK)
LEFT JOIN Billing.Withdraw w WITH (NOLOCK)
        ON w.ClientWithdrawReasonID = cwr.ClientWithdrawReasonID
WHERE   cwr.IsActive = 1
GROUP BY cwr.Name, cwr.DisplayOrder
ORDER BY cwr.DisplayOrder;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawalService_GetClientWitdrawReasons | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_GetClientWitdrawReasons.sql*
