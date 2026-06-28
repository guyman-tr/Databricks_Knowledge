# Billing.vWithdrawToFunding

> Full-projection view of Billing.WithdrawToFunding with WITH(NOLOCK) hint and the addition of ExchangeFeeInUSD and ExchangeFeeInPercentage columns (added Ran Ovadia 17/09/2024). Provides the complete withdrawal payment leg dataset for external consumers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | ID (WithdrawToFunding.ID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.vWithdrawToFunding` is a near-verbatim projection of `Billing.WithdrawToFunding` that exposes all columns including the two most recently added fields: `ExchangeFeeInUSD` and `ExchangeFeeInPercentage`. The view applies `WITH(NOLOCK)` to prevent the base table's transaction locks from blocking reads.

The view exists to provide downstream consumers (microservices, BI tools, Data Factory pipelines) with a stable query interface to the WithdrawToFunding table. As new columns are added to the base table, the view is updated to include them (as was done for ExchangeFeeInUSD/ExchangeFeeInPercentage), giving consumers a single versioned entry point that tracks the latest schema.

Unlike `Billing.GetWithdrawToFundingFXFeeAmount` (which computes derived FX fee metrics for account statements), this view is a raw data view with no computed columns or filters.

1,071,509 rows. No stored procedure callers in the SQL codebase - used by external tools/microservices.

---

## 2. Business Logic

### 2.1 Full Table Projection (No Filters)

**What**: All rows and all meaningful columns from Billing.WithdrawToFunding are returned with no WHERE clause.

**Columns/Parameters Involved**: All columns

**Rules**:
- No CashoutStatusID filter - all statuses (pending, processed, canceled, rejected) are included
- No date range filter - full historical data
- WITH(NOLOCK) hint prevents read operations from being blocked by ongoing write transactions
- Callers should apply their own filters (e.g., CashoutStatusID=3 for processed only)

### 2.2 ExchangeFeeInUSD and ExchangeFeeInPercentage (Added 17/09/2024)

**What**: Two fee columns added by Ran Ovadia in September 2024 to expose FX fee amounts in standardised USD and percentage form.

**Columns/Parameters Involved**: `ExchangeFeeInUSD`, `ExchangeFeeInPercentage`

**Rules**:
- `ExchangeFeeInUSD`: the FX fee expressed in USD (distinct from ExchangeFee which is in raw decimal form)
- `ExchangeFeeInPercentage`: the FX fee expressed as a percentage of the withdrawal amount
- These columns were added to the base table in the 2024 FX fee transparency initiative and are exposed here for consumers
- Values may be NULL for pre-2024 records where the columns were not populated

---

## 3. Data Overview

**Row count**: 1,071,509 (all withdrawal payment legs, all statuses)

For column-level data distributions, see `Billing.WithdrawToFunding` table documentation (the base table). This view adds no transformations.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | FK to Billing.Withdraw. The parent withdrawal request. One WithdrawID can have multiple payment legs. |
| 2 | FundingID | int | YES | - | CODE-BACKED | FK to Billing.Funding. The payment instrument used for this withdrawal leg. |
| 3 | CashoutStatusID | int | NO | - | CODE-BACKED | Current status of this withdrawal leg. References Dictionary.CashoutStatus. 3=Processed (money sent). NOT filtered in this view - all statuses returned. |
| 4 | ProcessCurrencyID | int | YES | - | CODE-BACKED | Currency in which the withdrawal was processed. References Dictionary.Currency. |
| 5 | ManagerID | int | YES | - | CODE-BACKED | Assigned manager/agent ID for manual review of this withdrawal leg. |
| 6 | ExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate applied to convert the withdrawal to USD. The customer-facing rate including FX markup. |
| 7 | Amount | money | NO | - | CODE-BACKED | Withdrawal leg amount in ProcessCurrencyID. |
| 8 | ModificationDate | datetime | YES | - | CODE-BACKED | Last modification timestamp of this withdrawal leg record. |
| 9 | ID | int | NO | - | CODE-BACKED | PK of Billing.WithdrawToFunding. Unique identifier for this withdrawal payment leg. |
| 10 | DepositID | int | YES | - | CODE-BACKED | FK to Billing.Deposit. Set when the withdrawal is a refund of a specific deposit (e.g., credit card refund must go back to original deposit's card). |
| 11 | RefundAmountInDepositCurrency | money | YES | - | CODE-BACKED | The USD-equivalent amount of this withdrawal leg. Used in FX fee calculations in GetWithdrawToFundingFXFeeAmount. |
| 12 | CashoutTypeID | int | YES | - | CODE-BACKED | Type of cashout/withdrawal. References Dictionary.CashoutType. |
| 13 | VerificationCode | varchar | YES | - | CODE-BACKED | Verification/confirmation code for this withdrawal leg. |
| 14 | ProcessorValueDate | datetime | YES | - | CODE-BACKED | Value date from the payment processor for this leg. |
| 15 | MatchStatusID | int | YES | - | CODE-BACKED | Reconciliation matching status. |
| 16 | DepotID | int | YES | - | CODE-BACKED | FK to Billing.Depot. Gateway/depot that processed this withdrawal leg. |
| 17 | BaseExchangeRate | decimal | YES | - | CODE-BACKED | Market/interbank exchange rate (without FX markup) at time of processing. Used with ExchangeRate to compute FX fee spread. |
| 18 | CashoutModeID | int | YES | - | CODE-BACKED | Mode of the cashout operation. References Dictionary.CashoutMode. |
| 19 | AutoPaymentStartDate | datetime | YES | - | CODE-BACKED | Start date of the automatic payment schedule (for recurring withdrawals). |
| 20 | ProtocolMIDSettingsID | int | YES | - | CODE-BACKED | FK to Billing.ProtocolMIDSettings. The specific MID configuration used for this withdrawal. |
| 21 | ExchangeFee | decimal | YES | - | CODE-BACKED | Raw FX fee value in the rate's decimal form. Used in BaseExchangeRate derivation (WireTransfer path): BaseRate = ExchangeRate - ExchangeFee/10^Multiplier. |
| 22 | CreationDate | datetime | YES | - | CODE-BACKED | Timestamp when this withdrawal leg was created. |
| 23 | AdditionalInformation | nvarchar | YES | - | CODE-BACKED | Free-text additional context for this withdrawal leg (notes, processor responses). |
| 24 | VendorCode | varchar | YES | - | CODE-BACKED | Vendor/processor-specific reference code for this withdrawal. |
| 25 | MerchantAccountID | int | YES | - | CODE-BACKED | FK to merchant account used for processing. |
| 26 | SchemeId | int | YES | - | CODE-BACKED | Payment scheme identifier (e.g., Visa, Mastercard scheme for card withdrawals). |
| 27 | ResponseID | int | YES | - | CODE-BACKED | Payment processor response identifier for this withdrawal leg. |
| 28 | RequestExecuteEntryMethodId | int | YES | - | CODE-BACKED | Entry method used when this withdrawal request was executed. |
| 29 | ExchangeFeeInUSD | money | YES | - | CODE-BACKED | FX fee expressed in USD. Added 17/09/2024 by Ran Ovadia. Part of the 2024 FX fee transparency initiative. NULL for pre-2024 records. |
| 30 | ExchangeFeeInPercentage | decimal | YES | - | CODE-BACKED | FX fee expressed as a percentage of the withdrawal amount. Added 17/09/2024. NULL for pre-2024 records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All 30 columns | Billing.WithdrawToFunding | Source (full projection, no filter) | All withdrawal payment leg records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedure callers found in SQL codebase | - | - | Likely consumed by microservices or BI/Data Factory tools |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.vWithdrawToFunding (view)
└── Billing.WithdrawToFunding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Full SELECT of all 30 columns; WITH(NOLOCK); no WHERE filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | No stored procedures reference this view in the SSDT repo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. 1,071,509 rows. Performance relies on Billing.WithdrawToFunding indexes. Callers should filter on WithdrawID (clustered), ID (PK), or CashoutStatusID (indexed) as appropriate.

### 7.2 Constraints

N/A for view. WITH(NOLOCK) is built into the view definition - dirty reads are possible but typically acceptable for withdrawal reporting. No SCHEMABINDING. No computed columns or filters. ExchangeFeeInUSD and ExchangeFeeInPercentage may be NULL for records predating September 2024.

---

## 8. Sample Queries

### 8.1 Get all processed withdrawal legs for a customer's withdrawal

```sql
SELECT ID, WithdrawID, FundingID, Amount, ProcessCurrencyID, ExchangeRate, BaseExchangeRate, CashoutStatusID, ExchangeFeeInUSD, ExchangeFeeInPercentage
FROM Billing.vWithdrawToFunding WITH (NOLOCK)
WHERE WithdrawID = @WithdrawID
```

### 8.2 Find withdrawal legs with exchange fee data (2024+)

```sql
SELECT ID, WithdrawID, Amount, ExchangeFeeInUSD, ExchangeFeeInPercentage
FROM Billing.vWithdrawToFunding WITH (NOLOCK)
WHERE ExchangeFeeInUSD IS NOT NULL
  AND CashoutStatusID = 3
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.vWithdrawToFunding | Type: View | Source: etoro/etoro/Billing/Views/Billing.vWithdrawToFunding.sql*
