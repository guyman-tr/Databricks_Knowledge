# History.GetCustomersCashflowData

> Returns cash-flow credits for multiple customers within a date range, filtered to actual money-movement types only (deposits, cashouts, bonuses, compensations, chargebacks, refunds), following the legacy CashFlowProvider exclusion pattern used by the DrawDown analytics system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs TVP (multi-customer) + @MinDate/@MaxDate date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **multi-customer cashflow data provider** for the DrawDown analytics system and related gain calculation services. It accepts a batch of customer IDs via a Table-Valued Parameter (`[Trade].[CidList]`), queries `History.Credit` for each, and returns only the credits that represent actual real money movements - deposits, cashouts, bonuses, compensations, chargebacks, and refunds. Position-related debits/credits (open/close), CopyTrader operational entries, fees, and data-fix entries are all excluded.

The comment in the code identifies this as a replacement for the "legacy DrawDown system / CashFlowProvider" pattern, with the same exclusion filter used by `Trade.Gain_LoadCashflows`.

---

## 2. Business Logic

### 2.1 CreditTypeID Exclusion Filter (Cash-Flow Classification)

**What**: Excludes 20 CreditTypeIDs from results, retaining only true money-movement credits.

**Excluded CreditTypeIDs** (with names from `Dictionary.CreditType`):

| CreditTypeID | Name | Reason for Exclusion |
|-------------|------|----------------------|
| 3 | Open Position | Position margin reservation, not real cash flow |
| 4 | Close Position | Position P&L settlement, not real cash flow |
| 8 | Reverse cashout | Reversal entry, not a real cash movement |
| 9 | Cashout request | Request placeholder, not the actual cashout |
| 13 | Edit Stop Loss | Adjustment record only |
| 14 | End Of Week Fee | Rollover/overnight fee (not cash received/paid) |
| 15 | Cashout Fee | Fee deducted from cashout amount |
| 18 | Account balance to mirror | CopyTrader capital allocation (internal) |
| 19 | Mirror balance to account | CopyTrader capital return (internal) |
| 20 | Register new mirror | Mirror registration operational |
| 21 | Unregister mirror | Mirror unregistration operational |
| 22 | Mirror Hierarchical Close position | CopyTrader copy-close record |
| 23 | Hierarchical Open position | CopyTrader copy-open record |
| 24 | Close position by recovery | Recovery mechanism close |
| 25 | Open position by recovery | Recovery mechanism open |
| 27 | Detach position from mirror | Mirror detach operational |
| 28 | Detach Stock From Mirror | Stock mirror detach operational |
| 29 | Open Stock Order | Stock order open |
| 30 | Close Stock Order | Stock order close |
| 31 | Data Fix | Administrative data corrections |

**Included CreditTypeIDs** (NOT in exclusion list):

| CreditTypeID | Name | Meaning |
|-------------|------|---------|
| 1 | Deposit | Real money deposited by customer |
| 2 | Cashout | Real money withdrawn by customer |
| 5 | Champ Winner | Championship prize payment |
| 6 | Compensation | Manual compensation credit |
| 7 | Bonus | Bonus credit |
| 10 | IB synchronization | Introducing Broker payment |
| 11 | Chargeback | Credit card chargeback |
| 12 | Refund | Refund payment |
| 16 | Refund As ChargeBack | Refund processed via chargeback channel |
| 17 | FixHistoryCreditChargeBacks | Historical chargeback correction |
| 26 | FixBonusCreditRealizedEquity | Bonus equity adjustment |
| 32 | Reverse Deposit | Reversed deposit |
| 33 | Cashout Rollback | Cashout rollback credit |

### 2.2 Temp Table with Clustered Index for Batch CID Processing

**What**: The TVP `@CIDs` is materialized into a temp table `#CustomerFilter` with a CLUSTERED INDEX on CID before the main query.

**Rules**:
- `SELECT CID INTO #CustomerFilter FROM @CIDs`
- `CREATE CLUSTERED INDEX idx_CID ON #CustomerFilter(CID)`
- The INNER JOIN on CID uses this indexed temp table for efficient filtering
- Temp table dropped at end of procedure

**Why**: SQL Server cannot create indexes on TVP parameters; materializing into a temp table and adding a clustered index dramatically improves join performance for large batch sizes.

### 2.3 Result Ordering

**Rules**: `ORDER BY a.CID, a.Occurred` - results are grouped by customer then sorted chronologically within each customer, ready for sequential processing by the calling analytics system.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | [Trade].[CidList] READONLY | NO | - | CODE-BACKED | Table-Valued Parameter containing CID (INT) values for batch customer lookup. Type defined in Trade schema as a single-column INT table. |
| 2 | @MinDate | DATETIME | NO | - | CODE-BACKED | Start of date range filter on History.Credit.Occurred. |
| 3 | @MaxDate | DATETIME | NO | - | CODE-BACKED | End of date range filter on History.Credit.Occurred. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| CID | History.Credit.CID | Customer ID |
| TransactionDate | History.Credit.Occurred | Timestamp of the credit transaction |
| Amount | History.Credit.TotalCashChange | Net cash change for this credit (positive = received, negative = paid out) |
| CreditTypeID | History.Credit.CreditTypeID | Type of credit (see Section 2.1 for included values) |
| CreditID | History.Credit.CreditID | Unique credit record identifier |
| WithdrawID | History.Credit.WithdrawID | Associated withdrawal ID (NULL for non-cashout credits) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Credit | Read | Primary source; filtered by CID batch + date range + CreditTypeID exclusion list. |
| TVP type | Trade.CidList | Type dependency | @CIDs parameter uses this user-defined table type from the Trade schema. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DrawDown / Gain analytics system | EXEC | Direct call | Batch cashflow retrieval for DrawDown calculation and gain reporting. |
| History.Credit (view) | Referenced By | Read | Procedure reads from this view (see Credit.md Section 5.2). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetCustomersCashflowData (procedure)
├── History.Credit (view) [main data source]
└── Trade.CidList (user defined type) [TVP parameter type]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | View | Main source queried for cashflow records by CID + date range + CreditTypeID filter. |
| Trade.CidList | User Defined Type | TVP parameter type for @CIDs batch input. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DrawDown analytics system | External | Batch retrieval of actual money flows per customer for DrawDown/gain calculations. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Exclusion of 20 CreditTypeIDs | Cash-flow filter | Only real money movement types are returned; position credits, fees, CopyTrader operational records, and data-fix types are excluded. |
| Temp table materialization | Performance | TVP materialized to #CustomerFilter with CLUSTERED INDEX to enable efficient INNER JOIN over large customer batches. |
| CreditType 15 excluded | Difference from Gain_LoadCashflows | Trade.Gain_LoadCashflows includes type-15 (Cashout Fee) but flags it as IsFee=1; this procedure excludes it entirely. |

---

## 8. Sample Queries

### 8.1 Get cashflow data for a single customer in 2024

```sql
DECLARE @cids [Trade].[CidList];
INSERT INTO @cids VALUES (12345);

EXEC History.GetCustomersCashflowData
    @CIDs = @cids,
    @MinDate = '2024-01-01',
    @MaxDate = '2024-12-31';
```

### 8.2 Verify included credit types for a customer

```sql
SELECT
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.TotalCashChange,
    hc.Occurred
FROM History.Credit hc WITH (NOLOCK)
JOIN Dictionary.CreditType ct ON hc.CreditTypeID = ct.CreditTypeID
WHERE hc.CID = 12345
  AND hc.Occurred BETWEEN '2024-01-01' AND '2024-12-31'
  AND hc.CreditTypeID NOT IN (3,4,8,9,13,14,15,18,19,20,21,22,23,24,25,27,28,29,30,31)
ORDER BY hc.Occurred;
```

### 8.3 Check all Dictionary.CreditType values

```sql
SELECT CreditTypeID, RTRIM(Name) AS Name
FROM Dictionary.CreditType
ORDER BY CreditTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetCustomersCashflowData | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetCustomersCashflowData.sql*
