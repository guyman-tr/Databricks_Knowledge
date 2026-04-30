# History.PWMBAddAccountRequest

> Status transition log for Portfolio Wealth Management Bridge (PWMB) add-account requests, capturing each status change as a separate row to provide a complete audit trail of the bank account authorization workflow.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (ExternalTransactionID is indexed but not unique here) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 2 (1 on CID + 1 on ExternalTransactionID) |

---

## 1. Business Meaning

`History.PWMBAddAccountRequest` is an append-only status transition log for the PWMB (Portfolio Wealth Management Bridge) add-bank-account workflow. The live table `Billing.PWMBAddAccountRequest` maintains one row per request (identified by `ExternalTransactionID`) with only the current state - this History table captures every status transition, providing the complete timeline of each request from creation through resolution.

The PWMB workflow allows customers to link their bank accounts for use with eToro's portfolio/wealth management services. When a customer initiates this process, it flows through the following states (Dictionary.PWMBAddAccountRequestStatus):
1. **Created** - request initiated
2. **SentToBankAuth** - sent to bank authorization system
3. **BankAuthAddAccountSuccess** - bank confirmed the account
4. **BankAuthAddAccountFailed** - bank rejected the account
5. **FundingUpdated** - eToro's funding record (Billing.Funding) has been created/linked
6. **HasNameConflict** - name on bank account doesn't match eToro account
7. **NoNameConflict** - name verification passed
8. **Technical** - technical error occurred

From live data, a typical successful flow transitions: Created (1) -> SentToBankAuth (2) -> BankAuthAddAccountSuccess (3) -> FundingUpdated (5) + HasNameConflict/NoNameConflict (6/7) - all within seconds.

With 21,153 rows and most recent data from October 2023, this represents several years of account addition requests across all customers who used the PWMB flow.

---

## 2. Business Logic

### 2.1 Append-Only Status Log vs. Live Table

**What**: Unlike the live table (which has one row per transaction with the current state), this table appends one row per status transition.

**Columns/Parameters Involved**: `ExternalTransactionID`, `Status`, `InsertedTime`, `LastModificationTime`

**Rules**:
- No PK constraint - `ExternalTransactionID` is NOT unique in this table (multiple rows per transaction, one per status)
- `InsertedTime` stays constant across all rows for the same transaction (set when request was first created)
- `LastModificationTime` updates with each status change
- `FundingID` is NULL until a funding record is created (Status=5=FundingUpdated); it's populated once Billing.Funding is allocated
- Each row represents a point-in-time snapshot: the status the request was in at that moment
- To see the current state: query Billing.PWMBAddAccountRequest by ExternalTransactionID

### 2.2 Status Transition Workflow

**What**: Requests follow a defined state machine through the PWMB bank authorization process.

**Columns/Parameters Involved**: `Status`, `FundingID`, `ExternalTransactionID`

**Rules**:
- Status values are FK to Dictionary.PWMBAddAccountRequestStatus:
  - 1=Created: initial state when request is inserted
  - 2=SentToBankAuth: request forwarded to bank's authorization API
  - 3=BankAuthAddAccountSuccess: bank confirmed account ownership
  - 4=BankAuthAddAccountFailed: bank rejected the request
  - 5=FundingUpdated: Billing.Funding record created/linked (FundingID becomes non-NULL)
  - 6=HasNameConflict: name mismatch between bank account and eToro account
  - 7=NoNameConflict: name verification passed
  - 8=Technical: technical error in the processing pipeline
- Observed rapid transitions (within milliseconds) suggest automated state machine processing
- ExternalTransactionID links to the bank's external reference for this authorization request

### 2.3 Billing Procedures Integration

**What**: Three procedures manage the lifecycle of PWMB requests in the live table; this history table captures the audit trail.

**Columns/Parameters Involved**: All

**Rules**:
- `Billing.InsertPWMBAddAccountRequest`: creates the initial request (Status=1=Created)
- `Billing.UpdatePWMBAddAccountRequest`: advances the request through status transitions
- `Billing.GetPWMBAddAccountRequest`: retrieves current state from live table
- Each UpdatePWMBAddAccountRequest call that changes status should also insert a history row here

---

## 3. Data Overview

21,153 rows. Multiple rows per ExternalTransactionID (one per status transition). Data through October 2023.

| CID | FundingID | Status | ExternalTransactionID | InsertedTime | LastModificationTime |
|---|---|---|---|---|---|
| 12563033 | NULL | 1 (Created) | 1024761123 | 2023-10-26 13:50:33 | 2023-10-26 13:50:33 |
| 12563033 | NULL | 2 (SentToBankAuth) | 1024761123 | 2023-10-26 13:50:33 | 2023-10-26 13:50:33 |
| 12563033 | NULL | 3 (BankAuthSuccess) | 1024761123 | 2023-10-26 13:50:33 | 2023-10-26 13:50:34 |
| 12563033 | 1664434 | 5 (FundingUpdated) | 1024761123 | 2023-10-26 13:50:33 | 2023-10-26 13:50:34 |
| 12563033 | 1664434 | 6 (HasNameConflict) | 1024761123 | 2023-10-26 13:50:33 | 2023-10-26 13:50:35 |

*Complete status history for one request: Created->SentToBankAuth->BankAuthSuccess->FundingUpdated->HasNameConflict, all within ~2 seconds.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. FK to Customer.CustomerStatic(CID) via the live Billing.PWMBAddAccountRequest table. Identifies which customer initiated this PWMB add-account request. Indexed (IX_HistoryPWMBAddAccountRequest_CID) for per-customer lookup. |
| 2 | FundingID | int | YES | - | VERIFIED | Billing.Funding record ID created for this bank account. NULL until Status=5 (FundingUpdated) - populated once eToro's billing system allocates a funding record. FK to Billing.Funding(FundingID) via live table. |
| 3 | Status | int | NO | - | VERIFIED | Current status at this point in the workflow. FK to Dictionary.PWMBAddAccountRequestStatus: 1=Created, 2=SentToBankAuth, 3=BankAuthAddAccountSuccess, 4=BankAuthAddAccountFailed, 5=FundingUpdated, 6=HasNameConflict, 7=NoNameConflict, 8=Technical. |
| 4 | ExternalTransactionID | varchar(15) | YES | - | VERIFIED | The external bank system's transaction/reference ID for this account addition request. Links eToro's request to the bank's authorization record. Not unique in this history table (one row per status transition). Indexed (IX_HistoryPWMBAddAccountRequest_ExternalTransactionID) for lookup by external reference. NOTE: NOT NULL in the live table but nullable in this history table. |
| 5 | InsertedTime | datetime | YES | - | VERIFIED | UTC timestamp when the original PWMB request was first created. Consistent across all history rows for the same request (preserves original creation time). Set via DEFAULT getutcdate() on the live table at initial insert. |
| 6 | LastModificationTime | datetime | YES | - | VERIFIED | UTC timestamp when this specific status was recorded. Changes with each status transition. Provides the exact timing of each state change in the workflow. Set via DEFAULT getutcdate() on the live table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit (FK via live table) | The customer who initiated the PWMB request |
| FundingID | Billing.Funding | Implicit (FK via live table) | The funding record created for the linked bank account |
| Status | Dictionary.PWMBAddAccountRequestStatus | Implicit | Status code lookup (8 values) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpdatePWMBAddAccountRequest | INSERT | WRITER | Appends a status transition row when request state changes |
| Billing.InsertPWMBAddAccountRequest | INSERT | WRITER | Appends initial Created row when request is first submitted |
| Billing.GetPWMBAddAccountRequest | SELECT | READER | May query this table for historical status trace |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PWMBAddAccountRequest (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetPWMBAddAccountRequest | Stored Procedure | READER - retrieves request history |
| Billing.InsertPWMBAddAccountRequest | Stored Procedure | WRITER - creates initial row |
| Billing.UpdatePWMBAddAccountRequest | Stored Procedure | WRITER - appends status transition rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_HistoryPWMBAddAccountRequest_CID | NONCLUSTERED | CID ASC | - | - | Active |
| IX_HistoryPWMBAddAccountRequest_ExternalTransactionID | NONCLUSTERED | ExternalTransactionID ASC | - | - | Active |

*No clustered index (heap table). FILLFACTOR=95 on both indexes. The ExternalTransactionID index is the primary lookup for tracing a specific transaction's history.*

### 7.2 Constraints

None (no PK, no FK constraints, no defaults on this history table - constraints enforced on the live Billing table).

---

## 8. Sample Queries

### 8.1 Full status history for a specific transaction

```sql
SELECT CID, FundingID, Status, ExternalTransactionID, InsertedTime, LastModificationTime
FROM History.PWMBAddAccountRequest WITH (NOLOCK)
WHERE ExternalTransactionID = @ExternalTransactionID
ORDER BY LastModificationTime ASC
```

### 8.2 All requests for a specific customer with status timeline

```sql
SELECT h.ExternalTransactionID, h.Status, s.Name AS StatusName,
    h.FundingID, h.InsertedTime, h.LastModificationTime
FROM History.PWMBAddAccountRequest h WITH (NOLOCK)
JOIN Dictionary.PWMBAddAccountRequestStatus s ON s.ID = h.Status
WHERE h.CID = @CID
ORDER BY h.ExternalTransactionID, h.LastModificationTime ASC
```

### 8.3 Failed requests in the last 30 days

```sql
SELECT CID, ExternalTransactionID, Status, InsertedTime, LastModificationTime
FROM History.PWMBAddAccountRequest WITH (NOLOCK)
WHERE Status IN (4, 8)  -- BankAuthAddAccountFailed, Technical
  AND LastModificationTime >= DATEADD(DAY, -30, GETDATE())
ORDER BY LastModificationTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PWMBAddAccountRequest | Type: Table | Source: etoro/etoro/History/Tables/History.PWMBAddAccountRequest.sql*
