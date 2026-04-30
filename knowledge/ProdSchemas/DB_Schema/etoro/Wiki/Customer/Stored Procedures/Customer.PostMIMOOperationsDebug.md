# Customer.PostMIMOOperationsDebug

> Debug variant of PostMIMOOperations: performs the same BSLRealFunds recalculation and bonus-cap logic as the production procedure, but uses the richer Trade.PositionForExternalUseWithPnL view and surfaces error messages to the result set for diagnostic purposes.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML (contains CID, CreditTypeID, CreditID, CheckBonus); returns @RetVal INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`PostMIMOOperationsDebug` is the diagnostic counterpart to `Customer.PostMIMOOperations`. It performs the identical post-MIMO (Money In Money Out) BSL recalculation - computing BSLRealFunds from open-position PnL, RealizedEquity, and BonusCredit, then writing the updated value via `Customer.SetBalanceDataFix` - but is designed for troubleshooting scenarios rather than production invocation.

The key difference is the position data source: instead of `Trade.PnL` (the production view used by PostMIMOOperations), this debug variant reads from `Trade.PositionForExternalUseWithPnL`, which provides additional position-level fields (InstrumentID, IsBuy, EndConversionRate) not strictly needed for the BSL calculation but useful for understanding which positions contributed to the result. Additionally, the CATCH block emits `SELECT ERROR_MESSAGE()` so any SQL error is returned directly to the caller for immediate inspection.

This procedure is not called by the production MIMO pipeline. It is used manually by engineers or support staff to re-run a MIMO reconciliation for a specific customer in a controlled environment to diagnose why the production run may have failed or produced unexpected results.

---

## 2. Business Logic

### 2.1 BSLRealFunds Recalculation (identical to PostMIMOOperations)

**What**: Same formula as PostMIMOOperations: BSLRealFunds = RealizedEquity + SUM(open PnL) - BonusCredit.

**Columns/Parameters Involved**: `@PnL`, `@RealizedEquity`, `@TMP_NewBonusChange`, `@BSLRealFunds`

**Rules**:
- Identical bonus-cap logic as PostMIMOOperations (see Customer.PostMIMOOperations Section 2.2).
- Identical @PartsToDo bitmask behavior (0 or bit-1 = execute Part 1).
- Same BSL whitelist removal and snapshot logging.
- See [Customer.PostMIMOOperations](Customer.PostMIMOOperations.md) Section 2 for the full logic documentation - logic is identical.

### 2.2 Differences vs Production Procedure

**What**: Two intentional differences make this a diagnostic tool rather than a production component.

**Rules**:
- **Position data source**: Uses `Trade.PositionForExternalUseWithPnL` instead of `Trade.PnL`. This view includes InstrumentID, IsBuy, and EndConversionRate - additional fields that capture richer position context into `@MimoRawData` for diagnostic inspection.
- **Error surfacing**: CATCH block executes `SELECT ERROR_MESSAGE()` - any SQL error during Part 1 is returned as a result set row, making failures immediately visible in SSMS or diagnostic tooling without needing to check logs.
- **No PositionID NULL filter**: The final SYNBSL_MIMOSnapShots insert does not filter `WHERE RD.PositionID IS NOT NULL` - all rows including NULL-PositionID rows are logged (captures the "customer has no open positions" state for debugging).
- **Description**: Minor - no `TRIM()` around the credit type name (cosmetic only).

```
Production (PostMIMOOperations)     Debug (PostMIMOOperationsDebug)
-------------------------------     --------------------------------
Trade.PnL (minimal fields)          Trade.PositionForExternalUseWithPnL (full fields)
CATCH: silent (@@RetVal++)          CATCH: SELECT ERROR_MESSAGE() + @@RetVal++
WHERE PositionID IS NOT NULL        (no filter - all rows logged)
TRIM(Name) in description           Name (no trim) in description
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | YES | null | VERIFIED | XML document containing all MIMO event context. Same structure as PostMIMOOperations: `<Root><CID Value="{int}"/><CreditTypeID Value="{int}"/><CreditID Value="{bigint}"/><CheckBonus Value="{tinyint}"/></Root>`. See [Customer.PostMIMOOperations](Customer.PostMIMOOperations.md) for full parameter documentation. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bitmask controlling which logic sections execute. 0 or bit-1 set = run Part 1 (BSL recalculation). Identical to PostMIMOOperations. |
| 3 | @ID | INT | NO | - | NAME-INFERRED | Reserved parameter - not used in the procedure body. Identical to PostMIMOOperations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID (from XML) | Customer.Customer (view) | Lookup | Reads BonusCredit, RealizedEquity for the customer |
| @CreditTypeID | Dictionary.CreditType | Lookup | Gets credit type name for description |
| @CID | Trade.PositionForExternalUseWithPnL | READ | Gets open position PnL with full position detail (vs Trade.PnL in production) |
| @MimoCreditID | History.ActiveCreditBucket_VW | READ | Gets deposit Payment for bonus cap calculation |
| @CID | Customer.CustomerMoney | MODIFIER | Conditionally updates BonusCredit |
| @MimoCreditID, @CID | Trade.BSLUsersWhiteList | DELETER | Removes customer from BSL whitelist |
| - | History.SYNBSL_MIMOSnapShots | WRITER | Logs position rate snapshot (includes NULL PositionID rows) |
| - | Customer.SetBalanceDataFix | Caller (EXEC) | Performs BSLRealFunds update |
| - | Trade.MimoPosition | User Defined Type | Table variable for position intermediary data |
| - | Trade.MimoRawData | User Defined Type | Table variable for raw MIMO calculation data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Engineers / Support staff | Manual EXEC | Diagnostic caller | Run manually to debug MIMO reconciliation failures for specific customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PostMIMOOperationsDebug (procedure)
+-- Trade.PositionForExternalUseWithPnL (view) [richer position data vs production Trade.PnL]
+-- Customer.Customer (view) [reads BonusCredit, RealizedEquity]
+-- Customer.CustomerMoney (table) [conditionally updates BonusCredit]
+-- Trade.BSLUsersWhiteList (table) [deletes whitelist entry]
+-- History.ActiveCreditBucket_VW (view) [reads deposit Payment]
+-- History.SYNBSL_MIMOSnapShots (table) [inserts calculation snapshot]
+-- Customer.SetBalanceDataFix (procedure) [writes BSLRealFunds update]
|     +-- Customer.CustomerMoney (table)
|     +-- Customer.SetBalanceInsertCredit_Native (procedure)
+-- Trade.MimoPosition (user-defined type)
+-- Trade.MimoRawData (user-defined type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUseWithPnL | View | SELECT open position data with full instrument/direction detail for the CID |
| Customer.Customer | View | SELECT BonusCredit, RealizedEquity |
| Customer.CustomerMoney | Table | UPDATE BonusCredit when bonus cap applies |
| Trade.BSLUsersWhiteList | Table | DELETE - removes customer from BSL whitelist |
| History.ActiveCreditBucket_VW | View | SELECT Payment for bonus cap calculation |
| History.SYNBSL_MIMOSnapShots | Table | INSERT audit snapshot |
| Customer.SetBalanceDataFix | Procedure | EXEC - BSLRealFunds update |
| Dictionary.CreditType | Table | SELECT Name for description |
| Trade.MimoPosition | User Defined Type | Table variable type |
| Trade.MimoRawData | User Defined Type | Table variable type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Used only via manual execution by engineering/support. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRAN / COMMIT TRAN | Transaction | Part 1 writes are transactional - same as PostMIMOOperations. |
| SELECT ERROR_MESSAGE() in CATCH | Diagnostic | Unlike the production procedure, this debug variant surfaces error text to the result set for immediate visibility. |

---

## 8. Sample Queries

### 8.1 Execute debug reconciliation for a specific MIMO event

```sql
-- Build the XML params and run the debug procedure for a specific CID/CreditID
DECLARE @params XML = '<Root>
    <CID Value="12345"/>
    <CreditTypeID Value="1"/>
    <CreditID Value="987654321"/>
    <CheckBonus Value="1"/>
</Root>';

EXEC Customer.PostMIMOOperationsDebug
    @Params = @params,
    @PartsToDo = 0,
    @ID = 0;
-- Any error message will appear in the result set
```

### 8.2 Compare position data between debug and production view for a customer

```sql
-- Debug uses PositionForExternalUseWithPnL (more fields)
SELECT PositionID, InstrumentID, IsBuy, PnLInDollars, EndConversionRate
FROM Trade.PositionForExternalUseWithPnL WITH (NOLOCK)
WHERE CID = 12345

UNION ALL

-- Production uses Trade.PnL (minimal fields)
SELECT PositionID, NULL AS InstrumentID, NULL AS IsBuy, PnLInDollars, ConversionRate
FROM Trade.PnL WITH (NOLOCK)
WHERE CID = 12345
```

### 8.3 Check last SYNBSL_MIMOSnapShots for a customer including NULL-position rows

```sql
-- Debug variant logs all rows including NULL PositionID (no-open-positions state)
SELECT TOP 20
    s.MimoCreditID,
    s.BSLChangeCreditID,
    s.PositionID,
    s.PriceRateID,
    s.Bid,
    s.Ask,
    CASE WHEN s.PositionID IS NULL THEN 'No open positions at MIMO time' ELSE 'Open position' END AS Note
FROM History.SYNBSL_MIMOSnapShots s WITH (NOLOCK)
ORDER BY s.MimoCreditID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Logic and purpose derived from DDL analysis and comparison with [Customer.PostMIMOOperations](Customer.PostMIMOOperations.md).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 7.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PostMIMOOperationsDebug | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PostMIMOOperationsDebug.sql*
