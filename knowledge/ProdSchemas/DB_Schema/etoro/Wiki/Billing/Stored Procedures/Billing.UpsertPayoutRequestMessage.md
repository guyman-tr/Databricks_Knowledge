# Billing.UpsertPayoutRequestMessage

> MERGE upsert for Billing.PayoutRequestMessages: inserts a new payout processing request or updates an existing one's status, step progress, and routing parameters; returns the new RequestID on INSERT. Used by Payout Service Gen 2.0 and Ixopay Service.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpsertPayoutRequestMessage` is the persistence layer for `Billing.PayoutRequestMessages`, a table introduced in Payout Service Gen 2.0 (PAYIL-1371) to support the next-generation payout processing flow via Azure Service Bus. When the Payout Service (or Ixopay Service) receives a payout job from the `{env}-payout-requests` queue, it creates a new PayoutRequestMessages record to track the processing state. As the request progresses through steps (provider API call, routing, completion), this procedure is called to update status, handle count, last success step, and routing parameters.

The procedure uses a MERGE on `@RequestID`:
- On INSERT (`@RequestID=-1` or no matching record): creates a new request record with all payout details.
- On UPDATE (existing @RequestID): updates status, processing counters, and routing metadata; `FundingTypeID` is preserved if not explicitly provided (ISNULL pattern); other tracking fields are fully overwritten.

Returns `@PayoutRequestID` via OUTPUT parameter on INSERT only (NULL on UPDATE). Changed from IF EXISTS to MERGE pattern by Shay Oren on 16/08/2020, with ProtocolParameters and DepotParameters added in the same change (PAYIL-1371).

Callers include: Old Payout Service (SQL_SecurePay), New Payout Service (PayoutUser), Ixopay Service, and NotificationGateway Service.

---

## 2. Business Logic

### 2.1 MERGE Upsert on RequestID

**What**: MERGE on `@RequestID` creates a new payout request record or updates an existing one.

**Columns/Parameters Involved**: `@RequestID`, `Billing.PayoutRequestMessages`

**Rules**:
- Default `@RequestID = -1`: -1 never matches an IDENTITY PK, so default always triggers INSERT
- WHEN MATCHED (update pass): Updates `Currency`, `CurrencyID`, `StatusID`, `HandleCount`, `LastSuccessStep`, `FundingTypeID` (ISNULL-preserved), `ProtocolParameters`, `DepotParameters`, `Modified=GETUTCDATE()`
- WHEN NOT MATCHED (insert pass): Inserts all payout metadata - PayoutID, WithdrawID, FundingID, Amount, Currency, CurrencyID, FundingTypeID, MassCorrelationID, CorrelationID, ManagerID, PayoutTypeID, StatusID, HandleCount, LastSuccessStep, ProtocolParameters, DepotParameters, Created/Modified=GETUTCDATE()
- OUTPUT: `CASE $action WHEN 'INSERT' THEN Inserted.RequestID END INTO @out`
- `SELECT TOP 1 @PayoutRequestID = id FROM @out` - returns new RequestID on INSERT, NULL on UPDATE

**Diagram**:
```
@RequestID=-1 (new request) or existing RequestID

  MERGE PayoutRequestMessages ON RequestID

  MATCHED (update):  UPDATE Currency, CurrencyID, StatusID, HandleCount,
                     LastSuccessStep, FundingTypeID[ISNULL], ProtocolParameters,
                     DepotParameters, Modified=GETUTCDATE()
                     @PayoutRequestID = NULL

  NOT MATCHED (new): INSERT all payout fields
                     @PayoutRequestID = new RequestID (SCOPE_IDENTITY via OUTPUT)
```

### 2.2 FundingTypeID ISNULL Preservation on Update

**What**: When updating an existing request, FundingTypeID is only changed if the caller provides a non-NULL value.

**Rules**:
- `FundingTypeID = ISNULL(@FundingTypeID, FundingTypeID)` in UPDATE SET clause
- All other updated fields (Currency, CurrencyID, StatusID, HandleCount, LastSuccessStep, ProtocolParameters, DepotParameters) are fully overwritten - not ISNULL-preserved
- This asymmetry means FundingTypeID is treated as immutable after initial set, while status/counter fields are always refreshed

### 2.3 HandleCount and LastSuccessStep: Resumable Processing

**What**: `@HandleCount` tracks retries; `@LastSuccessStep` enables the payout service to resume from the last completed checkpoint.

**Rules**:
- `@HandleCount` (default 1): Incremented by the Payout Service on each processing attempt; allows monitoring of retried requests
- `@LastSuccessStep` (VARCHAR(50)): Records the name of the last successfully completed step (e.g., provider API call, routing decision); enables crash recovery by resuming from the last checkpoint
- Both are overwritten on every UPDATE (not ISNULL-preserved)

### 2.4 Payout Service Architecture Context

**What**: PayoutRequestMessages records the Azure Service Bus-driven payout processing flow.

**Rules** (Source: Confluence PAYIL-1371 - "Payout Service Gen 2.0 - Changes"):
- Messages flow: Withdrawal request -> `{env}-payout-requests` Azure Service Bus queue -> Payout Service -> creates PayoutRequestMessages record -> processes via Ixopay / provider API -> `{env}-payout-toprovider` queue for provider submission
- `@PayoutID`: The PayoutProcess record ID driving this request
- `@WithdrawID`: The parent withdrawal request
- `@FundingID`: The funding method to pay out to
- `@MassCorrelationID`: Batch correlation ID for mass payout operations
- `@CorrelationID`: Individual request correlation ID for end-to-end tracing
- `@PayoutTypeID`: Type of payout (standard, instant, etc.)
- `@ProtocolParameters`: Provider-specific routing parameters (added PAYIL-1371)
- `@DepotParameters`: Depot routing configuration (added PAYIL-1371)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestID | INT | YES | -1 | CODE-BACKED | PK of `Billing.PayoutRequestMessages`. Default -1 triggers INSERT. Existing ID triggers UPDATE. |
| 2 | @PayoutID | INT | YES | -1 | CODE-BACKED | FK to the PayoutProcess record driving this payout request. -1 for unresolved. Only set on INSERT. |
| 3 | @WithdrawID | INT | YES | -1 | CODE-BACKED | FK to `Billing.Withdraw.WithdrawID`. The customer's withdrawal request being processed. Only set on INSERT. |
| 4 | @FundingID | INT | YES | NULL | CODE-BACKED | FK to `Billing.Funding.FundingID`. The funding method for the payout. ISNULL-preserved on UPDATE. |
| 5 | @Amount | DECIMAL | YES | NULL | CODE-BACKED | Payout amount in @CurrencyID denomination. Set on INSERT; not updated. |
| 6 | @Currency | VARCHAR(20) | YES | NULL | CODE-BACKED | Currency code string (e.g., "USD", "EUR"). Updated on UPDATE. |
| 7 | @CurrencyID | INT | YES | NULL | CODE-BACKED | Currency ID reference. Default 0. Updated on UPDATE. |
| 8 | @FundingTypeID | INT | YES | NULL | CODE-BACKED | Payment method type ID. ISNULL-preserved on UPDATE - once set, not overwritten unless explicitly provided. |
| 9 | @MassCorrelationID | VARCHAR(50) | YES | NULL | CODE-BACKED | Batch correlation ID for tracing mass payout operations. Set on INSERT. |
| 10 | @CorrelationID | VARCHAR(50) | YES | NULL | CODE-BACKED | Individual request correlation ID for end-to-end tracing across services. Set on INSERT. |
| 11 | @ManagerID | INT | YES | 0 | CODE-BACKED | Operator or service account ID initiating the payout. 0 = automated. Set on INSERT. |
| 12 | @PayoutTypeID | INT | YES | 0 | CODE-BACKED | Type of payout operation. 0 = standard. Set on INSERT. |
| 13 | @StatusID | INT | YES | 0 | CODE-BACKED | Processing status of the payout request. Overwritten on UPDATE. 0 = initial/pending. |
| 14 | @HandleCount | INT | YES | 1 | CODE-BACKED | Number of processing attempts. Default 1 (first attempt). Incremented by caller on retries. Overwritten on UPDATE. |
| 15 | @LastSuccessStep | VARCHAR(50) | YES | NULL | CODE-BACKED | Name of the last successfully completed processing step. Enables crash recovery / resume. Overwritten on UPDATE. |
| 16 | @ProtocolParameters | NVARCHAR(1000) | YES | NULL | CODE-BACKED | Provider-specific routing parameters (added PAYIL-1371, Shay Oren 16/08/2020). Overwritten on UPDATE. |
| 17 | @DepotParameters | NVARCHAR(1000) | YES | NULL | CODE-BACKED | Depot routing configuration parameters (added PAYIL-1371, Shay Oren 16/08/2020). Overwritten on UPDATE. |
| 18 | @PayoutRequestID | INT OUTPUT | YES | NULL | CODE-BACKED | OUTPUT parameter. Set to new RequestID via OUTPUT clause on INSERT. NULL on UPDATE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestID | Billing.PayoutRequestMessages | MERGE (UPDATE or INSERT) | Upserts payout request processing record |
| @WithdrawID | Billing.Withdraw | FK reference (INSERT) | Parent withdrawal request |
| @FundingID | Billing.Funding | FK reference (INSERT) | Funding method for the payout |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Old Payout Service (SQL_SecurePay) | Payout processing | Application call | Legacy payout service creates and updates payout request records |
| New Payout Service (PayoutUser) | Payout Service Gen 2.0 | Application call | Payout Service Gen 2.0 tracks Azure Service Bus-driven payout jobs |
| Ixopay Service (application) | Provider processing | Application call | Ixopay integration layer updates request status after provider API calls |
| NotificationGateway Service (application) | Provider callbacks | Application call | Updates status when provider sends a completion notification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpsertPayoutRequestMessage (procedure)
+-- Billing.PayoutRequestMessages (table) [MERGE - UPDATE or INSERT]
    +-- Billing.Withdraw (table) [FK - @WithdrawID]
    +-- Billing.Funding (table) [FK - @FundingID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutRequestMessages | Table | MERGE target: upserts payout request record by RequestID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout Service Gen 2.0 (application) | Application | Creates and tracks Azure Service Bus-driven payout jobs |
| Ixopay Service (application) | Application | Updates request status after Ixopay provider API interaction |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID ISNULL-preserved | Design | Only FundingTypeID uses ISNULL on update; all other update-path fields are fully overwritten |
| @PayoutRequestID NULL on UPDATE | Design | OUTPUT clause only emits on INSERT; callers must check if @PayoutRequestID is NULL to detect UPDATE vs. INSERT |
| No transaction wrapper | Design | MERGE runs in auto-commit; no explicit TRY/CATCH. MERGE is atomic by itself. |
| SET NOCOUNT ON | Performance | Suppresses row count messages from MERGE |

---

## 8. Sample Queries

### 8.1 Create a new payout request
```sql
DECLARE @ReqID INT;
EXEC Billing.UpsertPayoutRequestMessage
    @RequestID          = -1,
    @PayoutID           = 55001,
    @WithdrawID         = 98765,
    @FundingID          = 12345,
    @Amount             = 500.00,
    @Currency           = 'USD',
    @CurrencyID         = 1,
    @FundingTypeID      = 1,
    @CorrelationID      = 'abc-def-123',
    @ManagerID          = -1,
    @StatusID           = 0,
    @HandleCount        = 1,
    @PayoutRequestID    = @ReqID OUTPUT;
SELECT @ReqID AS NewRequestID;
```

### 8.2 Update status and step progress after provider call
```sql
EXEC Billing.UpsertPayoutRequestMessage
    @RequestID       = 77001,
    @StatusID        = 2,
    @HandleCount     = 2,
    @LastSuccessStep = 'ProviderApiCall',
    @Currency        = 'USD',
    @CurrencyID      = 1;
-- @PayoutRequestID OUTPUT will be NULL (UPDATE path)
```

### 8.3 Check all payout requests for a withdrawal
```sql
SELECT
    prm.RequestID,
    prm.PayoutID,
    prm.WithdrawID,
    prm.StatusID,
    prm.HandleCount,
    prm.LastSuccessStep,
    prm.CorrelationID,
    prm.Created,
    prm.Modified
FROM Billing.PayoutRequestMessages prm WITH (NOLOCK)
WHERE prm.WithdrawID = 98765
ORDER BY prm.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Payout Service Gen 2.0 - Changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1218937110) | Confluence | Full architecture: PAYIL-1371; Billing.PayoutRequestMessages table creation; callers (Old Payout Service/SQL_SecurePay, New Payout Service/PayoutUser, Ixopay Service, NGS); Azure Service Bus queues {env}-payout-requests and {env}-payout-toprovider; ProtocolParameters and DepotParameters added in same ticket |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.5/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpsertPayoutRequestMessage | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpsertPayoutRequestMessage.sql*
