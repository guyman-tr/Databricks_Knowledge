# Customer.PostMIMOOperations

> Post-Money-In-Money-Out (MIMO) reconciliation procedure that recalculates and updates a customer's BSLRealFunds balance after a deposit or withdrawal event, using live open-position PnL and bonus-credit adjustment logic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML (contains CID, CreditTypeID, CreditID, CheckBonus); returns @RetVal INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MIMO stands for "Money In Money Out" - the eToro term for deposit and withdrawal events. Whenever a customer deposits or withdraws funds, the platform must reconcile the Balance Stop Loss (BSL) threshold (`CustomerMoney.BSLRealFunds`) to reflect the customer's new financial state, incorporating the current unrealized PnL from all open positions. `Customer.PostMIMOOperations` is the engine that performs this reconciliation.

This procedure is called asynchronously after a MIMO event (deposit/withdrawal) completes. It receives all necessary inputs in a single XML parameter (`@Params`), supporting loose coupling with the calling system. The procedure then computes the updated BSLRealFunds value - which is the sum of RealizedEquity plus current open-position PnL minus the current bonus credit - and writes it back to `Customer.CustomerMoney` via `Customer.SetBalanceDataFix`.

A critical secondary concern is bonus credit integrity: if the customer has a bonus and the deposit amount exceeds their unrealized equity before the deposit, the bonus is capped to prevent customers from "gaming" the withdrawal system. The procedure additionally removes the customer from `Trade.BSLUsersWhiteList` (which had temporarily suspended BSL enforcement during the MIMO window) and logs a snapshot of all position rates used in the calculation to `History.SYNBSL_MIMOSnapShots` for auditability.

---

## 2. Business Logic

### 2.1 BSLRealFunds Recalculation

**What**: After every MIMO event, BSLRealFunds is recalculated as: `RealizedEquity + SUM(open position PnL) - BonusCredit`

**Columns/Parameters Involved**: `@PnL`, `@RealizedEquity`, `@TMP_NewBonusChange`, `@BSLRealFunds`

**Rules**:
- Open position PnL is pulled from `Trade.PnL` view (which provides live PnLInDollars per position).
- PnL is summed across ALL open positions for the CID using `Trade.MimoPosition` and `Trade.MimoRawData` user-defined table types.
- BSLRealFunds = ISNULL(RealizedEquity, 0) + ISNULL(PnL, 0) - ISNULL(NewBonusCredit, 0)
- The result is passed to `Customer.SetBalanceDataFix` with `@ShouldChangeBSLRealFunds = 1`.

```
MIMO event fires
  |
  +-> Read Trade.PnL for CID (all open positions)
  |
  +-> Aggregate: SUM(PnLInDollars) = @PnL
  |
  +-> Get RealizedEquity, BonusCredit from Customer.Customer
  |
  +-> Optionally cap BonusCredit (see 2.2)
  |
  +-> BSLRealFunds = RealizedEquity + PnL - BonusCredit
  |
  +-> EXEC Customer.SetBalanceDataFix (@ShouldChangeBSLRealFunds=1)
  |
  +-> DELETE Trade.BSLUsersWhiteList for this CreditID
  |
  +-> INSERT History.SYNBSL_MIMOSnapShots (audit)
```

### 2.2 Bonus Credit Cap After Deposit

**What**: When a customer receives a deposit (MIMO credit) AND has bonus credit, the bonus is capped so the customer can withdraw the deposited amount.

**Columns/Parameters Involved**: `@CheckBonus`, `@Deposit`, `@UnrealizedEquity`, `@TMP_NewBonusChange`, `@BonusCredit`

**Rules**:
- Only runs when `@CheckBonus = 1` AND the customer has non-zero BonusCredit.
- Gets the deposit amount from `History.ActiveCreditBucket_VW` WHERE CreditID = @MimoCreditID (the Payment field).
- Computes UnrealizedEquity = RealizedEquity + PnL - Deposit (equity before this deposit).
- New bonus cap = MIN(BonusCredit, UnrealizedEquity). Cannot be negative (floored to 0).
- If the new cap differs from the current BonusCredit, updates `Customer.CustomerMoney.BonusCredit` directly.
- Logic: ensures the customer is not blocked from withdrawing their own deposited funds by excess bonus.

```
If @CheckBonus = 1 AND BonusCredit > 0:
  @Deposit = Payment from History.ActiveCreditBucket_VW WHERE CreditID = @MimoCreditID
  @UnrealizedEquity = RealizedEquity + PnL - Deposit
  @NewBonus = MIN(BonusCredit, UnrealizedEquity)
  @NewBonus = MAX(@NewBonus, 0)  -- floor at zero
  If @NewBonus != BonusCredit:
    UPDATE Customer.CustomerMoney SET BonusCredit = @NewBonus WHERE CID = @CID
```

### 2.3 Parts Architecture (@PartsToDo Bitmask)

**What**: The procedure uses a bitmask parameter to allow partial execution of its logic sections.

**Columns/Parameters Involved**: `@PartsToDo`

**Rules**:
- `@PartsToDo = 0` OR `@PartsToDo & 1 = 1`: Execute Part 1 (BSLRealFunds update, bonus cap, whitelist removal, snapshot).
- The architecture suggests future parts (2, 4, 8, ...) may exist or were planned.
- The `@ID INT` parameter appears to be reserved - not used within the current body.
- Error handling: if Part 1 fails, @RetVal increments by 1; if initial XML parsing fails, returns -1.

### 2.4 BSL Whitelist Removal

**What**: During a MIMO event, the customer is temporarily added to `Trade.BSLUsersWhiteList` to suspend BSL enforcement. PostMIMOOperations removes them after recalculation.

**Columns/Parameters Involved**: `@MimoCreditID`, `@CID`

**Rules**:
- `DELETE Trade.BSLUsersWhiteList WHERE CreditID = @MimoCreditID AND CID = @CID`
- Must happen inside the same transaction as the BSLRealFunds update (COMMIT TRAN).
- Ensures BSL enforcement resumes with the correct new threshold.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | YES | null | VERIFIED | XML document containing all MIMO event context. Expected structure: `<Root><CID Value="{int}"/><CreditTypeID Value="{int}"/><CreditID Value="{bigint}"/><CheckBonus Value="{tinyint}"/></Root>`. CID = customer, CreditTypeID = event type (from Dictionary.CreditType), CreditID = the MIMO credit record ID, CheckBonus = 1 if bonus adjustment logic should run. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bitmask controlling which logic sections execute. Current: 0 or bit 1 set = run Part 1 (BSL recalculation). Enables the calling system to run specific parts of the reconciliation independently. |
| 3 | @ID | INT | NO | - | NAME-INFERRED | Reserved integer identifier parameter. Present in the signature but not used in the current procedure body. Likely reserved for future extension or legacy compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID (from XML) | Customer.Customer (view) | Lookup | Reads BonusCredit, RealizedEquity, BSLRealFunds for the customer |
| @CreditTypeID (from XML) | Dictionary.CreditType | Lookup | Gets credit type name for the SetBalanceDataFix description |
| @CID | Trade.PnL | READ | Gets all open position PnL for the customer via MimoPosition/MimoRawData table types |
| @MimoCreditID | History.ActiveCreditBucket_VW | READ | Gets the deposit Payment amount when bonus cap logic runs |
| @CID | Customer.CustomerMoney | MODIFIER | Conditionally updates BonusCredit when bonus cap applies |
| @MimoCreditID, @CID | Trade.BSLUsersWhiteList | DELETER | Removes customer from BSL whitelist after recalculation |
| @BSLChangeCreditID (OUTPUT) | History.SYNBSL_MIMOSnapShots | WRITER | Logs position rate snapshot used in BSL calculation |
| - | Customer.SetBalanceDataFix | Caller (EXEC) | Performs the actual BSLRealFunds update on CustomerMoney |
| - | Trade.MimoPosition | Table type | User-defined table type used as intermediate position data container |
| - | Trade.MimoRawData | Table type | User-defined table type used as raw MIMO calculation data container |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PostMIMOOperationsDebug | EXEC | Sibling/Debug | Debug variant that mirrors this procedure's behavior for troubleshooting |
| Billing MIMO pipeline | External | Caller | Called by Billing system after deposit/withdrawal transactions complete to reconcile BSL |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PostMIMOOperations (procedure)
+-- Trade.PnL (view) [reads open position PnL via MimoPosition table type]
+-- Customer.Customer (view) [reads BonusCredit, RealizedEquity]
+-- Customer.CustomerMoney (table) [conditionally updates BonusCredit]
+-- Trade.BSLUsersWhiteList (table) [deletes whitelist entry]
+-- History.ActiveCreditBucket_VW (view) [reads deposit Payment for bonus cap]
+-- History.SYNBSL_MIMOSnapShots (table) [inserts calculation snapshot]
+-- Customer.SetBalanceDataFix (procedure) [writes BSLRealFunds update]
|     +-- Customer.CustomerMoney (table) [UPDATE target for BSL fields]
|     +-- Customer.SetBalanceInsertCredit_Native (procedure) [logs credit record]
+-- Trade.MimoPosition (user-defined type) [table variable type for position data]
+-- Trade.MimoRawData (user-defined type) [table variable type for raw MIMO data]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PnL | View | SELECT open position PnL for the CID via Trade.MimoPosition table type |
| Customer.Customer | View | SELECT BonusCredit, RealizedEquity, BSLRealFunds for the CID |
| Customer.CustomerMoney | Table | UPDATE BonusCredit when bonus cap applies |
| Trade.BSLUsersWhiteList | Table | DELETE - removes customer from BSL whitelist post-reconciliation |
| History.ActiveCreditBucket_VW | View | SELECT Payment amount for the MIMO credit (bonus cap calculation) |
| History.SYNBSL_MIMOSnapShots | Table | INSERT audit snapshot of position rates used in BSL calculation |
| Customer.SetBalanceDataFix | Procedure | EXEC - performs BSLRealFunds update on CustomerMoney |
| Dictionary.CreditType | Table | SELECT Name for description construction |
| Trade.MimoPosition | User Defined Type | DECLARE @MimoPosition variable - holds open position intermediary data |
| Trade.MimoRawData | User Defined Type | DECLARE @MimoRawData variable - holds raw MIMO calculation data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PostMIMOOperationsDebug | Procedure | Debug sibling that mirrors this procedure's logic for diagnostic runs |
| Billing MIMO Pipeline | External | Called by Billing system post-deposit/withdrawal to update BSLRealFunds |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRAN / COMMIT TRAN (Part 1) | Transaction | All Part 1 writes (CustomerMoney BonusCredit update, BSLUsersWhiteList delete, SetBalanceDataFix call) are wrapped in a transaction. ROLLBACK on error; if nested transaction, commits to avoid partial rollback issues. |
| BEGIN TRY / BEGIN CATCH (outer) | Error handling | XML parsing failure returns -1 immediately. Part 1 failure increments @RetVal by 1 (non-fatal for multi-part execution). |
| History.SYNBSL_MIMOSnapShots insert (outside TRAN) | Design | Snapshot logging occurs after COMMIT TRAN - it is an audit log, not a transactional write. |

---

## 8. Sample Queries

### 8.1 View BSL snapshot history for a specific MIMO credit

```sql
SELECT
    s.MimoCreditID,
    s.BSLChangeCreditID,
    s.PositionID,
    s.PriceRateID,
    s.Bid,
    s.Ask
FROM History.SYNBSL_MIMOSnapShots s WITH (NOLOCK)
WHERE s.MimoCreditID = 987654321
ORDER BY s.PositionID
```

### 8.2 Check if a customer is currently on the BSL whitelist (pending MIMO reconciliation)

```sql
SELECT
    w.CID,
    w.CreditID,
    cm.BSLRealFunds,
    cm.Credit
FROM Trade.BSLUsersWhiteList w WITH (NOLOCK)
JOIN Customer.CustomerMoney cm WITH (NOLOCK) ON cm.CID = w.CID
WHERE w.CID = 12345
```

### 8.3 Trace a MIMO reconciliation: credit event -> BSL snapshot -> updated balance

```sql
DECLARE @MimoCreditID BIGINT = 999888777;

SELECT
    acb.CreditID AS MimoCreditID,
    acb.CreditTypeID,
    ct.Name AS CreditTypeName,
    acb.Payment AS DepositAmount,
    acb.Occurred AS EventTime,
    snap.BSLChangeCreditID,
    snap.PositionID,
    snap.Bid AS PositionRateAtMIMO,
    cm.BSLRealFunds AS CurrentBSLRealFunds,
    cm.Credit AS CurrentBalance
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
LEFT JOIN History.SYNBSL_MIMOSnapShots snap WITH (NOLOCK) ON snap.MimoCreditID = acb.CreditID
LEFT JOIN Customer.CustomerMoney cm WITH (NOLOCK) ON cm.CID = acb.CID
WHERE acb.CreditID = @MimoCreditID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661/Multi-Currency+Balance+API) | Confluence | MIMO terminology confirmed as "Money In Money Out" - the eToro term for deposit/withdrawal events. New Trading.BalanceService microservice will replace Billing SP entry-points including MIMO pipeline. |
| [Multi-Currency Database Schema Changes](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14019264620/Multi-Currency+Database+Schema+Changes) | Confluence | BSLRealFunds confirmed as account-level (USD aggregate) field in multi-currency design. PostMIMOOperations role in updating BSLRealFunds confirmed. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 7.0/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PostMIMOOperations | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PostMIMOOperations.sql*
