# Billing.PayoutProcess_GetNewRecords

> Atomically claims up to N unclaimed payout records for a worker session (InProcess=1), then returns all payment processing data needed to submit each withdrawal to the payment provider.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxNumOfItems + @CorrelationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_GetNewRecords` is the payout worker's "claim and load" procedure. A payout service worker calls it to atomically claim a batch of unclaimed payout records and receive all the data it needs to submit each withdrawal to the payment provider.

In a single transaction, the procedure:
1. Selects up to @MaxNumOfItems unclaimed records (`InProcess=0 AND CashoutStatusID IN (0,12)`)
2. Claims them by setting `InProcess=1`, `InProcessDate=GETUTCDATE()`, and stamping the worker's `CorrelationID`
3. Returns the full enriched dataset (funding type, amount, deposit reference, depot/protocol, customer blocking flags)

The claim is atomic: no other worker can pick up the same records because the UPDATE sets InProcess=1 before the transaction commits. The `@CorrelationID` ties the claimed records to this specific worker session, enabling `PayoutProcess_Abort` to release them if the worker fails.

Two result paths are unified via UNION ALL:
- **Credit Card withdrawals** (FundingTypeID=1): require special DepositID/DepotID fallback logic to find the originating deposit and resolve the correct terminal
- **Non-CC withdrawals** (FundingTypeID != 1): simpler join, DepotID taken directly from WTF

History: Initial SP by Geri Reshef (2017). Multiple revisions 2018-2023, including CID fix, IsRefundExcluded/IPAddress/WithdrawData additions, NOLOCK for deadlock prevention, PayoutGeneration filter, and a 2023 fix for "looped payout" bug.

---

## 2. Business Logic

### 2.1 Atomic Claim via CTE UPDATE with OUTPUT

**What**: Claims up to @MaxNumOfItems records in a single atomic UPDATE, capturing their IDs.

**Parameters Involved**: `@MaxNumOfItems`, `@CorrelationID`, `@PayoutGeneration`

**Rules**:
- CTE T: `SELECT TOP(@MaxNumOfItems) FROM Billing.PayoutProcess WHERE CashoutStatusID IN (0,12) AND InProcess=0 AND PayoutGeneration=@PayoutGeneration`
  - CashoutStatusID IN (0,12): ReceivedByBilling(12) or reset-to-zero state(0)
  - InProcess=0: unclaimed only
  - PayoutGeneration: routes to correct service generation (0=legacy, 1=new)
- UPDATE T: SET InProcess=1, InProcessDate=GETUTCDATE(), CorrelationID=@CorrelationID
  - `WithdrawToFundingID=WithdrawToFundingID` (self-assign - required to include it in OUTPUT)
  - OUTPUT Inserted.WithdrawToFundingID -> @Ids table variable
- Result: @Ids contains the WTF IDs of all claimed records

### 2.2 Credit Card Withdrawal Path (FundingTypeID=1)

**What**: Specialized enrichment for CC withdrawals that resolves DepositID and DepotID from originating deposit data.

**Rules (in MyCTE)**:
- Filter: `bf.FundingTypeID=1 AND bwtf.CashoutStatusID NOT IN (3,4)` (excludes Processed=3, Canceled=4)
- **DepositID resolution**: `IIf(IsNull(bwtf.DepositID,0)=0, (SELECT TOP 1 DepositID FROM Billing.Deposit WHERE CID=bw.CID AND FundingID=bwtf.FundingID AND PaymentStatusID=2 ORDER BY PaymentDate DESC), bwtf.DepositID)`
  - If WTF.DepositID is NULL: finds the most recent approved (PaymentStatusID=2) CC deposit for same CID+FundingID
  - If WTF.DepositID is set: uses it directly
- **DepotID resolution** (outer SELECT): `Iif(IsNull(bwtf.DepotID,0)=0 AND bwtf.DepositID IS NOT NULL, (SELECT bd.DepotID FROM Billing.Deposit WHERE DepositID=bwtf.DepositID), bwtf.DepotID)`
  - If DepotID not set but DepositID resolved: derives DepotID from the linked Deposit
- **ProtocolID**: Subquery from Billing.Depot using the resolved DepotID
- **ExTransactionID, PaymentData**: From Billing.Deposit (LEFT JOIN on resolved DepositID)
- FundingIsBlocked, WithdrawBlocked: From Billing.CustomerToFunding

### 2.3 Non-Credit Card Withdrawal Path (FundingTypeID != 1)

**What**: Standard enrichment for Wire, PayPal, Neteller, Crypto, etc. withdrawals.

**Rules (UNION ALL second branch)**:
- Filter: `bf.FundingTypeID <> 1 AND bwtf.CashoutStatusID NOT IN (3,4)`
- DepositID: taken directly from WTF.DepositID (no fallback lookup needed)
- DepotID: taken directly from WTF.DepotID (no DepositID-based lookup)
- ProtocolID: from LEFT JOIN Billing.Depot on WTF.DepotID
- ExTransactionID, PaymentData: LEFT JOIN Billing.Deposit on WTF.DepositID
- FundingIsBlocked, WithdrawBlocked: From Billing.CustomerToFunding

### 2.4 Result Set Columns

**What**: Combined result set from both paths, delivered to the payout worker.

| Column | Source | Purpose |
|--------|--------|---------|
| WithdrawID | WTF | Parent withdrawal request |
| FundingID | WTF | Payment instrument |
| ManagerID | PayoutProcess | Approving manager |
| CashoutStatusID | WTF | Current status |
| ProcessCurrencyID | WTF | Currency of payout |
| ExchangeRate | WTF | FX rate for USD conversion |
| Amount | WTF | Amount in ProcessCurrencyID |
| ID | WTF | WithdrawToFundingID |
| RefundAmountInDepositCurrency | WTF | Refund amount in original currency |
| CashoutTypeID | WTF | Type of cashout |
| VerificationCode | WTF | NULL = verified |
| DepositID | WTF / resolved | Originating deposit reference |
| DepotID | WTF / resolved | Terminal depot for routing |
| ExTransactionID | Deposit | External transaction ID from deposit |
| PaymentData | Deposit | Payment method metadata |
| ProtocolID | Depot | Payment protocol for routing |
| FundingTypeID | Funding | Payment method type |
| FundingIsBlocked | CustomerToFunding | Whether funding method is blocked |
| WithdrawBlocked | CustomerToFunding (IsRefundExcluded) | Whether withdrawals are blocked |
| FundingData | Funding | Funding method configuration data |
| CID | Withdraw | Customer ID |
| IPAddress | Withdraw | Customer IP from withdrawal request |
| WithdrawData | WTF | Additional withdrawal metadata |

### 2.5 Error Handling

**Rules**:
- TRY/CATCH wrapping the full transaction
- @@TRANCOUNT=1 -> ROLLBACK; @@TRANCOUNT>1 -> COMMIT (nested tx context)
- THROW re-raises exception to caller
- Commented-out RAISERROR for 0 results (removed to avoid noise)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxNumOfItems | INT | NO | - | CODE-BACKED | Maximum records to claim in this batch. Controls throughput per worker call. Passed to SELECT TOP. |
| 2 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | UUID for this worker processing session. Stamped on all claimed records (PayoutProcess.CorrelationID). Used by PayoutProcess_Abort to release on failure. |
| 3 | @PayoutGeneration | INT | YES | 0 | CODE-BACKED | 0=legacy payout service, 1=new service. Filters PayoutProcess records to the correct generation. Default=0. |
| 4 | Result set | TABLE | - | - | CODE-BACKED | 23 columns - full payment processing data for each claimed record. UNION ALL of CC (FundingTypeID=1) and non-CC (FundingTypeID!=1) branches. See Section 2.4 for column list. |
| 5 | RETURN value | - | - | - | CODE-BACKED | No explicit RETURN. THROW re-raises exceptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE (claim) | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | MODIFIER | Claims records by setting InProcess=1, CorrelationID, InProcessDate |
| JOIN | Billing.WithdrawToFunding | READ | Source of withdrawal data and current status |
| JOIN | Billing.Withdraw | READ | CID and IPAddress from withdrawal request |
| JOIN | Billing.Funding | READ | FundingTypeID for CC vs non-CC routing |
| JOIN | Billing.CustomerToFunding | READ | FundingIsBlocked, WithdrawBlocked (IsRefundExcluded) |
| LEFT JOIN | Billing.Deposit | READ | ExTransactionID, PaymentData, DepotID fallback |
| LEFT JOIN | Billing.Depot | READ | ProtocolID for routing |
| Subquery | Billing.Deposit | READ | CC: last approved deposit for DepositID/DepotID fallback |
| TVP | dbo.IdList | Type | @Ids internal table variable for claimed IDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout service (PayoutUser, SQL_SecurePay, RedeemServiceUser) | @MaxNumOfItems, @CorrelationID | EXEC caller | Called to claim and load payout records for submission to payment provider |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_GetNewRecords (procedure)
├── Billing.PayoutProcess (table) - claim UPDATE
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
├── Billing.CustomerToFunding (table)
├── Billing.Deposit (table) - DepositID/DepotID fallback
└── Billing.Depot (table) - ProtocolID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | UPDATE (claim InProcess=1, CorrelationID) |
| Billing.WithdrawToFunding | Table | INNER JOIN (WTF data) |
| Billing.Withdraw | Table | INNER JOIN (CID, IPAddress) |
| Billing.Funding | Table | INNER JOIN (FundingTypeID) |
| Billing.CustomerToFunding | Table | INNER JOIN (blocking flags) |
| Billing.Deposit | Table | LEFT JOIN (payment data) + subquery (CC deposit fallback) |
| Billing.Depot | Table | LEFT JOIN (ProtocolID) + subquery (DepotID fallback for CC) |
| dbo.IdList | User Defined Type | @Ids internal variable for claimed WTF IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout service (PayoutUser, SQL_SecurePay, RedeemServiceUser) | Application | Claims payout records and loads all submission data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. The claim UPDATE uses the filtered NC index on Billing.PayoutProcess (CashoutStatusID IN (0,12) AND InProcess=0). NOLOCK hints on most reads to prevent deadlocks during the claim transaction.

### 7.2 Constraints

N/A for stored procedure. Atomic CTE UPDATE+OUTPUT ensures no duplicate claims between concurrent workers. @PayoutGeneration routes claims to the correct service generation. FundingTypeID=1 vs !=1 UNION ALL split handles different DepositID/DepotID resolution logic. CashoutStatusID NOT IN (3,4) excludes already-finalized records from the result even if somehow claimed. 2023 fix addressed looped payout bug.

---

## 8. Sample Queries

### 8.1 Claim and retrieve up to 10 payout records for new payout service

```sql
EXEC Billing.PayoutProcess_GetNewRecords
    @MaxNumOfItems  = 10,
    @CorrelationID  = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    @PayoutGeneration = 1;  -- new payout service
```

### 8.2 Check how many records are waiting per payout generation

```sql
SELECT
    pp.PayoutGeneration,
    pp.CashoutStatusID,
    COUNT(*) AS WaitingCount
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.InProcess = 0
  AND pp.CashoutStatusID IN (0, 12)
GROUP BY pp.PayoutGeneration, pp.CashoutStatusID
ORDER BY pp.PayoutGeneration, pp.CashoutStatusID;
```

### 8.3 Find records currently in-process by worker session

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CorrelationID,
    pp.InProcessDate,
    pp.CashoutStatusID,
    pp.PayoutGeneration
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.InProcess = 1
ORDER BY pp.InProcessDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: PayoutUser/SQL_SecurePay/RedeemServiceUser EXECUTE grants confirmed | Corrections: 0 applied*
*Object: Billing.PayoutProcess_GetNewRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_GetNewRecords.sql*
