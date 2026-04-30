# BackOffice.UpsertMIMOAggregation

> Event-driven MIMO aggregation: called per credit event to MERGE financial deltas into three MIMO aggregation tables (AllTime, DayToDay, MonthToDate) using a TVT delta row built from the credit's type and payment amount.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @CreditTypeID - identifies the customer and event type for delta computation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpsertMIMOAggregation` is the event-driven write path for the MIMO (eToro Money) payment aggregation system. Unlike the standard aggregation pipeline (`UpsertIntoAggregationTablesAction`) which processes credit events in batches, MIMO aggregation is event-driven: this SP is called immediately when each individual credit event fires in the MIMO payment system.

The SP receives a single credit event's key parameters, computes a typed delta row using the `BackOffice.AggregatedDataType` user-defined table type, and executes three MERGE statements to atomically update all three MIMO aggregation tables in one call:
- **BackOffice.CustomerMIMOAllTimeAggregatedData** - lifetime totals per CID
- **BackOffice.CustomerMIMODTDAggregatedData** - daily totals per CID/Date
- **BackOffice.CustomerMIMOMTDAggregatedData** - monthly totals per CID/Year/Month

MIMO = eToro's embedded fintech/money transfer product ("eToro Money"). MIMO customers are tracked separately from standard trading customers because their funding flows through a distinct payment pipeline. The aggregation tables enable the back-office to quickly assess MIMO customers' financial standing and trigger Salesforce integrations (`LastOccurredTriggerToSF`).

Introduced November 2020 (PAYUS-1770), updated March 2022 (PAYSOLB-803) to fix FTD date calculation.

---

## 2. Business Logic

### 2.1 Delta Computation Into TVT

**What**: Builds a single-row delta table variable (`@Delta` of type `BackOffice.AggregatedDataType`) containing the financial impact of this specific credit event.

**CreditTypeID Mapping**:
| CreditTypeID | Column | Formula |
|---|---|---|
| 1 (Deposit) | Deposit | CAST(@Payment AS MONEY) / 100 |
| 2 (Cashout/Withdrawal) | Cashout | ProcessedWithdraws.WithdrawFullAmount (from Billing.WithdrawToFunding JOIN) |
| 6 (Compensation) | Compensation | CAST(@Payment AS MONEY) / 100 |
| 7 (Bonus) | Bonus | CAST(@Payment AS MONEY) / 100 |
| 8, 15 with @CreditChange > 0 (Reverse Cashout) | ReverseCashout | @CreditChange |
| 9, 15 with @CreditChange <= 0 (Cashout Request) | CashoutRequest | (-1) * @CreditChange |
| Any other | All columns | 0 |

**Cashout full amount**: For CreditTypeID=2, the full withdrawal amount is computed from `Billing.WithdrawToFunding` + `Billing.Withdraw`: `MIN(BW.Amount + BW.Fee)` where the first processing event for @WithdrawID matches @WithdrawProcessingID (FirstProcessedPayoutID). If @WithdrawProcessingID is not the first payout for this withdrawal, Cashout=0 (subsequent payouts do not double-count).

**Payment units**: @Payment is a BIGINT in cents. All money columns divide by 100 to convert to monetary units.

### 2.2 FTD Milestone Pre-Update

**What**: Before the MERGE, updates the delta row's FirstTimeDepositAttemptDate and FirstTimeDepositSuccessDate fields using COALESCE against the existing record (only for CreditTypeID=1 events).

**Rules**:
- Applies only when `@CreditTypeID = 1` (deposit event).
- `FirstTimeDepositAttemptDate = ISNULL(existing.FirstTimeDepositAttemptDate, BD.PaymentDate)` - preserves existing if already set.
- `FirstTimeDepositSuccessDate`: if `BD.PaymentStatusID=2` (successful deposit) -> COALESCE(existing, GETUTCDATE()); else NULL.
- The `UPDATE @Delta ... FROM CustomerMIMOAllTimeAggregatedData JOIN Billing.Deposit` pattern reads existing values before the MERGE so the MERGE can preserve FTD dates.

### 2.3 Three MERGE Statements

**What**: Three separate MERGE statements update all three MIMO aggregation tables atomically (within the same statement batch).

**MERGE 1 - CustomerMIMOAllTimeAggregatedData** (keyed on CID):
- NOT MATCHED: INSERT with all delta values; FirstTimeDepositAttemptDate/SuccessDate from MIN(Billing.Deposit) subqueries for new customers.
- MATCHED UPDATE: `TotalX += D.X` for all financial metrics; `LastUpdate = GETUTCDATE()`; `LastOccurredTriggerToSF = CASE WHEN COALESCE(Deposit,Bonus,Cashout,Compensation,0) > 0 THEN GETUTCDATE() ELSE NULL END`.
- FTD dates on MATCHED UPDATE use COALESCE (preserve existing if already set).

**MERGE 2 - CustomerMIMODTDAggregatedData** (keyed on CID + Date):
- NOT MATCHED: INSERT with CID, Date, all financial metrics, FTD dates.
- MATCHED UPDATE: `TotalX += D.X`, FTD dates preserved via ISNULL.
- No RealizedEquity or login tracking (MIMO tables are financial-only).

**MERGE 3 - CustomerMIMOMTDAggregatedData** (keyed on CID + Year(Date) + Month(Date)):
- NOT MATCHED: INSERT with CID, Year, Month, Date, all financial metrics, FTD dates.
- MATCHED UPDATE: `TotalX += D.X`, FTD dates preserved via ISNULL.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditTypeID | int | NO | - | CODE-BACKED | The type of credit event being processed. Determines which financial metric is updated: 1=Deposit, 2=Cashout, 6=Compensation, 7=Bonus, 8/15=ReverseCashout/CashoutRequest. All other types produce zero deltas. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID. The MIMO customer being updated. Used as the primary key for all three MERGE statements. |
| 3 | @Payment | bigint | NO | - | CODE-BACKED | Payment amount in cents (not monetary units). Divided by 100 for Deposit/Compensation/Bonus. For Cashout (CreditTypeID=2), @Payment is not used; instead the full withdrawal amount is computed from Billing.WithdrawToFunding. For ReverseCashout/CashoutRequest, @CreditChange is used. |
| 4 | @WithdrawID | int | YES | NULL | CODE-BACKED | ID of the withdrawal record (Billing.Withdraw.WithdrawID). Used in Cashout (CreditTypeID=2) to compute full withdrawal amount via Billing.WithdrawToFunding JOIN. NULL for non-cashout events. |
| 5 | @DepositID | int | YES | NULL | CODE-BACKED | ID of the deposit record (Billing.Deposit.DepositID). Used to look up PaymentDate and PaymentStatusID for FirstTimeDepositAttemptDate/SuccessDate milestone computation. NULL for non-deposit events. |
| 6 | @WithdrawProcessingID | int | YES | NULL | CODE-BACKED | ID of the specific payout processing record (Billing.WithdrawToFunding.ID). Used to identify whether this is the FIRST payout event for the withdrawal (FirstProcessedPayoutID). Cashout delta is only counted on the first payout to avoid double-counting split disbursements. NULL for non-cashout events. |
| 7 | @CreditChange | money | YES | NULL | CODE-BACKED | Net cash balance change for the credit event (in monetary units). Used for ReverseCashout (CreditTypeID 8/15, positive) and CashoutRequest (CreditTypeID 9/15, negative). NULL for events where @Payment is used instead. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | LEFT JOIN | PaymentDate for FTD attempt; PaymentStatusID for FTD success |
| @WithdrawID + @WithdrawProcessingID | Billing.Withdraw | OUTER APPLY | Full withdrawal amount (Amount + Fee) |
| @WithdrawID | Billing.WithdrawToFunding | OUTER APPLY | FirstProcessedPayoutID to guard against double-counting cashout |
| @CID | [BackOffice.CustomerMIMOAllTimeAggregatedData](../Tables/BackOffice.CustomerMIMOAllTimeAggregatedData.md) | MERGE target | Lifetime MIMO financial totals per CID |
| @CID + Date | BackOffice.CustomerMIMODTDAggregatedData | MERGE target | Daily MIMO financial totals per CID/Date |
| @CID + Year + Month | BackOffice.CustomerMIMOMTDAggregatedData | MERGE target | Monthly MIMO financial totals per CID/Year/Month |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called event-driven from MIMO payment processing services (PAYUS/PAYSOLB systems) per credit event. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpsertMIMOAggregation (procedure)
+-- BackOffice.AggregatedDataType (user-defined table type) [TVT schema for @Delta]
+-- Billing.Deposit (table) [LEFT JOIN: FTD dates and PaymentStatus]
+-- Billing.Withdraw (table) [OUTER APPLY: full withdrawal amount]
+-- Billing.WithdrawToFunding (table) [OUTER APPLY: payout processing ID]
+-- BackOffice.CustomerMIMOAllTimeAggregatedData (table) [MERGE target + FTD pre-read]
+-- BackOffice.CustomerMIMODTDAggregatedData (table) [MERGE target]
+-- BackOffice.CustomerMIMOMTDAggregatedData (table) [MERGE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AggregatedDataType | User Defined Type (TVT) | Defines @Delta table variable schema |
| Billing.Deposit | Table | LEFT JOIN for PaymentDate and PaymentStatusID (FTD milestone dates) |
| Billing.Withdraw | Table | OUTER APPLY for Amount + Fee (full cashout amount) |
| Billing.WithdrawToFunding | Table | OUTER APPLY for FirstProcessedPayoutID and cashout full amount |
| [BackOffice.CustomerMIMOAllTimeAggregatedData](../Tables/BackOffice.CustomerMIMOAllTimeAggregatedData.md) | Table | MERGE target (AllTime); also pre-read for FTD date preservation |
| BackOffice.CustomerMIMODTDAggregatedData | Table | MERGE target (daily grain) |
| BackOffice.CustomerMIMOMTDAggregatedData | Table | MERGE target (monthly grain) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in BackOffice repo. | - | Called from MIMO payment processing services per credit event. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No explicit transaction block - each MERGE is auto-committed separately.
- `BackOffice.AggregatedDataType` TVT is used as an intermediate staging row for all three MERGEs (single row populated, then reused).
- FTD date pre-update (`UPDATE @Delta ...`) runs before the MERGE to preserve existing FTD dates.
- CreditTypeID=2 cashout guard: only counted when @WithdrawProcessingID matches FirstProcessedPayoutID - prevents double-counting for split payouts.

---

## 8. Sample Queries

### 8.1 Process a deposit event for a MIMO customer

```sql
EXEC BackOffice.UpsertMIMOAggregation
    @CreditTypeID = 1,
    @CID          = 12345,
    @Payment      = 10000,   -- 100.00 monetary units (in cents)
    @DepositID    = 987654;
```

### 8.2 Process a cashout event

```sql
EXEC BackOffice.UpsertMIMOAggregation
    @CreditTypeID        = 2,
    @CID                 = 12345,
    @Payment             = 0,
    @WithdrawID          = 555555,
    @WithdrawProcessingID = 111111;   -- first payout -> counts cashout amount
```

### 8.3 Check a customer's MIMO totals

```sql
SELECT CID, TotalDeposit, TotalCashout, TotalBonus, TotalCompensation,
       FirstTimeDepositAttemptDate, FirstTimeDepositSuccessDate, LastUpdate
FROM BackOffice.CustomerMIMOAllTimeAggregatedData WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-1770 | Jira | Initial version - November 2020 |
| PAYSOLB-803 | Jira | Changed FirstTimeDepositSuccessDate calculation - March 2022 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 2 Jira (from DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpsertMIMOAggregation | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpsertMIMOAggregation.sql*
