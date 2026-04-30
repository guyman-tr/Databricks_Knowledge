# BackOffice.AggregatedDataType

> Table-valued parameter type used to stage a single day's financial aggregation delta (deposits, cashouts, bonuses, etc.) for a customer before merging it into the three MIMO aggregation tables.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID + Date (NONCLUSTERED primary key) |
| **Partition** | N/A |
| **Indexes** | 1 (NONCLUSTERED PK on CID, Date) |

---

## 1. Business Meaning

`BackOffice.AggregatedDataType` is a Table-Valued Type (TVT) that acts as an in-memory staging table for one row of daily financial aggregation data for a single customer. It holds all the financial metrics for a given customer on a given date: deposits, bonuses, championship wins, cashouts, cashout requests, reverse cashouts, compensations, and first deposit tracking dates.

This type exists to allow the `UpsertMIMOAggregation` procedure to compute and stage a delta row once, then MERGE it into three target aggregation tables (AllTime, DTD, MTD) without repeating the calculation logic. The staged row acts as the source of truth for a single atomic credit event.

Data flows into this type exclusively inside `BackOffice.UpsertMIMOAggregation`: the SP declares a local variable `@Delta AS BackOffice.AggregatedDataType`, inserts one computed row based on the credit event type and payment parameters, then executes three MERGE operations against the MIMO aggregation tables. The type is never passed as a parameter - it is always declared as a local variable inside the procedure.

---

## 2. Business Logic

### 2.1 MIMO Aggregation Delta Staging

**What**: A single-row staging buffer that holds the computed financial delta for one credit event, keyed by customer and date.

**Columns/Parameters Involved**: `CID`, `Date`, `Deposit`, `Cashout`, `Bonus`, `ChampWinner`, `ReverseCashout`, `CashoutRequest`, `Compensation`, `FirstTimeDepositAttemptDate`, `FirstTimeDepositSuccessDate`

**Rules**:
- The PK (CID + Date) enforces uniqueness per customer per day within the staging buffer.
- Only one column is non-zero per credit event call: the credit type determines which financial bucket gets the delta. E.g., CreditTypeID=1 -> Deposit, CreditTypeID=2 -> Cashout, CreditTypeID=7 -> Bonus.
- FirstTimeDepositAttemptDate and FirstTimeDepositSuccessDate are only populated for deposit events (CreditTypeID=1); otherwise NULL.
- After staging, the same `@Delta` variable is used in three sequential MERGE statements: AllTime, DTD (day-to-date), and MTD (month-to-date) aggregation tables.

**Diagram**:
```
Credit event arrives (CreditTypeID, CID, Amount, ...)
        |
        v
DECLARE @Delta AS BackOffice.AggregatedDataType
INSERT @Delta -> one row: CID=X, Date=today, Deposit=Amount (others 0)
        |
        +-- MERGE BackOffice.CustomerMIMOAllTimeAggregatedData  (lifetime totals)
        |
        +-- MERGE BackOffice.CustomerMIMODTDAggregatedData      (daily totals)
        |
        +-- MERGE BackOffice.CustomerMIMOMTDAggregatedData      (monthly totals)
```

### 2.2 Credit Type to Financial Column Mapping

**What**: The CreditTypeID parameter of the consuming SP determines which financial bucket column receives the delta amount.

**Columns/Parameters Involved**: `Deposit`, `Cashout`, `Bonus`, `ChampWinner`, `ReverseCashout`, `CashoutRequest`, `Compensation`

**Rules**:
- CreditTypeID=1 -> Deposit (payment amount / 100, converted from minor currency unit)
- CreditTypeID=2 -> Cashout (full withdraw amount from Billing.WithdrawToFunding)
- CreditTypeID=6 -> Compensation (payment amount / 100)
- CreditTypeID=7 -> Bonus (payment amount / 100)
- CreditTypeID=8 or 15 (credit change > 0) -> ReverseCashout
- CreditTypeID=9 or 15 (credit change <= 0) -> CashoutRequest (negated, stored positive)
- All other credit types -> all financial columns = 0

---

## 3. Data Overview

N/A for User Defined Type. This type is instantiated as a local variable inside stored procedures and holds at most one row at any time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. Part of the NONCLUSTERED primary key together with Date. Identifies which customer this aggregation delta belongs to. |
| 2 | Date | datetime | NO | - | CODE-BACKED | The UTC date (truncated to midnight) for this aggregation record. Computed as `DATEADD(dd, 0, DATEDIFF(dd, 0, GETUTCDATE()))` in the consuming SP. Part of the NONCLUSTERED primary key. |
| 3 | Deposit | money | YES | - | CODE-BACKED | Total deposit amount for this customer on this date, in account currency. Populated when CreditTypeID=1. Amount is converted from minor currency units (divided by 100). NULL or 0 for non-deposit events. |
| 4 | Bonus | money | YES | - | CODE-BACKED | Total bonus amount credited to the customer on this date. Populated when CreditTypeID=7. Represents promotional or loyalty bonuses granted by the back-office. |
| 5 | ChampWinner | money | YES | - | CODE-BACKED | Championship (trading competition) winnings received on this date. Populated as 0 in the current SP logic; column retained for schema completeness. Maps to TotalChampWin in the DTD/MTD aggregation tables. |
| 6 | Cashout | money | YES | - | CODE-BACKED | Total cashout (withdrawal) amount processed on this date. Populated when CreditTypeID=2 AND the withdrawal is the first processed payout. Uses `WithdrawFullAmount` (BW.Amount + BW.Fee). |
| 7 | CashoutRequest | money | YES | - | CODE-BACKED | Total cashout request amount (withdrawal requested but not yet processed) on this date. Populated when CreditTypeID=9 or 15 with a negative credit change. Stored as positive value (sign flipped). |
| 8 | ReverseCashout | money | YES | - | CODE-BACKED | Amount of a reversed/cancelled withdrawal credited back to the customer on this date. Populated when CreditTypeID=8 or 15 with a positive credit change. |
| 9 | Compensation | money | YES | - | CODE-BACKED | Compensation amount credited to the customer (e.g., for trading errors or service issues). Populated when CreditTypeID=6. |
| 10 | FirstTimeDepositAttemptDate | datetime | YES | - | CODE-BACKED | Date and time of the customer's very first deposit attempt. Populated only for deposit events (CreditTypeID=1). Used in COALESCE logic: preserved from existing aggregation row if already set, otherwise taken from Billing.Deposit.PaymentDate. |
| 11 | FirstTimeDepositSuccessDate | datetime | YES | - | CODE-BACKED | Date and time of the customer's very first successful deposit (PaymentStatusID=2). Populated only for deposit events (CreditTypeID=1). Set to GETUTCDATE() on the first successful deposit; preserved from existing row thereafter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.CustomerMIMOAllTimeAggregatedData.CID | Implicit | Row key for MERGE into all-time aggregation |
| CID + Date | BackOffice.CustomerMIMODTDAggregatedData.CID + Date | Implicit | Row key for MERGE into daily aggregation |
| CID + Date | BackOffice.CustomerMIMOMTDAggregatedData.CID + Year/Month | Implicit | Row key for MERGE into monthly aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertMIMOAggregation | @Delta (local variable) | Type usage | Procedure declares `DECLARE @Delta AS BackOffice.AggregatedDataType` as a local staging buffer for the aggregation delta. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertMIMOAggregation | Stored Procedure | Declares a local variable of this type to stage one financial delta row, then MERGEs it into CustomerMIMOAllTimeAggregatedData, CustomerMIMODTDAggregatedData, and CustomerMIMOMTDAggregatedData. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | NONCLUSTERED PK | CID ASC, Date ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IGNORE_DUP_KEY = OFF | Index option | Duplicate key inserts raise an error rather than being silently ignored. |

---

## 8. Sample Queries

### 8.1 Declare and inspect a deposit event delta

```sql
DECLARE @Delta AS BackOffice.AggregatedDataType;

INSERT @Delta (CID, Date, Deposit, FirstTimeDepositAttemptDate)
VALUES (
    99999,
    DATEADD(dd, 0, DATEDIFF(dd, 0, GETUTCDATE())),
    150.00,
    GETUTCDATE()
);

SELECT * FROM @Delta WITH (NOLOCK);
```

### 8.2 Simulate a cashout event delta

```sql
DECLARE @Delta AS BackOffice.AggregatedDataType;

INSERT @Delta (CID, Date, Cashout)
VALUES (
    99999,
    DATEADD(dd, 0, DATEDIFF(dd, 0, GETUTCDATE())),
    500.00
);

SELECT CID, Date, Cashout FROM @Delta WITH (NOLOCK);
```

### 8.3 Check current MIMO all-time aggregation for a customer

```sql
SELECT
    a.CID,
    a.TotalDeposit,
    a.TotalCashout,
    a.TotalBonus,
    a.TotalCompensation,
    a.FirstTimeDepositAttemptDate,
    a.FirstTimeDepositSuccessDate,
    a.LastUpdate
FROM BackOffice.CustomerMIMOAllTimeAggregatedData a WITH (NOLOCK)
WHERE a.CID = 99999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AggregatedDataType | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.AggregatedDataType.sql*
