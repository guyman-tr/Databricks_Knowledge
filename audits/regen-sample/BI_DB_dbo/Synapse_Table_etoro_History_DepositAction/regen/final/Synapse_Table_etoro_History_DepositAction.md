# BI_DB_dbo.Synapse_Table_etoro_History_DepositAction

> 41.8K-row Bronze landing table mirroring `etoro.History.DepositAction` — the complete payment processing event log for deposits. Contains one day of data at a time (rebuilt daily via COPY INTO from Bronze parquet). Used by `SP_AllDeposits` and `SP_H_Deposits` to resolve the latest payment provider ResponseID per deposit for downstream BI reporting tables.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.History.DepositAction` via Generic Pipeline (Append, daily, etoroDB-REAL) → Bronze parquet → COPY INTO via `SP_Create_Synapse_Table_etoro_History_DepositAction` |
| **Refresh** | Daily — dropped and recreated by `SP_AllDeposits` which calls `SP_Create_Synapse_Table_etoro_History_DepositAction` with a single day range |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a **volatile Bronze landing copy** of the production `etoro.History.DepositAction` table. It holds exactly one day of deposit action events at any given time — `SP_Create_Synapse_Table_etoro_History_DepositAction` drops and recreates the table each run using `COPY INTO` from partitioned Bronze parquet files at `/internal-sources/Bronze/etoro/History/DepositAction/`.

The production source (`History.DepositAction`) is an append-only event log recording every payment processing action taken on a deposit — each row captures one state transition in the deposit's payment lifecycle (New -> InProcess -> Closed/Approved/Declined). The Synapse landing table exists solely to provide `SP_AllDeposits` and `SP_H_Deposits` access to the latest `ResponseID` per `DepositID` for a given day, which is then joined with `External_etoro_Dictionary_Response` to resolve the provider response name for downstream BI tables (`BI_DB_AllDeposits`, `BI_DB_Deposits`).

As of 2026-04-26, the table contains 41,843 rows spanning a single day. The production source contains 37M+ rows from 2014 to present.

---

## 2. Business Logic

### 2.1 Daily Drop-and-Recreate Pattern

**What**: The table is ephemeral — dropped and recreated on each ETL run with a single day of data.
**Columns Involved**: All columns
**Rules**:
- `SP_Create_Synapse_Table_etoro_History_DepositAction` drops the table if it exists, then iterates day-by-day (typically a single day) using `COPY INTO` from Bronze parquet.
- The parquet files are partitioned by `etr_y`, `etr_ym`, `etr_ymd` (year, year-month, year-month-day). The partition columns are NOT included in the Synapse table (they exist only in the external table variant).
- `AUTO_CREATE_TABLE = 'ON'` means column types are inferred from parquet on first load.

### 2.2 Latest ResponseID Resolution

**What**: Downstream SPs use this table to find the most recent payment provider response per deposit.
**Columns Involved**: `DepositID`, `ResponseID`, `ModificationDate`
**Rules**:
- `SP_AllDeposits` filters to rows where `ResponseID IS NOT NULL`, then uses `ROW_NUMBER() OVER (PARTITION BY DepositID ORDER BY ModificationDate DESC) = 1` to get the latest response per deposit.
- The resolved `ResponseID` is joined with `External_etoro_Dictionary_Response` to get `ResponseName`.
- This response is attached to the final `BI_DB_AllDeposits` output row for each deposit.

### 2.3 Deposit Action Lifecycle (Inherited from Production)

**What**: Each row represents one state transition in a deposit's payment lifecycle.
**Columns Involved**: `DepositID`, `PaymentActionTypeID`, `PaymentActionStatusID`, `PaymentStatusID`, `ModificationDate`
**Rules**:
- `PaymentActionStatusID` progresses: 1=New (submitted) -> 2=InProcess (sent to provider) -> 3=Closed (final outcome received).
- `PaymentStatusID` is the deposit's overall status at the time of the action.
- `Amount` is populated only on the first action for a deposit (initial submission). Subsequent events carry NULL.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. No clustered index. The table is small (single day, ~42K rows) and ephemeral, so distribution strategy is not performance-critical.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What was the latest provider response for deposit X? | `SELECT TOP 1 * FROM BI_DB_dbo.Synapse_Table_etoro_History_DepositAction WHERE DepositID = X AND ResponseID IS NOT NULL ORDER BY ModificationDate DESC` |
| How many deposit actions were processed today? | `SELECT COUNT(*) FROM BI_DB_dbo.Synapse_Table_etoro_History_DepositAction` (table holds exactly one day) |
| What is the distribution of payment statuses? | `SELECT PaymentStatusID, COUNT(*) FROM BI_DB_dbo.Synapse_Table_etoro_History_DepositAction GROUP BY PaymentStatusID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit | DepositID = DepositID | Match deposit actions to billing deposit records |
| External_etoro_Dictionary_Response | ResponseID = ResponseID | Resolve ResponseID to ResponseName |

### 3.4 Gotchas

- **Ephemeral table**: Contains only ONE day of data. It is dropped and recreated on each ETL run. Do not rely on historical data being present.
- **NULL Amount**: Amount is only populated on the first action row per deposit. Most rows will have NULL Amount.
- **ManagerID = 0**: Means automated system processing, not a missing value. NULL ManagerID indicates legacy rows.
- **MatchStatusID = 0**: Default/unmatched state for PSP reconciliation. Not a missing value.
- **varchar(max) columns**: `ApprovalNumber`, `AuthCode`, and `Remark` are widened to `varchar(max)` in Synapse vs. production (varchar(20)/varchar(255)). This is a type accommodation, not a data difference.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (History.DepositAction) |
| Tier 2 | ETL-computed or transformed by SP |
| Tier 3 | No upstream wiki; grounded in DDL + SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositActionID | int | YES | Surrogate primary key, auto-incremented by 1 in production. NOT FOR REPLICATION prevents identity re-seeding on subscriber nodes. Returned as OUTPUT parameter from Billing.DepositActionAdd via SCOPE_IDENTITY(). (Tier 1 — History.DepositAction) |
| 2 | DepositID | int | YES | The deposit this action belongs to. FK to Billing.Deposit (implicit - no formal constraint). (Tier 1 — History.DepositAction) |
| 3 | PaymentActionStatusID | int | YES | The processing state of this specific action event. FK to Dictionary.PaymentActionStatus: 1=New (submitted, not yet sent to provider), 2=InProcess (sent to payment gateway, awaiting response), 3=Closed (final outcome received). (Tier 1 — History.DepositAction) |
| 4 | PaymentActionTypeID | int | YES | The type of payment action. FK to Dictionary.PaymentActionType: 1=PreAuthorization, 2=Purchase (the standard deposit action), 3=Cashout, 4=Refund, 5=Settle, 6=PostBack (asynchronous provider callback confirming outcome), 7=Cancel (cancellation action). (Tier 1 — History.DepositAction) |
| 5 | PaymentStatusID | int | YES | The deposit's overall payment status at the time this action was recorded. FK to Dictionary.PaymentStatus: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 26=RefundAsChargeback, 35=DeclineByRRE. Enables reconstructing the deposit's status trajectory across all actions. (Tier 1 — History.DepositAction) |
| 6 | ResponseID | int | YES | Links this action to the raw payment provider response received. NULL for actions created before the provider responds. Used in Billing.GetLastDepositActionWithResponseCode. (Tier 1 — History.DepositAction) |
| 7 | ManagerID | int | YES | The back-office agent ID who triggered this action, or 0 for automated system processing. Non-zero values reference BackOffice.Manager and identify manual interventions (e.g., a BO agent canceling a stuck deposit via BackOffice.DepositCancel). NULL for legacy rows. (Tier 1 — History.DepositAction) |
| 8 | ExchangeRate | numeric(16,8) | YES | Currency exchange rate applied when the deposit currency differs from USD (system base). Used to convert the deposit Amount to USD for internal accounting. NULL if no conversion was needed (USD deposits). (Tier 1 — History.DepositAction) |
| 9 | ApprovalNumber | varchar(max) | YES | Payment provider's approval/authorization number for this transaction. Used as a reference identifier in disputes, chargebacks, and manual investigation. Format varies by provider. (Tier 1 — History.DepositAction) |
| 10 | AuthCode | varchar(max) | YES | Authorization code returned by the payment provider. Used alongside ApprovalNumber for payment verification and dispute resolution. (Tier 1 — History.DepositAction) |
| 11 | ModificationDate | datetime2(7) | YES | UTC datetime when this action row was inserted (set to GETDATE() by Billing.DepositActionAdd, or overridden via @Now parameter for batch/reprocessing scenarios). (Tier 1 — History.DepositAction) |
| 12 | ClearingHouseEffectiveDate | datetime2(7) | YES | The date the payment clears the clearing house (bank settlement date). Different from ModificationDate (when the action was recorded) - represents the value date for accounting purposes. NULL for non-cleared actions. (Tier 1 — History.DepositAction) |
| 13 | Amount | numeric(19,4) | YES | The deposit amount in the customer's original currency. Set only on the first action for a deposit (the initial submission row). NULL on all subsequent action rows since the amount is already established. (Tier 1 — History.DepositAction) |
| 14 | CurrencyID | int | YES | The currency of the Amount. FK to Dictionary.Currency (implicit): 1=USD. NULL when Amount is NULL. Populated only on the initial submission action. (Tier 1 — History.DepositAction) |
| 15 | MatchStatusID | int | YES | PSP reconciliation match status - tracks whether this deposit's actions have been matched against payment provider settlement records. Carried forward from the previous row for the same DepositID by Billing.DepositActionAdd. 0=Unmatched/default. Used in Billing.DepositMatch and Billing.PSPMatchToEtoro for reconciliation workflows. (Tier 1 — History.DepositAction) |
| 16 | Remark | varchar(max) | YES | Free-text note explaining the reason for this action (e.g., reason for cancellation, manual override justification). NULL for automated actions. Carries over from the SP caller context. (Tier 1 — History.DepositAction) |
| 17 | SessionID | bigint | YES | The customer's web session ID at the time of the deposit action. Links the payment event to the customer session for fraud analysis and investigation. NULL for system-generated actions with no user session context. (Tier 1 — History.DepositAction) |
| 18 | DepotID | int | YES | Identifies the payment gateway/depot (provider routing) used for this action. Set when the deposit is assigned to a specific processor. NULL for initial actions before gateway assignment and for closure rows. (Tier 1 — History.DepositAction) |
| 19 | ExchangeFee | int | YES | Fee charged for currency exchange, in the smallest currency unit (cents). NULL for USD deposits or when no exchange fee applies. (Tier 1 — History.DepositAction) |
| 20 | BaseExchangeRate | numeric(16,8) | YES | The base (pre-markup) exchange rate, as opposed to ExchangeRate which may include the spread. Enables fee calculation: fee = Amount * (ExchangeRate - BaseExchangeRate). (Tier 1 — History.DepositAction) |
| 21 | PaymentGeneration | int | YES | Identifies the generation or version of the payment processing flow used for this deposit. Distinguishes between different payment processing implementations deployed over time (e.g., legacy vs. modern payment stack). (Tier 1 — History.DepositAction) |
| 22 | ProcessRegulationID | int | YES | The regulatory processing framework applied to this deposit. References a regulatory classification that determines which processing rules and compliance checks apply. May correspond to jurisdiction or entity (e.g., Cyprus vs. US regulatory environment). (Tier 1 — History.DepositAction) |
| 23 | MerchantAccountID | int | YES | The merchant account within the payment gateway used for this transaction. Works in conjunction with DepotID: DepotID identifies the gateway, MerchantAccountID identifies the specific merchant account on that gateway. (Tier 1 — History.DepositAction) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| DepositActionID | History.DepositAction | DepositActionID | Passthrough (IDENTITY stripped) |
| DepositID | History.DepositAction | DepositID | Passthrough |
| PaymentActionStatusID | History.DepositAction | PaymentActionStatusID | Passthrough |
| PaymentActionTypeID | History.DepositAction | PaymentActionTypeID | Passthrough |
| PaymentStatusID | History.DepositAction | PaymentStatusID | Passthrough |
| ResponseID | History.DepositAction | ResponseID | Passthrough |
| ManagerID | History.DepositAction | ManagerID | Passthrough |
| ExchangeRate | History.DepositAction | ExchangeRate | Passthrough (dbo.dtPrice -> numeric(16,8)) |
| ApprovalNumber | History.DepositAction | ApprovalNumber | Passthrough (varchar(20) -> varchar(max)) |
| AuthCode | History.DepositAction | AuthCode | Passthrough (varchar(20) -> varchar(max)) |
| ModificationDate | History.DepositAction | ModificationDate | Passthrough (datetime -> datetime2(7)) |
| ClearingHouseEffectiveDate | History.DepositAction | ClearingHouseEffectiveDate | Passthrough (datetime -> datetime2(7)) |
| Amount | History.DepositAction | Amount | Passthrough (money -> numeric(19,4)) |
| CurrencyID | History.DepositAction | CurrencyID | Passthrough |
| MatchStatusID | History.DepositAction | MatchStatusID | Passthrough (tinyint -> int) |
| Remark | History.DepositAction | Remark | Passthrough (varchar(255) -> varchar(max)) |
| SessionID | History.DepositAction | SessionID | Passthrough |
| DepotID | History.DepositAction | DepotID | Passthrough |
| ExchangeFee | History.DepositAction | ExchangeFee | Passthrough |
| BaseExchangeRate | History.DepositAction | BaseExchangeRate | Passthrough (dbo.dtPrice -> numeric(16,8)) |
| PaymentGeneration | History.DepositAction | PaymentGeneration | Passthrough |
| ProcessRegulationID | History.DepositAction | ProcessRegulationID | Passthrough |
| MerchantAccountID | History.DepositAction | MerchantAccountID | Passthrough |

### 5.2 ETL Pipeline

```
etoro.History.DepositAction (production, etoroDB-REAL, 37M+ rows)
  |-- Generic Pipeline (Append, daily, parquet) ---|
  v
Bronze/etoro/History/DepositAction/ (Data Lake, partitioned by etr_ymd)
  |-- COPY INTO via SP_Create_Synapse_Table_etoro_History_DepositAction ---|
  v
BI_DB_dbo.Synapse_Table_etoro_History_DepositAction (~42K rows, single day)
  |-- SP_AllDeposits (latest ResponseID per DepositID) ---|
  v
BI_DB_dbo.BI_DB_AllDeposits (enriched deposit reporting table)
  |-- SP_H_Deposits (via External table variant) ---|
  v
BI_DB_dbo.BI_DB_Deposits (historical deposit reporting table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DepositID | Billing.Deposit | The deposit this action belongs to |
| PaymentActionStatusID | Dictionary.PaymentActionStatus | 1=New, 2=InProcess, 3=Closed |
| PaymentActionTypeID | Dictionary.PaymentActionType | 1=PreAuthorization, 2=Purchase, 3=Cashout, 4=Refund, 5=Settle, 6=PostBack, 7=Cancel |
| PaymentStatusID | Dictionary.PaymentStatus | 1=New, 2=Approved, 3=Decline, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE |
| CurrencyID | Dictionary.Currency | Currency of the deposit amount (1=USD) |
| ManagerID | BackOffice.Manager | Back-office agent who triggered the action (0=automated) |
| ResponseID | Billing.Response | Raw payment provider response linked to this action |
| DepotID | Payment gateway/depot table | Payment gateway used for routing |
| MerchantAccountID | Merchant account table | Specific merchant account on the gateway |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_Create_Synapse_Table_etoro_History_DepositAction | Target table | Writer — drops and recreates via COPY INTO from Bronze parquet |
| SP_AllDeposits | DepositID, ResponseID, ModificationDate | Reader — resolves latest ResponseID per deposit for BI_DB_AllDeposits |
| SP_H_Deposits | (uses External table variant) | Reader — resolves ResponseID for BI_DB_Deposits |

---

## 7. Sample Queries

### 7.1 Latest provider response per deposit

```sql
SELECT da.DepositID, da.ResponseID, da.ModificationDate
FROM (
    SELECT DepositID, ResponseID, ModificationDate,
           ROW_NUMBER() OVER (PARTITION BY DepositID ORDER BY ModificationDate DESC) AS RN
    FROM BI_DB_dbo.Synapse_Table_etoro_History_DepositAction
    WHERE ResponseID IS NOT NULL
) da
WHERE da.RN = 1
```

### 7.2 Payment action status distribution for the day

```sql
SELECT PaymentActionStatusID,
       COUNT(*) AS ActionCount,
       CASE PaymentActionStatusID
           WHEN 1 THEN 'New'
           WHEN 2 THEN 'InProcess'
           WHEN 3 THEN 'Closed'
           WHEN 0 THEN 'Legacy'
       END AS StatusName
FROM BI_DB_dbo.Synapse_Table_etoro_History_DepositAction
GROUP BY PaymentActionStatusID
ORDER BY ActionCount DESC
```

### 7.3 Deposits with approved status and their action count

```sql
SELECT DepositID,
       COUNT(*) AS ActionCount,
       MIN(ModificationDate) AS FirstAction,
       MAX(ModificationDate) AS LastAction,
       MAX(Amount) AS DepositAmount
FROM BI_DB_dbo.Synapse_Table_etoro_History_DepositAction
WHERE PaymentStatusID = 2  -- Approved
GROUP BY DepositID
ORDER BY ActionCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 23 T1, 0 T2, 0 T3, 0 T4, 0 T5 | Elements: 23/23, Logic: 8/10, Relationships: 8/10*
*Object: BI_DB_dbo.Synapse_Table_etoro_History_DepositAction | Type: Table | Production Source: etoro.History.DepositAction*
