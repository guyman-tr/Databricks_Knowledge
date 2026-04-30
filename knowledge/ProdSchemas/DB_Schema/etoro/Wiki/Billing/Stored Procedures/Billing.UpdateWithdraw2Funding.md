# Billing.UpdateWithdraw2Funding

> Core TVP-based update engine for Billing.WithdrawToFunding: patch-updates any subset of fields (NULL = keep existing), immediately mirrors every change to History.WithdrawToFundingAction, and supports both ID-lookup and WithdrawID+FundingID lookup in one call.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Widraw2F TVP - matches on ID (primary) or WithdrawID+FundingID (business key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateWithdraw2Funding` is the central write path for the `Billing.WithdrawToFunding` table. Virtually every procedure that needs to change a withdrawal payment leg - status transitions, amount updates, exchange rate updates, provider response data, routing metadata - goes through this procedure.

The procedure accepts a `Billing.TBL_Withdraw2Funding` table-valued parameter (TVP), allowing callers to update multiple records in one call. For each row in the TVP, only non-NULL fields are applied (a "patch" pattern: NULL = preserve existing value). Every update is atomically mirrored to `History.WithdrawToFundingAction` via the SQL Server OUTPUT clause - this is the only write path that populates the withdrawal history log.

The procedure supports two lookup strategies for matching the TVP row to a `WithdrawToFunding` record:
- **By ID** (when `Src.ID IS NOT NULL`): direct primary-key lookup - most efficient and used when the WTF ID is known
- **By WithdrawID + FundingID** (when `Src.ID IS NULL`): business-key lookup - used when only the withdrawal and funding IDs are available

Both paths run within a single transaction (BEGIN TRAN / COMMIT). Returns the total number of rows updated (`@Ret`).

Change history: SchemeId added (PAYUS-3900, 24/10/2021), ResponseID added (PAYUA-2822, 31/10/2021), CashoutActionStatusID defaults to 0 when not provided (PAYIL-4189, 31/10/2021).

---

## 2. Business Logic

### 2.1 Dual Matching Strategy (ID vs. Business Key)

**What**: Two UPDATE statements in sequence handle the two ways callers can identify a WithdrawToFunding record.

**Columns/Parameters Involved**: `Src.ID`, `Src.WithdrawID`, `Src.FundingID`

**Rules**:
- **Path 1** (WHERE `Src.ID IS NOT NULL`): JOIN on `BWTF.ID = Src.ID` - direct PK lookup, most callers use this
- **Path 2** (WHERE `Src.ID IS NULL`): JOIN on `BWTF.WithdrawID = Src.WithdrawID AND BWTF.FundingID = Src.FundingID` - business-key lookup for legacy callers or cross-schema scenarios where the WTF primary key is not readily available
- Both paths execute; `@Ret` accumulates the `@@ROWCOUNT` from each. A typical call updates via one path only (either ID is provided or it is not)
- Both paths produce identical SET and OUTPUT clauses - same patch logic, same history logging

**Diagram**:
```
@Widraw2F TVP row:
  ID IS NOT NULL --> UPDATE BWTF JOIN TVP ON BWTF.ID = Src.ID
                     OUTPUT ... INTO History.WithdrawToFundingAction
  ID IS NULL     --> UPDATE BWTF JOIN TVP ON BWTF.WithdrawID = Src.WithdrawID
                                        AND BWTF.FundingID = Src.FundingID
                     OUTPUT ... INTO History.WithdrawToFundingAction
```

### 2.2 Patch Update Pattern (ISNULL Preservation)

**What**: Every field in the SET clause uses `ISNULL(Src.Field, BWTF.Field)` so that NULL values in the TVP leave the existing column value unchanged.

**Rules**:
- Passing a NULL value for any column in the TVP means "do not change this field"
- Passing a non-NULL value replaces the current value
- Exception: `ProtocolMIDSettingsID` uses `COALESCE(Src.ProtocolMIDSettingsID, BWTF.ProtocolMIDSettingsID, 0)` - falls back to 0 (not NULL) if both are NULL
- `ModificationDate` is always set to `GETUTCDATE()` - not patchable
- `CreationDate` is explicitly excluded from updates (comment: `--CreationDate`)

### 2.3 Automatic History Logging via OUTPUT

**What**: Every row updated in `Billing.WithdrawToFunding` is immediately written to `History.WithdrawToFundingAction` via the SQL Server OUTPUT clause - atomic with the UPDATE.

**Rules**:
- History captures the POST-update state of all tracked columns (via `Inserted.*`)
- `CashoutActionStatusID` in history: `ISNULL(Src.CashoutActionStatusID, 0)` - defaults to 0 (New) when the TVP row does not specify an action status
- `Remark` in history: taken from `Src.Remark` in the TVP (not stored on WithdrawToFunding itself - only in history)
- The history record is inserted in the same transaction as the update; no history orphans possible
- Columns NOT in OUTPUT (not tracked in history): `DepotID`, `AutoPaymentStartDate`, `VerificationCode`, `ProcessorValueDate`, `VendorCode`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Widraw2F | Billing.TBL_Withdraw2Funding READONLY | NO | - | CODE-BACKED | TVP containing one or more rows describing the update(s) to apply. Each row targets one `WithdrawToFunding` record. NULL fields in the TVP preserve the current DB value. The TVP type `Billing.TBL_Withdraw2Funding` mirrors the column structure of `Billing.WithdrawToFunding`. |

**TVP columns that drive the update (non-NULL = update applied):**

| # | TVP Column | Type | Description |
|---|-----------|------|-------------|
| 1 | ID | INT | Primary key of WithdrawToFunding. When non-NULL, triggers the ID-based matching path. |
| 2 | WithdrawID | INT | FK to Billing.Withdraw. Used in the business-key matching path when ID is NULL. |
| 3 | FundingID | INT | FK to Billing.Funding. Used in the business-key matching path when ID is NULL. |
| 4 | CashoutStatusID | INT | Payment leg execution status (see Billing.WithdrawToFunding lifecycle). |
| 5 | CashoutActionStatusID | INT | History record action type - stored only in History.WithdrawToFundingAction. Defaults to 0 (New) if NULL. |
| 6 | Remark | NVARCHAR | Free-text audit comment - stored only in History.WithdrawToFundingAction, not in the live table. |
| 7 | ProcessCurrencyID | INT | Currency of the payment amount. |
| 8 | ManagerID | INT | Operator/service account performing the update. -1 = billing service. |
| 9 | Amount | MONEY | Payment amount in ProcessCurrencyID. |
| 10 | ExchangeRate | DECIMAL | USD-to-process-currency rate at time of update. |
| 11 | BaseExchangeRate | DECIMAL | Base exchange rate (pre-fee). |
| 12 | ExchangeFee | DECIMAL | Fee component of the exchange rate. |
| 13 | WithdrawData | XML | Provider-specific response data (auth codes, transaction IDs, rejection reasons). |
| 14 | DepositID | INT | Linked deposit for refund legs (CashoutTypeID=2). |
| 15 | RefundAmountInDepositCurrency | MONEY | Refund amount in the original deposit currency. |
| 16 | CashoutTypeID | INT | 1=Cashout, 2=Refund. |
| 17 | MatchStatusID | INT | Match/reconciliation status. |
| 18 | DepotID | INT | Payment depot routing (not in history OUTPUT). |
| 19 | AutoPaymentStartDate | DATETIME | When SentToBilling (status 11) was first set; triggers auto-payment process (not in history). |
| 20 | ProtocolMIDSettingsID | INT | Merchant ID settings reference. COALESCE to 0 if NULL. |
| 21 | CashoutModeID | INT | Cashout processing mode. |
| 22 | AdditionalInformation | NVARCHAR | Extra notes or provider metadata. |
| 23 | VendorCode | NVARCHAR | Vendor-specific code (not in history OUTPUT). |
| 24 | MerchantAccountID | INT | Merchant account used for this payment. |
| 25 | SchemeId | NVARCHAR(255) | Recurring payment scheme token from provider (added PAYUS-3900). |
| 26 | ResponseID | INT | Payment provider response ID (added PAYUA-2822). |
| 27 | RequestExecuteEntryMethodId | INT | Execution trigger mode: 0=None, 1=Auto, 2=Manually (added PAYUA-3768). |
| 28 | VerificationCode | NVARCHAR | Verification code from provider (not in history OUTPUT). |
| 29 | ProcessorValueDate | DATETIME | Value date from payment processor (not in history OUTPUT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Widraw2F.ID | Billing.WithdrawToFunding | UPDATE (PK path) | Updates WTF record by primary key |
| @Widraw2F.WithdrawID + FundingID | Billing.WithdrawToFunding | UPDATE (BK path) | Updates WTF record by business key |
| (OUTPUT) | History.WithdrawToFundingAction | INSERT | Every update is atomically mirrored to history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.SetWithdrawToFundingScheme | EXEC | Caller | Sets SchemeId on a WTF record |
| Billing.UpdateRequestExecuteEntryMethod | EXEC | Caller | Sets RequestExecuteEntryMethodId in batch |
| Billing.WithdrawToFundingChangePaymentStatus | EXEC | Caller | Transitions cashout payment status |
| Billing.WithdrawToFundingProcess | EXEC | Caller | Core payout processing flow |
| Billing.WithdrawToFundingProcess_v2 | EXEC | Caller | V2 payout processing flow |
| Billing.WithdrawToFundingUpdate | EXEC | Caller | Generic WTF field update |
| Billing.WithdrawToFundingUpdateAdditionalInformation | EXEC | Caller | Updates AdditionalInformation field |
| Billing.WithdrawToFundingUpdateMerchantAccountID | EXEC | Caller | Updates MerchantAccountID field |
| Billing.WithdrawToFundingReject | EXEC | Caller | Marks WTF as rejected |
| Billing.WithdrawToFundingReverse | EXEC | Caller | Reverses a WTF payment leg |
| Billing.AddCashoutRollback | EXEC | Caller | Rollback processing |
| (and 5 more procedures) | EXEC | Callers | See SSDT grep: 16 total callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateWithdraw2Funding (procedure)
├── Billing.WithdrawToFunding (table) [UPDATE]
└── History.WithdrawToFundingAction (table) [INSERT via OUTPUT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Target of the patch UPDATE |
| History.WithdrawToFundingAction | Table | Receives OUTPUT rows - automatic audit log entry per update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| 16 stored procedures (see 5.2) | Stored Procedure | All use this as the standard WTF write path |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction integrity | BEGIN TRAN / COMMIT | Both UPDATEs and both OUTPUT inserts run atomically |
| Outer transaction safety | TRY/CATCH | ROLLBACK when @@TRANCOUNT=1; COMMIT (preserve outer) when @@TRANCOUNT>1; THROW re-propagates |
| Return value | @Ret | Total rows updated across both paths - 0 means no matching record found |

---

## 8. Sample Queries

### 8.1 Update cashout status and add a remark (by ID)
```sql
DECLARE @tvp Billing.TBL_Withdraw2Funding;
INSERT @tvp (ID, CashoutStatusID, CashoutActionStatusID, ManagerID, Remark)
VALUES (123456, 3, 1, 9001, N'Payment confirmed by provider');

EXEC Billing.UpdateWithdraw2Funding @Widraw2F = @tvp;
```

### 8.2 Update by business key (WithdrawID + FundingID)
```sql
DECLARE @tvp Billing.TBL_Withdraw2Funding;
INSERT @tvp (ID, WithdrawID, FundingID, CashoutStatusID, ManagerID, Remark)
VALUES (NULL, 55001, 66001, 7, -1, N'Rejected by provider');
-- ID IS NULL -> will match by WithdrawID + FundingID

EXEC Billing.UpdateWithdraw2Funding @Widraw2F = @tvp;
```

### 8.3 Verify the update was logged to history
```sql
SELECT TOP 10
    h.WithdrawToFundingActionID,
    h.BW2F_ID           AS WTF_ID,
    h.WithdrawID,
    h.CashoutStatusID,
    h.CashoutActionStatusID,
    h.ManagerID,
    h.Remark,
    h.ModificationDate
FROM History.WithdrawToFundingAction h WITH (NOLOCK)
WHERE h.BW2F_ID = 123456
ORDER BY h.WithdrawToFundingActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateWithdraw2Funding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateWithdraw2Funding.sql*
