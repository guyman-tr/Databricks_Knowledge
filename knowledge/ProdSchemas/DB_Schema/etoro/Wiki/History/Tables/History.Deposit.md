# History.Deposit

> Event-sourced audit log recording every state change of a deposit transaction, with one row per lifecycle event capturing the complete deposit snapshot including amount, payment status, FTD flag, and exchange details at each point in time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint IDENTITY, NONCLUSTERED PK); CLUSTERED on (Occurred, DepositID) |
| **Partition** | No |
| **Indexes** | 3 (1 CLUSTERED + 1 NC PK + 1 NC on DepositID) |

---

## 1. Business Meaning

This table is the immutable event log for every deposit lifecycle transition on the eToro platform. Each row represents a single snapshot of a deposit record at a specific moment - whenever `Billing.Deposit` is created or updated, the current state is written here as a new row. A single deposit (DepositID) typically appears multiple times, once per status change: from New -> InProcess -> Approved (or Failed/Declined).

The table enables complete audit traceability for compliance, fraud investigation, and reconciliation: "what was the exact state of deposit #X at 14:32 UTC yesterday?", "how long did this deposit spend in InProcess before failing?", "which deposits were First-Time Deposits (IsFTD=1) and what was their journey?". With 45.3M rows as of March 2026, this is one of the most active audit tables in the History schema, receiving continuous inserts as deposits flow through the payment processing pipeline.

Data enters exclusively via Billing procedures: `Billing.DepositAdd` (initial submission), `Billing.DepositUpdate` (status updates), `Billing.DepositProcess` (processing), `Billing.DepositCancel`/`Billing.DepositRollback` (failure paths). The CLUSTERED index on (Occurred, DepositID) optimizes time-range reporting queries. PAGE compression and FILLFACTOR=95 reflect the high-insert, append-only workload.

---

## 2. Business Logic

### 2.1 Deposit Lifecycle Event Sourcing

**What**: Multiple rows per DepositID build a complete timeline of the deposit's processing journey.

**Columns/Parameters Involved**: `DepositID`, `PaymentStatusID`, `Occurred`, `ID`

**Rules**:
- Each status change in `Billing.Deposit` triggers an INSERT here with the full row state
- A deposit with PaymentStatusID progression 1->5->2 would have 3 rows in this table
- The ID (IDENTITY) uniquely identifies each event; Occurred timestamps each event
- To get deposit history: `WHERE DepositID = @DepositID ORDER BY Occurred ASC`
- To get final state: `WHERE DepositID = @DepositID ORDER BY ID DESC` (highest ID = latest event)
- Live data example: DepositID 10793017 shows events 1 (New) then 13 (Failed) - a rejected deposit

**Diagram**:
```
DepositID 10793017 lifecycle (from live data):
  ID=45529717: Occurred=05:38:15.747 | PaymentStatusID=1 (New) -> deposit submitted
  ID=45529718: Occurred=05:38:15.933 | PaymentStatusID=13 (Failed) -> payment provider rejected

DepositID 10793016 lifecycle (from live data):
  ID=45529719: Occurred=05:38:16.763 | PaymentStatusID=5 (InProcess) -> being processed
  ID=45529720: Occurred=05:38:16.783 | PaymentStatusID=5 (InProcess) -> re-stamped (same status)
  ID=45529721: Occurred=05:38:16.783 | PaymentStatusID=5 (InProcess) -> another re-stamp
```

### 2.2 First-Time Deposit (FTD) Tracking

**What**: The IsFTD flag identifies the deposit that qualified as the customer's first real-money deposit.

**Columns/Parameters Involved**: `IsFTD`, `CID`, `DepositID`

**Rules**:
- IsFTD = 1 on the specific deposit row where the customer's FTD was confirmed
- IsFTD = 0 or NULL on all subsequent deposits for the same CID
- The FTD event is critical for: marketing attribution, bonus eligibility, compliance KYC triggers, regulatory first-deposit reporting
- One customer should have at most one deposit row with IsFTD=1 across all their DepositIDs

### 2.3 Dispute and Reversal Tracking (DRStatusID)

**What**: Tracks deposit disputes (chargebacks/reversals) as a separate status dimension.

**Columns/Parameters Involved**: `DRStatusID`, `DRDate`

**Rules**:
- DRStatusID = 0 indicates no active dispute (the majority of deposits)
- Non-zero DRStatusID indicates a chargeback or reversal was initiated
- DRDate captures when the dispute was opened or resolved
- Combined with PaymentStatusID to understand the full payment status including dispute state

---

## 3. Data Overview

| ID | Occurred | DepositID | CID | PaymentStatusID | Amount | IsFTD | DepositTypeID |
|---|---|---|---|---|---|---|---|
| 45529721 | 2026-03-19 05:38:16 | 10793016 | 25483136 | 5 (InProcess) | $100.00 | false | 1 (Regular) | Standard $100 regular deposit in processing; the same event appeared 3x in milliseconds suggesting a retry or concurrent update pattern |
| 45529718 | 2026-03-19 05:38:15 | 10793017 | 25483129 | 13 (Failed) | $100.00 | false | 1 (Regular) | $100 regular deposit that failed immediately after creation (ID 45529717 was 1=New, this was 13=Failed ~186ms later) |
| 45529717 | 2026-03-19 05:38:15 | 10793017 | 25483129 | 1 (New) | $100.00 | false | 1 (Regular) | Initial deposit submission event - PaymentStatusID=1 (New) is always the first event for any deposit |
| 45529716 | (earlier) | (different) | - | - | - | - | - | Earlier deposit event showing the high throughput of deposit processing (IDs increment by 1 per event) |
| 45529715 | (earlier) | (different) | - | - | - | - | - | Another concurrent deposit event - multiple deposits process simultaneously on this platform |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp of this event. DEFAULT = GETUTCDATE(). The CLUSTERED index lead key - rows are physically sorted by (Occurred, DepositID). Null allowed in DDL but DEFAULT ensures it is always populated. |
| 2 | DepositID | int | NO | - | CODE-BACKED | Identifier of the deposit record being audited. FK to Billing.Deposit (implicit). Indexed via IX_HistoryDeposit_DepositID for efficient per-deposit history lookup. Part of CLUSTERED index key. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer who made the deposit. Enables customer-level deposit history queries without joining to Billing.Deposit. |
| 4 | FundingID | int | NO | - | CODE-BACKED | Specific payment account/instrument used (e.g., a specific credit card, PayPal account, or bank account ID). References Billing.FundingAccount or similar. |
| 5 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the deposit amount. Live data shows 1 (USD) and 2 (EUR) most commonly. References Dictionary.Currency. |
| 6 | PaymentStatusID | int | NO | - | CODE-BACKED | Deposit processing state at this event. This is the primary "what changed" field. Values include: 1=New, 2=Approved, 5=InProcess, 13=Failed, 11=Chargeback, 36=PendingReview. See [Payment Status](_glossary.md#payment-status). |
| 7 | ManagerID | int | YES | - | NAME-INFERRED | Back-office manager who manually triggered this deposit state change. NULL for automated payment processor events. |
| 8 | RiskManagementStatusID | int | YES | - | NAME-INFERRED | Risk engine evaluation result for this deposit event. Non-null when a risk rule was applied. References Dictionary.RiskStatus or an internal risk classification. |
| 9 | Amount | money | NO | - | CODE-BACKED | Gross deposit amount in the deposit's currency (CurrencyID). The face value requested by the customer - before commissions/fees are deducted. Live data shows $100 (USD) and 100 (EUR) as common amounts. |
| 10 | ExchangeRate | dtPrice | YES | - | NAME-INFERRED | Exchange rate applied to convert the deposit currency to the account's base currency. Uses the dbo.dtPrice UDT (precision price type). NULL if no currency conversion was needed (same-currency deposit). |
| 11 | PaymentDate | datetime | NO | - | NAME-INFERRED | The payment provider's confirmed transaction date. May differ from Occurred (the event timestamp) when provider confirmation is delayed. |
| 12 | ModificationDate | datetime | YES | - | CODE-BACKED | Timestamp of the last modification to the source Billing.Deposit record at the time this history row was captured. |
| 13 | TransactionID | char(6) | NO | - | NAME-INFERRED | Short 6-character transaction reference code. Legacy field from early eToro - may be the last 6 characters of a payment provider reference. |
| 14 | IPAddress | numeric(18,0) | YES | - | NAME-INFERRED | Customer's IP address at deposit time, stored as a numeric value (legacy IP-as-integer format). Used for fraud geo-analysis and velocity checks. |
| 15 | Approved | bit | YES | - | CODE-BACKED | Legacy approval flag. 1 = deposit was approved; 0 or NULL = not approved. Predates the full PaymentStatusID system. Maintained for backward compatibility. |
| 16 | Commission | money | NO | - | CODE-BACKED | Platform commission (fee) deducted from the deposit amount. In most cases 0 for standard deposits; non-zero for specific funding types or promotions. |
| 17 | PaymentData | xml | YES | - | NAME-INFERRED | Raw XML payload from the payment provider response. Contains provider-specific transaction data, authorization codes, and response codes. Stored in TEXTIMAGE_ON PRIMARY filegroup. Used for dispute resolution and provider reconciliation. |
| 18 | ClearingHouseEffectiveDate | datetime | YES | - | NAME-INFERRED | Date the clearing house (bank) recognized the transaction. Used for bank reconciliation; may lag the PaymentDate by 1-3 business days for wire transfers. |
| 19 | OldPaymentID | int | YES | - | NAME-INFERRED | Reference to a superseded/replaced payment record. Used when a deposit is re-submitted or migrated from a legacy payment system. |
| 20 | IsFTD | bit | YES | - | CODE-BACKED | First-Time Deposit flag. 1 = this deposit event was identified as the customer's qualifying first deposit. Drives marketing attribution, bonus eligibility, and KYC compliance triggers. Critical field for acquisition analytics. |
| 21 | ProcessorValueDate | datetime | YES | - | NAME-INFERRED | Value date assigned by the payment processor. For bank wires, the date funds become available to eToro. Used for treasury/cash management. |
| 22 | RefundVerificationCode | varchar(50) | YES | - | NAME-INFERRED | Verification code required to authorize a refund of this deposit. Security measure ensuring refunds match the original deposit. |
| 23 | DepotID | int | YES | - | NAME-INFERRED | Depot/vault identifier for the funds. Used in multi-entity or multi-jurisdiction fund segregation. NULL for standard retail deposits. |
| 24 | MatchStatusID | tinyint | YES | - | NAME-INFERRED | Wire transfer matching status. Used for bank wire deposits where the incoming transfer must be matched to the deposit request. References a small lookup for match states (e.g., unmatched, matched, partial). |
| 25 | FunnelID | int | YES | - | NAME-INFERRED | Marketing/acquisition funnel the customer was on when they made this deposit. Used for conversion analytics and campaign ROI measurement. |
| 26 | Code | varchar(50) | YES | - | NAME-INFERRED | Promotional or campaign code applied at deposit time. Links to a bonus/promotion definition. NULL for no-promo deposits. |
| 27 | ExTransactionID | varchar(50) | YES | - | NAME-INFERRED | External transaction ID from the payment provider. Used for provider-side reconciliation and dispute filing. Distinct from TransactionID (which is internal). |
| 28 | CampaignCodeID | int | YES | - | NAME-INFERRED | Campaign code that qualified this deposit for a bonus. FK to BackOffice.Campaign or similar. NULL if deposit was not part of a bonus campaign. |
| 29 | BonusStatusID | int | YES | - | NAME-INFERRED | Processing state of the bonus associated with this deposit. Tracks whether bonus was awarded, failed, or is pending. |
| 30 | BonusAmount | money | YES | - | NAME-INFERRED | Bonus credit amount granted based on this deposit. NULL if no bonus was applicable. The actual bonus credited to the account balance. |
| 31 | BonusErrorCode | int | YES | - | CODE-BACKED | Error code when bonus processing failed. From Billing.AmountAddBonus: 1=Campaign inactive, 2=Already received, 3=Max users reached, 4=Max amount reached, 5=User cap reached, 6=Bonus max reached. NULL = no error. |
| 32 | SessionID | bigint | YES | - | NAME-INFERRED | Web/API session ID of the customer at deposit submission time. Links to session audit tables for end-to-end request tracing. |
| 33 | DepositTypeID | int | YES | - | CODE-BACKED | Nature/purpose of the deposit. Live data shows 1 (Regular) for standard deposits. See [Deposit Type](_glossary.md#deposit-type). Values: 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. |
| 34 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK for this audit event row. Auto-incrementing (NOT FOR REPLICATION). NONCLUSTERED PK. Monotonically increasing - higher ID = later event. Not the same as DepositID. |
| 35 | DRStatusID | int | YES | - | CODE-BACKED | Dispute/Reversal status. 0 = no dispute (majority of rows per live data). Non-zero = chargeback or reversal process active. Used by the dispute management workflow. |
| 36 | DRDate | datetime | YES | - | CODE-BACKED | Date when the dispute/reversal was opened or last updated. NULL when DRStatusID=0 (no dispute). |
| 37 | ProtocolMIDSettingsID | int | NO | 0 | CODE-BACKED | Merchant ID configuration at the time of this deposit. DEFAULT = 0. Identifies which payment gateway MID (Merchant ID) processed this deposit. References History.ProtocolMIDSettings. |
| 38 | ExchangeFee | int | YES | - | NAME-INFERRED | Fixed fee component for currency exchange, in minor units. Applied when the deposit currency differs from the account currency. |
| 39 | BaseExchangeRate | dtPrice | YES | - | NAME-INFERRED | The base exchange rate before any markup. Uses the dbo.dtPrice UDT. Paired with ExchangeRate to calculate the markup applied on top of the mid-market rate. |
| 40 | PaymentGeneration | int | YES | - | NAME-INFERRED | Payment system generation/version indicator. Used to distinguish deposits processed by different versions of the payment pipeline (e.g., legacy vs next-gen processor). |
| 41 | ProcessRegulationID | int | YES | - | NAME-INFERRED | Regulatory jurisdiction under which this deposit was processed. References Dictionary.Regulation. Determines compliance rules and reporting requirements. |
| 42 | IsSetBalanceCompleted | bit | YES | - | NAME-INFERRED | Whether the balance update (Customer.SetBalance) that accompanies deposit approval was successfully completed. 1 = balance updated; NULL/0 = pending or failed. |
| 43 | RoutingReasonID | int | YES | - | NAME-INFERRED | Reason the deposit was routed to a specific payment processor or path. Used in multi-processor setups where routing logic selects the best provider. |
| 44 | MerchantAccountID | int | YES | - | NAME-INFERRED | Specific merchant account (within a payment provider) that processed the deposit. More granular than ProtocolMIDSettingsID. |
| 45 | StatusReasonID | int | YES | - | NAME-INFERRED | Detailed reason code for the current PaymentStatusID (especially for declines and failures). Provides more granular context than PaymentStatusID alone. |
| 46 | FlowID | int | YES | - | NAME-INFERRED | Payment processing flow version or type. Identifies which deposit flow variant was used (e.g., standard, express, recurring). |
| 47 | ExchangeFeeInUSD | money | YES | - | NAME-INFERRED | Exchange fee amount converted to USD equivalent. Enables standardized fee reporting across multi-currency deposits. |
| 48 | ExchangeFeePercentage | money | YES | - | NAME-INFERRED | Exchange fee expressed as a percentage of the deposit amount. Stored alongside the absolute ExchangeFeeInUSD for reporting flexibility. Note: uses money type despite being a percentage - the value represents a decimal (e.g., 0.005 = 0.5%). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.Deposit | Implicit | The deposit record being audited |
| CID | Customer.CustomerStatic | Implicit | Customer who made the deposit |
| FundingID | Billing.FundingAccount | Implicit | Payment instrument used |
| CurrencyID | Dictionary.Currency | Implicit | Deposit denomination currency |
| PaymentStatusID | Dictionary.PaymentStatus | Implicit | Deposit processing state. See [Payment Status](_glossary.md#payment-status) |
| DepositTypeID | Dictionary.DepositType | Implicit | Deposit classification. See [Deposit Type](_glossary.md#deposit-type) |
| ProtocolMIDSettingsID | History.ProtocolMIDSettings | Implicit | Payment gateway MID configuration |
| ProcessRegulationID | Dictionary.Regulation | Implicit | Regulatory jurisdiction for this deposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositAdd | INSERT | WRITER | Inserts initial deposit event row when a new deposit is created |
| Billing.DepositUpdate | INSERT | WRITER | Inserts a new history row on every deposit status update |
| Billing.DepositProcess | INSERT | WRITER | Inserts row when deposit is processed by payment provider |
| Billing.DepositCancel | INSERT | WRITER | Inserts cancellation event row |
| Billing.DepositRollback | INSERT | WRITER | Inserts rollback event row |
| Billing.DepositActionAdd | INSERT | WRITER | Inserts deposit action events |
| Billing.DepositLogAdd / Billing.DepositLogInsert | INSERT | WRITER | Inserts deposit log entries |
| Billing.DepositMatch | INSERT | WRITER | Inserts match event for wire transfer deposits |
| Billing.DepositPendingCancel | INSERT | WRITER | Inserts pending-cancel event row |
| BackOffice.DepositCancel | INSERT | WRITER | Back-office manual cancellation of deposits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Deposit (table)
- no code-level dependencies (leaf table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Data type for ExchangeRate and BaseExchangeRate columns - precision price type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositAdd | Stored Procedure | WRITER - initial deposit submission |
| Billing.DepositUpdate | Stored Procedure | WRITER - status update events |
| Billing.DepositProcess | Stored Procedure | WRITER - processing events |
| Billing.DepositCancel / BackOffice.DepositCancel | Stored Procedure | WRITER - cancellation events |
| Billing.DepositRollback | Stored Procedure | WRITER - rollback/reversal events |
| Billing.DepositsCancelByLastDays | Stored Procedure | READER - bulk cancellation job reads history for filtering |
| History.Deposit_DataFactory (view) | View | Likely reads this table for DWH/DataFactory consumption |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_Deposit_Occurred_DepositID | CLUSTERED (PAGE compressed, FILLFACTOR=95) | Occurred ASC, DepositID ASC | - | - | Active |
| PK_History_Deposit | NONCLUSTERED (PAGE compressed, FILLFACTOR=95) | ID ASC | - | - | Active |
| IX_HistoryDeposit_DepositID | NONCLUSTERED (PAGE compressed, FILLFACTOR=95) | DepositID ASC | - | - | Active |

Note: CLUSTERED on (Occurred, DepositID) means the table is sorted by time, optimizing time-range deposit reporting. The NONCLUSTERED PK on ID allows identity-based inserts without page splits. FILLFACTOR=95 leaves 5% free space for the high-insert workload. Table is on the MAIN filegroup with XML data in PRIMARY.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_History_Deposit | PRIMARY KEY NONCLUSTERED | ID (bigint IDENTITY) - unique per audit event |
| Df_History_Deposit_Occurred | DEFAULT | Occurred = GETUTCDATE() - timestamp is always set even if caller omits it |
| HDEP_ProtocolMIDSettingsID | DEFAULT | ProtocolMIDSettingsID = 0 - default MID when not specified |

---

## 8. Sample Queries

### 8.1 Get full deposit lifecycle events

```sql
SELECT
    h.ID,
    h.Occurred,
    ps.Name AS PaymentStatus,
    h.Amount,
    h.IsFTD,
    h.ManagerID,
    h.BonusErrorCode
FROM History.Deposit h WITH (NOLOCK)
JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON h.PaymentStatusID = ps.PaymentStatusID
WHERE h.DepositID = @DepositID
ORDER BY h.Occurred ASC;
```

### 8.2 Find a customer's FTD event

```sql
SELECT TOP 1
    h.DepositID,
    h.Occurred AS FTDDate,
    h.Amount,
    h.CurrencyID,
    h.FundingID,
    h.PaymentStatusID
FROM History.Deposit h WITH (NOLOCK)
WHERE h.CID = @CID
  AND h.IsFTD = 1
ORDER BY h.Occurred ASC;
```

### 8.3 Deposit processing funnel by status (time-range report)

```sql
SELECT
    ps.Name AS PaymentStatus,
    COUNT(DISTINCT h.DepositID) AS UniqueDeposits,
    SUM(h.Amount) AS TotalAmount
FROM History.Deposit h WITH (NOLOCK)
JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON h.PaymentStatusID = ps.PaymentStatusID
WHERE h.Occurred >= @StartDate
  AND h.Occurred < @EndDate
  AND h.DepositTypeID = 1  -- Regular deposits only
GROUP BY ps.Name, h.PaymentStatusID
ORDER BY UniqueDeposits DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.2/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 30 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Deposit | Type: Table | Source: etoro/etoro/History/Tables/History.Deposit.sql*
