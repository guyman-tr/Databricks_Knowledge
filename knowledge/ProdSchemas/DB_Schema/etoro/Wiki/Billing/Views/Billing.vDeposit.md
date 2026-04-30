# Billing.vDeposit

> Near-complete projection of Billing.Deposit with two additions: an IsRecurring flag (via OUTER APPLY to Billing.RecurringDeposit) and exclusion of a known spammer account (CID=43496401). The standard filtered deposit view for downstream consumers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | DepositID |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.vDeposit` is the standard deposit view for the Billing schema - a near-verbatim projection of `Billing.Deposit` that adds one business-useful computed flag (`IsRecurring`) and applies one data quality exclusion (CID=43496401, a known spammer).

The `IsRecurring` flag (added by Shay O. on 08/08/2021) indicates whether a deposit was triggered by a recurring/scheduled payment plan. It is derived via `OUTER APPLY` to `Billing.RecurringDeposit` - if the DepositID appears in RecurringDeposit, IsRecurring=1; otherwise 0.

The spammer exclusion (`WHERE CID NOT IN (43496401)`) suppresses a hardcoded account known to generate fraudulent/test deposit records that would otherwise pollute reporting and analytics.

7,677,785 rows. 75,396 are recurring (1%). Used by `Billing.DD_GetDepositFollowUpCID`.

---

## 2. Business Logic

### 2.1 IsRecurring Flag via OUTER APPLY

**What**: Marks each deposit as recurring (1) or non-recurring (0) based on existence in Billing.RecurringDeposit.

**Columns/Parameters Involved**: `IsRecurring`, `DepositID`

**Rules**:
- `OUTER APPLY (SELECT 1 IsRecurring FROM Billing.RecurringDeposit WHERE DepositID = BD.DepositID)`
- OUTER APPLY: all deposits are returned; RecurringTest produces 1 if DepositID matches, NULL if not
- `ISNULL(RecurringTest.IsRecurring, 0)`: converts NULL to 0 -> always 0 or 1
- 75,396 deposits are recurring (1%) out of 7,677,785 total
- Recurring deposits represent auto-payment plan charges; non-recurring are one-time deposits

### 2.2 Spammer Exclusion (CID=43496401)

**What**: One hardcoded spammer account is excluded from all results.

**Columns/Parameters Involved**: `CID`

**Rules**:
- WHERE CID NOT IN (43496401): single account excluded
- Hardcoded in DDL with comment "-- Spammers"
- This customer's deposits are suppressed from all views and reports consuming vDeposit
- The account remains in Billing.Deposit (base table is unaffected)

---

## 3. Data Overview

| DepositID | CID | FundingID | CurrencyID | PaymentStatusID | Amount | IsRecurring | Meaning |
|-----------|-----|-----------|------------|-----------------|--------|-------------|---------|
| 10781199 | 25465201 | 606748 | 1 (USD) | 5 | 100 | 0 | Standard $100 deposit, status=5 (some pending/processing state), non-recurring |
| 10781198 | 25465200 | 4148993 | 1 (USD) | 2 | 100 | 0 | Completed $100 deposit (PaymentStatusID=2), non-recurring |

**Row count**: 7,677,785 (Billing.Deposit minus CID=43496401 records)

**IsRecurring distribution**: 75,396 recurring (1%) / 7,602,390 non-recurring (99%)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositID | int | NO | - | CODE-BACKED | Unique deposit identifier. PK of Billing.Deposit. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. From Billing.Deposit. CID=43496401 (spammer) excluded via WHERE. |
| 3 | FundingID | int | YES | - | CODE-BACKED | FK to Billing.Funding. The payment instrument used for this deposit. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Deposit currency. References Dictionary.Currency. 1=USD dominant. |
| 5 | PaymentStatusID | int | NO | - | CODE-BACKED | Deposit processing status. 2=Completed, 5=Pending (other values exist). References Dictionary.PaymentStatus. |
| 6 | ManagerID | int | YES | - | CODE-BACKED | Assigned manager/agent ID for the deposit. From Billing.Deposit. |
| 7 | RiskManagementStatusID | int | YES | - | CODE-BACKED | Risk management review status. References Dictionary.RiskManagementStatus. |
| 8 | Amount | money | NO | - | CODE-BACKED | Deposit amount in CurrencyID. |
| 9 | ExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate applied to convert CurrencyID to USD at deposit time. |
| 10 | PaymentDate | datetime | YES | - | CODE-BACKED | Date/time the payment was processed. |
| 11 | ModificationDate | datetime | YES | - | CODE-BACKED | Last modification timestamp of the deposit record. |
| 12 | TransactionID | varchar | YES | - | CODE-BACKED | Payment processor transaction reference. |
| 13 | IPAddress | varchar | YES | - | CODE-BACKED | Customer IP address at time of deposit. Used for fraud detection. |
| 14 | Approved | bit | YES | - | CODE-BACKED | Manual approval flag. |
| 15 | Commission | money | YES | - | CODE-BACKED | Commission charged on the deposit. |
| 16 | ClearingHouseEffectiveDate | datetime | YES | - | CODE-BACKED | Date when the deposit cleared through the clearing house. |
| 17 | OldPaymentID | int | YES | - | CODE-BACKED | Legacy payment system reference ID. |
| 18 | IsFTD | bit | YES | - | CODE-BACKED | First-time deposit flag. 1=this was the customer's first deposit. Important for bonus and marketing segmentation. |
| 19 | ProcessorValueDate | datetime | YES | - | CODE-BACKED | Value date from the payment processor. |
| 20 | RefundVerificationCode | varchar | YES | - | CODE-BACKED | Verification code for refund processing. |
| 21 | DepotID | int | YES | - | CODE-BACKED | FK to Billing.Depot. The gateway/depot that processed this deposit. |
| 22 | MatchStatusID | int | YES | - | CODE-BACKED | Matching status for reconciliation. |
| 23 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel identifier at time of deposit. |
| 24 | Code | varchar | YES | - | CODE-BACKED | Short code from Billing.GenTransactionID (6-char hex token). |
| 25 | ExTransactionID | varchar | YES | - | CODE-BACKED | External/third-party transaction reference. |
| 26 | BaseExchangeRate | decimal | YES | - | CODE-BACKED | Market/interbank exchange rate (without FX markup). Used to compute FX fee in GetDepositFXFeeAmount. |
| 27 | PaymentGeneration | int | YES | - | CODE-BACKED | Payment processing generation/version. |
| 28 | ProcessRegulationID | int | YES | - | CODE-BACKED | Regulatory jurisdiction that governed this deposit. |
| 29 | MerchantAccountID | int | YES | - | CODE-BACKED | Merchant account that processed the deposit. |
| 30 | IsSetBalanceCompleted | bit | YES | - | CODE-BACKED | Flag indicating balance adjustment for this deposit was completed. |
| 31 | RoutingReasonID | int | YES | - | CODE-BACKED | Reason the deposit was routed to a specific depot/gateway. |
| 32 | IsRecurring | bit (computed) | NO | 0 | CODE-BACKED | 1=this deposit was created by a recurring/scheduled payment plan (exists in Billing.RecurringDeposit). 0=one-time deposit. Added by Shay O. 08/08/2021. Always 0 or 1 (ISNULL converts NULL to 0). 75,396 recurring out of 7,677,785 total (1%). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All deposit columns | Billing.Deposit | Source (FROM, WHERE CID NOT IN (43496401)) | All deposit columns excluding spammer account |
| IsRecurring | Billing.RecurringDeposit | Source (OUTER APPLY on DepositID) | Recurring payment plan flag per deposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DD_GetDepositFollowUpCID | DepositID, CID, ... | Reference | Deposit follow-up processing that uses the filtered/flagged view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.vDeposit (view)
├── Billing.Deposit (table)
└── Billing.RecurringDeposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM source: all deposit columns; WHERE CID NOT IN (43496401) spammer exclusion |
| Billing.RecurringDeposit | Table | OUTER APPLY on DepositID: presence check -> IsRecurring flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DD_GetDepositFollowUpCID | Stored Procedure | Uses vDeposit as the clean deposit source with IsRecurring flag |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. 7,677,785 rows. Performance relies on Billing.Deposit clustered index (DepositID). OUTER APPLY to RecurringDeposit is a correlated lookup per row (checking DepositID match) - efficient when the result set is pre-filtered by the caller. The spammer exclusion (CID NOT IN) uses one hardcoded value and does not materially affect performance.

### 7.2 Constraints

N/A for view. OUTER APPLY semantics: every deposit row is returned regardless of RecurringDeposit match (unlike CROSS APPLY which would filter unmatched rows). IsRecurring is always 0 or 1 - never NULL. The view intentionally omits no columns from Billing.Deposit (all 31 columns are projected); the only additions are the spammer exclusion filter and IsRecurring flag.

---

## 8. Sample Queries

### 8.1 Get all completed deposits for a customer

```sql
SELECT DepositID, Amount, CurrencyID, PaymentStatusID, IsFTD, IsRecurring, PaymentDate
FROM Billing.vDeposit WITH (NOLOCK)
WHERE CID = @CustomerID AND PaymentStatusID = 2
ORDER BY DepositID DESC
```

### 8.2 Count recurring vs one-time deposits

```sql
SELECT IsRecurring, COUNT(*) AS DepositCount, SUM(Amount) AS TotalAmount
FROM Billing.vDeposit WITH (NOLOCK)
WHERE PaymentStatusID = 2
GROUP BY IsRecurring
```

### 8.3 First-time depositors (IsFTD flag)

```sql
SELECT CID, DepositID, Amount, CurrencyID, PaymentDate
FROM Billing.vDeposit WITH (NOLOCK)
WHERE IsFTD = 1 AND PaymentStatusID = 2
ORDER BY PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 32 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.vDeposit | Type: View | Source: etoro/etoro/Billing/Views/Billing.vDeposit.sql*
