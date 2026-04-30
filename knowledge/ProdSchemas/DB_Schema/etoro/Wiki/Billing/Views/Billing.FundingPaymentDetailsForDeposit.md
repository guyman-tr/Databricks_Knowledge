# Billing.FundingPaymentDetailsForDeposit

> Funding-instrument-only projection that surfaces payment instrument details with a pre-computed human-readable FundingDetails field for deposit investigation, without joining to any deposit transaction table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | FundingID (from Billing.Funding) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.FundingPaymentDetailsForDeposit` is a simplified variant of the deposit investigation views that exposes payment instrument data WITHOUT joining to any transaction (deposit or withdrawal) table. Each row represents one registered payment instrument with its metadata and a computed FundingDetails string that extracts human-readable account identifiers from the FundingData XML.

The view exists as a lightweight alternative to `Billing.FundingDataForDeposit` when callers only need payment instrument information and do not need deposit transaction details. Querying this view avoids the expensive join to Billing.Deposit and the cross-database join to History.Credit, making it significantly faster for instrument-level lookups.

The difference from `Billing.FundingPaymentDetailsForWithdraw` is that this view does NOT join Dictionary.Country (country resolution for WireTransfer type 2 is commented out in the DDL) and does NOT include eToroMoney refund-specific logic. It is authored by Maksym S. on 29/09/2020 (PAYUA-992), same sprint as the related withdrawal view. Created against Billing.Funding (~3.5M rows).

---

## 2. Business Logic

### 2.1 FundingDetails - Payment Account Identifier (Deposit Context)

**What**: Extracts a human-readable account identifier from FundingData XML, scoped to payment types relevant for deposits. Note the output column is named `FundingDetails` (not `PaymentDetails` like the sibling views).

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData`, `FundingDetails`

**Rules** (by FundingTypeID):
- 1 (CreditCard): '...' (PCI masking)
- 3 or 8 (PayPal/similar): Email from `/Funding/EmailAsString`
- 6 (Neteller): '#' + AccountID + '; ' + email
- 7 or 10 (Skrill/WebMoney): '#' + AccountID
- 11 (bank): IBAN if available, else 'AccID:#' + AccountID
- 17 (UnionPay): BankCode
- 29/32 (ACH): Bank Name, last 4 digits, account type
- 33 (eToroMoney): PlatformAccountId
- 34 (SEPA): IBAN + BIC/SWIFT
- 2 (WireTransfer): NULL (commented out in DDL - requires Deposit.PaymentData not available in this view)
- All others: NULL

---

## 3. Data Overview

N/A - the view exposes all ~3.5M rows of Billing.Funding. Sample rows would mirror Billing.Funding records with the FundingDetails column populated. FundingDetails='...' for credit cards (majority of rows), email strings for e-wallet types.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Payment instrument PK. From Billing.Funding. IDENTITY starting at 1000. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. From Billing.Funding. Controls which XML fields FundingDetails extracts. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Operations manager who created/last modified this instrument. From Billing.Funding. NULL=self-registered. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=instrument blocked from future transactions. 0=active. |
| 5 | BlockedDescription | nvarchar | YES | - | CODE-BACKED | From Billing.Funding. Reason for block. NULL if not blocked. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | From Billing.Funding. Timestamp when blocked. NULL if not blocked. |
| 7 | FundingData | nvarchar(4000) | YES | - | CODE-BACKED | FundingData XML CAST to NVARCHAR(4000). Provider-specific instrument data. Subject to DDM masking. Truncated at 4000 chars. |
| 8 | IsRefundExcluded | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=excluded from automatic refund. |
| 9 | DocumentRequired | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=additional documentation required. |
| 10 | DateCreated | datetime | NO | - | CODE-BACKED | UTC timestamp when this instrument was first registered. From Billing.Funding. |
| 11 | FundingDetails | varchar | YES | - | CODE-BACKED | Computed human-readable payment account identifier from FundingData XML. Named `FundingDetails` (not `PaymentDetails` as in sibling views). WireTransfer (type 2) returns NULL (requires Deposit.PaymentData, commented out). All other logic mirrors FundingDataForDeposit.PaymentDetails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Billing.Funding | Source (FROM - no JOIN) | Single-table view; all rows from Billing.Funding |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Ad-hoc instrument lookup view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingPaymentDetailsForDeposit (view)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | FROM source: all payment instrument rows with FundingDetails CASE computed from FundingData XML |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | Ad-hoc lookup view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: output column is named `FundingDetails` (not `PaymentDetails`). WireTransfer (FundingTypeID=2) returns NULL because the required Deposit.PaymentData is not available in a Funding-only view. No Dictionary.Country JOIN (unlike FundingPaymentDetailsForWithdraw).

---

## 8. Sample Queries

### 8.1 Look up payment instrument details by FundingID

```sql
SELECT FundingID, FundingTypeID, FundingDetails, IsBlocked, BlockedDescription, DateCreated
FROM Billing.FundingPaymentDetailsForDeposit WITH (NOLOCK)
WHERE FundingID = @FundingID
```

### 8.2 Find all blocked payment instruments with their account details

```sql
SELECT FundingID, FundingTypeID, FundingDetails, BlockedDescription, BlockedAt
FROM Billing.FundingPaymentDetailsForDeposit WITH (NOLOCK)
WHERE IsBlocked = 1
ORDER BY BlockedAt DESC
```

### 8.3 Find all eToroMoney instruments by platform account ID

```sql
SELECT FundingID, FundingDetails AS PlatformAccountId, DateCreated
FROM Billing.FundingPaymentDetailsForDeposit WITH (NOLOCK)
WHERE FundingTypeID = 33  -- eToroMoney
  AND FundingDetails = @PlatformAccountId
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-992 | Jira (referenced in DDL comment) | Created by Maksym S. 29/09/2020 as part of the payment details view series |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira (DDL comment ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingPaymentDetailsForDeposit | Type: View | Source: etoro/etoro/Billing/Views/Billing.FundingPaymentDetailsForDeposit.sql*
