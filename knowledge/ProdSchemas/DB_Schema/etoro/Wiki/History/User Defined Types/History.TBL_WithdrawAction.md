# History.TBL_WithdrawAction

> Table-valued parameter type that serves as the OUTPUT buffer in Billing.UpsertWithdraw, capturing the result of each Billing.Withdraw insert/update so the data can be immediately written to History.WithdrawAction as an audit trail entry.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | User Defined Type |
| **Key Identifier** | WithdrawID (effective PK - no formal PK constraint) |
| **Partition** | No |
| **Indexes** | None (standard non-memory-optimized type) |

---

## 1. Business Meaning

This UDT defines the schema for a table variable used exclusively in `Billing.UpsertWithdraw` as the bridge between a MERGE operation on `Billing.Withdraw` and audit logging into `History.WithdrawAction`. Every time a withdrawal record is created or updated, the MERGE statement's OUTPUT clause routes the resulting row state into a variable of this type, which is then immediately selected into `History.WithdrawAction`.

The type exists because SQL Server requires a declared table structure to capture MERGE OUTPUT results. By using a named UDT rather than an inline `DECLARE @t TABLE (...)`, the schema is centrally defined and shared across any procedure that performs the same withdraw-upsert-and-log pattern. The column set intentionally omits some `Billing.Withdraw` columns (such as `ClientPersonalID` which is hardcoded to NULL in the INSERT) to capture only the audit-relevant fields.

Data flows strictly in one direction: `Billing.UpsertWithdraw` is called by billing services -> MERGE modifies `Billing.Withdraw` -> OUTPUT captures the new/updated row state into `@Info` of this type -> SELECT inserts into `History.WithdrawAction` for permanent audit record.

---

## 2. Business Logic

### 2.1 MERGE-OUTPUT-INSERT Audit Pattern

**What**: Captures the exact post-MERGE state of a withdrawal record for immutable audit logging.

**Columns/Parameters Involved**: `WithdrawID`, `CashoutStatusID`, `ManagerID`, `Commission`, `Approved`, `ModificationDate`, `Comment`, `SessionID`, `CashoutReasonID`, `FundingID`, `FundingTypeID`, `Amount`, `CurrencyID`, `Fee`, `AccountCurrencyID`

**Rules**:
- The MERGE OUTPUT clause writes `Inserted.*` column values into `@Info` of this type
- For the ManagerID column specifically, the OUTPUT applies: `ISNULL(Src.[WithrawActionManagerID], Inserted.[ManagerID])` - the action-specific manager ID overrides the record-level ManagerID when provided
- `ClientPersonalID` is present in the type definition but the UpsertWithdraw INSERT hardcodes it to NULL (PII protection - personal ID is not logged in history)
- The captured `@Info` data is inserted verbatim into `History.WithdrawAction`, creating an immutable point-in-time snapshot of the withdrawal state at the moment of each create/update operation

**Diagram**:
```
Billing.UpsertWithdraw called (@Withdraw TVP input)
         |
         v
MERGE INTO Billing.Withdraw
  WHEN NOT MATCHED -> INSERT (new withdrawal)
  WHEN MATCHED     -> UPDATE (status change, approval, etc.)
         |
         | OUTPUT Inserted.* INTO @Info (this type)
         v
@Info variable (History.TBL_WithdrawAction)
         |
         | INSERT INTO History.WithdrawAction
         v
Permanent audit record created
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | Primary identifier for the withdrawal record. Captured from `Inserted.WithdrawID` in the OUTPUT clause. Used as the linking key when writing to History.WithdrawAction. |
| 2 | CashoutStatusID | int | NO | - | CODE-BACKED | Lifecycle state of the withdrawal at the time of this audit entry. Captured from `Inserted.CashoutStatusID`. Values: 1=Pending, 2=InProcess, 3=Processed, etc. See [Cashout Status](_glossary.md#cashout-status). |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager who performed the withdrawal action. In the OUTPUT clause, this is computed as `ISNULL(Src.[WithrawActionManagerID], Inserted.[ManagerID])` - the action-specific manager override takes priority over the record's stored ManagerID. NULL for system-initiated changes. |
| 4 | Commission | money | NO | - | CODE-BACKED | Commission fee charged on this withdrawal. Captured from `Inserted.Commission` (defaulted to 0 if NULL on insert). Represents eToro's revenue from the withdrawal transaction. |
| 5 | Approved | bit | YES | - | CODE-BACKED | Approval flag captured at the moment of insert/update. 1 = approved to proceed; 0 or NULL = pending approval or not yet approved. Captured from `Inserted.Approved`. |
| 6 | ModificationDate | datetime | YES | - | CODE-BACKED | Timestamp of the insert/update operation. For new withdrawals: `ISNULL(Src.RequestDate, GETUTCDATE())`. For updates: always `GETUTCDATE()` per the MERGE UPDATE SET clause. Records when this audit snapshot was created. |
| 7 | Comment | nvarchar(255) | YES | - | CODE-BACKED | Internal remark on the withdrawal action. In UpsertWithdraw, this is populated as `ISNULL(@HistoryOnlyRemark, Inserted.[Comment])` - the @HistoryOnlyRemark parameter allows callers to write a history-specific note that differs from the main record comment. Latin1_General_BIN collation. |
| 8 | SessionID | bigint | YES | - | NAME-INFERRED | Session identifier of the user or agent who triggered this withdrawal action. Provides traceability back to the web/API session for audit investigations. |
| 9 | CashoutReasonID | int | YES | - | NAME-INFERRED | Customer-provided reason for requesting the withdrawal. Captured from the withdrawal record at action time. References Dictionary.ClientWithdrawReason or similar. |
| 10 | ClientPersonalID | varchar(255) | YES | - | CODE-BACKED | Customer's government-issued personal ID. Present in the type schema but hardcoded to NULL in UpsertWithdraw (PII protection: personal ID is intentionally excluded from the history log). Latin1_General_BIN collation. |
| 11 | FundingID | int | YES | - | NAME-INFERRED | Specific funding account (e.g., bank account, card ID on file) to which the withdrawal is directed. Identifies the destination payment instrument. |
| 12 | FundingTypeID | int | YES | - | CODE-BACKED | Payment method used for the withdrawal. Captured from `Inserted.FundingTypeID`. Values: 1=CreditCard, 2=WireTransfer, 3=PayPal, etc. See [Funding Type](_glossary.md#funding-type). |
| 13 | Amount | money | YES | - | CODE-BACKED | Gross withdrawal amount requested, in the CurrencyID denomination. Captured from `Inserted.Amount`. |
| 14 | CurrencyID | int | YES | - | CODE-BACKED | Currency of the withdrawal amount. Captures the denomination at the time of the action. References Dictionary.Currency. |
| 15 | Fee | money | YES | - | CODE-BACKED | Processing fee charged for this withdrawal action, separate from Commission. Captured from `Inserted.Fee`. |
| 16 | AccountCurrencyID | int | YES | - | CODE-BACKED | Currency of the customer's trading account (may differ from the withdrawal CurrencyID if cross-currency). Used for account-level reconciliation in History.WithdrawAction. References Dictionary.Currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | FK to the withdrawal record being audited |
| WithdrawID | History.WithdrawAction | Implicit | This type's contents are inserted into History.WithdrawAction |
| CashoutStatusID | Dictionary.CashoutStatus | Implicit | Lookup for withdrawal lifecycle state values |
| FundingTypeID | Dictionary.FundingType | Implicit | Lookup for payment method |
| CurrencyID | Dictionary.Currency | Implicit | Currency denomination of withdrawal amount |
| AccountCurrencyID | Dictionary.Currency | Implicit | Currency denomination of customer account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpsertWithdraw | @Info | Local variable | Declared as `DECLARE @Info [History].[TBL_WithdrawAction]`; receives MERGE OUTPUT; source for History.WithdrawAction insert |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpsertWithdraw | Stored Procedure | Sole consumer - declares `@Info` of this type; OUTPUT clause of MERGE INTO Billing.Withdraw populates it; then INSERTs into History.WithdrawAction |

---

## 7. Technical Details

### 7.1 Indexes

N/A - standard (non-memory-optimized) table type has no explicit indexes. The variable is used for single-pass OUTPUT capture and immediate INSERT, so indexing is unnecessary.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WithdrawID NOT NULL | NOT NULL | Guarantees every captured OUTPUT row has a valid WithdrawID, enabling reliable INSERT into History.WithdrawAction. |
| CashoutStatusID NOT NULL | NOT NULL | Withdrawal status must always be present in the audit record. |
| Commission NOT NULL | NOT NULL | Commission value must always be captured (defaults to 0 if not provided). |

---

## 8. Sample Queries

### 8.1 Usage pattern inside a withdraw upsert procedure

```sql
DECLARE @Info [History].[TBL_WithdrawAction];

MERGE INTO Billing.Withdraw BW
USING @WithdrawInput AS Src ON BW.WithdrawID = Src.WithdrawID
WHEN NOT MATCHED THEN INSERT (...) VALUES (...)
WHEN MATCHED THEN UPDATE SET [CashoutStatusID] = Src.[CashoutStatusID], ...
OUTPUT
    Inserted.WithdrawID, Inserted.CashoutStatusID, ISNULL(Src.WithrawActionManagerID, Inserted.ManagerID),
    Inserted.Commission, Inserted.Approved, Inserted.ModificationDate, Inserted.Comment,
    Inserted.SessionID, Inserted.CashoutReasonID, Inserted.FundingID, Inserted.FundingTypeID,
    Inserted.Amount, Inserted.CurrencyID, Inserted.Fee, Inserted.AccountCurrencyID
INTO @Info (WithdrawID, CashoutStatusID, ManagerID, Commission, Approved, ModificationDate, Comment,
    SessionID, CashoutReasonID, FundingID, FundingTypeID, Amount, CurrencyID, Fee, AccountCurrencyID);

INSERT History.WithdrawAction (WithdrawID, CashoutStatusID, ManagerID, ...)
SELECT WithdrawID, CashoutStatusID, ManagerID, ...
FROM @Info;
```

### 8.2 Inspect the type column definitions

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable, c.column_id
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON c.user_type_id = t.user_type_id
WHERE tt.schema_id = SCHEMA_ID('History')
  AND tt.name = 'TBL_WithdrawAction'
ORDER BY c.column_id;
```

### 8.3 Review recent withdraw actions using the target history table

```sql
SELECT TOP 10
    wa.WithdrawID,
    wa.CashoutStatusID,
    cs.Name AS CashoutStatus,
    wa.Amount,
    wa.CurrencyID,
    wa.ModificationDate,
    wa.ManagerID
FROM History.WithdrawAction wa WITH (NOLOCK)
LEFT JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON wa.CashoutStatusID = cs.CashoutStatusID
ORDER BY wa.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TBL_WithdrawAction | Type: User Defined Type | Source: etoro/etoro/History/User Defined Types/History.TBL_WithdrawAction.sql*
