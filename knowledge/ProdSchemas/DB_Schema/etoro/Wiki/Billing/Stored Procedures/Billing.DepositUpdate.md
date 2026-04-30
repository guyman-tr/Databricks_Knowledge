# Billing.DepositUpdate

> General-purpose deposit status-and-metadata updater - validates XML and state machine transitions, updates the deposit record across many fields, appends a History.DepositAction audit row, and (for approvals) increments the DepotToCurrency processed amount. Returns the new DepositActionID as OUTPUT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit + INSERT History.DepositAction; @DepositActionID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositUpdate` is the general deposit update SP used during payment processing flows to transition a deposit's status and update its metadata. It is broader than `Billing.DepositProcess` (which handles only the Approved path with balance crediting); `DepositUpdate` handles any status transition for which the caller supplies the appropriate `@PaymentActionStatusID` and `@PaymentActionTypeID`.

Like `DepositProcess`, it validates the payment gateway XML response against the funding-type-specific schema (via `CLR.ParseXML`) and validates the state machine transition (via `Dictionary.PaymentStatusStateMachine`). However, it does NOT call `Billing.AmountAdd` - balance crediting is not part of its responsibilities. It updates a wider set of deposit columns (including `MerchantAccountID`, `RoutingReasonID`, `ExchangeFeeInUSD`, `ProcessRegulationID`) compared to `DepositProcess`.

When the new status is Approved (2), it additionally updates `Billing.DepotToCurrency.ProcessedAmount` to track the accumulated transaction volume on the payment provider account.

The procedure is signed with certificate `CERT_ParseXML` (required for CLR assembly access) - the source code comment warns that any modification requires re-signing.

Version history reflects continuous additions: ProtocolMIDSettingsID (Oct 2018), ExchangeFee (Feb 2019), BaseExchangeRate (Sep 2019), DepotID (May 2020), MerchantAccountID (Dec 2020), RoutingReasonID (Oct 2021 PAYIL-3194), state machine validation (Jan 2023 PAYIL-5632), ProcessRegulationID (May 2024).

---

## 2. Business Logic

### 2.1 Initial Data Load and XML Schema Fetch

**What**: Loads current deposit state and the XML validation schema in a single JOIN query.

**Columns/Parameters Involved**: `@DepositID`, `@SessionID`, `@ExchangeRate`, `@DepotID`, `@DepositTypeID`

**Rules**:
- Joins: Dictionary.GetXMLSchema + Dictionary.FundingType + Billing.Funding + Billing.Deposit.
- Schema name = `'Deposit' + FundingType.Name` (same pattern as DepositProcess).
- `@SessionID`: inherits from Billing.Deposit.SessionID if NULL.
- `@ExchangeRate`, `@ExchangeFee`, `@BaseExchangeRate`: always loaded FROM deposit (NOT updated back - MaksymSh 08/11/2020 change). These are used only in the DepositAction audit INSERT.
- `@DepotID`: if parameter is NULL, inherits from deposit's current DepotID.
- `@CurrentPaymentStatusID`, `@FundingTypeID`: loaded for state machine validation.

### 2.2 ApplyFTD Flag Resolution

**What**: Determines whether FTD marking applies for this deposit type.

**Rules**:
- If `@DepositTypeID IS NOT NULL`: fetch `ApplyFtd` from `Dictionary.DepositType`.
- If no DepositType (NULL), `@ApplyFTD` defaults to 1 (FTD eligible).

### 2.3 Payment State Machine Validation

**What**: Validates the requested status transition is legal for this funding type.

**Columns/Parameters Involved**: `@PaymentStatusID`, `@CurrentPaymentStatusID`, `@FundingTypeID`

**Rules**:
- Only triggered if `@PaymentStatusID <> @CurrentPaymentStatusID` (status is actually changing).
- Check: `EXISTS (SELECT 1 FROM Dictionary.PaymentStatusStateMachine WHERE FundingTypeID=@FundingTypeID AND BeforePaymentStatusID=@CurrentPaymentStatusID AND AfterPaymentStatusID=@PaymentStatusID)`.
- If transition not allowed: `THROW 60025` with FORMATMESSAGE(60200, @FundingTypeID, @CurrentPaymentStatusID, @PaymentStatusID).
- Added PAYIL-5632 (10/01/2023, Elrom B.).

### 2.4 XML Validation

**What**: Validates the gateway response XML against the funding-type schema.

**Rules**:
- `CLR.ParseXML(@xmlSchema, @xmlValue)` - returns 1=valid, 0=invalid.
- If invalid -> RAISERROR(60030) + RETURN 60030.
- Note: certificate requirement - SP must be signed with CERT_ParseXML after any DDL change.

### 2.5 Deposit Record Update

**What**: Updates the deposit with all provided metadata and the new status.

**Columns/Parameters Involved**: Many columns of Billing.Deposit

**Rules**:
- `IsFTD = CASE WHEN @IsFTDCount = 0 AND @PaymentStatusID = 2 THEN @ApplyFTD ELSE 0 END` - only set FTD if no prior FTDs AND this is an approval.
- `ModificationDate` update is conditional: `CASE WHEN PaymentStatusID = @PaymentStatusID THEN ModificationDate ELSE @ModificationDate END` - if status is not changing, ModificationDate is NOT touched.
- `ProcessRegulationID = ISNULL(@ProcessRegulationID, ProcessRegulationID)` - preserves existing if not provided.
- `RoutingReasonID = ISNULL(@RoutingReasonID, RoutingReasonID)` - same pattern.
- `ExchangeFeeInUSD = ISNULL(@ExchangeFeeInUSD, ExchangeFeeInUSD)` - same pattern.
- ExchangeRate, ExchangeFee, BaseExchangeRate: NOT updated in Billing.Deposit (by design since MaksymSh 08/11/2020).
- `@@ROWCOUNT = 0` after UPDATE -> RAISERROR(60000).

### 2.6 Audit Action Insert

**What**: Inserts a DepositAction record using caller-provided action type/status.

**Columns/Parameters Involved**: `@PaymentActionStatusID`, `@PaymentActionTypeID`, `@DepositActionID OUTPUT`

**Rules**:
- Unlike DepositProcess (hardcoded ActionStatus=3, ActionType=2), this SP takes these as parameters - supporting any action type (Declined, Pending, etc.).
- `SET @DepositActionID = SCOPE_IDENTITY()` - returns the new action row ID to the caller.
- Inherits MatchStatusID from the latest existing DepositAction (same ROW_NUMBER pattern as DepositProcess).
- ExchangeRate/ExchangeFee/BaseExchangeRate written to DepositAction from loaded values (not from @ExchangeRate param which was ignored in the deposit update).

### 2.7 DepotToCurrency Accumulation (Approval Only)

**What**: Increments the processed amount on the payment provider account when a deposit is approved.

**Columns/Parameters Involved**: `@PaymentStatusID = 2`, `Billing.DepotToCurrency`, `@DepotID`, `@CurrencyID`

**Rules**:
- Only executes if `@PaymentStatusID = 2 (Approved)`.
- `UPDATE Billing.DepotToCurrency SET LastTransactionDate=@ModificationDate, ProcessedAmount=ProcessedAmount+@Amount WHERE DepotID=@DepotID AND CurrencyID=@CurrencyID`.
- If @@ROWCOUNT = 0 -> RAISERROR(60001) - no matching DepotToCurrency row found.

```
Load schema + deposit state -> XML validate
State machine check (if status changing)
BEGIN TRANSACTION:
  -> Compute IsFTD (count prior FTDs for CID)
  -> UPDATE Billing.Deposit (many fields)
  -> Get MatchStatusID from latest DepositAction
  -> INSERT History.DepositAction (caller-specified ActionStatus/ActionType)
  -> SET @DepositActionID = SCOPE_IDENTITY()
  -> If PaymentStatusID=2: UPDATE DepotToCurrency.ProcessedAmount
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositActionID | INTEGER | YES | - | CODE-BACKED | OUTPUT: Returns the new History.DepositAction.DepositActionID after INSERT via SCOPE_IDENTITY(). Caller uses this to link subsequent operations to the specific action created. |
| 2 | @DepositID | INTEGER | NO | - | CODE-BACKED | PK of the deposit to update. FK to Billing.Deposit.DepositID. Used to load current state, XML schema, and as UPDATE/INSERT target. |
| 3 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | New payment status for the deposit. Written to Billing.Deposit.PaymentStatusID. Validated against Dictionary.PaymentStatusStateMachine if status is changing. Status=2 (Approved) triggers additional DepotToCurrency update. |
| 4 | @PaymentActionStatusID | INTEGER | NO | - | CODE-BACKED | Action completion state for History.DepositAction. Unlike DepositProcess (hardcoded 3/Closed), this is caller-supplied - supports Pending, Closed, or other action states. FK to Dictionary.PaymentActionStatus. |
| 5 | @PaymentActionTypeID | INTEGER | NO | - | CODE-BACKED | Action type for History.DepositAction. Caller-supplied - supports any action type (Purchase, Cancel, Declined, etc.). FK to Dictionary.PaymentActionType. |
| 6 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Manager/system user authorizing the update. Written to History.DepositAction.ManagerID. |
| 7 | @ProtocolID | INTEGER | NO | - | CODE-BACKED | Protocol identifier (payment gateway protocol). Included in the procedure signature but not visibly used in the UPDATE or INSERT logic in the current code (possibly used in removed/commented code). |
| 8 | @ExTransactionID | VARCHAR(50) | YES | NULL | CODE-BACKED | External gateway transaction ID. Written to Billing.Deposit.ExTransactionID. |
| 9 | @PaymentData | XML | NO | - | CODE-BACKED | Gateway response XML. Validated against the funding-type-specific schema via CLR.ParseXML. Written to Billing.Deposit.PaymentData. |
| 10 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session ID. Inherits from deposit if NULL. Written to Billing.Deposit.SessionID and History.DepositAction.SessionID. |
| 11 | @ProtocolMIDSettingsID | INT | NO | 0 | CODE-BACKED | MID settings record. Written to Billing.Deposit.ProtocolMIDSettingsID. Default 0 means no MID override. FK to Billing.ProtocolMIDSettings. Added 24/10/2018. |
| 12 | @MerchantAccountID | INT | YES | NULL | CODE-BACKED | Merchant account ID. Written to Billing.Deposit.MerchantAccountID and History.DepositAction.MerchantAccountID. FK to Dictionary.MerchantAccount. Added PAYUS-20163. |
| 13 | @ExchangeRate | dtPrice | YES | NULL | CODE-BACKED | Loaded from Billing.Deposit at start (parameter value ignored). Written to History.DepositAction.ExchangeRate. NOT written back to Billing.Deposit (MaksymSh 08/11/2020). |
| 14 | @ExchangeFee | INT | YES | NULL | CODE-BACKED | Loaded from Billing.Deposit at start. Written to History.DepositAction.ExchangeFee. NOT updated in Billing.Deposit. |
| 15 | @BaseExchangeRate | dtPrice | YES | NULL | CODE-BACKED | Loaded from Billing.Deposit at start. Written to History.DepositAction.BaseExchangeRate. NOT updated in Billing.Deposit. |
| 16 | @DepotID | INT | YES | NULL | CODE-BACKED | Depot ID. If NULL, inherits from deposit. Written to Billing.Deposit.DepotID, History.DepositAction.DepotID, and used in DepotToCurrency update when @PaymentStatusID=2. Added 19/05/2020. |
| 17 | @RoutingReasonID | INT | YES | NULL | CODE-BACKED | Routing reason code. ISNULL pattern - written to Billing.Deposit.RoutingReasonID only if provided. FK to routing reason lookup. Added PAYIL-3194. |
| 18 | @ProcessRegulationID | INT | YES | NULL | CODE-BACKED | Regulatory jurisdiction ID. ISNULL pattern - updates Billing.Deposit.ProcessRegulationID only if provided. FK to Dictionary.Regulation. Added 02/05/2024. |
| 19 | @ExchangeFeeInUSD | MONEY | YES | NULL | CODE-BACKED | FX fee amount in USD. ISNULL pattern - updates Billing.Deposit.ExchangeFeeInUSD only if provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | READ + MODIFIER (UPDATE) | Loads state + XML schema; updates status and many metadata fields. |
| FundingID | Billing.Funding | JOIN | Resolves FundingTypeID. |
| FundingTypeID | Dictionary.FundingType | JOIN | Resolves FundingType.Name for schema key. |
| XMLSchema | Dictionary.GetXMLSchema | READ | Fetches XSD for XML validation. |
| @PaymentData | CLR.ParseXML | FUNCTION CALL | Validates XML against schema. Requires CERT_ParseXML certificate signing. |
| FundingTypeID + StatusIDs | Dictionary.PaymentStatusStateMachine | Validation READ | Checks legal state transition. Added PAYIL-5632. |
| DepositTypeID | Dictionary.DepositType | READ | Resolves ApplyFtd flag. |
| @DepositID | History.DepositAction | READ + WRITER (INSERT) | Gets latest MatchStatusID; inserts new action with caller-specified types. |
| @DepotID + @CurrencyID | Billing.DepotToCurrency | MODIFIER (UPDATE) | Increments ProcessedAmount when @PaymentStatusID=2 (Approved). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment processing pipeline (various status transitions) | @DepositID | EXEC | Called for status transitions: Pending, Declined, and other non-approval states. Also used for Approved when called with appropriate action types. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositUpdate (procedure)
+-- Billing.Deposit (table) [READ + UPDATE]
+-- Billing.Funding (table)
+-- Billing.DepotToCurrency (table) [conditional UPDATE]
+-- Dictionary.GetXMLSchema (table/view)
+-- Dictionary.FundingType (table)
+-- Dictionary.DepositType (table)
+-- Dictionary.PaymentStatusStateMachine (table)
+-- CLR.ParseXML (CLR function) [cross-schema]
+-- History.DepositAction (table) [cross-schema, READ + INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ (load state + schema) + UPDATE (status and metadata). |
| Billing.Funding | Table | JOIN - FundingTypeID resolution. |
| Billing.DepotToCurrency | Table | UPDATE ProcessedAmount when @PaymentStatusID=2. |
| Dictionary.GetXMLSchema | Table/View (cross-schema) | READ - XSD schema for XML validation. |
| Dictionary.FundingType | Table (cross-schema) | JOIN - schema name prefix. |
| Dictionary.DepositType | Table (cross-schema) | READ - ApplyFtd flag. |
| Dictionary.PaymentStatusStateMachine | Table (cross-schema) | Validation - legal state transition check. |
| CLR.ParseXML | CLR Function (cross-schema) | Validates @PaymentData XML. |
| History.DepositAction | Table (cross-schema) | READ (MatchStatusID) + INSERT (audit). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment processing services | External | EXEC for deposit status transitions. |

---

## 7. Technical Details

**Certificate requirement**: SP must be signed with `CERT_ParseXML` after any DDL modification (required for CLR.ParseXML access). The comment is in the SP header as a prominent warning.

**ExchangeRate/ExchangeFee/BaseExchangeRate**: Loaded from `Billing.Deposit` but NOT updated back into the deposit row (MaksymSh change 08/11/2020). They are forwarded to `History.DepositAction` only for audit purposes.

**vs DepositProcess**: DepositProcess calls Billing.AmountAdd (credits balance), uses XLOCK (concurrency guard), has duplicate-processing guard, hardcodes ActionStatus=3/ActionType=2. DepositUpdate does none of those but is more general-purpose for non-approval status updates.

**Error codes**: 60025 (state machine violation via THROW), 60030 (XML validation failure), 60000 (deposit not found after UPDATE), 60001 (DepotToCurrency not updated on approval).

---

## 8. Sample Queries

### 8.1 Update deposit to Declined status

```sql
DECLARE @ActionID INT;
EXEC [Billing].[DepositUpdate]
    @DepositActionID = @ActionID OUTPUT,
    @DepositID = 12345678,
    @PaymentStatusID = 3,            -- Declined
    @PaymentActionStatusID = 3,      -- Closed
    @PaymentActionTypeID = 3,        -- Declined
    @ManagerID = 0,
    @ProtocolID = 1,
    @PaymentData = N'<Deposit><Status>Declined</Status></Deposit>';
SELECT @ActionID AS NewDepositActionID;
```

### 8.2 Check state machine transitions for a specific funding type

```sql
SELECT BeforePaymentStatusID, AfterPaymentStatusID
FROM [Dictionary].[PaymentStatusStateMachine] WITH (NOLOCK)
WHERE FundingTypeID = 1  -- CreditCard
ORDER BY BeforePaymentStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositUpdate.sql*
