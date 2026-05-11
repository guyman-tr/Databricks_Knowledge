---
name: cross-refund-chargeback-chain
description: |
  Forensic chain for a single dispute event — refund, chargeback,
  chargeback-reversal — joining the original deposit (Payments C.1), the
  reversal-side fee accounting (Revenue & Fees), and the AML / risk
  classification overlay (Compliance). Use when investigating ONE specific
  dispute, building a chargeback case, or auditing a refund decision.
  NOT for aggregate reversal volume questions (those live in Revenue & Fees).
keywords: [chargeback, refund, dispute, reversal, chargeback reversal,
           dispute investigation, dispute case, chargeback recovery,
           BI_DB_DepositWithdrawFee_Reversals, AML refund, risk refund,
           PaymentStatusID 11, PaymentStatusID 12, PaymentStatusID 26,
           ReversalType, fraud chargeback]
load_after: [_router.md]
connects:
  - payments/deposits-and-withdrawals
  - revenue-and-fees/SKILL
  # - compliance/SKILL  (planned)
intersects_with:
  - payments/mimo-panel-and-ddr
  - payments/finance-recon-and-balances
primary_objects:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit  # Synapse: DWH_dbo.Fact_BillingDeposit
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw  # Synapse: DWH_dbo.Fact_BillingWithdraw
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals  # Synapse: BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction  # Synapse: DWH_dbo.Fact_CustomerAction
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus  # Synapse: DWH_dbo.Dim_PaymentStatus
synapse_only_objects:
  - "DWH_dbo.Fact_Deposit_State (alter.sql says _Not_Migrated)"
  - "DWH_dbo.Fact_Cashout_Rollback (wiki only; never ingested)"
---

# Cross-domain skill — Refund / Chargeback Chain

A dispute event in fiat payments has many actors:
1. The original deposit (or withdrawal).
2. The dispute trigger (customer-initiated refund vs bank-initiated
   chargeback vs ops-initiated reversal vs AML-flag-triggered reversal).
3. The reversal record (with sign-corrected amounts) in BI_DB_layer.
4. Optional follow-on (chargeback reversal — the bank reverses ITS
   chargeback because we won the case).
5. The AML/risk context (was this customer flagged before/after?).

This cross-domain skill stitches the chain so a single dispute can be fully audited.

> **Mixed UC / Synapse coverage.** The aggregate reversal table
> (`BI_DB_DepositWithdrawFee_Reversals`) and the customer-action audit
> (`Fact_CustomerAction`) are in UC. The State-table provenance
> (`Fact_Deposit_State`, `Fact_Cashout_Rollback`) is `_Not_Migrated` —
> only available in Synapse. On Databricks Genie you can do the
> reversal-aggregate analysis; for the full forensic chain (which State
> row triggered which reversal) drop down to Synapse via the synapse_*
> MCP servers.

## The chain

```mermaid
graph TB
    Dep[Original deposit<br/>Fact_BillingDeposit<br/>PaymentStatusID transitions to 11/12/26]
    Trig[Trigger event]
    Refund[Customer-initiated refund<br/>PaymentStatusID = 12]
    Chargeback[Bank-initiated chargeback<br/>PaymentStatusID = 11]
    AmlRev[AML reversal<br/>PaymentStatusID = 26 ReversedDeposit]
    OpsRev[Operator reversal<br/>tracked in Fact_CustomerAction]

    StatePost[Fact_Deposit_State<br/>TransactionType in Refund/Chargeback/etc.<br/>provides ExTransactionID for provider]

    RevFee[BI_DB_DepositWithdrawFee_Reversals<br/>AMOUNTS PRE-SIGNED<br/>reversal-type enum<br/>Revenue & Fees super-domain]

    CB_Rev[Chargeback reversal<br/>bank reverses its chargeback<br/>positive amount in BI_DB_DepositWithdrawFee_Reversals]

    AmlCtx[AML / risk context<br/>BI_DB_AML_*<br/>Compliance super-domain]

    Action[Operator action audit<br/>Fact_CustomerAction]

    Dep --> Trig
    Trig --> Refund
    Trig --> Chargeback
    Trig --> AmlRev
    Trig --> OpsRev
    Refund --> StatePost --> RevFee
    Chargeback --> StatePost
    AmlRev --> StatePost
    OpsRev --> StatePost
    Chargeback --> CB_Rev
    Dep -.context.-> AmlCtx
    OpsRev --> Action
```

## Anchor table: `BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals`

The reversal/dispute facts table. Every refund, chargeback, and
chargeback-reversal lands here. **Key properties:**

- **`Amount` and `AmountUSD` are PRE-SIGNED.** Refunds & chargebacks
  negative; chargeback-reversals positive. Don't multiply by `-1`.
- **`TransactionType`** has the reversal-type enum. Includes the known
  production typo `'Partialy Reversed'` (yes, "Partialy"). Don't fix it
  in queries.
- **`CreditTypeID`, `MOPCountry`, `IsGermanBaFin`** are ALWAYS NULL here
  (per SR-313302 / SR-359957). Don't filter on them.
- Owned by **Revenue & Fees super-domain** for aggregate questions, but
  used by THIS cross-domain skill for chain-walking.

## Canonical patterns

```sql
-- 1. Full chain for ONE specific dispute (start from a chargeback row)
WITH dispute AS (
  SELECT *
  FROM BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals
  WHERE DepositID = @disputed_deposit_id
)
SELECT
  'original_deposit' AS stage,
  fbd.DepositID, fbd.CID, fbd.PaymentStatusID, ps.Status,
  fbd.Amount, fbd.AmountUSD, fbd.ExchangeRate, fbd.ModificationDate,
  NULL AS reversal_type, NULL AS reversal_amount_usd, NULL AS reversal_date
FROM dispute d
JOIN DWH_dbo.Fact_BillingDeposit fbd ON fbd.DepositID = d.DepositID
JOIN DWH_dbo.Dim_PaymentStatus ps ON ps.PaymentStatusID = fbd.PaymentStatusID

UNION ALL

SELECT
  'reversal_event',
  d.DepositID, d.CID, NULL, d.TransactionType,
  d.Amount, d.AmountUSD, NULL, NULL,
  d.TransactionType, d.AmountUSD, d.Occurred
FROM dispute d
ORDER BY 1, 8 NULLS FIRST
```

```sql
-- 2. AML-flagged customers with refunds in the same period (overlay with Compliance)
SELECT rev.CID, rev.DepositID, rev.TransactionType, rev.AmountUSD, rev.Occurred,
       /* placeholder — real query joins to Compliance AML dim */
       'see Compliance super-domain' AS aml_context
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals rev
WHERE rev.TransactionType IN ('Refund', 'AMLRefund')  -- enum subset
  AND rev.Occurred BETWEEN @from AND @to
  AND rev.CID IN (
    SELECT CID FROM /* compliance.aml_flagged_customers */ ANY_AML_TABLE
    WHERE FlagDate BETWEEN @from AND @to
  )
```

```sql
-- 3. Operator-initiated reversals (the audit answer to "who refunded this customer")
SELECT rev.DepositID, rev.CID, rev.TransactionType, rev.AmountUSD,
       fca.ActionDate, fca.OperatorID, fca.Comment
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals rev
JOIN DWH_dbo.Fact_CustomerAction fca
       ON fca.CID = rev.CID
      AND fca.ActionTypeID IN (/* operator-refund codes */)
      AND ABS(DATEDIFF(MINUTE, fca.ActionDate, rev.Occurred)) <= 60
WHERE rev.DepositID = @disputed_deposit_id
```

```sql
-- 4. Chargeback success (we lost) vs chargeback recovery (we won)
SELECT rev.DepositID, rev.CID,
       MAX(CASE WHEN rev.TransactionType = 'Chargeback' THEN rev.AmountUSD END) AS chargeback_amt,
       MAX(CASE WHEN rev.TransactionType = 'ChargebackReversal' THEN rev.AmountUSD END) AS recovery_amt,
       CASE
         WHEN MAX(CASE WHEN rev.TransactionType = 'ChargebackReversal' THEN 1 END) = 1
              THEN 'Recovered'
         ELSE 'Lost'
       END AS outcome
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals rev
WHERE rev.Occurred BETWEEN @from AND @to
GROUP BY rev.DepositID, rev.CID
```

## PaymentStatus IDs of interest

| ID | Status | Trigger |
|----|--------|---------|
| 2  | Approved | Original successful deposit |
| 11 | Chargeback | Bank-initiated dispute |
| 12 | Refund | Customer or ops-initiated refund |
| 26 | ReversedDeposit | AML-driven reversal |
| 35 | DeclineByRRE | Risk engine decline (NOT a dispute — pre-auth decline) |
| 37-39 | Cancelled-reversals | The reversal itself was cancelled |

(See `Fact_BillingDeposit` wiki §5 for the complete enum.)

## Reversal type enum (subset, from BI_DB_DepositWithdrawFee_Reversals)

- `Refund`
- `Chargeback`
- `ChargebackReversal`
- `Reversed`
- `'Partialy Reversed'` (production typo — keep as-is)
- `CashoutRollback`
- `CancelledCashoutRollback`
- `CancelledChargebackReversal`

(Sign-correction logic for the last three uses `Fact_CustomerAction` lookups
in the source SP — trust the table's signed value, don't re-derive.)

## Gotchas

1. **Reversal `Amount` is PRE-SIGNED.** Don't `* -1`. Don't `ABS()` unless you specifically want absolute value.
2. **One deposit can have MULTIPLE reversal rows** (refund + later chargeback-reversal, partial reversal followed by full, etc.). Group by `DepositID` and inspect the timeline.
3. **`Fact_Deposit_State` carries non-Deposit `TransactionType` rows** for reversals — those are useful for the provider-side `ExTransactionID` of the reversal event itself (separate from the original deposit's `ExTransactionID`).
4. **AML reversals** (`PaymentStatusID = 26`) typically have a corresponding row in Compliance's AML alert tables. The two should be cross-referenced for any "we refunded due to AML — was the alert valid" audit.
5. **Operator audit trail** lives in `Fact_CustomerAction` — but that's owned by the planned **Operations super-domain**, not Compliance. If a refund was operator-initiated, look there.
6. **Chargeback ≠ Refund.** Chargeback is bank-initiated (we may dispute it back). Refund is internal-initiated (customer asked, or ops gave). Different commercial implications, different processes.
7. **Partial reversals** complicate aggregation. Sum across all reversal rows for one `DepositID`, then compare to the original `AmountUSD`, to know if the deposit was fully or partially reversed.
8. **For aggregate volume / rate questions** (chargeback rate, refund rate, recovery rate over time), GO TO Revenue & Fees super-domain. This cross-domain skill is for SINGLE-CASE forensics.

## When to load just one parent instead

- "Total refund volume this month" → Revenue & Fees super-domain alone.
- "Was deposit X approved" → C.1 alone (`Fact_BillingDeposit.PaymentStatusID`).
- "Show me the AML alerts for this customer" → Compliance super-domain alone.
- "Walk me through what happened to deposit X — refund? chargeback? when? who?" → load this cross-domain skill.
