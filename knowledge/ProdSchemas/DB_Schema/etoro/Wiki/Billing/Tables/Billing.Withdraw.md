# Billing.Withdraw

> Core withdrawal request table (1.66M records); each row represents one customer withdrawal request with full lifecycle tracking from pending through processed or cancelled, including amount, fees, commission, and the funding instrument used for payout.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | WithdrawID (PRIMARY KEY NONCLUSTERED, IDENTITY(1,1)) |
| **Row Count** | ~1,662,375 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED; 1 - CLUSTERED on WithdrawID; 5 - NC covering indexes; total 7 |

---

## 1. Business Meaning

`Billing.Withdraw` is the primary withdrawal request table - the central record of all customer cash-out requests since eToro's payment platform migrated from the legacy `Billing.Cashout` table (early 2010s). Every withdrawal request appears here, from initial submission through final processing or cancellation.

A withdrawal lifecycle:
1. Customer submits a withdrawal request -> `WithdrawRequestAdd` inserts a row with initial `CashoutStatusID`
2. Operations/system moves it through status transitions (Pending -> InProcess -> Processed or Cancelled)
3. Payment execution: `WithdrawToFundingProcess` / `WithdrawToFundingProcessBatch` process each `Billing.WithdrawToFunding` leg (links between this withdraw request and specific funding instruments)
4. Each status change is logged in `History.WithdrawAction`

With 1.66M rows spanning from 2007 (earliest records) to present, 26 distinct funding types, 10 CashoutStatus values, and roughly 71% cancelled rate (1.19M of 1.66M), the table reflects the full scope of eToro's withdrawal operations.

The `WithdrawTypeID` and `FlowID` columns were added in later iterations of the platform to support specialized flows:
- `FlowID=2` + `FundingTypeID=33`: eToroMoney local currency withdrawal (43K records)
- `FlowID=3` + `WithdrawTypeID=1`: specific alternate withdrawal flow (708 records)
These trigger `MoveMoneyReasonID` overrides in `WithdrawToFundingProcess` (IDs 5 and 6 respectively).

---

## 2. Business Logic

### 2.1 Withdrawal Request Lifecycle

**What**: A withdrawal request is created and moves through a status machine until it is either processed (payout sent) or cancelled.

**Columns Involved**: `CashoutStatusID`, `WithdrawID`, `Amount`, `CID`, `ModificationDate`

**Status Distribution** (from live data):

| CashoutStatusID | Business Meaning | Count | % |
|----------------|-----------------|-------|---|
| 1 | Pending (new request) | 3,266 | 0.2% |
| 2 | InProcess | 3,931 | 0.2% |
| 3 | Processed (completed) | 438,218 | 26.4% |
| 4 | Cancelled | 1,185,834 | 71.3% |
| 5 | (status 5) | 20,127 | 1.2% |
| 7 | (status 7) | 54 | <0.1% |
| 8 | (status 8) | 2 | <0.1% |
| 14 | (status 14) | 3,652 | 0.2% |
| 16 | (status 16) | 43 | <0.1% |
| 17 | (status 17) | 7,248 | 0.4% |

**Process flow** (from WithdrawRequestAdd and related SPs):
```
WithdrawRequestAdd(@FundingTypeID, @CID, @Amount, @FundingID, ...)
  -> INSERT Billing.Withdraw (CashoutStatusID=initial, ModificationDate=NOW)
  -> INSERT History.WithdrawAction
  -> Customer.SetBalance(@Amount negated, UpdateType = withdraw_request)

CashoutRequestUpdate(@tbl TBL_CashoutStatusInfo)  -- DBA-648 pattern
  -> Billing.UpsertWithdraw(@TBL TBL_Withdraw) -> UPDATE Billing.Withdraw

WithdrawToFundingProcess / WithdrawToFundingProcessBatch
  -> Processes the actual payout via Billing.WithdrawToFunding
  -> Customer.SetBalance(@Amount, UpdateType = withdraw_process)
```

### 2.2 Amount and Fee Fields

**What**: Tracks the withdrawal amount, platform fee, commission, and bonus deduction components.

**Columns Involved**: `Amount`, `Fee`, `Commission`, `SuggestedBonusDeductionAmount`, `ActualBonusDeductionAmount`

**Rules**:
- `Amount` (money): the gross withdrawal amount in `CurrencyID` currency. `money` type (unlike legacy `Billing.Cashout.Amount` which was `int`)
- `Fee` (money NOT NULL): platform fee charged for the withdrawal
- `Commission` (money NOT NULL, DEFAULT=0): broker commission on the withdrawal
- `SuggestedBonusDeductionAmount` (money NOT NULL, DEFAULT=0): pre-calculated bonus clawback amount
- `ActualBonusDeductionAmount` (money NULL): actual bonus deducted after processing; may differ from suggested amount

### 2.3 Special Flow Identification (WithdrawTypeID and FlowID)

**What**: Newer fields classify withdrawals into specialized processing flows.

**Columns Involved**: `WithdrawTypeID`, `FlowID`

**Values observed in live data**:

| WithdrawTypeID | Count | Meaning |
|---------------|-------|---------|
| NULL | 909,994 | Legacy (pre-column addition) |
| 0 | 682,820 | Standard withdrawal |
| 1 | 61,017 | Special/alternate type |
| 2 | 8,544 | (second alternate type) |

| FlowID | Count | Meaning |
|--------|-------|---------|
| NULL | 987,641 | Legacy |
| 0 | 631,064 | Standard flow |
| 1 | 1 | (rare alternate) |
| 2 | 42,952 | eToroMoney flow (triggers MoveMoneyReasonID=5 in WTF processing) |
| 3 | 708 | Specific alternate flow (triggers MoveMoneyReasonID=6) |
| 9 | 9 | (special case) |

### 2.4 Currency Fields

- `CurrencyID`: the currency of the withdrawal amount (customer account currency)
- `AccountCurrencyID` (nullable): the customer's eToro account currency, if different from `CurrencyID`. Used when the withdrawal is processed in a different currency than the account.

### 2.5 Client Communication Fields

- `ClientWithdrawReasonID`: why the client wants to withdraw (customer-selected reason)
- `ClientWithdrawReasonComment`: free text from the customer explaining the reason
- `ClientWithdrawCommentID`: FK to `Dictionary.ClientWithdrawComment` - standardized comment category
- `RequestorComments`: notes added by the requesting party (operations/system)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~1,662,375 |
| WithdrawID range | 5,939 to 1,734,826 (gaps) |
| Date range | 2007-10-28 (earliest) to present |
| Distinct FundingTypes | 26 |
| CashoutStatus values | 10 |
| Processed | 438,218 (26.4%) |
| Cancelled | 1,185,834 (71.3%) |
| WithdrawTypeID NULL (legacy) | 909,994 (55%) |
| FlowID=2 (eToroMoney) | 42,952 (2.6%) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. IDENTITY starting at 1. Both a PK NONCLUSTERED and a separate CLUSTERED index exist on this column (unusual pattern - PK is non-clustered to allow covering indexes to reference the clustered key). NOT FOR REPLICATION. |
| 2 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the withdrawal amount. FK to `Dictionary.Currency` (FK_DCUR_BWDR). Indexed (i_CureenyID - note typo in index name). |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type (Visa/Wire/Neteller/eToroMoney/etc.). References `Dictionary.FundingType` implicitly. 26 distinct values in live data. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to `Customer.CustomerStatic` (FK_CCST_BWDR). Indexed in covering indexes (CashoutStatusID+CID, CoveringNew). |
| 5 | ManagerID | int | YES | NULL | CODE-BACKED | Operations manager who processed or last modified this withdrawal. FK to `BackOffice.Manager` (FK_BMNG_BWDR). NULL=system-initiated or customer self-service. |
| 6 | CashoutStatusID | int | NO | - | CODE-BACKED | Current withdrawal status. FK to `Dictionary.CashoutStatus` (FK_DCSS_BWDR). 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/7/8/14/16/17=specialized states. Indexed (multiple covering indexes). |
| 7 | RequestDate | datetime | NO | - | CODE-BACKED | Timestamp when the customer submitted the withdrawal request. Included in covering indexes for date-range queries. |
| 8 | Amount | money | NO | - | CODE-BACKED | Gross withdrawal amount in `CurrencyID` denomination. `money` type (4 decimal places). Included in covering indexes. |
| 9 | Commission | money | NO | 0 | CODE-BACKED | Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers; may be non-zero for professional/partner accounts. |
| 10 | Approved | bit | NO | 0 | CODE-BACKED | Whether the withdrawal has received required approval (e.g., compliance/operations sign-off): 1=Approved, 0=Pending approval. DEFAULT=0. Included in covering index for filtered queries. |
| 11 | IPAddress | numeric(18,0) | YES | NULL | CODE-BACKED | Customer's IP address at request time, stored as integer (IPv4 -> decimal). Fraud detection and audit trail. |
| 12 | ModificationDate | datetime | NO | - | CODE-BACKED | UTC timestamp of the most recent status change or update. Indexed (ix_BillingWithdraw_ModificationDate). Included in covering index. |
| 13 | Remark | nvarchar(500) | YES | NULL | CODE-BACKED | Processing note added by the system or operations staff. Included in covering index INCLUDE list. |
| 14 | Comment | nvarchar(255) | YES | NULL | CODE-BACKED | Additional operations comment. Included in covering index INCLUDE list. |
| 15 | Fee | money | NO | - | CODE-BACKED | Platform fee charged for this withdrawal. Subtracted from the gross Amount. Included in covering index. |
| 16 | FundingID | int | YES | NULL | CODE-BACKED | FK to `Billing.Funding` - the payment instrument to which the withdrawal should be paid. NULL if no specific instrument selected at request time. Included in covering index. |
| 17 | RequestorComments | nvarchar(255) | YES | NULL | CODE-BACKED | Notes added by the requesting party (customer or system). DEFAULT NULL. |
| 18 | SessionID | bigint | YES | NULL | CODE-BACKED | Audit session identifier linking this withdrawal to a specific user session. DEFAULT NULL. |
| 19 | CashoutReasonID | int | YES | NULL | CODE-BACKED | Internal reason code for the withdrawal decision (e.g., why it was cancelled or flagged). References an internal catalog. |
| 20 | SuggestedBonusDeductionAmount | money | NO | 0 | CODE-BACKED | Pre-calculated amount of trading bonus to claw back when the customer withdraws (per bonus terms). DEFAULT=0. |
| 21 | ActualBonusDeductionAmount | money | YES | NULL | CODE-BACKED | Actual bonus amount deducted after processing. May differ from suggested amount if conditions changed. NULL until finalized. |
| 22 | ClientWithdrawReasonID | int | YES | NULL | CODE-BACKED | Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). References a reason catalog implicitly. |
| 23 | ClientWithdrawReasonComment | nvarchar(510) | YES | NULL | CODE-BACKED | Customer's free-text explanation for the withdrawal reason. Max 510 characters. |
| 24 | AccountCurrencyID | int | YES | NULL | CODE-BACKED | Customer's eToro account currency, if different from `CurrencyID`. FK to `Dictionary.Currency` (FK_DCUR_BWAC). Included in covering index. Used when account and withdrawal currencies differ. |
| 25 | ClientWithdrawCommentID | int | YES | NULL | CODE-BACKED | FK to `Dictionary.ClientWithdrawComment` (FK_BillingWithdraw_DictionaryClientWithdrawComment). Standardized comment category for the withdrawal (used in customer-facing messaging). |
| 26 | ExTransactionID | varchar(500) | YES | NULL | CODE-BACKED | External transaction identifier from the payment provider. Links this withdrawal record to the provider's transaction reference. |
| 27 | WithdrawTypeID | int | YES | NULL | CODE-BACKED | Withdrawal type classification added in a later release. NULL=legacy record (55%). 0=standard withdrawal (41%). 1=special/alternate type (3.7%). 2=second alternate type (0.5%). Used by `WithdrawToFundingProcess` to determine MoveMoneyReasonID override: WithdrawTypeID=1 + FlowID=2 -> MoveMoneyReasonID=5; WithdrawTypeID=1 + FlowID=3 -> MoveMoneyReasonID=6. |
| 28 | FlowID | int | YES | NULL | CODE-BACKED | Processing flow identifier added in a later release. NULL=legacy (59%). 0=standard flow (38%). 2=eToroMoney local currency withdrawal (2.6%, 42,952 records). 3=specific alternate flow (708 records). 9=rare special case (9 records). 1=one record. FlowID=2 with FundingTypeID=33 triggers eToroMoney-specific balance accounting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_BWDR) | Customer who submitted the withdrawal |
| CashoutStatusID | Dictionary.CashoutStatus | FK (FK_DCSS_BWDR) | Current withdrawal status |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_BWDR) | Withdrawal currency |
| AccountCurrencyID | Dictionary.Currency | FK (FK_DCUR_BWAC) | Customer account currency |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_BWDR) | Processing manager |
| ClientWithdrawCommentID | Dictionary.ClientWithdrawComment | FK (FK_BillingWithdraw_DictionaryClientWithdrawComment) | Standardized comment category |
| FundingID | Billing.Funding | Implicit | Payment instrument for payout |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFunding | WithdrawID | FK (implicit) | Payment legs for this withdrawal |
| History.WithdrawAction | WithdrawID | FK (implicit) | Status change audit log |
| Billing.WithdrawToFundingProcess | WithdrawID | Read/Write | Processes payout legs |
| Billing.WithdrawRequestAdd | WithdrawID (OUTPUT) | Write | Creates new withdrawal request |
| Billing.CashoutRequestUpdate | WithdrawID | Write | Updates status via TBL_CashoutStatusInfo TVP |
| Billing.UpsertWithdraw | WithdrawID | Write | DBA-648: TVP-based insert/update |
| Billing.WithdrawalService_RiskManagementStatus_Add | WithdrawID | Related | Adds risk check results for this withdrawal |
| Billing.GetOrdersForExecutionReport | WithdrawID | Read | Reporting |
| Billing.GetWithdrawHistory | WithdrawID | Read | Historical reporting |
| Billing.WithdrawalService_WithdrawRequestAdd | WithdrawID (OUTPUT) | Write | Creates withdrawal record via UpsertWithdraw; entry point for withdrawal request creation |
| Billing.WithdrawalService_GetCustomerLastFundingPerFundingType | WithdrawID | Read | Returns last funding instrument per type for a customer |
| Billing.WithdrawalService_HasWithdrawals | WithdrawID | Read | Checks if customer has any withdrawal records |
| Billing.WithdrawToFundingReject | WithdrawID | Read | Reads withdrawal context when rejecting the WTF leg |
| Billing.WithdrawToFundingReverse | WithdrawID | Read | Reads withdrawal context when reversing the WTF leg |
| Billing.WithdrawToFundingUpdate | WithdrawID | Read | Reads withdrawal context for general WTF metadata update |
| Billing.WithdrawService_GetWithdrawsWithoutRedeems | WithdrawID | Read | Returns withdrawals with no linked Redeem record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Withdraw
  -> Customer.CustomerStatic (CID)
  -> Dictionary.CashoutStatus (CashoutStatusID)
  -> Dictionary.Currency (CurrencyID, AccountCurrencyID)
  -> BackOffice.Manager (ManagerID)
  -> Dictionary.ClientWithdrawComment (ClientWithdrawCommentID)
  -> Billing.Funding (FundingID - implicit)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID |
| Dictionary.CashoutStatus | Table | FK on CashoutStatusID |
| Dictionary.Currency | Table | FK on CurrencyID and AccountCurrencyID |
| BackOffice.Manager | Table | FK on ManagerID |
| Dictionary.ClientWithdrawComment | Table | FK on ClientWithdrawCommentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FK on WithdrawID - payment execution legs |
| History.WithdrawAction | Table | Status change audit log |
| Billing.WithdrawToRiskManagementStatus | Table | Risk check results |
| Billing.UpsertWithdraw | Stored Procedure | TVP-based upsert (DBA-648, Shay Oren Sep 2021) |
| Billing.WithdrawRequestAdd | Stored Procedure | Creates new withdrawal request |
| Billing.CashoutRequestUpdate | Stored Procedure | Status update via TBL_CashoutStatusInfo |
| Billing.WithdrawToFundingProcess | Stored Procedure | Processes individual payout legs |
| Billing.WithdrawToFundingProcessBatch | Stored Procedure | Batch payout processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Notes |
|-----------|------|-------------|---------|-------|
| PK_BWDR | NONCLUSTERED PK | WithdrawID ASC | - | FILLFACTOR=90 |
| Idx_Billing_Withdraw | CLUSTERED | WithdrawID ASC | - | FILLFACTOR=95; separate clustered index (not PK) |
| Idx_Billing_Withdraw_CashoutStatusID | NC | CashoutStatusID | RequestDate, CID, Amount | FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| Idx_Billing_Withdraw_CashoutStatusID_CID_CashoutStatusID | NC | (CID, CashoutStatusID) | RequestDate, Amount | FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| i_CureenyID | NC | CurrencyID ASC | - | Note: typo in index name ('Cureeny' not 'Currency') |
| ix_BillingWithdraw_CoveringNew | NC | (CID, CashoutStatusID, Amount, Approved) | WithdrawID, CurrencyID, AccountCurrencyID, FundingTypeID, FundingID, Fee, ModificationDate, RequestDate, Remark, ManagerID, Comment | FILLFACTOR=95; large covering index for customer withdrawal queries |
| ix_BillingWithdraw_ModificationDate | NC | ModificationDate ASC | - | FILLFACTOR=95; DATA_COMPRESSION=PAGE |

### 7.2 Constraints and Defaults

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BWDR | PRIMARY KEY NONCLUSTERED (WithdrawID) | One row per withdrawal |
| FK_CCST_BWDR | FOREIGN KEY CID -> Customer.CustomerStatic | Customer must exist |
| FK_DCSS_BWDR | FOREIGN KEY CashoutStatusID -> Dictionary.CashoutStatus | Status must be valid |
| FK_DCUR_BWDR | FOREIGN KEY CurrencyID -> Dictionary.Currency | Currency must be valid |
| FK_DCUR_BWAC | FOREIGN KEY AccountCurrencyID -> Dictionary.Currency | Account currency must be valid |
| FK_BMNG_BWDR | FOREIGN KEY ManagerID -> BackOffice.Manager | Manager must exist if set |
| FK_BillingWithdraw_DictionaryClientWithdrawComment | FOREIGN KEY ClientWithdrawCommentID -> Dictionary.ClientWithdrawComment | Comment category must be valid |
| BWDR_COMMISSION | DEFAULT (0) FOR Commission | Commission defaults to 0 |
| BWDR_APPROVED | DEFAULT (0) FOR Approved | Not approved by default |
| Def_BillingWithdraw_FundingID | DEFAULT NULL FOR FundingID | No funding instrument by default |
| Def_BillingWithdraw_RequestorComments | DEFAULT NULL | |
| DF_BillingWithdraw_SuggestedBonusDeductionAmount | DEFAULT (0) | No bonus deduction by default |

---

## 8. Sample Queries

### 8.1 Withdrawal status distribution

```sql
SELECT
    cs.Name AS StatusName,
    cs.CashoutStatusID,
    COUNT(*) AS WithdrawCount,
    SUM(w.Amount) AS TotalAmount
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
GROUP BY cs.Name, cs.CashoutStatusID
ORDER BY WithdrawCount DESC
```

### 8.2 Pending withdrawals for operations processing

```sql
SELECT
    w.WithdrawID,
    w.CID,
    w.FundingTypeID,
    w.Amount,
    w.Fee,
    w.CurrencyID,
    w.RequestDate,
    w.Approved,
    w.FundingID
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.CashoutStatusID = 1  -- Pending
ORDER BY w.RequestDate
-- Uses Idx_Billing_Withdraw_CashoutStatusID (includes RequestDate, CID, Amount)
```

### 8.3 Customer withdrawal history

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    w.FundingTypeID,
    w.Amount,
    w.Fee,
    w.RequestDate,
    w.ModificationDate,
    w.Remark
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.CID = @CID
  AND w.CashoutStatusID IN (1, 2, 3)  -- Active statuses
ORDER BY w.RequestDate DESC
-- Uses ix_BillingWithdraw_CoveringNew (CID, CashoutStatusID key; many included columns)
```

### 8.4 eToroMoney withdrawal flow analysis

```sql
SELECT
    w.WithdrawID,
    w.FundingTypeID,
    w.FlowID,
    w.WithdrawTypeID,
    w.Amount,
    w.CashoutStatusID,
    w.RequestDate
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.FlowID = 2  -- eToroMoney flow
ORDER BY w.RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,6,7,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Withdraw | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Withdraw.sql*
