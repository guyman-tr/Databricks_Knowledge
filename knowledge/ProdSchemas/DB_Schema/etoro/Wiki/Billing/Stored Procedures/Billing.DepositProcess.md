# Billing.DepositProcess

> The core deposit approval SP - validates state, credits the customer's account via Billing.AmountAdd, marks the deposit Approved (PaymentStatusID=2), calculates FTD status, and appends an audit action. Called in the "Finalize" step of the deposit processing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit PaymentStatusID->2 + EXEC Billing.AmountAdd + INSERT History.DepositAction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositProcess` is the critical path SP that converts a pending or in-flight deposit into an approved one. It is called in the **Finalize** step of the payment processing pipeline (confirmed by Confluence) - after the payment gateway has confirmed the transaction, the calling service invokes this SP to: validate the deposit can legally be approved, credit the customer's balance, stamp the deposit record as Approved, and record the action in audit history.

The SP is surrounded by extensive safety machinery: an XLOCK prevents race conditions when two threads try to finalize the same deposit simultaneously; XML schema validation ensures the gateway response payload conforms to the payment method's schema; a state machine check ensures the deposit is in a legally-transitionable status for its specific funding type; and a duplicate-processing guard (via `History.ActiveCreditRecentMemoryBucket` and `History.ActiveCredit`) prevents crediting a customer twice if the procedure is called more than once for the same deposit.

For offline payment methods (wire transfers, local bank wires), the SP additionally requires the caller to supply the settlement amount and currency - because these are negotiated outside the online flow and may differ from the original deposit amount.

The SP is also used manually by the Payments Integration team to recover stuck deposits: setting the deposit back to Pending status then calling this SP directly with the known exchange rate and gateway response data (per Confluence How-To guide).

Version history shows continuous evolution: XLOCK added 07/02/2021 (Shay O.) replacing an sp_getapplock approach; IsFTD calculation moved from History.Credit to Billing.Deposit (PAYIL-2121, 8/12/2020); MIMO aggregation call added (04/02/2021); ProtocolMIDSettingsID added (MIMOPS-4487, 01/07/2021). Removed: LocalPerfLog audit (DBAD-79, 30/07/2023), DepotToCurrency update (06/03/2024).

---

## 2. Business Logic

### 2.1 Pre-Transaction Validation (Phase 1 - No Transaction)

**What**: Loads deposit state and runs all validations before opening a transaction.

**Columns/Parameters Involved**: `@DepositID`, `@FundingTypeID`, `@PaymentStatusID`, `@isSingleFunding`, `@ApplyFTD`

**Rules**:
- Acquires XLOCK ROWLOCK on `Billing.Deposit` for the target row - prevents concurrent execution for same DepositID.
- Loads: `IsSingleFunding` (from `Dictionary.FundingType`), `FundingTypeID` (from `Billing.Funding`), current `PaymentStatusID`, `ApplyFtd` flag (from `Dictionary.DepositType` via LEFT JOIN - defaults to 1 if DepositType has no record).
- `@SessionID`: if not provided, inherits the deposit's existing SessionID.
- **Offline validation**: if `IsSingleFunding=1` OR `FundingTypeID=17` (Local Bank Wire) -> `@ProcessorValueDate`, `@NewAmount`, and `@NewCurrencyID` are ALL required. Raises error 60025 if missing.
- **Online validation**: if NOT offline -> `@NewAmount`, `@NewCurrencyID`, `@NewDepotID` are all reset to NULL (online amounts come from the deposit record itself).

### 2.2 XML Schema Validation

**What**: Validates the payment gateway response XML against the funding-type-specific schema.

**Columns/Parameters Involved**: `@PaymentData`, `Dictionary.GetXMLSchema`, `CLR.ParseXML`

**Rules**:
- Schema name = `'Deposit' + FundingType.Name` (e.g., `'DepositCreditCard'`, `'DepositPayPal'`).
- Fetched from `Dictionary.GetXMLSchema.XSD` via JOIN chain: GetXMLSchema -> FundingType -> Funding -> Deposit.
- If no matching schema found -> RAISERROR(60030, 'No XML Schema') + RETURN 60030.
- `CLR.ParseXML(@xmlSchema, @xmlValue)` - CLR assembly validates XML; returns 1 = valid, 0 = invalid.
- If @ParseResult = 0 -> RAISERROR(60030, 'parse result error') + RETURN 60030.

### 2.3 Payment State Machine Validation

**What**: Enforces that the deposit's current status is a legal predecessor to Approved (2) for its funding type.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@FundingTypeID`, `Dictionary.PaymentStatusStateMachine`

**Rules**:
- Check: `EXISTS (SELECT 1 FROM Dictionary.PaymentStatusStateMachine WHERE FundingTypeID=@FundingTypeID AND BeforePaymentStatusID=@PaymentStatusID AND AfterPaymentStatusID=2)`.
- Each funding type has its own allowed state transitions. A deposit in Declined status cannot be re-approved. A Pending (13) deposit CAN be approved for most funding types.
- If transition not allowed -> RAISERROR(60025, 'attempt to process from illegal payment STATUS') + RETURN 60025.
- Confirmed by Confluence: operators must check `Dictionary.PaymentStatusStateMachine` before manually running the SP.

### 2.4 Duplicate Processing Guard

**What**: Prevents crediting a customer's account twice for the same deposit.

**Columns/Parameters Involved**: `@DepositID`, `History.ActiveCreditRecentMemoryBucket`, `History.ActiveCredit`

**Rules**:
- First checks `History.ActiveCreditRecentMemoryBucket` for CreditTypeID=1 + DepositID (recent in-memory bucket for speed).
- If not found there, falls back to `History.ActiveCredit` WITH NOLOCK for the same criteria.
- If either check finds a record -> RAISERROR(60025, 'Deposit Already Processed') + RETURN 60025.
- This is the idempotency guard: if AmountAdd already ran for this deposit (creating an ActiveCredit record), the SP refuses to run again.
- Note: Confluence refactor doc flags "need to handle SP to be idempotent" - this guard IS that idempotency mechanism.

### 2.5 Amount Calculation and Account Credit

**What**: Converts deposit amount to integer USD cents and calls Billing.AmountAdd to credit the customer.

**Columns/Parameters Involved**: `@NewAmount`, `@ExchangeRate`, `@Amount`, `@ExchangeFee`, `@BaseExchangeRate`, `@MoveMoneyReasonID`

**Rules**:
- Amount formula: `CAST(ROUND(ISNULL(@NewAmount, Amount) * @ExchangeRate * 100, 0) AS INTEGER)` - converts to integer cents in USD (CurrencyID=1 hardcoded).
- ExchangeFee: if @ExchangeFee provided, overrides deposit's stored ExchangeFee.
- BaseExchangeRate: similarly overridden if provided.
- ManagerID: if @ManagerID > 0, overrides deposit's stored ManagerID; otherwise preserves.
- `EXEC Billing.AmountAdd @CID, 1 (USD), 1 (Deposit), @Amount, NULL, @ManagerID, @Description, NULL, NULL, @DepositID, NULL, NULL, @MoveMoneyReasonID`.
- If Billing.AmountAdd returns non-zero -> RAISERROR(60102) but does NOT RETURN (control falls through to deposit update anyway - this may be intentional for logging continuity).

### 2.6 FTD (First Time Deposit) Calculation

**What**: Determines if this is the customer's first-ever successful deposit.

**Columns/Parameters Involved**: `@isFirstTimeDeposit`, `@ApplyFTD`, `Billing.Deposit.IsFTD`

**Rules**:
- `@PreviousFTDCount = COUNT(1) FROM Billing.Deposit WHERE CID=@CID AND IsFTD=1 AND DepositID <> @DepositID` - counts other approved FTDs for this customer.
- `@isFirstTimeDeposit = CASE WHEN @PreviousFTDCount > 0 THEN 0 ELSE @ApplyFTD END`.
- If the customer already has a prior FTD, this deposit is NOT an FTD (IsFTD=0).
- If no prior FTD exists, the result depends on `Dictionary.DepositType.ApplyFtd` flag for the deposit's type.
- Change from PAYIL-2121 (Dec 2020): IsFTD now computed from `Billing.Deposit` (approved records) instead of `History.Credit` (more reliable source after decommission of old credit system).
- IsFTD=1 marks acquisition conversions; used by analytics, CRM triggers, and bonus programs.

### 2.7 Deposit Record Update

**What**: Stamps the deposit as Approved and records all finalization data.

**Columns/Parameters Involved**: `Billing.Deposit.PaymentStatusID`, `ExchangeRate`, `IsFTD`, `ProtocolMIDSettingsID`, all relevant columns

**Rules**:
- `SET PaymentStatusID=2 (Approved)` - the definitive approval stamp.
- Preserves existing values if override params are NULL: `Amount = ISNULL(@NewAmount, Amount)`, `CurrencyID = ISNULL(@NewCurrencyID, CurrencyID)`, `DepotID = ISNULL(@NewDepotID, DepotID)`, `ExTransactionID = ISNULL(@ExTransactionID, ExTransactionID)`.
- `ProtocolMIDSettingsID = IIF(ISNULL(@ProtocolMIDSettingsID,0) > 0, @ProtocolMIDSettingsID, ProtocolMIDSettingsID)` - only overrides if provided non-zero value.
- ManagerID: `IIF(@ManagerID > 0, @ManagerID, ManagerID)` - same override pattern.

### 2.8 MIMO Aggregation Update

**What**: Updates BackOffice reporting tables with FirstDepositSuccessDate for CRM and compliance.

**Columns/Parameters Involved**: `BackOffice.UpsertMIMOAggregation`, `@CID`, `@DepositID`

**Rules**:
- `EXEC BackOffice.UpsertMIMOAggregation @CreditTypeID=1, @CID=@CID, @Payment=0, @DepositID=@DepositID`.
- `@Payment=0` because the account balance was already updated by Billing.AmountAdd before this call.
- Only called when Billing.AmountAdd succeeds (inside the ELSE branch).
- Sets `FirstDepositSuccessDate` in the MIMO aggregation table if this is the customer's first deposit.

### 2.9 Audit Trail

**What**: Creates a completed-purchase action record in History.DepositAction.

**Columns/Parameters Involved**: `History.DepositAction.PaymentActionStatusID`, `PaymentActionTypeID`, `PaymentStatusID`, `MatchStatusID`

**Rules**:
- Inherits `MatchStatusID` from the latest existing DepositAction for this deposit (using ROW_NUMBER() OVER ORDER BY DepositActionID DESC).
- `PaymentActionStatusID=3 (Closed)`, `PaymentActionTypeID=2 (Purchase)`, `PaymentStatusID=2 (Approved)`.
- ManagerID taken from `@AmountAddVars` (which may have been overridden by @ManagerID > 0 logic).
- `Amount = @NewAmount`, `CurrencyID = @NewCurrencyID` (the override values, even if NULL for online).

### 2.10 Output Parameter Assignment

**What**: Returns key finalization results to the caller via OUTPUT parameters.

**Columns/Parameters Involved**: `@IsFTD OUTPUT`, `@ModificationDate OUTPUT`

**Rules**:
- `SET @IsFTD = @isFirstTimeDeposit` - lets the calling service know if this was an FTD (triggers downstream CRM/bonus flows).
- `SET @ModificationDate = @Now` - returns the exact approval timestamp for the caller's use.
- Both are optional OUTPUT parameters (default NULL) - callers that don't need them can omit them.

```
Pre-transaction (no lock held):
  XLOCK Billing.Deposit -> load FundingTypeID, PaymentStatusID, IsSingleFunding, ApplyFtd
  -> Offline param validation (if IsSingleFunding=1 or FundingTypeID=17)
  -> XML schema fetch (Dictionary.GetXMLSchema) -> CLR.ParseXML validation
  -> State machine check (Dictionary.PaymentStatusStateMachine -> AfterStatus=2)
  -> Duplicate guard (History.ActiveCreditRecentMemoryBucket OR History.ActiveCredit)

BEGIN TRANSACTION:
  -> Compute amount = ROUND(Amount * ExchangeRate * 100, 0) [USD cents]
  -> EXEC Billing.AmountAdd (CreditTypeID=1/Deposit, CurrencyID=1/USD)
  -> If AmountAdd succeeds:
     -> FTD calculation (count prior IsFTD=1 for same CID)
     -> UPDATE Billing.Deposit SET PaymentStatusID=2 + all finalization fields
     -> EXEC BackOffice.UpsertMIMOAggregation (FirstDepositSuccessDate)
  -> Inherit MatchStatusID from latest DepositAction
  -> INSERT History.DepositAction (ActionStatus=3/Closed, ActionType=2/Purchase, Status=2/Approved)
  -> SET @IsFTD, @ModificationDate OUTPUT
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | PK of the deposit to approve. FK to Billing.Deposit.DepositID. The XLOCK is acquired on this specific row to prevent concurrent processing. All downstream operations reference this ID. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | ID of the manager or system user authorizing approval. Written to Billing.Deposit.ManagerID and History.DepositAction.ManagerID. If @ManagerID > 0, overrides the deposit's existing ManagerID; if 0, preserves existing. Manual runs use 0 per Confluence How-To. |
| 3 | @ExchangeRate | dtPrice | NO | - | CODE-BACKED | FX rate at time of approval. Used to compute USD amount (Amount * ExchangeRate * 100). Written to Billing.Deposit.ExchangeRate and History.DepositAction.ExchangeRate. Custom type dtPrice (DECIMAL precision). |
| 4 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable description of the approval action. Passed to Billing.AmountAdd as the credit description. Manual runs include Jira ticket ID and team name (per Confluence How-To: 'PINT-<ID>: Processed By Payments Integration Team.'). |
| 5 | @PaymentData | XML | NO | - | CODE-BACKED | Full gateway response payload in XML format. Validated against the funding-type-specific schema from Dictionary.GetXMLSchema (schema name = 'Deposit' + FundingType.Name). Stored in Billing.Deposit.PaymentData on approval. |
| 6 | @ProcessorValueDate | DATETIME | YES | NULL | CODE-BACKED | Settlement value date from the payment processor. REQUIRED for offline deposits (IsSingleFunding=1 or FundingTypeID=17/Local Bank Wire). NULL for online card/wallet deposits. Written to Billing.Deposit.ProcessorValueDate. |
| 7 | @NewAmount | MONEY | YES | NULL | CODE-BACKED | Override amount for offline deposits. REQUIRED for IsSingleFunding=1 or FundingTypeID=17. For online deposits, reset to NULL (amount taken from Billing.Deposit.Amount). Written to Billing.Deposit.Amount and History.DepositAction.Amount. |
| 8 | @NewCurrencyID | INTEGER | YES | NULL | CODE-BACKED | Override currency for offline deposits. REQUIRED together with @NewAmount for offline flows. For online, reset to NULL. Written to Billing.Deposit.CurrencyID and History.DepositAction.CurrencyID. FK to Dictionary.Currency. |
| 9 | @ExTransactionID | VARCHAR(50) | YES | NULL | CODE-BACKED | External transaction ID from the payment gateway (authorization code, transaction reference). Preserved via ISNULL - written to Billing.Deposit.ExTransactionID only if provided. Added 03/07/2012. |
| 10 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Web/app session ID of the original deposit session. If NULL, inherits from Billing.Deposit.SessionID. Written to Billing.Deposit.SessionID and History.DepositAction.SessionID. Added 20/10/2015. |
| 11 | @NewDepotID | INTEGER | YES | NULL | CODE-BACKED | Override depot (payment provider account/bucket) ID. For offline deposits, may be provided to assign a specific depot. For online, reset to NULL. Written to Billing.Deposit.DepotID. FK to Billing.Depot. |
| 12 | @ExchangeFee | INT | YES | NULL | CODE-BACKED | FX fee amount. Overrides Billing.Deposit.ExchangeFee if provided. If NULL, preserves existing value via IIF pattern. Written to both Billing.Deposit.ExchangeFee and History.DepositAction.ExchangeFee. Added 19/02/2019. |
| 13 | @BaseExchangeRate | dtPrice | YES | NULL | CODE-BACKED | Base exchange rate before fee markup. Overrides Billing.Deposit.BaseExchangeRate if provided. If NULL, preserves existing. Added 16/09/2019, type changed from MONEY to dtPrice 10/06/2020. |
| 14 | @ProtocolMIDSettingsID | INT | YES | NULL | CODE-BACKED | MID (Merchant ID) settings record FK to Billing.ProtocolMIDSettings. Identifies the specific payment gateway merchant account used. Written to Billing.Deposit.ProtocolMIDSettingsID only if provided (>0). Added MIMOPS-4487 01/07/2021. |
| 15 | @MoveMoneyReasonID | INT | YES | NULL | CODE-BACKED | Reason code for the credit movement. Passed directly to Billing.AmountAdd. Allows tagging the balance change with a specific business reason. FK to a reasons lookup (Dictionary schema). |
| 16 | @IsFTD | BIT | YES | NULL OUTPUT | CODE-BACKED | OUTPUT: Returns 1 if this deposit is the customer's First Time Deposit, 0 otherwise. Computed from count of prior IsFTD=1 deposits for same CID. The calling service uses this to trigger CRM events, bonus awards, and acquisition attribution. |
| 17 | @ModificationDate | DATETIME | YES | NULL OUTPUT | CODE-BACKED | OUTPUT: Returns the exact UTC timestamp (@Now = GETUTCDATE()) when the approval was stamped. Allows the caller to record the precise approval time without a separate query. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID (XLOCK) | Billing.Deposit | READ + MODIFIER (UPDATE) | Acquires exclusive lock; reads amount/currency/CID; updates PaymentStatusID=2 and all finalization fields. |
| FundingID | Billing.Funding | JOIN | Resolves FundingTypeID and IsSingleFunding from the deposit's funding instrument. |
| FundingTypeID | Dictionary.FundingType | JOIN | Resolves IsSingleFunding flag and provides FundingType.Name for XML schema lookup. |
| DepositTypeID | Dictionary.DepositType | LEFT JOIN | Resolves ApplyFtd flag - controls whether this deposit type is eligible for FTD marking. |
| XMLSchema | Dictionary.GetXMLSchema | READ | Fetches XSD schema for XML validation ('Deposit' + FundingType.Name). |
| @PaymentData | CLR.ParseXML | FUNCTION CALL | CLR assembly validates payment XML against schema. Returns 1/0. |
| FundingTypeID + PaymentStatusID | Dictionary.PaymentStatusStateMachine | Validation READ | Checks if current->Approved(2) transition is legal for this FundingType. |
| @DepositID | History.ActiveCreditRecentMemoryBucket | Duplicate guard READ | Recent in-memory bucket check: CreditTypeID=1 + DepositID. |
| @DepositID | History.ActiveCredit | Duplicate guard READ | Persistent duplicate check: CreditTypeID=1 + DepositID. |
| @CID | Billing.AmountAdd | EXEC (caller) | Credits customer's USD account: (CID, CurrencyID=1, CreditTypeID=1/Deposit, Amount, DepositID, ...). |
| @CID | BackOffice.UpsertMIMOAggregation | EXEC (caller) | Updates MIMO aggregation with FirstDepositSuccessDate for CRM. Called after AmountAdd succeeds. |
| @DepositID | History.DepositAction | READ + WRITER (INSERT) | Reads latest MatchStatusID; inserts approval action (ActionStatus=3/Closed, ActionType=2/Purchase, Status=2/Approved). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit processing pipeline (Finalize step) | @DepositID | EXEC | Called in the "finalize-process" step after gateway confirmation. Preceded by FinalSetup; followed by DepositActionAdd and approve-deposit-notification. (Source: Confluence - VERIFIED) |
| Billing.DepositActionAdd | - | EXEC (peer reference) | Mentioned together with DepositProcess in the finalization pipeline - they are called sequentially in the Finalize step. |
| Payments Integration Team (manual ops) | @DepositID | EXEC (manual) | Used for manual deposit recovery - operators set deposit to Pending then call this SP directly with gateway data. (Source: Confluence How-To - VERIFIED) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositProcess (procedure)
+-- Billing.Deposit (table) [XLOCK + UPDATE]
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table)
+-- Dictionary.DepositType (table)
+-- Dictionary.GetXMLSchema (table/view)
+-- CLR.ParseXML (CLR function) [cross-schema]
+-- Dictionary.PaymentStatusStateMachine (table)
+-- History.ActiveCreditRecentMemoryBucket (table) [cross-schema]
+-- History.ActiveCredit (table) [cross-schema]
+-- Billing.AmountAdd (procedure) [EXEC]
+-- BackOffice.UpsertMIMOAggregation (procedure) [cross-schema, EXEC]
+-- History.DepositAction (table) [cross-schema, READ + INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | XLOCK READ (validation) + UPDATE (approval). Core data source and target. |
| Billing.Funding | Table | JOIN to resolve FundingTypeID from FundingID. |
| Dictionary.FundingType | Table (cross-schema) | JOIN for IsSingleFunding flag and FundingType.Name for XML schema key. |
| Dictionary.DepositType | Table (cross-schema) | LEFT JOIN for ApplyFtd flag. |
| Dictionary.GetXMLSchema | Table/View (cross-schema) | READ to fetch XSD schema for PaymentData XML validation. |
| CLR.ParseXML | CLR Function (cross-schema) | Validates @PaymentData XML against fetched schema. |
| Dictionary.PaymentStatusStateMachine | Table (cross-schema) | Validation - checks legal status transition to Approved(2) for this FundingType. |
| History.ActiveCreditRecentMemoryBucket | Table (cross-schema) | READ - duplicate-processing guard (fast path). |
| History.ActiveCredit | Table (cross-schema) | READ - duplicate-processing guard (fallback). |
| Billing.AmountAdd | Stored Procedure | EXEC - credits customer's USD balance. Core money movement. |
| BackOffice.UpsertMIMOAggregation | Stored Procedure (cross-schema) | EXEC - updates FirstDepositSuccessDate in MIMO aggregation. |
| History.DepositAction | Table (cross-schema) | READ (latest MatchStatusID) + INSERT (approval audit record). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit processing pipeline (external service) | External service | EXEC in Finalize step after gateway confirmation. (Source: Confluence) |
| Manual deposit recovery scripts | Operations tooling | EXEC for stuck/failed deposit recovery by Payments Integration Team. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Two-phase TRY/CATCH structure**:
- Phase 1 (pre-transaction): All validations run BEFORE the transaction opens. The XLOCK on Billing.Deposit in the SELECT is held through the transaction but the validation errors cause early RETURN (not ROLLBACK) since no transaction is open yet.
- Phase 2 (transactional): BEGIN TRANSACTION wraps AmountAdd + Deposit UPDATE + UpsertMIMOAggregation + DepositAction INSERT. CATCH: if @@TRANCOUNT=1 -> ROLLBACK; if >1 (nested) -> COMMIT; then THROW.

**XLOCK semantics**: The XLOCK ROWLOCK on `Billing.Deposit` in the initial SELECT acquires an exclusive row lock that is held for the duration of the connection (within the transaction). This prevents two threads from processing the same deposit concurrently - the second thread's SELECT will block until the first commits. Added 07/02/2021 (Shay O.) replacing a commented-out sp_getapplock approach.

**Error codes**:
- `60025` - Input validation failures: missing offline params, illegal state transition, deposit already processed.
- `60030` - XML schema missing or parse failure.
- `60100-60103` - DML failures (legacy @@ERROR checks, partially commented out).
- After CATCH: THROW (re-raises original exception to caller).

**Removed functionality**:
- `DepotToCurrency` ProcessedAmount update - removed 06/03/2024.
- `LocalPerfLog` performance audit - removed DBAD-79 (30/07/2023).
- `sp_getapplock` distributed lock - replaced by XLOCK ROWLOCK approach 07/02/2021.
- `IsSetBalanceCompleted` flag update - commented out, no longer maintained.

**Hardcoded values**:
- `CurrencyID = 1` (USD) in Billing.AmountAdd call - all deposits credited in USD.
- `CreditTypeID = 1` (Deposit) in duplicate guard and AmountAdd.
- `PaymentStatusID = 2` (Approved) - target approval status.
- `PaymentActionStatusID = 3` (Closed), `PaymentActionTypeID = 2` (Purchase) in DepositAction insert.

---

## 8. Sample Queries

### 8.1 Manual deposit finalization (Confluence How-To pattern)

```sql
DECLARE @ManagerID INT = 0;
DECLARE @DepositID INT = 72450057;
DECLARE @ExchangeRate DECIMAL(18,8) = 1.17963000;
DECLARE @Description NVARCHAR(255) = N'PINT-1234: Processed By Payments Integration Team.';
DECLARE @PaymentData XML = N'<PaymentData><TransactionID>ABC123</TransactionID></PaymentData>';
DECLARE @ExTransactionID NVARCHAR(50) = N'ABC123';
DECLARE @IsFTD BIT;
DECLARE @ModDate DATETIME;

-- Ensure deposit can transition: set to Pending first if needed
-- UPDATE Billing.Deposit SET PaymentStatusID = 13 WHERE DepositID = @DepositID;

EXEC [Billing].[DepositProcess]
    @DepositID = @DepositID,
    @ManagerID = @ManagerID,
    @ExchangeRate = @ExchangeRate,
    @Description = @Description,
    @PaymentData = @PaymentData,
    @ExTransactionID = @ExTransactionID,
    @IsFTD = @IsFTD OUTPUT,
    @ModificationDate = @ModDate OUTPUT;

SELECT @IsFTD AS WasFirstTimeDeposit, @ModDate AS ApprovalTimestamp;
```

### 8.2 Check state machine transitions before processing

```sql
-- What statuses allow a deposit to be approved for a given FundingTypeID?
SELECT BeforePaymentStatusID, AfterPaymentStatusID, FundingTypeID
FROM [Dictionary].[PaymentStatusStateMachine] WITH (NOLOCK)
WHERE FundingTypeID = 1  -- CreditCard
  AND AfterPaymentStatusID = 2;  -- Approved
```

### 8.3 Verify approval result for a deposit

```sql
SELECT D.DepositID, D.PaymentStatusID, D.IsFTD, D.ExchangeRate,
       D.ModificationDate, D.Amount, D.CurrencyID, D.ProtocolMIDSettingsID
FROM [Billing].[Deposit] D WITH (NOLOCK)
WHERE D.DepositID = 72450057;

-- Check audit record created
SELECT TOP 1 DepositActionID, PaymentActionStatusID, PaymentActionTypeID,
    PaymentStatusID, ManagerID, ExchangeRate, ModificationDate
FROM [History].[DepositAction] WITH (NOLOCK)
WHERE DepositID = 72450057
ORDER BY DepositActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Deposit Finalize Steps Current](https://etoro-jira.atlassian.net/wiki/spaces/PAY/pages/2212135001) | Confluence | Confirmed this SP is called in the "Finalize" step as "Process Deposit - execute SP [Billing].[DepositProcess]". Full pipeline: FinalSetup -> FinalProcess -> Finalize (calls DepositProcess + DepositActionAdd + Send Approve Topic) -> SendEmail -> UpdateFundingData -> BankClassification. |
| [Deposit Finalize Steps Refactor](https://etoro-jira.atlassian.net/wiki/spaces/PAY/pages/2217115688) | Confluence | Proposed refactor places this SP in "finalize-process" step. Note: "need to handle SP to be idempotent" - confirms the XLOCK + duplicate guard design intent. DepositActionAdd follows immediately. approve-deposit-notification and send-mail are candidates to be async. |
| [How-To: Manual Deposit Finalization](https://etoro-jira.atlassian.net/wiki/spaces/PAY/pages/14062584089) | Confluence | Documents exact manual execution pattern: check PaymentStatusStateMachine for valid transitions; set deposit to Pending; call SP with @ManagerID=0 + real ExchangeRate + PaymentData XML + ExTransactionID. Confirms operators use this SP directly for deposit recovery. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositProcess | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositProcess.sql*
