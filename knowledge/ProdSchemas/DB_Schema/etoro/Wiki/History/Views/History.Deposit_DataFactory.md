# History.Deposit_DataFactory

> BI-optimized view of the deposit audit log - filters out known spam customers and excludes bulk XML and late-added fee columns to provide a clean, analysis-ready interface to History.Deposit for data pipelines and reporting.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | ID (bigint, from base table History.Deposit) |
| **Partition** | N/A (view - base table is unpartitioned, clustered on Occurred/DepositID) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.Deposit_DataFactory is a purpose-built BI interface to the deposit event log (`History.Deposit`). Created by Ran Ovadia on 2023-08-06 specifically for data factory/BI pipelines, this view does two things: it removes known spam customers from the output to prevent them from polluting BI metrics, and it excludes certain columns that are either too heavy for bulk extract (the `PaymentData` XML field) or were added very late to the base table (`StatusReasonID`, `FlowID`, `ExchangeFeeInUSD`, `ExchangeFeePercentage`).

The view allows BI pipelines, Data Factory jobs, and analytics queries to consume deposit history without needing to filter spam accounts themselves or deal with large XML payloads. It exposes 43 of the 48 base table columns - the full business-meaningful set minus the excluded technical/late-addition columns.

No stored procedures currently reference this view by name - it appears to be consumed directly by external BI tools (Azure Data Factory, Databricks, or similar) rather than SQL procedures. This is consistent with the "DataFactory" naming convention indicating it is an external consumption endpoint.

---

## 2. Business Logic

### 2.1 Spam Account Exclusion

**What**: A static exclusion filter removes a known spam customer from all BI output.

**Columns/Parameters Involved**: `CID`

**Rules**:
- WHERE CID NOT IN (43496401) - a single hardcoded exclusion
- CID 43496401 is identified in the DDL comment as a "Spammer"
- This prevents test or artificially-generated deposit data from polluting FTD counts, volume metrics, and conversion funnel analytics
- The exclusion is static (not driven by a table) - any future spam accounts require a DDL change to the view

**Diagram**:
```
History.Deposit (all rows, all real + spam accounts)
    |
    | WHERE CID NOT IN (43496401)
    v
History.Deposit_DataFactory (clean BI dataset, spam excluded)
```

### 2.2 Column Selection for BI Consumption

**What**: 43 of 48 base table columns are selected; 5 columns are intentionally excluded.

**Excluded columns (vs History.Deposit base table)**:
- `PaymentData` (xml) - raw XML payment provider payload; too large and unstructured for bulk extract
- `StatusReasonID` (int) - added after this view was created (2023-08-06)
- `FlowID` (int) - late addition not included in original BI scope
- `ExchangeFeeInUSD` (money) - late addition
- `ExchangeFeePercentage` (money) - late addition

**Rules**:
- All 43 included columns are direct pass-throughs with no transformations
- Column order in the view matches an intentional BI layout (Occurred first, then DepositID, CID for natural pipeline key ordering)
- Newly added columns to the base table will NOT appear in this view until a DDL change is made

---

## 3. Data Overview

| Occurred | DepositID | CID | CurrencyID | PaymentStatusID | Amount | IsFTD | DepositTypeID | PaymentGeneration | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 2026-03-21 12:20:09 | 10803055 | 24860946 | 3 | 2 (Approved) | 100 | false | 5 (RecurringInvestment) | 1 | An approved recurring investment deposit of $100. PaymentGeneration=1 indicates first-generation payment processor. Not FTD - customer has deposited before. |
| 2026-03-21 12:20:09 | 10803057 | 24860975 | 2 (EUR) | 2 (Approved) | 100 | false | 5 (RecurringInvestment) | 1 | EUR 100 recurring investment approved. CurrencyID=2 (EUR) shows the platform receives multi-currency recurring deposits. |
| 2026-03-21 12:20:09 | 10803055 | 24860946 | 3 | 13 (Failed) | 100 | false | 5 (RecurringInvestment) | 1 | An earlier event for the SAME DepositID=10803055 showing a failure BEFORE the approval above - the deposit went through Failed then Approved in rapid succession (milliseconds apart), confirming multi-row event sourcing. |
| (spam rows for CID=43496401) | - | - | - | - | - | - | - | - | Filtered out by the view's WHERE clause - do not appear in BI output. |
| (rows with PaymentData XML) | - | - | - | - | - | - | - | - | PaymentData column excluded from this view; available from History.Deposit directly for dispute/reconciliation use. |

---

## 4. Elements

43 output columns - all direct pass-throughs from History.Deposit, no transformations. Descriptions inherited from History.Deposit.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp of this deposit event. The base table CLUSTERED index sorts on (Occurred, DepositID). Primary time axis for BI time-series analysis. |
| 2 | DepositID | int | NO | - | CODE-BACKED | Identifier of the deposit record being audited. One DepositID appears multiple times as the deposit progresses through status stages. FK to Billing.Deposit (implicit). |
| 3 | CID | int | NO | - | CODE-BACKED | Customer who made the deposit. Filtered: CID=43496401 excluded (spam account). Central key for per-customer deposit analytics. |
| 4 | FundingID | int | NO | - | CODE-BACKED | Specific payment instrument used (credit card, bank account, PayPal, etc.). References Billing.Funding. |
| 5 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the deposit amount. Live data shows 2=EUR, 3=other currencies. References Dictionary.Currency. |
| 6 | PaymentStatusID | int | NO | - | CODE-BACKED | Deposit processing state at this event. 1=New, 2=Approved, 5=InProcess, 13=Failed, 11=Chargeback, 36=PendingReview. The primary "what changed" field in the event log. (Source: Dictionary.PaymentStatus) |
| 7 | ManagerID | int | YES | - | NAME-INFERRED | Back-office manager who manually triggered this deposit state change. NULL for automated payment processor events. |
| 8 | RiskManagementStatusID | int | YES | - | NAME-INFERRED | Risk engine evaluation result for this deposit event. Non-null when a risk rule was applied. |
| 9 | Amount | money | NO | - | CODE-BACKED | Gross deposit amount in the deposit's currency before fees/commissions. The face value requested by the customer. |
| 10 | ExchangeRate | dbo.dtPrice | YES | - | NAME-INFERRED | Exchange rate applied to convert the deposit currency to the account's base currency. NULL if same-currency deposit. |
| 11 | PaymentDate | datetime | NO | - | NAME-INFERRED | Payment provider's confirmed transaction date. May differ from Occurred when provider confirmation is delayed. |
| 12 | ModificationDate | datetime | YES | - | CODE-BACKED | Timestamp of the last modification to the source Billing.Deposit record at the time this history row was captured. |
| 13 | TransactionID | char(6) | NO | - | NAME-INFERRED | Short 6-character internal transaction reference code. Legacy field from early eToro. |
| 14 | IPAddress | numeric(18,0) | YES | - | NAME-INFERRED | Customer's IP address at deposit time, stored as a numeric integer (legacy IP-as-integer format). Used for fraud geo-analysis. |
| 15 | Approved | bit | YES | - | CODE-BACKED | Legacy approval flag. 1=deposit was approved. Predates the full PaymentStatusID system; maintained for backward compatibility. |
| 16 | Commission | money | NO | - | CODE-BACKED | Platform commission (fee) deducted from the deposit. 0 for most standard deposits. |
| 17 | ClearingHouseEffectiveDate | datetime | YES | - | NAME-INFERRED | Date the clearing house (bank) recognized the transaction. May lag PaymentDate by 1-3 business days for wire transfers. |
| 18 | OldPaymentID | int | YES | - | NAME-INFERRED | Reference to a superseded/replaced payment record. Used when a deposit is re-submitted from a legacy payment system. |
| 19 | IsFTD | bit | YES | - | CODE-BACKED | First-Time Deposit flag. 1=this event was the customer's qualifying first deposit. Critical for marketing attribution, bonus eligibility, and KYC compliance triggers. |
| 20 | ProcessorValueDate | datetime | YES | - | NAME-INFERRED | Value date assigned by the payment processor - when funds become available to eToro. Important for treasury/cash management. |
| 21 | RefundVerificationCode | varchar(50) | YES | - | NAME-INFERRED | Verification code required to authorize a refund. Security measure ensuring refunds match the original deposit. |
| 22 | DepotID | int | YES | - | NAME-INFERRED | Depot/vault identifier for the funds. Used in multi-entity or multi-jurisdiction fund segregation. NULL for standard retail deposits. |
| 23 | MatchStatusID | tinyint | YES | - | NAME-INFERRED | Wire transfer matching status. For bank wire deposits where the incoming transfer must be matched to the deposit request. |
| 24 | FunnelID | int | YES | - | NAME-INFERRED | Marketing/acquisition funnel the customer was on at deposit time. Used for conversion analytics and campaign ROI. |
| 25 | Code | varchar(50) | YES | - | NAME-INFERRED | Promotional or campaign code applied at deposit time. NULL for no-promo deposits. |
| 26 | ExTransactionID | varchar(50) | YES | - | NAME-INFERRED | External transaction ID from the payment provider. Used for provider-side reconciliation and dispute filing. |
| 27 | CampaignCodeID | int | YES | - | NAME-INFERRED | Campaign code that qualified this deposit for a bonus. NULL if deposit was not part of a bonus campaign. |
| 28 | BonusStatusID | int | YES | - | NAME-INFERRED | Processing state of the bonus associated with this deposit. Tracks whether bonus was awarded, failed, or pending. |
| 29 | BonusAmount | money | YES | - | NAME-INFERRED | Bonus credit amount granted based on this deposit. NULL if no bonus was applicable. |
| 30 | BonusErrorCode | int | YES | - | CODE-BACKED | Error code when bonus processing failed. 1=Campaign inactive, 2=Already received, 3=Max users reached, 4=Max amount reached, 5=User cap reached, 6=Bonus max reached. NULL=no error. |
| 31 | SessionID | bigint | YES | - | NAME-INFERRED | Web/API session ID at deposit submission time. Links to session audit tables for end-to-end request tracing. |
| 32 | DepositTypeID | int | YES | - | CODE-BACKED | Deposit transaction type. Live data shows 5=RecurringInvestment. 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. (Source: Dictionary.DepositType) |
| 33 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK for this audit event row. Auto-incrementing - higher ID = later event. Not the same as DepositID. |
| 34 | DRStatusID | int | YES | - | CODE-BACKED | Dispute/Reversal status. 0=no dispute. Non-zero=chargeback or reversal process active. |
| 35 | DRDate | datetime | YES | - | CODE-BACKED | Date when the dispute/reversal was opened or last updated. NULL when DRStatusID=0. |
| 36 | ProtocolMIDSettingsID | int | NO | 0 | CODE-BACKED | Merchant ID configuration at the time of this deposit. Identifies which payment gateway MID processed this deposit. References History.ProtocolMIDSettings. |
| 37 | ExchangeFee | int | YES | - | NAME-INFERRED | Fixed fee component for currency exchange in minor units. Applied when deposit currency differs from account currency. |
| 38 | BaseExchangeRate | dbo.dtPrice | YES | - | NAME-INFERRED | Base exchange rate before markup. Paired with ExchangeRate to calculate the markup applied on top of the mid-market rate. |
| 39 | PaymentGeneration | int | YES | - | NAME-INFERRED | Payment system generation/version indicator. Live data shows 1=first-generation pipeline. Distinguishes deposits processed by different versions. |
| 40 | ProcessRegulationID | int | YES | - | NAME-INFERRED | Regulatory jurisdiction under which this deposit was processed. Determines compliance rules and reporting requirements. (Source: Dictionary.Regulation) |
| 41 | IsSetBalanceCompleted | bit | YES | - | NAME-INFERRED | Whether the Customer.SetBalance call that accompanies deposit approval completed successfully. 1=balance updated; NULL/0=pending or failed. |
| 42 | RoutingReasonID | int | YES | - | NAME-INFERRED | Reason the deposit was routed to a specific payment processor. Used in multi-processor setups. |
| 43 | MerchantAccountID | int | YES | - | NAME-INFERRED | Specific merchant account within a payment provider that processed this deposit. More granular than ProtocolMIDSettingsID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns, WHERE filter) | History.Deposit | View | Filtered subset - all 43 columns direct pass-through, one spam CID excluded |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (no SQL procedure consumers found) | - | - | Consumed directly by external BI/Data Factory tools, not via SQL procedures in this schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Deposit_DataFactory (view)
└── History.Deposit (table - leaf node)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Deposit | Table | Sole data source - SELECT 43 of 48 columns, WHERE CID NOT IN (43496401) |

### 6.2 Objects That Depend On This

No SQL procedure dependents in current codebase. Consumed by external BI/Data Factory pipelines directly.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries use History.Deposit indexes:
- CLUSTERED: (Occurred ASC, DepositID ASC) - time-range reporting
- NC PK: ID (event lookup)
- NC: DepositID (per-deposit history lookup)

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get deposit events for a customer (clean, no spam)
```sql
SELECT
    df.DepositID,
    df.PaymentStatusID,
    df.Amount,
    df.CurrencyID,
    df.IsFTD,
    df.DepositTypeID,
    df.Occurred
FROM History.Deposit_DataFactory df WITH (NOLOCK)
WHERE df.CID = 12345678
ORDER BY df.Occurred ASC;
```

### 8.2 Find all First-Time Deposits in a date range (for BI/marketing analytics)
```sql
SELECT
    df.CID,
    df.DepositID,
    df.Amount,
    df.CurrencyID,
    df.FundingID,
    df.FunnelID,
    df.CampaignCodeID,
    df.Occurred
FROM History.Deposit_DataFactory df WITH (NOLOCK)
WHERE df.IsFTD = 1
  AND df.PaymentStatusID = 2  -- Approved only
  AND df.Occurred >= '2026-01-01'
ORDER BY df.Occurred DESC;
```

### 8.3 Deposit pipeline volume by type and status over time
```sql
SELECT
    CAST(df.Occurred AS date) AS DepositDate,
    df.DepositTypeID,
    df.PaymentStatusID,
    df.PaymentGeneration,
    COUNT(*) AS EventCount,
    SUM(df.Amount) AS TotalAmount
FROM History.Deposit_DataFactory df WITH (NOLOCK)
WHERE df.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CAST(df.Occurred AS date), df.DepositTypeID, df.PaymentStatusID, df.PaymentGeneration
ORDER BY DepositDate DESC, EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.Deposit_DataFactory. Business context inherited from History.Deposit documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 7.9/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 19 NAME-INFERRED (inherited from base table, predominantly late-addition columns) | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL consumers | App Code: 0 repos | Corrections: 0 applied*
*Object: History.Deposit_DataFactory | Type: View | Source: etoro/etoro/History/Views/History.Deposit_DataFactory.sql*
