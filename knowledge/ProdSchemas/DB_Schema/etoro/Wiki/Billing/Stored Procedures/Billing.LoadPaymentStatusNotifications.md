# Billing.LoadPaymentStatusNotifications

> Data loader that returns all rows from Dictionary.PaymentStatusNotification, providing the billing engine with the customer-facing notification messages for each payment status outcome.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.PaymentStatusNotification table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPaymentStatusNotifications is a bulk data loader that returns every row from Dictionary.PaymentStatusNotification. This dictionary table maps payment status IDs to the HTML notification messages that are displayed to customers when their deposit results in a specific outcome - for example, a success message with transaction ID for status 2 (Approved), or a decline message explaining the reason for statuses 3-4, 6-10, etc.

This procedure exists as part of the billing engine's initialization pattern. The billing engine loads all notification messages at startup into memory, enabling it to immediately retrieve and display the appropriate customer message when a deposit completes without re-querying the database. Each notification is language-aware (LanguageID column), though the current data contains only English (LanguageID=1) messages.

The table contains 19 rows covering the main status-to-message mappings. Statuses without a notification row (e.g., 1=New, 5=InProcess, 11=Chargeback) presumably use default messaging or no notification.

---

## 2. Business Logic

### 2.1 Customer Notification by Payment Outcome

**What**: Maps payment status codes to HTML notification messages displayed to customers.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns and all rows from Dictionary.PaymentStatusNotification via SELECT * WITH (NOLOCK).
- Key (PaymentStatusID, LanguageID) maps each status+language combination to an HTML notification template.
- Templates may contain dynamic placeholders: `<#amount#>` (deposit amount), `<#transactionId#>` (transaction ID).
- Currently only LanguageID=1 (English) rows exist.
- Not all payment statuses have notification rows - status 1 (New), 5 (InProcess), 11 (Chargeback) have no notification.
- Status coverage: 2=Approved (success), 3=Decline, 4=Technical, 6=Canceled, 7=Confirmed (duplicate), 8=DeclineBlockCard, 9=DeclineBadBins, 10=DeclineMemberLimits, 13=Pending, 14-17=Blocked payment method, 18=BlockedCountry, 19=HighRiskCID, 22-24=Blocked method variants, 28=BlockedSofort.

**Diagram**:
```
Payment Result (Billing Engine)
        |
        v
Dictionary.PaymentStatusNotification
  [PaymentStatusID=2 + LanguageID=1]
        |
        v
"Congratulations, The transaction was processed
 successfully. Your account will be credited with $<#amount#>."
        |
        v
Customer UI Notification Display
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Returns 0 on successful execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Dictionary.PaymentStatusNotification | READ | Reads all customer notification message templates keyed by payment status and language. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache all customer-facing payment notification messages. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentStatusNotifications (procedure)
└── Dictionary.PaymentStatusNotification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentStatusNotification | Table | SELECT * - reads all payment notification templates. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads notification messages at startup. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader to retrieve all payment status notifications
```sql
EXEC Billing.LoadPaymentStatusNotifications;
```

### 8.2 Get the notification message for a specific payment status
```sql
SELECT PaymentStatusID, LanguageID, NotificationMessage
FROM Dictionary.PaymentStatusNotification WITH (NOLOCK)
WHERE PaymentStatusID = 2 AND LanguageID = 1;
```

### 8.3 View all decline-related notifications
```sql
SELECT psn.PaymentStatusID, ps.Name AS StatusName,
       LEFT(psn.NotificationMessage, 100) AS MessagePreview
FROM Dictionary.PaymentStatusNotification psn WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON psn.PaymentStatusID = ps.PaymentStatusID
WHERE ps.Name LIKE 'Decline%'
ORDER BY psn.PaymentStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentStatusNotifications | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentStatusNotifications.sql*
