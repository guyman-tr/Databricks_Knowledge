# History.DepositAction

> Append-only event log recording every payment processing action taken on a deposit - each row captures one state transition in the deposit's payment lifecycle (New -> InProcess -> Closed/Approved/Declined) across 37M+ events from 2014.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | DepositActionID (int IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active (CLUSTERED on DepositID, NONCLUSTERED PK on DepositActionID, NC on ResponseID, NC on (ModificationDate, DepositActionID), NC on (DepositID, ModificationDate, PaymentStatusID)) |

---

## 1. Business Meaning

This table is the **complete payment processing event log** for all deposits on the eToro platform. Every interaction between the eToro billing system and an external payment provider (card processors, e-wallets, wire transfer systems) generates a row here via `Billing.DepositActionAdd`. Unlike `History.Deposit` (which stores the final deposit outcome as a single row), this table records **every intermediate step**: the initial request, provider submission, response receipt, and final closure.

Each row answers: "At `ModificationDate`, what was the payment action (`PaymentActionTypeID`) in what processing state (`PaymentActionStatusID`), and what was the deposit's overall status (`PaymentStatusID`) at that moment?" The chronological sequence of rows for a single `DepositID` traces the complete payment journey - from the moment a customer clicks "Deposit" through provider processing to the final approved or declined outcome.

With 37.4M+ rows spanning June 2014 to present, this is one of the highest-volume audit tables in the system. It serves the finance, risk, and support teams for deposit investigation, PSP reconciliation (matching eToro records to payment provider records via `Billing.PSPMatchToEtoro`), and chargeback/refund processing.

The companion table `History.Deposit` stores the final deposit state; this table stores every step that led there.

---

## 2. Business Logic

### 2.1 Deposit Action Lifecycle (State Machine)

**What**: Each deposit progresses through multiple action events. Each event is one row with a PaymentActionTypeID (what kind of action) and PaymentActionStatusID (the state of that action).

**Columns/Parameters Involved**: `DepositID`, `PaymentActionTypeID`, `PaymentActionStatusID`, `PaymentStatusID`, `ModificationDate`

**Rules**:
- `Billing.DepositActionAdd` is called once per event, inserting one row per call.
- `PaymentActionStatusID` progresses: 1=New (submitted) -> 2=InProcess (sent to provider) -> 3=Closed (final outcome received).
- `PaymentStatusID` is the deposit's overall status at the time of the action - it can advance independently of `PaymentActionStatusID`. Example: a deposit can be `PaymentStatusID=13` (Pending) while a new action is in `PaymentActionStatusID=1` (New).
- `Amount` is populated only on the first action for a deposit (the initial submission). Subsequent events carry NULL Amount since the amount is already recorded.
- `DepotID` and `MerchantAccountID` are set when the action is assigned to a specific payment gateway and merchant account; they may be NULL for the initial action or system-generated closure rows.

**Diagram**:
```
Deposit #10793580, Amount=$400 USD:
  ActionID=45624467: ActionStatus=1 (New),       DepositStatus=1 (New),      Amount=400, DepotID=null   <- initial submission
  ActionID=45624468: ActionStatus=2 (InProcess),  DepositStatus=1 (New),      Amount=null, DepotID=87   <- sent to processor (depot=87, merchant=7)
  ActionID=45624469: ActionStatus=1 (New),        DepositStatus=13 (Pending), Amount=null, DepotID=87   <- awaiting provider confirmation
  ActionID=45624470: ActionStatus=3 (Closed),     DepositStatus=2 (Approved), Amount=null, ResponseID=null <- closed internally
  ActionID=45624471: ActionStatus=3 (Closed),     DepositStatus=2 (Approved), Amount=null, ResponseID=3356  <- closed with provider response captured
```

### 2.2 MatchStatusID Carry-Forward Pattern

**What**: `MatchStatusID` is copied from the most recent existing row for the same DepositID before each new INSERT.

**Columns/Parameters Involved**: `MatchStatusID`, `DepositID`

**Rules**:
- In `Billing.DepositActionAdd`, before inserting a new row, the SP reads `MatchStatusID` from the last existing row for `@DepositID` and carries it into the new row.
- This means all rows for a deposit share the same `MatchStatusID` until a matching operation explicitly changes it.
- In practice, 99.9% of rows have `MatchStatusID=0` (unmatched/default state). A small set (41K rows, 0.1%) have NULL from legacy inserts before this logic existed.
- `MatchStatusID` tracks whether this deposit has been matched against the payment provider's settlement records (PSP reconciliation). 0=Unmatched, other values indicate match states (not fully enumerated in DDL).

### 2.3 ResponseID and Provider Responses

**What**: `ResponseID` links the action to the raw payment provider response received.

**Columns/Parameters Involved**: `ResponseID`, `AuthCode`, `ApprovalNumber`

**Rules**:
- `ResponseID` is NULL until the payment provider sends a response. Actions created before the provider responds will have NULL ResponseID.
- Once a provider response arrives, the closing action row gets the `ResponseID`.
- `AuthCode` and `ApprovalNumber` carry the provider's authorization identifiers - used for manual investigation and chargeback defense.
- The NONCLUSTERED index `HDPA_RESPONSE` on `ResponseID` supports fast lookup: "which deposit action corresponds to this provider response?"

### 2.4 Manager Actions vs. Automated Processing

**What**: `ManagerID` distinguishes system-automated actions from back-office manual interventions.

**Columns/Parameters Involved**: `ManagerID`

**Rules**:
- `ManagerID=0` (automated system, no human agent) covers virtually all standard deposit processing.
- Non-zero `ManagerID` values indicate a back-office agent manually triggered an action (e.g., `BackOffice.DepositCancel` -> manual cancel action logged here with the agent's ID).
- NULL `ManagerID` may appear in legacy rows.

---

## 3. Data Overview

| DepositActionID | DepositID | PaymentActionStatusID | PaymentActionTypeID | PaymentStatusID | Amount | ModificationDate | Meaning |
|---|---|---|---|---|---|---|---|
| 45624467 | 10793580 | 1 (New) | 2 (Purchase) | 1 (New) | 400.00 USD | 2026-03-19 10:14:20 | Initial purchase action submitted for deposit #10793580 - $400 deposited, no processor assigned yet. |
| 45624468 | 10793580 | 2 (InProcess) | 2 (Purchase) | 1 (New) | null | 2026-03-19 10:14:20 | Same deposit, action now in-process: assigned to DepotID=87, MerchantAccountID=7. Request sent to payment gateway. |
| 45624469 | 10793580 | 1 (New) | 2 (Purchase) | 13 (Pending) | null | 2026-03-19 10:14:24 | New action cycle: deposit now Pending (awaiting final provider confirmation). New action event opened in New state. |
| 45624470 | 10793580 | 3 (Closed) | 2 (Purchase) | 2 (Approved) | null | 2026-03-19 10:14:35 | Deposit approved. Action closed internally (no ResponseID yet). |
| 45624471 | 10793580 | 3 (Closed) | 2 (Purchase) | 2 (Approved) | null | 2026-03-19 10:14:35 | Final closure with ResponseID=3356 - provider response captured. Deposit processing complete. |

**Volume by PaymentActionStatusID** (37.4M total rows):

| PaymentActionStatusID | Name | Row Count | Share |
|---|---|---|---|
| 1 | New | ~16.1M | ~43% |
| 3 | Closed | ~13.8M | ~37% |
| 2 | InProcess | ~4.5M | ~12% |
| 0 | (Legacy/pre-dictionary) | ~3.0M | ~8% |

**Volume by PaymentActionTypeID**:

| PaymentActionTypeID | Name | Row Count | Share |
|---|---|---|---|
| 2 | Purchase | ~30.7M | ~82% |
| 6 | PostBack | ~3.7M | ~10% |
| 0 | (Legacy) | ~3.0M | ~8% |
| 7 | Cancel | <100K | <0.1% |

**Top PaymentStatusID values at time of action**:

| PaymentStatusID | Name | Row Count | Share |
|---|---|---|---|
| 1 | New | 14.6M | 39% |
| 2 | Approved | 11.1M | 30% |
| 13 | Pending | 5.1M | 14% |
| 5 | InProcess | 3.2M | 9% |
| 35 | DeclineByRRE | 1.5M | 4% |
| 3 | Decline | 1.5M | 4% |
| 4 | Technical | 253K | 1% |
| 12 | Refund | 10K | <1% |
| 11 | Chargeback | 2.5K | <1% |
| 26 | RefundAsChargeback | 824 | <1% |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositActionID | int | NO | IDENTITY | CODE-BACKED | Surrogate primary key, auto-incremented by 1. NOT FOR REPLICATION prevents identity re-seeding on subscriber nodes. NONCLUSTERED PK - the table is physically ordered by DepositID (see clustered index), so range scans by deposit are efficient. Returned as OUTPUT parameter from Billing.DepositActionAdd via SCOPE_IDENTITY(). |
| 2 | DepositID | int | NO | - | CODE-BACKED | The deposit this action belongs to. Clustered index key (HDPA_DEPOSIT) - all rows for a single deposit are physically co-located, enabling fast retrieval of the full action history for one deposit. FK to Billing.Deposit (implicit - no formal constraint). |
| 3 | PaymentActionStatusID | int | NO | - | VERIFIED | The processing state of this specific action event. FK to Dictionary.PaymentActionStatus: 1=New (submitted, not yet sent to provider), 2=InProcess (sent to payment gateway, awaiting response), 3=Closed (final outcome received). Distribution: New 43%, Closed 37%, InProcess 12%, 0=legacy 8%. |
| 4 | PaymentActionTypeID | int | NO | - | VERIFIED | The type of payment action. FK to Dictionary.PaymentActionType: 1=PreAuthorization, 2=Purchase (82% of rows - the standard deposit action), 3=Cashout, 4=Refund, 5=Settle, 6=PostBack (10% - asynchronous provider callback confirming outcome), 7=Cancel (<0.1% - cancellation action). Legacy 0 values in 8% of rows predate the dictionary. |
| 5 | PaymentStatusID | int | NO | - | VERIFIED | The deposit's overall payment status at the time this action was recorded. FK to Dictionary.PaymentStatus: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 26=RefundAsChargeback, 35=DeclineByRRE, 39=ReversedDeposit (39 total values). Enables reconstructing the deposit's status trajectory across all actions. |
| 6 | ResponseID | int | YES | - | CODE-BACKED | Links this action to the raw payment provider response received. NULL for actions created before the provider responds. The NONCLUSTERED index HDPA_RESPONSE on ResponseID supports fast lookup of "which action corresponds to this provider response?" Used in Billing.GetLastDepositActionWithResponseCode. |
| 7 | ManagerID | int | YES | - | CODE-BACKED | The back-office agent ID who triggered this action, or 0 for automated system processing. Non-zero values reference BackOffice.Manager and identify manual interventions (e.g., a BO agent canceling a stuck deposit via BackOffice.DepositCancel). NULL for legacy rows. |
| 8 | ExchangeRate | dbo.dtPrice (decimal(16,8)) | YES | - | NAME-INFERRED | Currency exchange rate applied when the deposit currency differs from USD (system base). Used to convert the deposit Amount to USD for internal accounting. NULL if no conversion was needed (USD deposits). |
| 9 | ApprovalNumber | varchar(20) | YES | - | CODE-BACKED | Payment provider's approval/authorization number for this transaction. Used as a reference identifier in disputes, chargebacks, and manual investigation. Format varies by provider. |
| 10 | AuthCode | varchar(20) | YES | - | CODE-BACKED | Authorization code returned by the payment provider. Used alongside ApprovalNumber for payment verification and dispute resolution. |
| 11 | ModificationDate | datetime | NO | - | VERIFIED | UTC datetime when this action row was inserted (set to GETDATE() by Billing.DepositActionAdd, or overridden via @Now parameter for batch/reprocessing scenarios). The composite NC index on (ModificationDate, DepositActionID) enables chronological queries across all deposits for a time window. |
| 12 | ClearingHouseEffectiveDate | datetime | YES | - | NAME-INFERRED | The date the payment clears the clearing house (bank settlement date). Different from ModificationDate (when the action was recorded) - represents the value date for accounting purposes. NULL for non-cleared actions. |
| 13 | Amount | money | YES | - | CODE-BACKED | The deposit amount in the customer's original currency. Set only on the first action for a deposit (the initial submission row). NULL on all subsequent action rows since the amount is already established. Stored as `money` type (4 decimal places) rather than dbo.dtPrice since this is a transacted fiat amount, not a price. |
| 14 | CurrencyID | int | YES | - | CODE-BACKED | The currency of the Amount. FK to Dictionary.Currency (implicit): 1=USD. NULL when Amount is NULL. Populated only on the initial submission action. |
| 15 | MatchStatusID | tinyint | YES | NULL | CODE-BACKED | PSP reconciliation match status - tracks whether this deposit's actions have been matched against payment provider settlement records. Carried forward from the previous row for the same DepositID by Billing.DepositActionAdd (all rows for a deposit share the same value until a matching operation changes it). Distribution: 0=Unmatched/default (99.9% of rows), NULL=legacy (0.1%). Used in Billing.DepositMatch and Billing.PSPMatchToEtoro for reconciliation workflows. |
| 16 | Remark | varchar(255) | YES | NULL | CODE-BACKED | Free-text note explaining the reason for this action (e.g., reason for cancellation, manual override justification). NULL for automated actions. Carries over from the SP caller context. |
| 17 | SessionID | bigint | YES | NULL | CODE-BACKED | The customer's web session ID at the time of the deposit action. Links the payment event to the customer session for fraud analysis and investigation. NULL for system-generated actions with no user session context. |
| 18 | DepotID | int | YES | - | CODE-BACKED | Identifies the payment gateway/depot (provider routing) used for this action. Set when the deposit is assigned to a specific processor. NULL for initial actions before gateway assignment and for closure rows. Example: DepotID=87 in recent data. |
| 19 | ExchangeFee | int | YES | - | NAME-INFERRED | Fee charged for currency exchange, in the smallest currency unit (cents). NULL for USD deposits or when no exchange fee applies. |
| 20 | BaseExchangeRate | dbo.dtPrice (decimal(16,8)) | YES | - | NAME-INFERRED | The base (pre-markup) exchange rate, as opposed to ExchangeRate which may include the spread. Enables fee calculation: fee = Amount * (ExchangeRate - BaseExchangeRate). |
| 21 | PaymentGeneration | int | YES | - | NAME-INFERRED | Identifies the generation or version of the payment processing flow used for this deposit. Distinguishes between different payment processing implementations deployed over time (e.g., legacy vs. modern payment stack). |
| 22 | ProcessRegulationID | int | YES | - | NAME-INFERRED | The regulatory processing framework applied to this deposit. References a regulatory classification that determines which processing rules and compliance checks apply. May correspond to jurisdiction or entity (e.g., Cyprus vs. US regulatory environment). |
| 23 | MerchantAccountID | int | YES | - | CODE-BACKED | The merchant account within the payment gateway used for this transaction. Works in conjunction with DepotID: DepotID identifies the gateway, MerchantAccountID identifies the specific merchant account on that gateway. Example: MerchantAccountID=7 with DepotID=87 in recent data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.Deposit | Implicit | The deposit this action belongs to |
| PaymentActionStatusID | Dictionary.PaymentActionStatus | Implicit | 1=New, 2=InProcess, 3=Closed |
| PaymentActionTypeID | Dictionary.PaymentActionType | Implicit | 1=PreAuthorization, 2=Purchase, 3=Cashout, 4=Refund, 5=Settle, 6=PostBack, 7=Cancel |
| PaymentStatusID | Dictionary.PaymentStatus | Implicit | 39 values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE ... |
| CurrencyID | Dictionary.Currency | Implicit | The currency of the deposit Amount (1=USD) |
| ManagerID | BackOffice.Manager | Implicit | Back-office agent who triggered the action (0=automated) |
| ResponseID | Billing.Response (or similar) | Implicit | The raw payment provider response linked to this action |
| DepotID | Payment routing/depot table | Implicit | The payment gateway used for routing |
| MerchantAccountID | Merchant account table | Implicit | The specific merchant account on the gateway |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositActionAdd | History.DepositAction | Writer | Primary writer - inserts one row per payment action event |
| Billing.GetLastDepositAction | History.DepositAction | Reader | Returns the most recent action for a deposit |
| Billing.GetLastDepositActionForLog | History.DepositAction | Reader | Most recent action for log/reporting queries |
| Billing.GetLastDepositActionWithResponseCode | History.DepositAction | Reader | Most recent action that has a ResponseID |
| Billing.DepositMatch | History.DepositAction | Reader/Writer | Reads and updates MatchStatusID for reconciliation |
| Billing.PSPMatchToEtoro | History.DepositAction | Reader | PSP-to-eToro deposit matching |
| Billing.PSPMatchToEtoro2 | History.DepositAction | Reader | Variant PSP matching procedure |
| Billing.DepositUpdate | History.DepositAction | Reader | Reads deposit action history during update processing |
| Billing.DepositProcess | History.DepositAction | Reader | Reads action history during deposit processing |
| Billing.DepositCancel | History.DepositAction | Writer | Inserts cancel action row via DepositActionAdd |
| Billing.DepositPendingCancel | History.DepositAction | Writer | Inserts pending-cancel action row |
| Billing.DepositRollback | History.DepositAction | Writer | Inserts rollback action row |
| BackOffice.DepositCancel | History.DepositAction | Writer | Manual BO cancel - inserts cancel action row |
| BackOffice.BillingDepositsPCIVersion | History.DepositAction | Reader | BO deposit investigation view |
| Billing.GetDepositsForExecutions | History.DepositAction | Reader | Queries deposits pending execution |
| Billing.GetDepositsCustomerCardPCIVersion | History.DepositAction | Reader | PCI-compliant card deposit lookup |
| Billing.DepositsCancelByLastDays | History.DepositAction | Writer | Bulk cancellation of deposits by date range |
| Maintenance.JOB_SendDepositToCRM | History.DepositAction | Reader | Reads deposit action data for CRM sync job |
| dbo.Report_Chines_CUP_Summery | History.DepositAction | Reader | China UnionPay deposit summary report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DepositAction (table)
- Leaf node - no code-level dependencies
- Written by Billing.DepositActionAdd (procedure)
- Related to Billing.Deposit (sibling table in deposit lifecycle)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | ExchangeRate, BaseExchangeRate columns (decimal(16,8) NULL) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositActionAdd | Stored Procedure | Primary writer |
| Billing.GetLastDepositAction | Stored Procedure | Reader - most recent action lookup |
| Billing.GetLastDepositActionForLog | Stored Procedure | Reader - log query |
| Billing.GetLastDepositActionWithResponseCode | Stored Procedure | Reader - response-linked action lookup |
| Billing.DepositMatch | Stored Procedure | Reader/Writer - reconciliation |
| Billing.PSPMatchToEtoro | Stored Procedure | Reader - PSP reconciliation |
| Billing.PSPMatchToEtoro2 | Stored Procedure | Reader - PSP reconciliation variant |
| Billing.DepositUpdate | Stored Procedure | Reader |
| Billing.DepositProcess | Stored Procedure | Reader |
| Billing.DepositCancel | Stored Procedure | Writer |
| Billing.DepositPendingCancel | Stored Procedure | Writer |
| Billing.DepositRollback | Stored Procedure | Writer |
| BackOffice.DepositCancel | Stored Procedure | Writer (manual BO action) |
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | Reader (BO investigation) |
| Billing.GetDepositsForExecutions | Stored Procedure | Reader |
| Maintenance.JOB_SendDepositToCRM | Stored Procedure | Reader (CRM sync) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Fill Factor | Status |
|-----------|------|-------------|-----------------|--------|------------|--------|
| HDPA_DEPOSIT | CLUSTERED | DepositID ASC | - | - | 90% | Active |
| PK_HDPA | NONCLUSTERED (PK) | DepositActionID ASC | - | - | 90% | Active |
| HDPA_RESPONSE | NONCLUSTERED | ResponseID ASC | - | - | 90% | Active |
| ix_DepositAction_ModificationDateDepositActionID | NONCLUSTERED | ModificationDate ASC, DepositActionID ASC | - | - | 95% | Active |
| ix_DepositIDModificationIDPaymentStatusID | NONCLUSTERED | DepositID ASC, ModificationDate ASC, PaymentStatusID ASC | - | - | 95% | Active |

**Access patterns served**:
- **By deposit** (most common): CLUSTERED index on DepositID - all action rows for a deposit are physically adjacent. Used by GetLastDepositAction and all deposit processing SPs.
- **By response**: HDPA_RESPONSE on ResponseID - maps provider responses back to deposit actions.
- **By time window**: ix_DepositAction_ModificationDateDepositActionID - enables "what deposit actions occurred in the last N days?" queries (used by monitoring and CRM sync jobs).
- **By deposit + time + status**: ix_DepositIDModificationIDPaymentStatusID - supports status-filtered queries per deposit over a time range.

**Filegroup**: [HISTORY] - dedicated history filegroup.
**Storage**: DATA_COMPRESSION = PAGE on all indexes and heap (table-level + index-level specification).
**Replication**: NOT FOR REPLICATION on IDENTITY - identity values not re-seeded on subscriber nodes.
**Fill factors**: 90% on high-insert indexes (DepositID clustered, ResponseID), 95% on composite indexes used for range scans (allowing more data per page with moderate insert activity).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HDPA | PRIMARY KEY (NONCLUSTERED) | Uniqueness on DepositActionID |
| DF_HistoryDepositAction_MatchStatusID | DEFAULT | MatchStatusID = NULL if not provided |
| DF_HistoryDepositAction_Remark | DEFAULT | Remark = NULL if not provided |
| (unnamed) | DEFAULT | SessionID = NULL if not provided |

---

## 8. Sample Queries

### 8.1 Full action history for a specific deposit
```sql
SELECT da.DepositActionID, da.ModificationDate,
       pas.Name AS ActionStatus, pat.Name AS ActionType,
       ps.Name AS DepositStatus,
       da.Amount, da.CurrencyID, da.ManagerID, da.ResponseID,
       da.DepotID, da.MerchantAccountID, da.Remark
FROM [History].[DepositAction] da WITH (NOLOCK)
LEFT JOIN [Dictionary].[PaymentActionStatus] pas WITH (NOLOCK) ON da.PaymentActionStatusID = pas.PaymentActionStatusID
LEFT JOIN [Dictionary].[PaymentActionType] pat WITH (NOLOCK) ON da.PaymentActionTypeID = pat.PaymentActionTypeID
LEFT JOIN [Dictionary].[PaymentStatus] ps WITH (NOLOCK) ON da.PaymentStatusID = ps.PaymentStatusID
WHERE da.DepositID = 10793580
ORDER BY da.DepositActionID
```

### 8.2 Most recent action per deposit (today's activity)
```sql
SELECT da.DepositID, da.DepositActionID,
       da.PaymentActionStatusID, da.PaymentStatusID,
       da.ModificationDate, da.ResponseID
FROM [History].[DepositAction] da WITH (NOLOCK)
WHERE da.ModificationDate >= CAST(GETDATE() AS DATE)
  AND da.DepositActionID = (
      SELECT MAX(da2.DepositActionID)
      FROM [History].[DepositAction] da2 WITH (NOLOCK)
      WHERE da2.DepositID = da.DepositID
  )
ORDER BY da.ModificationDate DESC
```

### 8.3 Deposits with chargebacks - action history
```sql
SELECT da.DepositID, MIN(da.ModificationDate) AS FirstAction,
       MAX(da.ModificationDate) AS LastAction,
       COUNT(*) AS ActionCount,
       MAX(CASE WHEN da.PaymentStatusID = 11 THEN da.ModificationDate END) AS ChargebackDate
FROM [History].[DepositAction] da WITH (NOLOCK)
WHERE da.PaymentStatusID = 11  -- Chargeback
   OR da.DepositID IN (
       SELECT DISTINCT DepositID FROM [History].[DepositAction] WITH (NOLOCK)
       WHERE PaymentStatusID = 11
   )
GROUP BY da.DepositID
ORDER BY ChargebackDate DESC
```

### 8.4 PSP reconciliation - unmatched deposits by type
```sql
SELECT da.PaymentActionTypeID, COUNT(DISTINCT da.DepositID) AS UnmatchedDeposits
FROM [History].[DepositAction] da WITH (NOLOCK)
WHERE da.MatchStatusID = 0
  AND da.PaymentActionStatusID = 3  -- Closed
  AND da.PaymentStatusID = 2        -- Approved
  AND da.ModificationDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY da.PaymentActionTypeID
ORDER BY UnmatchedDeposits DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 8.8/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DepositAction | Type: Table | Source: etoro/etoro/History/Tables/History.DepositAction.sql*
