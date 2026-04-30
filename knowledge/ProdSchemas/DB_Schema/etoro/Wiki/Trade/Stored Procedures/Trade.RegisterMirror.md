# Trade.RegisterMirror

> Creates a new copy-trade relationship (mirror) between a copier (@CID) and a leader (@ParentCID), allocating funds from the copier's balance, recording the mirror in Trade.Mirror, queuing an audit row via Trade.PostDetachOperation, debiting the copier's account via Customer.SetBalance, and signaling first-time copier events to the broker CRM.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID OUTPUT (SCOPE_IDENTITY after Trade.Mirror INSERT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RegisterMirror is the primary entry point for starting a copy-trade relationship on eToro. When a user decides to "copy" a popular investor (the leader), the app calls this procedure. It validates the copier has sufficient balance, that the relationship does not already exist, that no circular copy chain would result, and that the MSL (Mirror Stop Loss) percentage is internally consistent with the absolute amount.

On success it performs four writes atomically:
1. INSERT into Trade.Mirror - creates the live mirror record
2. INSERT into Trade.PostDetachOperation - queues the History.Mirror audit row for async processing (the direct History.Mirror INSERT is commented out)
3. Customer.SetBalance (CreditTypeID=20) - debits the copier's account
4. If this is the copier's very first mirror ever: Broker.QueueCopyTraderAdd - sends a "new copier" event to the broker CRM with the customer's acquisition tracking data

@IsReopenMirror=1 skips the MSL consistency check (used by Trade.MirrorReopen when restoring a closed mirror with previously validated parameters). @ValidateUserBalance=0 allows programmatic mirror creation without a real balance constraint (used for demo or admin flows).

---

## 2. Business Logic

### 2.1 Null Guard

**What**: Rejects calls where any required identifier is missing.

**Columns/Parameters Involved**: `@CID`, `@ParentCID`, `@AmountInCents`

**Rules**:
- IF @CID IS NULL OR @ParentCID IS NULL OR @AmountInCents IS NULL: RAISERROR(60056) - "One of the parameters had null value"

### 2.2 Customer Existence and Balance Check

**What**: Verifies the copier exists and has sufficient funds.

**Columns/Parameters Involved**: `Customer.Customer.Credit`, `@AmountInCents`, `@ValidateUserBalance`

**Rules**:
- SELECT Credit FROM Customer.Customer WHERE CID=@CID; @@ROWCOUNT<>1 -> RAISERROR(60058) - "The customer doesn't exist"
- @AmountInDollars = @AmountInCents / 100
- IF @AmountInDollars > @Credit AND @ValidateUserBalance=1 -> RAISERROR(60054) - "User doesn't have the requested money in his balance"
- @ValidateUserBalance=0 bypasses the balance check entirely

### 2.3 Duplicate Mirror Check

**What**: Prevents a copier from copying the same leader twice.

**Columns/Parameters Involved**: `Trade.Mirror.CID`, `Trade.Mirror.ParentCID`

**Rules**:
- IF EXISTS (Trade.Mirror WHERE CID=@CID AND ParentCID=@ParentCID) -> RAISERROR(60061) - "The requested mirror already exists"

### 2.4 Copy Loop Detection (Real DB Only)

**What**: Prevents circular copy chains (A copies B who copies A).

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID=22`, `Trade.IsCreateLoop`

**Rules**:
- SELECT Value FROM Maintenance.Feature WHERE FeatureID=22 (1=Real DB, 0=Demo)
- IF Value=1: EXEC Trade.IsCreateLoop @CID, @ParentCID; if @Answer<>0 -> RAISERROR(60059)
- Demo databases skip this check (no copy loops possible in demo)

### 2.5 MSL Consistency Check (New Mirrors Only)

**What**: Validates the absolute MSL and percentage MSL are consistent with each other and the investment amount.

**Columns/Parameters Involved**: `@MirrorSL`, `@MirrorSLPercentage`, `@AmountInCents`, `@IsReopenMirror`

**Rules**:
- Skipped when @IsReopenMirror=1
- Check: round((@MirrorSL*100)/@AmountInCents, 2) <> round(@MirrorSLPercentage/100, 2) -> custom RAISERROR
- Ensures the caller-supplied absolute SL and percentage SL agree given the investment amount
- Default @MirrorSLPercentage=2 means 2% of investment triggers mirror liquidation

### 2.6 First-Mirror Flag

**What**: Detects whether this is the copier's first-ever copy relationship.

**Columns/Parameters Involved**: `Trade.Mirror.CID`, `History.Mirror.CID`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Trade.Mirror WHERE CID=@CID UNION SELECT 1 FROM History.Mirror WHERE CID=@CID): @Flag=1
- @Flag=1 drives the Broker.QueueCopyTraderAdd call after commit

### 2.7 Mirror Creation and Audit Queue

**What**: Creates the live mirror row and queues the History.Mirror audit record for async processing.

**Columns/Parameters Involved**: `Trade.Mirror`, `Trade.PostDetachOperation`, `Trade.Tv_RegisterMirror`

**Rules**:
- @Occurred = GETUTCDATE()
- NULL defaults applied: @InitialInvestment defaults to @AmountInDollars, @DepositSummary/@WithdrawalSummary/@NetProfit default to 0
- INSERT INTO Trade.Mirror (CID, ParentCID, ParentUserName, Amount, Occurred, IsActive=1, MirrorTypeID, IsOpenOpen, GuruTPV, MirrorSL, RealizedEquity=@AmountInDollars, MirrorSLPercentage, InitialInvestment, DepositSummary, WithdrawalSummary, NetProfit, MirrorCalculationType)
- OUTPUT clause captures the new row + supplemental columns (ReferenceID, ExternalOperationType, MirrorOperationID=1, SessionID, PauseCopy=0, ClientRequestGuid) into @TradeTv_RegisterMirror (Trade.Tv_RegisterMirror TVP)
- @MirrorID = SCOPE_IDENTITY()
- INSERT INTO Trade.PostDetachOperation from @TradeTv_RegisterMirror (all H_M_* columns) - this is the async History.Mirror write; the direct INSERT INTO History.Mirror is commented out

### 2.8 Balance Debit

**What**: Moves the copy investment amount from the copier's free balance to the mirror.

**Columns/Parameters Involved**: `Customer.SetBalance`, `@AmountInCents`, `CreditTypeID=20`

**Rules**:
- @AmountInCents negated before call (0 - @AmountInCents) - convention per SetBalance signature (negative = debit)
- Description = 'Register new ' + Dictionary.MirrorType.Description (e.g. "Register new Copy")
- EXEC Customer.SetBalance @CID=@CID, @Payment=-@AmountInCents, @CreditTypeID=20 (Register Mirror), @MirrorID=@MirrorID, @ParentCID=@ParentCID, @ParentUserName=@ParentUserName
- IF @Answer<>0: RAISERROR(@Answer)

### 2.9 First-Copier CRM Event

**What**: Sends acquisition tracking data to the broker CRM when this is the copier's first-ever mirror.

**Columns/Parameters Involved**: `Broker.QueueCopyTraderAdd`, `Customer.Customer` (OriginalCID, ProviderID, IsReal, IP, SerialID, etc.)

**Rules**:
- Only executed when @Flag=1
- Pulls registration/attribution data from Customer.Customer: OriginalCID, ProviderID, OriginalProviderID, RealProviderID, IsReal, IP, SerialID, SubSerialID, DownloadID, BannerID, FunnelID, PlayerLevelID, LabelID
- @RegCountryID = Internal.GetCountryIDByIP(@IP)
- EXEC Broker.QueueCopyTraderAdd with all attribution columns
- IF @Answer<>0: RAISERROR(@Answer)

### 2.10 Transaction and Error Handling

**What**: Wraps all writes in a single transaction with conditional rollback.

**Rules**:
- SET XACT_ABORT ON - any error auto-aborts the transaction
- CATCH: IF @@TRANCOUNT=1 -> ROLLBACK; IF @@TRANCOUNT>1 -> COMMIT (nested transaction scenario)
- IF @ErrorID<>60070: THROW (re-raise original); ELSE RAISERROR(@ErrorID, 16, 1, @MaxMirrorActionAmountPercentage_INT) - error 60070 requires the formatted int parameter
- RETURN 0 on success, 1 on error

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Copier's customer ID. Used for balance check, mirror existence check, and all write operations. |
| 2 | @ParentCID | INT | NO | - | CODE-BACKED | Leader's customer ID (the popular investor being copied). Written to Trade.Mirror.ParentCID. |
| 3 | @AmountInCents | MONEY | NO | - | CODE-BACKED | Copy investment amount in cents (e.g. 20000 = $200). Converted to dollars (@AmountInDollars) for Trade.Mirror.Amount. Negated for Customer.SetBalance. |
| 4 | @MirrorID | INT | NO (OUTPUT) | - | CODE-BACKED | OUTPUT: the assigned MirrorID from SCOPE_IDENTITY() after Trade.Mirror INSERT. Returned to caller for use in position copying and subsequent operations. |
| 5 | @MirrorTypeID | INT | YES | 1 | CODE-BACKED | Mirror type from Dictionary.MirrorType (e.g. 1=Copy). Controls the SetBalance description string. Written to Trade.Mirror.MirrorTypeID. |
| 6 | @IsOpenOpen | BIT | YES | 0 | CODE-BACKED | If 1, the copier wants to open copies of the leader's currently open positions at registration time. Written to Trade.Mirror.IsOpenOpen. |
| 7 | @GuruTPV | MONEY | YES | NULL | CODE-BACKED | Leader's total portfolio value at the time of mirror creation. Written to Trade.Mirror.GuruTPV. |
| 8 | @MirrorSL | MONEY | YES | 0 | CODE-BACKED | Mirror Stop Loss absolute amount in dollars (e.g. 40 = stop at $40 loss). Must be consistent with @MirrorSLPercentage given @AmountInCents. Written to Trade.Mirror.MirrorSL. |
| 9 | @MirrorSLPercentage | MONEY | YES | 2 | CODE-BACKED | Mirror Stop Loss as a percentage (e.g. 2 = 2% of investment). Default 2% is the platform minimum. Written to Trade.Mirror.MirrorSLPercentage. |
| 10 | @ParentUserName | VARCHAR(50) | NO | - | CODE-BACKED | Leader's username (denormalized at registration time). Written to Trade.Mirror.ParentUserName and passed to Customer.SetBalance and Broker.QueueCopyTraderAdd. |
| 11 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session ID from calling context. Written to Trade.PostDetachOperation.H_M_SessionID for History.Mirror audit. |
| 12 | @Occurred | DATETIME | YES (OUTPUT) | NULL | CODE-BACKED | OUTPUT: set to GETUTCDATE() inside the procedure. Returned to caller as the canonical mirror creation timestamp. Written to Trade.Mirror.Occurred. |
| 13 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client GUID for deduplication. Added FB-51445. Written to Trade.PostDetachOperation.H_M_ClientRequestGuid. |
| 14 | @ValidateUserBalance | BIT | YES | 1 | CODE-BACKED | If 0, skips the balance >= investment check. Used in demo flows or admin-initiated mirrors. |
| 15 | @IsReopenMirror | BIT | YES | 0 | CODE-BACKED | If 1, skips the MSL consistency check (round check). Used by Trade.MirrorReopen when restoring a previously closed mirror. |
| 16 | @InitialInvestment | MONEY | YES | NULL | CODE-BACKED | Explicit initial investment; defaults to @AmountInDollars if NULL. Written to Trade.Mirror.InitialInvestment. |
| 17 | @DepositSummary | MONEY | YES | NULL | CODE-BACKED | Accumulated deposits into the mirror; defaults to 0 if NULL. Written to Trade.Mirror.DepositSummary. |
| 18 | @WithdrawalSummary | MONEY | YES | NULL | CODE-BACKED | Accumulated withdrawals from the mirror; defaults to 0 if NULL. Written to Trade.Mirror.WithdrawalSummary. |
| 19 | @NetProfit | MONEY | YES | NULL | CODE-BACKED | Net profit at time of creation; defaults to 0 if NULL. Written to Trade.Mirror.NetProfit. |
| 20 | @MirrorCalculationType | INT | YES | 0 | CODE-BACKED | How copy trade sizing is calculated. Written to Trade.Mirror.MirrorCalculationType. |
| 21 | @ReferenceID | VARCHAR(36) | YES | NULL | CODE-BACKED | External reference ID (e.g. external platform reference). Written to Trade.PostDetachOperation.H_M_ReferenceID for History.Mirror. |
| 22 | @ExternalOperationType | INT | YES | NULL | CODE-BACKED | External operation type code. Written to Trade.PostDetachOperation.H_M_ExternalOperationType for History.Mirror. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read | Balance lookup (Credit column) and acquisition tracking data (OriginalCID, ProviderID, IP, etc.) |
| FeatureID=22 | Maintenance.Feature | Read | Determines if running in Real (1) or Demo (0) database for loop check |
| @CID, @ParentCID | Trade.IsCreateLoop | EXEC | Loop detection in Real environment |
| @CID, @ParentCID | Trade.Mirror | Read | Duplicate mirror check (current active mirrors) |
| @CID | History.Mirror | Read | Part of first-mirror UNION check (includes historical/closed mirrors) |
| All mirror columns | Trade.Mirror | Write | Primary INSERT creating the live mirror record |
| @TradeTv_RegisterMirror | Trade.PostDetachOperation | Write | Async audit row (replaces commented-out History.Mirror INSERT) |
| @CID | Customer.SetBalance | EXEC | Debits copier's balance (CreditTypeID=20 Register Mirror) |
| @MirrorTypeID | Dictionary.MirrorType | Read | Fetches Description for SetBalance call |
| @IP | Internal.GetCountryIDByIP | Function | Resolves copier's registration country for CRM event |
| Multiple attribution columns | Broker.QueueCopyTraderAdd | EXEC | First-mirror CRM event (only when @Flag=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MirrorReopen | - | EXEC | Calls with @IsReopenMirror=1 to restore a closed mirror |
| Trade.TDAPI_GetLeaderStats | - | EXEC | Calls in test/demo data generation context |
| Trade.UnRegisterMirrorForMoe | - | EXEC | Calls RegisterMirror as part of mirror reassignment workflow |
| Trade.UpdateEtorianUsersCopiedBlockRestriction | - | EXEC | Administrative bulk mirror registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RegisterMirror (procedure)
|- Customer.Customer (table) - balance + attribution read
|- Maintenance.Feature (table) - Real/Demo flag
|- Trade.IsCreateLoop (procedure) - circular copy check
|- Trade.Mirror (table) - duplicate check + INSERT
|- History.Mirror (table) - first-mirror UNION check (read only)
|- Trade.PostDetachOperation (table) - async audit write
|- Customer.SetBalance (procedure) - balance debit
|- Dictionary.MirrorType (table) - description lookup
|- Internal.GetCountryIDByIP (function) - IP geolookup
|- Broker.QueueCopyTraderAdd (procedure) - CRM event
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Balance check (Credit) and acquisition attribution data for CRM |
| Maintenance.Feature | Table | FeatureID=22 determines Real vs Demo (Real->run loop check) |
| Trade.IsCreateLoop | Procedure | Detects A copies B copies A chains in Real DB |
| Trade.Mirror | Table | Duplicate check read; primary INSERT for new mirror |
| History.Mirror | Table | UNION with Trade.Mirror for first-mirror detection (read only) |
| Trade.PostDetachOperation | Table | Async History.Mirror audit record (INSERT from TVP) |
| Customer.SetBalance | Procedure | Debits @AmountInCents from copier's balance (CreditTypeID=20) |
| Dictionary.MirrorType | Table | MirrorTypeID -> Description for SetBalance call |
| Internal.GetCountryIDByIP | Function | IP -> RegCountryID for Broker.QueueCopyTraderAdd |
| Broker.QueueCopyTraderAdd | Procedure | CRM notification for first-time copiers |
| Trade.Tv_RegisterMirror | User Defined Type | TVP buffer for OUTPUT clause -> PostDetachOperation insert |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorReopen | Procedure | Re-creates a closed mirror with @IsReopenMirror=1 |
| Trade.TDAPI_GetLeaderStats | Procedure | Mirror registration in data/test generation |
| Trade.UnRegisterMirrorForMoe | Procedure | Mirror reassignment workflow |
| Trade.UpdateEtorianUsersCopiedBlockRestriction | Procedure | Administrative bulk registration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- SET XACT_ABORT ON: any runtime error automatically aborts the transaction
- CATCH block handles @@TRANCOUNT=1 (sole owner: ROLLBACK) vs >1 (nested: COMMIT to release savepoint)
- Error 60070 specially handled: RAISERROR with @MaxMirrorActionAmountPercentage_INT formatted argument (despite @MaxMirrorActionAmountPercentage_INT being declared but not set in this procedure - vestigial from removed validation code)
- History.Mirror INSERT is COMMENTED OUT: replaced by the Trade.PostDetachOperation pattern for async History.Mirror writes
- MSL consistency formula: round((@MirrorSL*100)/@AmountInCents, 2) = round(@MirrorSLPercentage/100, 2) - e.g. $200 investment, 2% SL -> @MirrorSL must equal $4.00
- @AmountInDollars used for Trade.Mirror.Amount and RealizedEquity (initial equity equals initial investment)
- @IsOpenOpen=1 instructs downstream position-copy logic to replicate leader's open positions at mirror creation

---

## 8. Sample Queries

### 8.1 Find all active mirrors for a copier

```sql
SELECT m.MirrorID, m.CID, m.ParentCID, m.ParentUserName, m.Amount,
       m.MirrorSL, m.MirrorSLPercentage, m.Occurred, m.MirrorTypeID
FROM Trade.Mirror WITH (NOLOCK)
WHERE CID = <CID>
ORDER BY m.Occurred DESC;
```

### 8.2 Check if copier has ever had any mirror (first-mirror detection logic)

```sql
SELECT 'Active' AS Source, CID, MirrorID, Occurred FROM Trade.Mirror WITH (NOLOCK) WHERE CID = <CID>
UNION ALL
SELECT 'Historical' AS Source, CID, MirrorID, Occurred FROM History.Mirror WITH (NOLOCK) WHERE CID = <CID>
ORDER BY Occurred;
```

### 8.3 Find mirrors created via RegisterMirror in PostDetachOperation queue

```sql
SELECT H_M_MirrorID, H_M_CID, H_M_ParentCID, H_M_Amount, H_M_Occurred,
       H_M_MirrorOperationID, H_M_MirrorSL, H_M_MirrorSLPercentage
FROM Trade.PostDetachOperation WITH (NOLOCK)
WHERE H_M_CID = <CID>
ORDER BY H_M_Occurred DESC;
```

### 8.4 Verify balance debit after mirror creation

```sql
SELECT TOP 10 CID, MirrorID, Payment, CreditTypeID, Description, Occurred
FROM Customer.Balance WITH (NOLOCK)
WHERE CID = <CID>
  AND CreditTypeID = 20 -- Register Mirror
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 SP callers (MirrorReopen, TDAPI_GetLeaderStats, UnRegisterMirrorForMoe, UpdateEtorianUsersCopiedBlockRestriction) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.RegisterMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RegisterMirror.sql*
