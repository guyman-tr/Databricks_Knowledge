# History.PayPalBillingAgreement

> SQL Server temporal history table storing prior row versions of Billing.PayPalBillingAgreement, tracking the full audit trail of PayPal billing agreements linked to customer funding sources.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No (on DICTIONARY filegroup) |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.PayPalBillingAgreement is the SQL Server system-versioning history table for Billing.PayPalBillingAgreement (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[PayPalBillingAgreement])`). Whenever a PayPal billing agreement record is updated or deleted, the prior version is automatically written here by the SQL Server temporal engine.

Billing.PayPalBillingAgreement stores active PayPal billing agreements - pre-authorized recurring payment agreements that allow eToro's BillingService to charge a customer's PayPal account without requiring the customer to re-authorize each deposit. Each agreement is linked to a customer (CID), their specific PayPal funding source (FundingID), and the original deposit that created the agreement (DepositID). The BillingAgreementID is PayPal's reference for the recurring agreement.

Data from the Trace field in the history records shows the most recent history writes were from `PayPalBillingAgreementDelete` procedure calls, indicating these are deletion audit records - agreements that were removed from the active Billing table. The BillingService on the staging billing server writes these changes.

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: This table captures prior versions of PayPal billing agreement records.

**Columns/Parameters Involved**: `PayPalBillingAgreementID`, `SysStartTime`, `SysEndTime`

**Rules**:
- The SysStartTime and SysEndTime columns are declared as HIDDEN in the source table (Billing.PayPalBillingAgreement), but are visible in this history table.
- All changes (updates and deletes) to Billing.PayPalBillingAgreement are automatically captured here.
- To see when a specific agreement was active, query by PayPalBillingAgreementID and sort by SysStartTime.

### 2.2 Agreement Deletion Tracking

**What**: Deleted billing agreements are recorded here with their SysEndTime indicating when deletion occurred.

**Columns/Parameters Involved**: `Trace`, `SysEndTime`

**Rules**:
- Trace is a JSON string capturing the host, application, SQL user, SPID, database, and calling procedure at the time of the change.
- When SysEndTime is far past SysStartTime: the record was live for that duration then deleted or replaced.
- Trace shows `"ObjectName": "PayPalBillingAgreementDelete"` for all observed deletions - agreements were removed by this specific procedure.

---

## 3. Data Overview

| PayPalBillingAgreementID | CID | FundingID | BillingAgreementID | DepositID | SysStartTime | SysEndTime | Meaning |
|-------------------------|-----|-----------|-------------------|-----------|-------------|------------|---------|
| 8531 | 20205283 | 3249761 | B-6TW58840B95321135 | 8574786 | 2025-03-13 12:18 | 2025-07-29 13:10 | Customer's PayPal billing agreement was active ~4.5 months before being deleted by BillingService |
| 8304 | 18565271 | 3154506 | B-0UP689819J1365257 | 8285845 | 2025-01-22 11:47 | 2025-07-29 12:25 | A shared billing agreement (FundingID 3154506) used by two different customers, deleted together |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PayPalBillingAgreementID | int | NO | - | CODE-BACKED | Agreement record identifier from Billing.PayPalBillingAgreement (IDENTITY). Not unique in this history table - the same ID appears for each version. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer identifier who owns this PayPal billing agreement. Links to Customer.CustomerStatic. |
| 3 | FundingID | int | NO | - | CODE-BACKED | PayPal funding source identifier for this customer's PayPal account used in the billing agreement. Unique PayPal-assigned ID for the customer's PayPal payment method. |
| 4 | BillingAgreementID | nvarchar(255) | NO | - | CODE-BACKED | PayPal's reference identifier for the recurring billing agreement. Format: "B-XXXXXXXXXXXXXXXXX" (e.g., "B-6TW58840B95321135"). Used by BillingService to execute future charges against the customer's PayPal account without re-authorization. |
| 5 | DepositID | int | NO | - | CODE-BACKED | The original deposit that established this billing agreement. Links to the Billing/payment system deposit record that was the first use of this PayPal agreement. |
| 6 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON audit string captured at write time, containing: HostName (server), AppName (application), SUserName (SQL login), SPID, DBName, ObjectName (calling procedure). Computed from environment functions in the source table. Shows "PayPalBillingAgreementDelete" for most history records - indicating deletion events. |
| 7 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active. HIDDEN in the source table but visible here. |
| 8 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded (updated or deleted). HIDDEN in source but visible here. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Billing.PayPalBillingAgreement | Temporal History | This table is the declared HISTORY_TABLE for Billing.PayPalBillingAgreement. |
| CID | Customer.CustomerStatic | Implicit | The customer who owns the PayPal billing agreement. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayPalBillingAgreement | HISTORY_TABLE | Temporal system versioning | All changes to active billing agreements are written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayPalBillingAgreement | Table | Source of all history writes via SQL Server temporal system versioning |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PayPalBillingAgreement | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

---

## 8. Sample Queries

### 8.1 View all historical versions of a specific billing agreement record

```sql
SELECT PayPalBillingAgreementID, CID, FundingID, BillingAgreementID, DepositID, SysStartTime, SysEndTime
FROM History.PayPalBillingAgreement WITH (NOLOCK)
WHERE PayPalBillingAgreementID = 8531
ORDER BY SysStartTime;
```

### 8.2 Find all deleted PayPal agreements in the last 90 days

```sql
SELECT PayPalBillingAgreementID, CID, BillingAgreementID, SysStartTime, SysEndTime,
       JSON_VALUE(Trace, '$.ObjectName') AS DeletedBy
FROM History.PayPalBillingAgreement WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -90, GETUTCDATE())
  AND SysEndTime < '9999-12-31'
ORDER BY SysEndTime DESC;
```

### 8.3 Show agreement history for a specific customer

```sql
SELECT PayPalBillingAgreementID, BillingAgreementID, FundingID, DepositID,
       SysStartTime, SysEndTime,
       DATEDIFF(DAY, SysStartTime, SysEndTime) AS DaysActive
FROM History.PayPalBillingAgreement WITH (NOLOCK)
WHERE CID = 20205283
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PayPalBillingAgreement | Type: Table | Source: etoro/etoro/History/Tables/History.PayPalBillingAgreement.sql*
