# Billing.DepositFundingUpdate

> Updates a deposit's linked payment instrument by finding or creating the matching Billing.Funding record via hash-based deduplication, then upserts the customer-to-funding link - the post-deposit payment data correction procedure.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @depositID identifies the deposit; @fundingData + @fundingTypeID identify or create the funding record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositFundingUpdate` corrects or updates the payment instrument (`FundingID`) linked to an existing deposit. It handles the case where a payment provider returns updated or corrected card/account data after a deposit has already been created - for example, when a card token is normalized, a bank account number is formatted differently, or an instrument is re-tokenized by the provider.

The procedure uses hash-based deduplication to avoid creating duplicate funding records: it computes `Billing.FundingHash(CONVERT(XML, @fundingData))` and checks if a `Billing.Funding` record with that exact hash and FundingType already exists. If it does, the deposit is simply re-linked to the existing record. If it does not, a new `Billing.Funding` record is created via `Billing.FundingAdd`, then the deposit is linked to the new record.

After updating the `FundingID` on the deposit, the procedure also ensures the customer's `Billing.CustomerToFunding` link is up to date via `Billing.CustomerToFunding_Upsert`. This synchronizes the customer's saved payment methods list with the updated instrument.

The hash function was changed from SQL Server `CHECKSUM()` to `HASHBYTES()` on 04/04/2018 (Ran Ovadia, FB 52081) to eliminate the collision risk inherent in 32-bit checksums. The original comment `Cast(FundingData AS NVarChar(Max))=@fundingData` comparison was also removed at that time as redundant once HASHBYTES provides sufficient collision resistance.

Created by Geri Reshef on 14/11/2017 (ticket 49493 - "DB: Query Optimization SP").

---

## 2. Business Logic

### 2.1 Hash-Based Funding Record Lookup

**What**: Checks if a Billing.Funding record with the exact same payment data already exists, using the FundingHash computed column for efficient deduplication.

**Columns/Parameters Involved**: `@fundingData`, `@fundingTypeID`, `@existingFundingID`, `Billing.Funding.FundingHash`, `Billing.Funding.FundingTypeID`

**Rules**:
- `SELECT @existingFundingID = FundingID FROM Billing.Funding WHERE FundingHash = Billing.FundingHash(CONVERT(XML, @fundingData)) AND FundingTypeID = @fundingTypeID`
- `Billing.FundingHash` is a CLR or scalar function that computes a HASHBYTES-based fingerprint of the XML-formatted payment data
- `@existingFundingID` initializes to 0; a result > 0 means the funding record already exists
- Two conditions: same hash AND same FundingTypeID (ensures a credit card hash doesn't accidentally match an ACH hash)
- No NOLOCK hint on this SELECT - consistent read to avoid race conditions when creating new records

### 2.2 Conditional Create or Link

**What**: Either links the deposit to an existing funding record or creates a new one.

**Columns/Parameters Involved**: `@existingFundingID`, `@fundingID`, `Billing.Deposit.FundingID`, `Billing.FundingAdd`

**Rules**:
- **If @existingFundingID > 0 (found)**: `UPDATE Billing.Deposit SET FundingID=@existingFundingID WHERE DepositID=@depositID`
- **If @existingFundingID = 0 (not found)**:
  1. `EXEC Billing.FundingAdd @fundingID OUTPUT, @fundingTypeID, @fundingData` -> creates new Billing.Funding record
  2. `UPDATE Billing.Deposit SET FundingID=@fundingID WHERE DepositID=@depositID`
- In both paths, the deposit ends up pointing to the correct FundingID

### 2.3 CustomerToFunding Upsert

**What**: Synchronizes the customer's saved payment methods with the updated funding instrument.

**Columns/Parameters Involved**: `@CID`, `@fundingIDForCTF`, `Billing.CustomerToFunding_Upsert`

**Rules**:
- `SELECT @CID=CID, @fundingIDForCTF=FundingID FROM Billing.Deposit WHERE DepositID=@depositID`
- Reads the FundingID just set in step 2.2 (the new or existing FundingID)
- `EXEC Billing.CustomerToFunding_Upsert @CID, @fundingIDForCTF` - inserts or updates the CustomerToFunding link
- Ensures the customer's payment method list reflects the updated funding instrument

### 2.4 Transaction and Error Handling

**What**: Wraps all operations in a single atomic transaction.

**Rules**:
- `BEGIN TRY / BEGIN TRANSACTION ... COMMIT TRAN`
- `BEGIN CATCH`: IF @@TRANCOUNT=1 -> ROLLBACK; IF @@TRANCOUNT>1 -> COMMIT (nested transaction pattern)
- `THROW` - re-raises the original exception to the caller
- All three DML operations (Billing.Deposit UPDATE, potential Billing.FundingAdd, Billing.CustomerToFunding_Upsert) are rolled back atomically on failure

**Diagram**:
```
@depositID + @fundingData + @fundingTypeID
         |
  SELECT FundingID WHERE FundingHash = Billing.FundingHash(XML(@fundingData))
  AND FundingTypeID = @fundingTypeID
         |
  @existingFundingID > 0?
  YES -> UPDATE Billing.Deposit SET FundingID=@existingFundingID
  NO  -> EXEC Billing.FundingAdd -> new @fundingID
      -> UPDATE Billing.Deposit SET FundingID=@fundingID
         |
  SELECT @CID, @fundingIDForCTF FROM Billing.Deposit
         |
  EXEC Billing.CustomerToFunding_Upsert @CID, @fundingIDForCTF
         |
  COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @depositID | INT | NO | - | CODE-BACKED | The deposit whose FundingID needs to be updated. Used to UPDATE Billing.Deposit and to read the CID for the CustomerToFunding upsert. |
| 2 | @fundingData | NVARCHAR(MAX) | NO | - | CODE-BACKED | The payment instrument data as an XML string. Converted to XML for the FundingHash computation. Contains the funding-type-specific fields (e.g., card token, bank account number, wallet identifier). |
| 3 | @fundingTypeID | INT | NO | - | CODE-BACKED | The payment method type (e.g., 1=CreditCard, 29=ACH). Used together with the FundingHash to uniquely identify the funding record and as a parameter for Billing.FundingAdd if a new record must be created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Hash lookup | Billing.Funding | Read | Finds existing funding record by FundingHash + FundingTypeID. See [Billing.Funding](../Tables/Billing.Funding.md). |
| FundingID update | Billing.Deposit | Read + Update | Reads CID, updates FundingID to the found/created record. See [Billing.Deposit](../Tables/Billing.Deposit.md). |
| New funding creation | Billing.FundingAdd | Stored Procedure call | Creates new Billing.Funding record when no matching hash exists. |
| Customer link sync | Billing.CustomerToFunding_Upsert | Stored Procedure call | Upserts the customer's saved payment method link after the deposit's FundingID is updated. |
| Hash computation | Billing.FundingHash | Scalar function | Computes HASHBYTES fingerprint of XML payment data for deduplication. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by payment gateway integration code when a provider returns updated or corrected payment instrument data after deposit creation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositFundingUpdate (procedure)
├── Billing.Funding (table)
├── Billing.Deposit (table)
├── Billing.FundingAdd (procedure) [called if new funding needed]
├── Billing.CustomerToFunding_Upsert (procedure)
└── Billing.FundingHash (scalar function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Read (hash lookup for existing FundingID by FundingHash + FundingTypeID) |
| Billing.Deposit | Table | Read (CID retrieval) + Update (SET FundingID) |
| Billing.FundingAdd | Stored Procedure | Creates new Billing.Funding record when no existing hash match found |
| Billing.CustomerToFunding_Upsert | Stored Procedure | Upserts customer-to-funding link after FundingID is updated |
| Billing.FundingHash | Scalar function | Computes hash fingerprint of @fundingData XML for deduplication |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment gateway integration | External (App) | Called when provider returns updated card/account data post-deposit |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update a deposit's funding instrument with new card data

```sql
EXEC Billing.DepositFundingUpdate
    @depositID    = 12345678,
    @fundingData  = N'<CreditCard><Token>tok_new_xyz</Token><Last4>1234</Last4></CreditCard>',
    @fundingTypeID = 1;  -- CreditCard
```

### 8.2 Check the deposit's current and potential new FundingID before calling

```sql
-- Current state
SELECT d.DepositID, d.FundingID, d.CID,
       f.FundingTypeID,
       CAST(f.FundingData AS NVARCHAR(MAX)) AS FundingData
FROM Billing.Deposit d WITH (NOLOCK)
    JOIN Billing.Funding f WITH (NOLOCK)
        ON d.FundingID = f.FundingID
WHERE d.DepositID = 12345678;

-- Check if the new funding data already exists (hash lookup)
DECLARE @newData NVARCHAR(MAX) = N'<CreditCard><Token>tok_new_xyz</Token><Last4>1234</Last4></CreditCard>';
SELECT FundingID, FundingTypeID
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingHash = Billing.FundingHash(CONVERT(XML, @newData))
  AND FundingTypeID = 1;
```

### 8.3 Verify the update after calling

```sql
SELECT d.DepositID, d.FundingID,
       CAST(f.FundingData AS NVARCHAR(MAX)) AS NewFundingData,
       ctf.CustomerFundingStatusID
FROM Billing.Deposit d WITH (NOLOCK)
    JOIN Billing.Funding f WITH (NOLOCK)
        ON d.FundingID = f.FundingID
    LEFT JOIN Billing.CustomerToFunding ctf WITH (NOLOCK)
        ON d.CID = ctf.CID AND d.FundingID = ctf.FundingID
WHERE d.DepositID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Ticket 49493 (Geri Reshef, 14/11/2017): "DB: Query Optimization SP - [Billing].[DepositFundingUpdate]". FB 52081 (Ran Ovadia, 04/04/2018): changed FundingHash from CHECKSUM to HASHBYTES for collision resistance.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 2 Jira/FB tickets (49493, FB 52081) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositFundingUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositFundingUpdate.sql*
