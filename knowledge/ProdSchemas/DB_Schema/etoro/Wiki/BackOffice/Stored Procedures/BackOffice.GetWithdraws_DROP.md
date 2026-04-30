# BackOffice.GetWithdraws_DROP

> Returns financial status and AlreadyPaid amounts for a batch of withdrawals by IDs - used by the CashoutTool service as a data-fetch step before a bulk withdrawal drop/cancellation operation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawIDs [BackOffice].[IDs] READONLY (TVP of withdrawal IDs); returns one row per WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdraws_DROP` fetches core financial data for a set of withdrawals supplied as a table-valued parameter (TVP), enriched with an `AlreadyPaid` aggregate that shows how much of each withdrawal has already been disbursed. The "_DROP" suffix indicates this is the read step in a bulk withdrawal drop (cancellation/rollback) workflow - the caller (CashoutTool) fetches current state before deciding which withdrawals can safely be dropped and rolling them back.

This procedure exists to provide a single efficient bulk read instead of querying each withdrawal individually. It accepts the `BackOffice.IDs` UDT (a table of integer IDs) as input and returns state for all matching withdrawals in one pass.

The `AlreadyPaid` calculation mirrors the logic in `BackOffice.GetWithdraw` (single-record variant): it sums `Billing.WithdrawToFunding.Amount` for completed funding transfers where `IsFinishedWithoutMoneyTransfer = 0`, meaning actual money moved. This value is essential before dropping a withdrawal - if `AlreadyPaid > 0`, money has already left and a reversal/chargeback process is required before the withdrawal can be voided.

Created by Michal R. (Oct 2021, MIMOPS-5246). Called exclusively by the `CashoutTool` service user.

---

## 2. Business Logic

### 2.1 AlreadyPaid Batch Calculation

**What**: For each withdrawal in the input set, compute how much has already been paid out via completed funding transfers that involved actual money movement.

**Columns/Parameters Involved**: `AlreadyPaid`, `Billing.WithdrawToFunding.Amount`, `Dictionary.CashoutStatus.IsFinishedWithoutMoneyTransfer`

**Rules**:
- CTE `FundingAmount`: Groups `Billing.WithdrawToFunding` by `WithdrawID` for all input IDs
- Includes only records where `IsFinishedWithoutMoneyTransfer = 0` (real money transfers, excludes terminal statuses that closed without payment like rejections or reversals)
- `SUM(Amount)` per WithdrawID gives the total already disbursed
- If no qualifying funding records exist, `ISNULL(AlreadyPaid, 0)` returns 0 in the main SELECT

**Diagram**:
```
@WithdrawIDs (TVP) -> Billing.WithdrawToFunding
  JOIN Dictionary.CashoutStatus WHERE IsFinishedWithoutMoneyTransfer = 0
  GROUP BY WithdrawID -> SUM(Amount) = AlreadyPaid per withdrawal
                                            |
Billing.Withdraw <-- LEFT JOIN FundingAmount FA on WithdrawID
  ISNULL(AlreadyPaid, 0) -> 0 if no paid funding records
```

### 2.2 Payment Method Identification

**What**: Returns the payment method identifiers needed to determine the reversal path when dropping a withdrawal with AlreadyPaid > 0.

**Columns/Parameters Involved**: `PaymentMethodTypeID`, `PaymentMethodID`

**Rules**:
- `PaymentMethodTypeID` = `ISNULL(BW.FundingTypeID, 0)` - the funding method type; 0 if not set
- `PaymentMethodID` = `ISNULL(BW.FundingID, 0)` - the specific funding record; 0 if not set
- These two fields together identify how to process any required reversal/chargeback

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawIDs | [BackOffice].[IDs] READONLY | NO | - | CODE-BACKED | Table-valued parameter of withdrawal IDs to look up. Uses the `BackOffice.IDs` UDT (table of INT IDs). The batch can contain any number of withdrawal IDs. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerId | INT | NO | - | CODE-BACKED | Customer identifier for this withdrawal (`Billing.Withdraw.CID`). Used by the caller to associate the withdrawal with its customer account for the drop operation. |
| 2 | WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal identifier (`Billing.Withdraw.WithdrawID`). Echoes the input IDs with their data. |
| 3 | Status | INT | NO | - | CODE-BACKED | Current cashout status of the withdrawal (`Billing.Withdraw.CashoutStatusID`). The caller checks this to determine if a withdrawal is eligible for dropping (e.g. only certain statuses allow cancellation). |
| 4 | Amount | DECIMAL | NO | - | CODE-BACKED | Total requested withdrawal amount from `Billing.Withdraw.Amount`. |
| 5 | AlreadyPaid | DECIMAL | NO | 0 | CODE-BACKED | Sum of completed funding transfers that involved actual money movement. 0 if no money has been disbursed. If > 0, a financial reversal is required before the withdrawal can be dropped. See Section 2.1. |
| 6 | CurrencyID | INT | NO | - | CODE-BACKED | Currency of the withdrawal (`Billing.Withdraw.CurrencyID`). Used by the caller to determine the currency denomination for any reversal amounts. |
| 7 | AccountCurrencyID | INT | YES | - | CODE-BACKED | Original deposit currency ID (`Billing.Withdraw.AccountCurrencyID`). May be NULL for older withdrawals. |
| 8 | PaymentMethodTypeID | INT | NO | 0 | CODE-BACKED | Funding type identifier (`Billing.Withdraw.FundingTypeID`), defaulting to 0 if NULL. Identifies the payment channel (credit card, wire, PayPal, etc.) to determine the reversal path. |
| 9 | PaymentMethodID | INT | NO | 0 | CODE-BACKED | Specific funding record ID (`Billing.Withdraw.FundingID`), defaulting to 0 if NULL. Combined with `PaymentMethodTypeID` to identify the exact payment method record for reversal processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawIDs | BackOffice.IDs | UDT | Table-valued parameter type used to pass the batch of IDs |
| @WithdrawIDs IDs | Billing.Withdraw | Filter | Main withdrawal records retrieved by ID batch |
| @WithdrawIDs IDs | Billing.WithdrawToFunding | CTE filter | Funding records for AlreadyPaid calculation |
| WithdrawToFunding.CashoutStatusID | Dictionary.CashoutStatus | Lookup (CTE) | IsFinishedWithoutMoneyTransfer flag for AlreadyPaid filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool service | @WithdrawIDs | Caller | Fetches batch withdrawal state before executing bulk drop/cancellation operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdraws_DROP (procedure)
├── BackOffice.IDs (user defined type) [TVP]
├── Billing.WithdrawToFunding (table) [in CTE]
├── Dictionary.CashoutStatus (table) [in CTE - IsFinishedWithoutMoneyTransfer]
└── Billing.Withdraw (table) [main SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | User Defined Type | TVP type for @WithdrawIDs parameter |
| Billing.Withdraw | Table | Main FROM; provides all withdrawal financial fields |
| Billing.WithdrawToFunding | Table | CTE; aggregates Amount for AlreadyPaid calculation |
| Dictionary.CashoutStatus | Table | CTE JOIN; provides IsFinishedWithoutMoneyTransfer flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool service | External service | Calls this to fetch withdrawal state before bulk drop operation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Query hint | All tables use NOLOCK - reads are for pre-drop assessment, dirty reads acceptable |
| TVP READONLY | Parameter constraint | @WithdrawIDs cannot be modified within the procedure |
| ISNULL(..., 0) | NULL handling | AlreadyPaid, PaymentMethodTypeID, PaymentMethodID all default to 0 when NULL |

---

## 8. Sample Queries

### 8.1 Fetch withdrawal state for a batch of IDs

```sql
DECLARE @IDs [BackOffice].[IDs];
INSERT INTO @IDs VALUES (285760), (285761), (285762);
EXEC [BackOffice].[GetWithdraws_DROP] @WithdrawIDs = @IDs;
```

### 8.2 Check which withdrawals in a batch have already paid out

```sql
DECLARE @IDs [BackOffice].[IDs];
INSERT INTO @IDs VALUES (285760), (285761), (285762);

-- Get results and find those with money already moved
EXEC [BackOffice].[GetWithdraws_DROP] @WithdrawIDs = @IDs;
-- Filter result: WHERE AlreadyPaid > 0 -> these require reversal before drop
```

### 8.3 Manually replicate AlreadyPaid for a single withdrawal

```sql
SELECT
    wtf.WithdrawID,
    SUM(wtf.Amount) AS AlreadyPaid
FROM Billing.WithdrawToFunding WITH (NOLOCK) wtf
INNER JOIN Dictionary.CashoutStatus WITH (NOLOCK) dcs ON dcs.CashoutStatusID = wtf.CashoutStatusID
WHERE wtf.WithdrawID = 285760
  AND dcs.IsFinishedWithoutMoneyTransfer = 0
GROUP BY wtf.WithdrawID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: CashoutTool service (permissions grant) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdraws_DROP | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdraws_DROP.sql*
