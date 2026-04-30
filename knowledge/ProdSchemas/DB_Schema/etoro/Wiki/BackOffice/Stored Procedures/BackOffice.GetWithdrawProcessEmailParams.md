# BackOffice.GetWithdrawProcessEmailParams

> Retrieves all customer contact, financial, and geographic data needed to populate and send a withdrawal processing email notification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID (input); returns single-row result set with 20 fields |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawProcessEmailParams` assembles the complete parameter set required to render and send a withdrawal notification email to a customer. It consolidates data from six sources - the withdrawal record, customer profile, withdrawal currency, account currency, funding type, and customer state/geography - into a single flat result set ready for email template substitution.

This procedure exists because the withdrawal email template requires data scattered across multiple schemas (Billing, Customer, Dictionary). Without this SP, the email service would need to issue six separate queries and assemble the payload itself. The SP centralises this assembly logic and includes business formatting (e.g. `CONVERT(VARCHAR(50), Amount + Fee, 1)` for currency display with commas).

The procedure is called by the Azure Function `prod-WithdrawNotif-func-ne` (user: `WithdrawalServiceUser`) on a 5-minute timer. The function runs a pipeline: `GetNotificationRecordsForProcessing` -> `GetWithdrawProcessEmailParams` -> `GetPaymentsDetailsHTMLTable` -> render email -> `NotificationsUpdate` -> `AuditActionAdd`. This SP handles the data-fetch step of that pipeline.

---

## 2. Business Logic

### 2.1 Dual-Currency Display

**What**: A withdrawal may be denominated in a currency different from the customer's account deposit currency. Both must be shown on the email.

**Columns/Parameters Involved**: `Currency`, `CurrencySymbol`, `AccountCurrency`, `AccountCurrencySymbol`, `AmountInCurrency`

**Rules**:
- `Currency` / `CurrencySymbol` - the currency in which the withdrawal amount (`Amount + Fee`) is denominated. INNER JOIN to `Dictionary.Currency` on `Withdraw.CurrencyID`.
- `AccountCurrency` / `AccountCurrencySymbol` - the original deposit currency, shown so the customer sees the equivalent amount in their deposit currency. LEFT JOIN to `Dictionary.Currency` on `Withdraw.AccountCurrencyID` (nullable - some older withdrawals have no AccountCurrencyID).
- `AmountInCurrency` (= `RefundAmountInDepositCurrency`) - the withdrawal amount expressed in the account/deposit currency. Populated when `AccountCurrencyID` is set.
- Display name preference: `ISNULL(DisplayName, Abbreviation)` - uses the full display name (e.g. "US Dollar") if available, falls back to abbreviation ("USD").

**Diagram**:
```
Billing.Withdraw
  CurrencyID ---------> Dictionary.Currency (INNER) -> Currency, CurrencySymbol
  AccountCurrencyID ---> Dictionary.Currency (LEFT)  -> AccountCurrency, AccountCurrencySymbol
  RefundAmountInDepositCurrency ------------------------> AmountInCurrency
```

### 2.2 Funding Type Resolution

**What**: The email may need to reference the payment method (e.g. credit card, wire transfer) used for the withdrawal. This is resolved via a two-table subquery.

**Columns/Parameters Involved**: `FundingTypeID`

**Rules**:
- `Billing.WithdrawToFunding` links a withdraw to one or more funding records. The subquery takes `TOP 1` by default ordering (no explicit ORDER BY - most recent or first inserted).
- `Billing.Funding.FundingTypeID` identifies the payment method type (e.g. credit card = specific ID, wire = another ID).
- LEFT JOIN - `FundingTypeID` may be NULL if no funding record exists for this withdrawal.
- Change introduced in Sept 2021 (MIMOPS-3439) to support showing the payment method on the email.

**Diagram**:
```
Billing.Withdraw.WithdrawID
  -> Billing.WithdrawToFunding (TOP 1 by WithdrawID)
      -> Billing.Funding.FundingTypeID -> returned as FundingTypeID
```

### 2.3 Amount Formatting

**What**: Financial amounts are formatted as locale-aware strings with comma thousand separators before being returned, as the email template uses them directly without further formatting.

**Columns/Parameters Involved**: `TotalAmountIncludeFee`, `Fee`

**Rules**:
- `TotalAmountIncludeFee` = `CONVERT(VARCHAR(50), Amount + Fee, 1)` - sum of withdraw amount and fee, formatted as "1,234.56".
- `Fee` = `CONVERT(VARCHAR(50), (-1) * Fee, 1)` - fee amount negated and formatted. Fee is stored as a negative value in `Billing.Withdraw`; multiplying by -1 makes it positive for display.
- Style 1 in CONVERT produces comma-separated thousands with 2 decimal places.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INTEGER | NO | - | CODE-BACKED | Input parameter. The unique identifier of the withdrawal to fetch email parameters for. Maps to `Billing.Withdraw.WithdrawID`. All JOINs and subqueries are filtered to this single withdrawal. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FirstName | NVARCHAR | YES | - | CODE-BACKED | Customer's first name. Sourced from `Customer.CustomerStatic.FirstName`. Used in the email salutation. |
| 2 | LastName | NVARCHAR | YES | - | CODE-BACKED | Customer's last name. Sourced from `Customer.CustomerStatic.LastName`. Added by Eliran Ben Lulu (MIMOPS-5081) for fuller email personalisation. |
| 3 | UserName | NVARCHAR | NO | - | CODE-BACKED | Customer's eToro username. Sourced from `Customer.CustomerStatic.UserName`. Used as the account identifier in the email body. |
| 4 | Address | NVARCHAR | YES | - | CODE-BACKED | Customer's street address. Sourced from `Customer.CustomerStatic.Address`. Added (MIMOPS-5081) to support address-line display in certain jurisdictions' email templates. |
| 5 | PhoneNumber | NVARCHAR | YES | - | CODE-BACKED | Customer's phone number. Sourced from `Customer.CustomerStatic.Phone`. Added (MIMOPS-5081). |
| 6 | TotalAmountIncludeFee | VARCHAR(50) | NO | - | CODE-BACKED | Formatted total withdrawal amount including the fee: `CONVERT(VARCHAR(50), Amount + Fee, 1)`. Rendered as a locale-style string (e.g. "1,250.00") ready for direct insertion into the email template. |
| 7 | Fee | VARCHAR(50) | NO | - | CODE-BACKED | Formatted withdrawal fee as a positive display value: `CONVERT(VARCHAR(50), (-1) * Fee, 1)`. Fee is stored negative in `Billing.Withdraw`; negation makes it positive for display. Style 1 applies comma-thousands formatting. |
| 8 | Currency | NVARCHAR | YES | - | CODE-BACKED | Display name of the withdrawal currency: `ISNULL(cur.DisplayName, cur.Abbreviation)`. E.g. "US Dollar" or falls back to "USD". From `Dictionary.Currency` joined on `Withdraw.CurrencyID`. Updated (MIMOPSA-11413) to prefer `DisplayName` over `Abbreviation`. |
| 9 | CurrencySymbol | NVARCHAR | YES | - | CODE-BACKED | Symbol of the withdrawal currency (e.g. "$", "EUR"). From `Dictionary.Currency.CurrencySymbol`. Added (MIMOPS2-714) Sept 2024 to allow symbol display alongside amount in email. |
| 10 | AccountCurrency | NVARCHAR | YES | - | CODE-BACKED | Display name of the customer's account/deposit currency: `ISNULL(accur.DisplayName, accur.Abbreviation)`. NULL if `Withdraw.AccountCurrencyID` is NULL (older withdrawals). Used to show "your account currency" equivalent amount. LEFT JOIN added (MIMOPS2-2801) replacing prior INNER JOIN to prevent row drops for missing account currencies. |
| 11 | AccountCurrencySymbol | NVARCHAR | YES | - | CODE-BACKED | Symbol of the account/deposit currency. NULL if `AccountCurrencyID` is NULL. Companion to `AccountCurrency` for symbol display. |
| 12 | AmountInCurrency | DECIMAL | YES | - | CODE-BACKED | The withdrawal amount expressed in the original deposit currency (`Billing.Withdraw.RefundAmountInDepositCurrency`). NULL if no deposit-currency conversion is stored. Shown on the email as the equivalent amount in the customer's deposit currency. |
| 13 | RequestedDate | DATETIME | NO | - | CODE-BACKED | Timestamp when the customer submitted the withdrawal request (`Billing.Withdraw.RequestDate`). Shown on the email as the initiation date. |
| 14 | FundingTypeID | INT | YES | - | CODE-BACKED | Identifier of the payment method (funding type) used for this withdrawal. Sourced from `Billing.Funding.FundingTypeID` via `Billing.WithdrawToFunding` (TOP 1 subquery). NULL if no funding record is linked. Added (MIMOPS-3439) to allow payment-method-specific email content. |
| 15 | GCID | UNIQUEIDENTIFIER / VARCHAR | YES | - | CODE-BACKED | Global Customer ID - the cross-system customer identifier used alongside CID. Sourced from `Customer.CustomerStatic.GCID`. Added (MIMOPS-2565, Oct 2020) to support tracking and cross-system correlation in downstream notification systems. |
| 16 | BuildingNumber | NVARCHAR | YES | - | CODE-BACKED | Customer's building/house number. Sourced from `Customer.CustomerStatic.BuildingNumber`. Added (MIMOPSB-1607) Sept 2022 to support full address display on regulated withdrawal confirmations. |
| 17 | City | NVARCHAR | YES | - | CODE-BACKED | Customer's city. Sourced from `Customer.CustomerStatic.City`. Added (MIMOPSB-1607). |
| 18 | State | NVARCHAR | YES | - | CODE-BACKED | Customer's state name (full text), resolved from `Customer.CustomerStatic.StateID` via `Dictionary.State.Name`. NULL if `StateID` is not set or not found. Added (MIMOPSB-1607). |
| 19 | Zip | NVARCHAR | YES | - | CODE-BACKED | Customer's postal / ZIP code. Sourced from `Customer.CustomerStatic.Zip`. Added (MIMOPSB-1607). |
| 20 | WithdrawType | INT | YES | - | CODE-BACKED | Withdrawal type identifier (`Billing.Withdraw.WithdrawTypeID`). Identifies the category of withdrawal (e.g. standard cashout vs. redeem). Added (MIMOPSA-14508) Sept 2024 to allow type-specific email content or routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | Lookup | Primary filter - retrieves the single withdrawal record for the given ID |
| Withdraw.CID | Customer.CustomerStatic | JOIN | Retrieves customer contact and personal data for the email |
| Withdraw.CurrencyID | Dictionary.Currency | Lookup | Resolves the withdrawal currency name and symbol |
| Withdraw.AccountCurrencyID | Dictionary.Currency | Lookup (LEFT) | Resolves the account deposit currency name and symbol; nullable |
| Withdraw.WithdrawID | Billing.WithdrawToFunding | JOIN (subquery) | Links withdrawal to its funding record to get FundingTypeID |
| WithdrawToFunding.FundingID | Billing.Funding | JOIN (subquery) | Retrieves FundingTypeID for payment method identification |
| CustomerStatic.StateID | Dictionary.State | Lookup (LEFT) | Resolves state code to full state name for address display |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Azure Function prod-WithdrawNotif-func-ne | WithdrawID | Caller | Calls this SP every 5 minutes as part of the withdrawal email notification pipeline (user: WithdrawalServiceUser) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawProcessEmailParams (procedure)
├── Billing.Withdraw (table)
├── Customer.CustomerStatic (table)
├── Dictionary.Currency (table) [x2 - withdrawal currency + account currency]
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
└── Dictionary.State (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Main FROM table; filtered by @WithdrawID; provides Amount, Fee, CurrencyID, AccountCurrencyID, RefundAmountInDepositCurrency, RequestDate, CID, WithdrawTypeID |
| Customer.CustomerStatic | Table | INNER JOIN on CID; provides FirstName, LastName, UserName, Address, Phone, GCID, BuildingNumber, City, StateID, Zip |
| Dictionary.Currency | Table | INNER JOIN (withdrawal currency) + LEFT JOIN (account currency); provides DisplayName, Abbreviation, CurrencySymbol |
| Billing.WithdrawToFunding | Table | LEFT JOIN subquery TOP 1 on WithdrawID; links withdrawal to funding record |
| Billing.Funding | Table | INNER JOIN within subquery on FundingID; provides FundingTypeID |
| Dictionary.State | Table | LEFT JOIN on StateID; provides full state Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Azure Function prod-WithdrawNotif-func-ne | External Azure Function | Calls this SP via WithdrawalServiceUser every 5 minutes to fetch email parameters during the withdrawal notification pipeline |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages for caller compatibility |
| WITH (NOLOCK) | Query hint | All tables use NOLOCK - the SP is read-only and tolerates dirty reads for performance |
| TOP 1 in subquery | Row limiter | Billing.WithdrawToFunding subquery takes only the first funding record; no explicit ORDER BY means insertion order is used |

---

## 8. Sample Queries

### 8.1 Fetch email parameters for a specific withdrawal

```sql
EXEC [BackOffice].[GetWithdrawProcessEmailParams] @WithdrawID = 285760;
```

### 8.2 Preview what data would populate the email template

```sql
SELECT
    FirstName + ' ' + LastName AS CustomerName,
    UserName,
    TotalAmountIncludeFee,
    Fee,
    Currency,
    CurrencySymbol,
    AccountCurrency,
    RequestedDate,
    FundingTypeID,
    WithdrawType
FROM (
    EXEC [BackOffice].[GetWithdrawProcessEmailParams] @WithdrawID = 285760
) EmailParams;
```

### 8.3 Check the underlying withdrawal record and customer directly

```sql
SELECT
    w.WithdrawID,
    w.CID,
    cs.UserName,
    cs.FirstName,
    cs.LastName,
    w.Amount,
    w.Fee,
    w.Amount + w.Fee AS TotalIncludeFee,
    cur.DisplayName AS Currency,
    cur.CurrencySymbol,
    w.RequestDate,
    w.WithdrawTypeID
FROM Billing.Withdraw WITH (NOLOCK) w
JOIN Customer.CustomerStatic WITH (NOLOCK) cs ON cs.CID = w.CID
JOIN Dictionary.Currency WITH (NOLOCK) cur ON cur.CurrencyID = w.CurrencyID
WHERE w.WithdrawID = 285760;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Task scheduler for sending Email](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12562301093) | Confluence | Azure Function `prod-WithdrawNotif-func-ne` calls this SP every 5 minutes as part of the withdrawal notification pipeline; user is `WithdrawalServiceUser`; full pipeline: GetNotificationRecordsForProcessing -> GetWithdrawProcessEmailParams -> GetPaymentsDetailsHTMLTable -> NotificationsUpdate -> AuditActionAdd |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers in SSDT (Azure Function caller) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawProcessEmailParams | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawProcessEmailParams.sql*
