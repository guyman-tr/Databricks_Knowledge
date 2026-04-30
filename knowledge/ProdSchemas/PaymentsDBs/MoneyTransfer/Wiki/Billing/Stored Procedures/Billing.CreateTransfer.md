# Billing.CreateTransfer

> Creates a new money transfer record in Billing.Transfers with the initial status of New(0), returning the auto-generated TransferID to the caller.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TransferID (int) via SELECT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.CreateTransfer is the entry point for the money transfer lifecycle. It creates a new transfer record in the Billing.Transfers table, establishing the core identity and financial details of the transfer. Every transfer in the system begins with a call to this procedure.

This procedure is critical because it defines the initial state of every transfer. Without it, no transfer records would exist, and the entire Billing pipeline - status updates, routing, funding assignments, and post-transfer actions - would have nothing to operate on.

The procedure is called by the MoneyTransfer service (MoneyTransferUser has EXECUTE permission) when a customer initiates a fund movement. It accepts the transfer parameters (customer, currency, amount, funding types, external reference), inserts a single row with TransferStatusID = 0 (New), and immediately returns the auto-generated TransferID via SCOPE_IDENTITY(). Subsequent procedures (SaveRoutingInfo, SaveTransferOrigin, UpdateTransferStatus, etc.) then progressively populate and advance the transfer.

---

## 2. Business Logic

### 2.1 Initial State Assignment

**What**: Every new transfer starts in a known initial state with minimal required fields.

**Columns/Parameters Involved**: `TransferStatusID`, `CreateDate`, `ModificationDate`

**Rules**:
- TransferStatusID is hardcoded to 0 (New) - the caller cannot specify an initial status
- CreateDate and ModificationDate are auto-set to GETUTCDATE() via DEFAULT constraints
- ExReferenceID is the only optional-like field passed at creation; all other nullable columns (OriginFundingData, DestinationFundingData, FundingIds, DepotId, CountryId, ExtTransactionId) remain NULL
- The procedure uses SET NOCOUNT ON and returns the new TransferID via SELECT @ID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Application-generated GUID serving as the business key for this transfer. Must be unique (enforced by UNIQUE CLUSTERED index on Billing.Transfers.ReferenceID). Used by all subsequent UPDATE procedures as the lookup key. |
| 2 | @CID | INT | NO | - | VERIFIED | Customer identifier - the user initiating the transfer. Maps to Billing.Transfers.CID. Used for customer-scoped queries. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency of the transfer amount. Maps to Billing.Transfers.CurrencyID. No lookup table in this database; values managed externally (observed: 2=EUR, 3=GBP). |
| 4 | @OriginFundingTypeID | INT | NO | - | CODE-BACKED | Type of the source funding instrument (e.g., bank account type). Maps to Billing.Transfers.OriginFundingTypeID. Application-managed values (observed: 38). |
| 5 | @DestinationFundingTypeID | INT | NO | - | CODE-BACKED | Type of the destination funding instrument. Maps to Billing.Transfers.DestinationFundingTypeID. Application-managed values (observed: 33). |
| 6 | @Amount | MONEY | NO | - | VERIFIED | Transfer amount in the specified currency. Maps to Billing.Transfers.Amount. Set once at creation, never modified. |
| 7 | @ExReferenceID | VARCHAR(50) | NO | - | CODE-BACKED | External reference ID from the payment provider. Maps to Billing.Transfers.ExReferenceID. Prefix patterns observed: "TZ" and "TK" followed by GUID fragments. Can be updated later by SaveExtRefId. |
| 8 | (RETURN) TransferID | INT | - | - | VERIFIED | Auto-generated identity value from the INSERT, returned via SELECT SCOPE_IDENTITY(). Used by the caller to create subsequent records (e.g., PostTransferActions) and track the transfer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Billing.Transfers | Write (INSERT) | Creates a new row in the transfers table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the MoneyTransfer application service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreateTransfer (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | INSERT target - creates new transfer records |

### 6.2 Objects That Depend On This

No dependents found in the database. Called by the application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a new transfer
```sql
EXEC Billing.CreateTransfer
    @ReferenceID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @CID = 12345678,
    @CurrencyID = 2,
    @OriginFundingTypeID = 38,
    @DestinationFundingTypeID = 33,
    @Amount = 100.00,
    @ExReferenceID = 'TZa1b2c3d4e5f67890'
```

### 8.2 Create a transfer and capture the returned ID
```sql
DECLARE @NewTransferID INT
EXEC @NewTransferID = Billing.CreateTransfer
    @ReferenceID = NEWID(),
    @CID = 12345678,
    @CurrencyID = 2,
    @OriginFundingTypeID = 38,
    @DestinationFundingTypeID = 33,
    @Amount = 500.00,
    @ExReferenceID = 'TK_test_ref'
-- Note: TransferID is returned via SELECT, not RETURN value
```

### 8.3 Verify the created transfer
```sql
SELECT TransferID, ReferenceID, CID, Amount, TransferStatusID, CreateDate
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = @ReferenceID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CreateTransfer | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.CreateTransfer.sql*
