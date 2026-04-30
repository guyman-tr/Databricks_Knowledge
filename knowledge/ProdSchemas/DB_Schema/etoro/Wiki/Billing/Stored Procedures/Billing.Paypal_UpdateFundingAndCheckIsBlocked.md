# Billing.Paypal_UpdateFundingAndCheckIsBlocked

> Resolves or creates the PayPal funding instrument by FundingHash, upserts the CustomerToFunding link, repairs the deposit's FundingID if needed, and returns the resolved FundingID plus whether the customer's funding is blocked - the newer PayPal deposit resolution path.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingHash (PayPal account hash) + @CID + @DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Paypal_UpdateFundingAndCheckIsBlocked` is the newer version of `Billing.Paypal_IsFundingBlockedAndUpdateDeposit`. Both procedures resolve a PayPal funding instrument and repair the deposit's FundingID, but this procedure differs in three key ways:

1. **Lookup key**: Uses `FundingHash` (a hashed identifier) instead of `Parameter` (raw account string) for a more privacy-safe and consistent lookup.
2. **CustomerToFunding upsert**: After resolving the funding record, this procedure ensures the Customer-to-Funding relationship exists by calling an upsert helper - the older procedure does not do this.
3. **IsBlocked source**: Returns `@IsBlocked` from `Billing.CustomerToFunding` (the customer-specific block flag), NOT from `Billing.Funding` directly. This means block decisions can be per-customer rather than per-instrument, allowing finer granularity.
4. **Proper transaction scope**: Uses an explicit BEGIN TRAN / COMMIT TRAN pattern, unlike the older procedure's anomalous standalone COMMIT.

This procedure is called during PayPal deposit processing callbacks where a proper CustomerToFunding record must be established and the customer-level block status matters.

---

## 2. Business Logic

### 2.1 Funding Record Resolution (Find or Create by FundingHash)

**What**: Resolves the Billing.Funding row using the hashed PayPal identifier.

**Columns Involved**: `Billing.Funding.FundingHash`, `Billing.Funding.FundingTypeID`, `Billing.Funding.FundingID`

**Rules**:
- SELECT FundingID FROM Billing.Funding WHERE FundingHash=@FundingHash AND FundingTypeID=3.
- FundingTypeID=3 is the PayPal constant.
- If no row found: INSERT INTO Billing.Funding (FundingTypeID=3, FundingHash=@FundingHash, ...). @FundingID=SCOPE_IDENTITY().
- If row found: @FundingID set from the existing row.

### 2.2 CustomerToFunding Upsert

**What**: Ensures the customer-to-funding relationship record exists, creating it if necessary.

**Columns Involved**: `Billing.CustomerToFunding.CID`, `Billing.CustomerToFunding.FundingID`, `Billing.CustomerToFunding.IsBlocked`

**Rules**:
- After resolving @FundingID, calls the CustomerToFunding upsert helper with @CID and @FundingID.
- If the CustomerToFunding row already exists, it is returned; if not, a new row is inserted with IsBlocked=0.
- @IsBlocked is read from the CustomerToFunding row (customer-level block), NOT from Billing.Funding.IsBlocked (instrument-level block).

### 2.3 Deposit FundingID Repair

**What**: Aligns the deposit's FundingID with the resolved PayPal funding instrument.

**Columns Involved**: `Billing.Deposit.FundingID`, `Billing.Deposit.DepositID`

**Rules**:
- UPDATE Billing.Deposit SET FundingID=@FundingID WHERE DepositID=@DepositID AND FundingID<>@FundingID.
- Conditional update: no-op if already correct. Repairs deposits initially created with a default or placeholder FundingID.

### 2.4 Transaction Handling

**What**: Wraps the multi-table write operations in an explicit transaction.

**Rules**:
- BEGIN TRAN / COMMIT TRAN wraps the Funding INSERT (if needed) + CustomerToFunding upsert + Deposit UPDATE.
- This is the correct pattern (vs. the older procedure's anomalous standalone COMMIT).
- On error in CATCH, the transaction is rolled back.

**Diagram**:
```
@FundingHash + @CID + @DepositID
  |
  BEGIN TRAN
  |
  SELECT FundingID FROM Billing.Funding
    WHERE FundingHash=@FundingHash AND FundingTypeID=3
  |
  Found?        Not Found?
   |               |
   Use existing    INSERT Billing.Funding (FundingTypeID=3, FundingHash=...)
   @FundingID      @FundingID=SCOPE_IDENTITY()
  |
  EXEC CustomerToFunding_Upsert(@CID, @FundingID)
    -> returns @IsBlocked (customer-level block from CustomerToFunding)
  |
  UPDATE Billing.Deposit SET FundingID=@FundingID
    WHERE DepositID=@DepositID AND FundingID<>@FundingID
  |
  COMMIT TRAN
  |
  RETURN @FundingID, @IsBlocked
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingHash | nvarchar(255) | NO | - | CODE-BACKED | Hashed PayPal account identifier. Matched against `Billing.Funding.FundingHash` WHERE FundingTypeID=3. Used as the privacy-safe lookup key instead of the raw Parameter string. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID. Used in the CustomerToFunding upsert to establish the customer-funding relationship and retrieve the customer-level IsBlocked status. |
| 3 | @DepositID | int | NO | - | CODE-BACKED | The deposit record to repair. Used in `UPDATE Billing.Deposit SET FundingID=@FundingID WHERE DepositID=@DepositID AND FundingID<>@FundingID`. |
| 4 | @FundingID | int | YES | OUTPUT | CODE-BACKED | OUTPUT: the resolved Billing.Funding.FundingID for this PayPal hash. Either an existing or newly-inserted ID. |
| 5 | @IsBlocked | bit | YES | OUTPUT | CODE-BACKED | OUTPUT: customer-level block status from Billing.CustomerToFunding.IsBlocked. 0=allowed, 1=blocked. Differs from the older procedure which reads IsBlocked from Billing.Funding directly. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingHash + FundingTypeID=3 | Billing.Funding | Read/Write (SELECT + INSERT) | Resolves or creates the PayPal funding instrument by hash. |
| @CID + @FundingID | Billing.CustomerToFunding | Write (Upsert via helper) | Ensures the customer-funding relationship exists; reads @IsBlocked from it. |
| @DepositID | [Billing.Deposit](../Tables/Billing.Deposit.md) | Write (UPDATE) | Repairs FundingID on the deposit if mismatched. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayPal billing application | - | EXEC | Called during PayPal deposit callback processing (newer path). No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Paypal_UpdateFundingAndCheckIsBlocked (procedure)
├── Billing.Funding (table) - SELECT + conditional INSERT
├── Billing.CustomerToFunding (table, via upsert helper) - READ IsBlocked
├── Billing.Deposit (table) - conditional UPDATE FundingID
└── CustomerToFunding_Upsert (helper procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT to resolve PayPal funding by FundingHash; INSERT if not found. |
| Billing.CustomerToFunding | Table | Upserted to establish customer-funding link; IsBlocked read from it. |
| [Billing.Deposit](../Tables/Billing.Deposit.md) | Table | Conditional UPDATE to repair FundingID. |
| CustomerToFunding_Upsert (helper) | Stored Procedure | Called to upsert CustomerToFunding and return IsBlocked. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayPal billing application | Application | Newer PayPal deposit callback path for funding resolution. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The FundingHash lookup on Billing.Funding benefits from an index on (FundingHash, FundingTypeID). The Deposit UPDATE uses the DepositID PK. The CustomerToFunding upsert targets (CID, FundingID) - the composite key of that table.

**Key difference vs. Paypal_IsFundingBlockedAndUpdateDeposit**:
- This procedure uses FundingHash (hashed), the older uses Parameter (raw string).
- This procedure gets IsBlocked from CustomerToFunding (customer-level), the older gets it from Funding (instrument-level).
- This procedure has proper BEGIN/COMMIT TRAN; the older has anomalous COMMIT without BEGIN.
- This procedure upserts CustomerToFunding; the older does not.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Resolve PayPal funding by hash and check block status

```sql
DECLARE @FundingID INT, @IsBlocked BIT;
EXEC Billing.Paypal_UpdateFundingAndCheckIsBlocked
    @FundingHash = 'a3f8b2c1d4e5...',
    @CID         = 12345,
    @DepositID   = 987654,
    @FundingID   = @FundingID OUTPUT,
    @IsBlocked   = @IsBlocked OUTPUT;
SELECT @FundingID AS FundingID, @IsBlocked AS IsBlocked;
-- @IsBlocked=0: proceed; 1: payment is blocked at customer level
```

### 8.2 Compare the two PayPal funding resolution procedures

```sql
-- Old path: uses Billing.Funding.IsBlocked
-- New path: uses Billing.CustomerToFunding.IsBlocked
SELECT
    f.FundingID,
    f.FundingHash,
    f.IsBlocked AS FundingLevelBlock,
    ctf.IsBlocked AS CustomerLevelBlock
FROM Billing.Funding f WITH (NOLOCK)
LEFT JOIN Billing.CustomerToFunding ctf WITH (NOLOCK)
    ON ctf.FundingID = f.FundingID AND ctf.CID = 12345
WHERE f.FundingTypeID = 3
  AND f.FundingHash = 'a3f8b2c1d4e5...';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Paypal_UpdateFundingAndCheckIsBlocked | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Paypal_UpdateFundingAndCheckIsBlocked.sql*
