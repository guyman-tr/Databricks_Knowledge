# BackOffice.CustomerMIMOAllTimeAggregatedData

> Lifetime financial aggregates for customers transacting through the MIMO (eToro Money) payment pipeline, tracking money-in and money-out totals per customer. Parallel to BackOffice.CustomerAllTimeAggregatedData_1 but covers the eToro Money fintech funding path only, with no trading metrics.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 2 active (1 clustered PK + 1 NC on LastUpdate) |

---

## 1. Business Meaning

BackOffice.CustomerMIMOAllTimeAggregatedData stores lifetime financial totals for customers who transact through the MIMO payment pipeline - eToro's embedded fintech/money transfer product (branded "eToro Money"). Each row holds a single customer's cumulative money-in (deposits, bonuses, compensation) and money-out (cashouts, cashout requests, reverse cashouts) from this channel.

MIMO is a distinct payment pipeline from the standard trading funding path. While standard customers are tracked in BackOffice.CustomerAllTimeAggregatedData_1 (via History.Credit batch processing), MIMO customers are tracked here via event-driven per-credit MERGE calls from BackOffice.UpsertMIMOAggregation - called individually as each credit event fires.

The table intentionally omits trading metrics (no Profit, Commission, Volume, Lot, PositionCount, EndOfWeekFee) because MIMO customers are primarily transacting through the money transfer product, not necessarily active traders. The focus is solely on financial flows.

4.674M rows as of 2026-03-17. 99.3% have TotalDeposit > 0 (nearly all MIMO customers have deposited). 0.13% have bonuses, 1.5% have compensation. 23,743 have SalesForce triggers set.

**Related MIMO tables**: CustomerMIMODTDAggregatedData (daily grain) and CustomerMIMOMTDAggregatedData (monthly grain) are maintained by the same UpsertMIMOAggregation procedure in the same transaction.

---

## 2. Business Logic

### 2.1 Event-Driven Per-Credit MERGE (not Batch)

**What**: Unlike the standard aggregation tables (which are updated in batch via UpsertIntoAggregationTablesAction), MIMO aggregates are updated event-by-event via MERGE immediately when each credit event fires.

**Columns Involved**: All `Total*` columns, `LastUpdate`, `LastOccurredTriggerToSF`, `FirstTimeDepositAttemptDate`, `FirstTimeDepositSuccessDate`

**Rules**:
- `UpsertMIMOAggregation` is called per credit event with @CID, @CreditTypeID, @Payment (in cents - divided by 100 for storage), @WithdrawID, @DepositID, @WithdrawProcessingID, @CreditChange.
- A MERGE statement handles both INSERT (new CID, first MIMO event) and UPDATE (existing CID, add delta).
- CreditTypeID mapping:
  - CreditTypeID=1 (Deposit): TotalDeposit += @Payment/100. Also sets FirstTimeDepositAttemptDate and FirstTimeDepositSuccessDate (once, when NULL).
  - CreditTypeID=2 (Cashout): TotalCashout += withdraw full amount (from Billing.WithdrawToFunding join).
  - CreditTypeID=6 (Compensation): TotalCompensation += @Payment/100.
  - CreditTypeID=7 (Bonus): TotalBonus += @Payment/100.
  - CreditTypeID=8 or 15 with @CreditChange > 0 (Reverse Cashout): TotalReverseCashout += @CreditChange.
  - CreditTypeID=9 or 15 with @CreditChange <= 0 (Cashout Request): TotalCashoutRequest += (-@CreditChange).
- LastUpdate set to GETUTCDATE() on every write.
- LastOccurredTriggerToSF: Set to GETUTCDATE() if Deposit, Bonus, Cashout, or Compensation > 0. Set to NULL otherwise (important: the MATCH branch always sets this, even to NULL on non-financial events).

**Diagram**:
```
MIMO/eToro Money credit event fires
    |
    v
BackOffice.UpsertMIMOAggregation (@CID, @CreditTypeID, @Payment, ...)
    |-- Compute delta for this single credit event
    |-- MERGE into CustomerMIMOAllTimeAggregatedData (AllTime lifetime)
    |-- MERGE into CustomerMIMODTDAggregatedData (daily)
    |-- MERGE into CustomerMIMOMTDAggregatedData (monthly)
    (all three in the same procedure call, same transaction)
```

### 2.2 SalesForce Trigger Tracking

**What**: `LastOccurredTriggerToSF` signals SalesForce CRM that a financially significant event occurred for this customer via MIMO.

**Rules**:
- Set to GETUTCDATE() when: Deposit > 0 OR Bonus > 0 OR Cashout > 0 OR Compensation > 0.
- Set to NULL when: only CashoutRequest or ReverseCashout (not considered CRM-trigger events).
- Note: the MATCH branch ALWAYS writes this column, meaning a non-trigger event (CashoutRequest) will reset it to NULL. This differs from the standard AllTime table where it is only updated when non-zero.
- 23,743 rows (0.5%) have this set - MIMO SF triggers are rare relative to standard pipeline.

### 2.3 First-Time Milestone Dates

**What**: Captures the first deposit attempt and first successful deposit via the MIMO channel.

**Rules**:
- `FirstTimeDepositAttemptDate`: Set from Billing.Deposit.PaymentDate for CreditTypeID=1 events. Preserved once set.
- `FirstTimeDepositSuccessDate`: Set to GETUTCDATE() when deposit PaymentStatusID=2 (approved). If new CID and no prior history, falls back to MIN(PaymentDate FROM Billing.Deposit WHERE PaymentStatusID=2).
- These are MIMO-channel FTD dates - distinct from the FTD dates in CustomerAllTimeAggregatedData_1 (which covers the standard channel).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (2026-03-17) | 4.674M |
| Has TotalDeposit > 0 | 4.642M (99.3%) |
| Has TotalBonus > 0 | 5,917 (0.13%) |
| Has TotalCompensation != 0 | 69,317 (1.5%) |
| Has LastOccurredTriggerToSF set | 23,743 (0.5%) |
| Oldest LastUpdate | 2021-01-07 |
| Newest LastUpdate | 2026-03-17 (live) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Clustered PK. Implicit FK to Customer.CustomerStatic.CID. One row per customer per MIMO pipeline lifetime. |
| 2 | TotalDeposit | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of MIMO deposits (CreditTypeID=1). @Payment parameter converted from cents to dollars. 99.3% of rows have this > 0. |
| 3 | TotalBonus | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of bonus credits via MIMO channel (CreditTypeID=7). Rare - only 0.13% of customers have MIMO bonuses. |
| 4 | TotalCashout | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of successful MIMO withdrawal payments (CreditTypeID=2). Computed from Billing.WithdrawToFunding (full withdraw amount including fee). |
| 5 | TotalCashoutRequest | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of MIMO withdrawal requests (CreditTypeID=9 or 15 with negative CreditChange, stored as positive). |
| 6 | TotalReverseCashout | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of reversed MIMO withdrawals (CreditTypeID=8 or 15 with positive CreditChange). |
| 7 | TotalCompensation | decimal(34,4) | NO | 0 | VERIFIED | All-time sum of compensation payments via MIMO (CreditTypeID=6). Covers 1.5% of customers. |
| 8 | LastUpdate | datetime | NO | GETUTCDATE() | VERIFIED | Timestamp of the most recent upsert to this row. Set to GETUTCDATE() on every MERGE execution. |
| 9 | FirstTimeDepositAttemptDate | datetime | YES | - | VERIFIED | First time this customer attempted a MIMO deposit (from Billing.Deposit.PaymentDate, CreditTypeID=1). Set once when NULL. MIMO-channel specific - may differ from standard pipeline FTD attempt date. |
| 10 | FirstTimeDepositSuccessDate | datetime | YES | - | VERIFIED | First time this customer completed a successful MIMO deposit (Billing.Deposit.PaymentStatusID=2). Set to GETUTCDATE() at time of first successful deposit. Set once when NULL. |
| 11 | LastOccurredTriggerToSF | datetime | YES | - | VERIFIED | Last time a deposit, bonus, cashout, or compensation event occurred via MIMO - triggers SalesForce CRM re-sync. Set to GETUTCDATE() on financial events; set to NULL on non-financial events (CashoutRequest, ReverseCashout). 23,743 rows have this set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer account scope |
| CID (at upsert) | Billing.Deposit | Implicit | FTD dates sourced at INSERT time |
| CID (at upsert) | Billing.WithdrawToFunding | Implicit | Cashout full amount calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertMIMOAggregation | CID | WRITER/MODIFIER | Primary event-driven MERGE - sole data writer |
| BackOffice.UpsertIntoAggregationTablesAction | CID | READER | BonusOnlyCustomers cleanup - reads TotalDeposit and TotalCompensation to remove depositing customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerMIMOAllTimeAggregatedData (table)
- No FK constraints
- Written by BackOffice.UpsertMIMOAggregation (event-driven per credit)
- Source data: Billing.Deposit, Billing.Withdraw, Billing.WithdrawToFunding
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FTD date sourcing at INSERT time |
| Billing.Withdraw | Table | Withdraw amount for cashout calculation |
| Billing.WithdrawToFunding | Table | Full cashout amount including fee |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertMIMOAggregation | Procedure | WRITER - sole population mechanism |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | READER - BonusOnlyCustomers cleanup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BOCATDADN_New | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=95, ON [PRIMARY]) |
| IX_LastUpdate | NC | LastUpdate ASC | TotalDeposit, TotalCompensation | - | Active (ON [PRIMARY]) |

**Storage**: ON [PRIMARY] filegroup (unlike the _1 tables which are on [HISTORY]). No DATA_COMPRESSION=PAGE. FILLFACTOR=95 on PK.

**NC index design**: The `IX_LastUpdate` index with included TotalDeposit and TotalCompensation is specifically designed for the BonusOnlyCustomers cleanup query in UpsertIntoAggregationTablesAction: `WHERE LastUpdate > GETDATE()-7 AND (TotalDeposit <> 0 OR TotalCompensation...)`

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BOCATDADN_New | PK | CID - one row per customer |
| (unnamed) DEFAULT | DEFAULT | TotalDeposit through TotalCompensation = 0 |
| (unnamed) DEFAULT | DEFAULT | LastUpdate = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get MIMO financial summary for a customer
```sql
SELECT
    m.CID,
    m.TotalDeposit,
    m.TotalCashout,
    m.TotalDeposit - m.TotalCashout AS NetMIMOFunding,
    m.TotalBonus,
    m.TotalCompensation,
    m.FirstTimeDepositSuccessDate AS MIMOFTDDate,
    m.LastUpdate
FROM BackOffice.CustomerMIMOAllTimeAggregatedData m WITH (NOLOCK)
WHERE m.CID = 12345
```

### 8.2 Find customers needing SalesForce sync via MIMO
```sql
SELECT
    m.CID,
    m.TotalDeposit,
    m.TotalCashout,
    m.LastOccurredTriggerToSF
FROM BackOffice.CustomerMIMOAllTimeAggregatedData m WITH (NOLOCK)
WHERE m.LastOccurredTriggerToSF > '2026-03-17 00:00:00'
ORDER BY m.LastOccurredTriggerToSF ASC
```

### 8.3 Compare MIMO vs standard pipeline deposits for a customer
```sql
SELECT
    a.CID,
    a.TotalDeposit AS StandardDeposit,
    ISNULL(m.TotalDeposit, 0) AS MIMODeposit,
    a.TotalDeposit + ISNULL(m.TotalDeposit, 0) AS CombinedDeposit
FROM BackOffice.CustomerAllTimeAggregatedData_1 a WITH (NOLOCK)
LEFT JOIN BackOffice.CustomerMIMOAllTimeAggregatedData m WITH (NOLOCK)
    ON m.CID = a.CID
WHERE a.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

Jira: PAYUS-1770 (initial version, November 2020 - Shay Oren), PAYSOLB-803 (March 2022 - FTD success date calculation change). MIMO pipeline corresponds to the eToro Money/PAYSOLB Jira project indicating a payments solutions / banking product workstream.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.2/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: Jira PAYUS-1770, PAYSOLB-803 | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerMIMOAllTimeAggregatedData | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerMIMOAllTimeAggregatedData.sql*
