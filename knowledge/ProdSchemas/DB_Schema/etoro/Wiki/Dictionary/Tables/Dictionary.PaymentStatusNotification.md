# Dictionary.PaymentStatusNotification

> Localized notification message templates displayed to customers for each payment status — HTML-formatted deposit outcome messages in multiple languages.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentStatusID + LanguageID (composite NC PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 3 active (PK composite + NC on LanguageID + NC on PaymentStatusID) |

---

## 1. Business Meaning

Dictionary.PaymentStatusNotification stores the customer-facing notification messages displayed after a payment operation (primarily deposits). Each message is an HTML-formatted template associated with a specific payment status and language, allowing the platform to show localized feedback to customers when their deposit succeeds, fails, is blocked, or encounters other conditions.

This table exists because different payment outcomes require different customer communication. A successful deposit (status 2) shows a congratulatory message with the amount and transaction ID, while a declined deposit (status 3/4) explains the rejection and suggests next steps. Blocked payment methods (statuses 8, 14-17, 22-24, 28) show provider-specific block messages.

The notification messages use HTML formatting and support template placeholders like `<#amount#>` and `<#transactionId#>` that are replaced at runtime. The table is read by Billing.LoadPaymentStatusNotifications to load all templates into the billing engine's notification system.

---

## 2. Business Logic

### 2.1 Status-to-Message Mapping

**What**: Each payment status + language combination maps to a specific HTML notification template with dynamic placeholders.

**Columns/Parameters Involved**: `PaymentStatusID`, `LanguageID`, `NotificationMessage`

**Rules**:
- Composite key (PaymentStatusID + LanguageID) ensures exactly one message per status per language.
- Messages use HTML formatting for rich display (bold, links, lists).
- Template placeholders `<#amount#>` and `<#transactionId#>` are replaced at runtime with actual values.
- Payment method block messages (PayPal, Neteller, MoneyBookers, WebMoney, Giropay, ELV, Direct24, Sofort) each have their own status ID and message.
- Currently only English (LanguageID=1) messages exist in production — the multi-language structure supports future localization.

### 2.2 Payment Outcome Categories

**What**: The notification messages group into distinct outcome categories based on the payment status they describe.

**Columns/Parameters Involved**: `PaymentStatusID`, `NotificationMessage`

**Rules**:
- **Success (2)** — Congratulatory message with amount and transaction ID.
- **Decline (3, 4)** — Bank rejection with suggested remediation steps.
- **Cancellation (6)** — User-cancelled deposit with redirect to retry.
- **Duplicate (7)** — Already-transmitted transaction warning.
- **Blocked (8, 14-17, 22-24, 28)** — Payment method blocked by eToro, provider-specific messages.
- **Region Restriction (18)** — Services not available for user's region.
- **Account Restriction (19)** — Online payments blocked for the account.
- **Pending (13)** — eCheque payment awaiting verification.
- **Limit Exceeded (10)** — Deposit limits reached, contact support.

**Diagram**:
```
Payment Notification Categories
├── Success → Status 2 (amount + transactionId)
├── Decline → Status 3, 4 (bank rejection + remediation)
├── Cancel  → Status 6 (redirect to retry)
├── Duplicate → Status 7 (already transmitted)
├── Blocked → Status 8, 14-17, 22-24, 28 (per-provider block)
├── Region  → Status 18 (geographic restriction)
├── Account → Status 19 (account-level block)
├── Pending → Status 13 (eCheque verification)
└── Limit   → Status 10 (deposit limit exceeded)
```

---

## 3. Data Overview

| PaymentStatusID | LanguageID | Meaning |
|---|---|---|
| 2 | 1 | Success message — congratulates the customer, confirms the credited amount and transaction ID. The happy-path outcome for completed deposits. |
| 3 | 1 | Decline message — explains the bank declined the transaction, suggests verifying card details or trying a different card. Shows support link. |
| 8 | 1 | Credit card blocked — informs the customer their credit card has been blocked by eToro. Directs to support for resolution. |
| 13 | 1 | Pending eCheque — payment is pending verification due to eCheque usage. Customer will be notified when verified. |
| 18 | 1 | Region restriction — services are not available in the customer's geographic region. Suggests contacting support if received in error. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentStatusID | int | NO | - | VERIFIED | FK to Dictionary.PaymentStatus. Identifies which payment outcome this notification applies to. Part of composite PK. Values include: 2=Success, 3/4=Decline, 6=Cancel, 7=Duplicate, 8=CardBlocked, 10=LimitExceeded, 13=Pending, 14-17=ProviderBlocked, 18=RegionRestriction, 19=AccountRestriction, 22-24=ProviderBlocked, 28=SofortBlocked. |
| 2 | LanguageID | int | NO | - | VERIFIED | FK to Dictionary.Language. Identifies the language of the notification message. Part of composite PK. Currently only LanguageID=1 (English) is populated. Supports multi-language expansion. |
| 3 | NotificationMessage | nvarchar(1024) | NO | - | VERIFIED | HTML-formatted notification message displayed to the customer. Supports template placeholders: `<#amount#>` (deposit amount), `<#transactionId#>` (transaction reference). Contains HTML tags for formatting (br, ul, li, a href). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentStatusID | Dictionary.PaymentStatus | FK | References the payment status that triggers this notification |
| LanguageID | Dictionary.Language | FK | References the language for localization |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.LoadPaymentStatusNotifications | - | Reader | Loads all notification templates into the billing engine |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PaymentStatusNotification (table)
├── Dictionary.PaymentStatus (table)
└── Dictionary.Language (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentStatus | Table | FK target for PaymentStatusID |
| Dictionary.Language | Table | FK target for LanguageID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.LoadPaymentStatusNotifications | Stored Procedure | Reader — loads all notification templates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPSN | NC PK | PaymentStatusID ASC, LanguageID ASC | - | - | Active |
| DPSN_LANGUAGE | NC | LanguageID ASC | - | - | Active |
| DPSN_PAYMENTSTATUS | NC | PaymentStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPSN | PRIMARY KEY | Unique combination of payment status + language |
| FK_DLNG_DPSN | FOREIGN KEY | LanguageID references Dictionary.Language |
| FK_DPMS_DPSN | FOREIGN KEY | PaymentStatusID references Dictionary.PaymentStatus |

---

## 8. Sample Queries

### 8.1 List all notification messages
```sql
SELECT  psn.PaymentStatusID,
        ps.Name AS StatusName,
        l.Name AS Language,
        psn.NotificationMessage
FROM    [Dictionary].[PaymentStatusNotification] psn WITH (NOLOCK)
JOIN    [Dictionary].[PaymentStatus] ps WITH (NOLOCK)
        ON psn.PaymentStatusID = ps.PaymentStatusID
JOIN    [Dictionary].[Language] l WITH (NOLOCK)
        ON psn.LanguageID = l.LanguageID
ORDER BY psn.PaymentStatusID;
```

### 8.2 Find all blocked-provider messages
```sql
SELECT  PaymentStatusID,
        NotificationMessage
FROM    [Dictionary].[PaymentStatusNotification] WITH (NOLOCK)
WHERE   NotificationMessage LIKE '%blocked%'
ORDER BY PaymentStatusID;
```

### 8.3 Find messages with template placeholders
```sql
SELECT  PaymentStatusID,
        NotificationMessage
FROM    [Dictionary].[PaymentStatusNotification] WITH (NOLOCK)
WHERE   NotificationMessage LIKE '%<#%#>%'
ORDER BY PaymentStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentStatusNotification | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentStatusNotification.sql*
