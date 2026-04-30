# AffiliateCommission.InsertCredit

> Atomically creates a credit record (deposit/chargeback) with deduplication through CreditAccountMapping, generating a CreditID via IDENTITY and inserting Credit + CreditCommission in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CreditID OUTPUT - generated or existing CreditID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertCredit is the primary data writer for credit events (deposits, chargebacks) entering the affiliate commission system. It implements a two-phase deduplication pattern: first it attempts to insert into CreditAccountMapping (the dedup registry using the natural key of AccountTypeID + TransactionID + AccountID + DateCreated). If successful (new record), it generates a CreditID via SCOPE_IDENTITY() and creates Credit + CreditCommission records. If the mapping already exists (duplicate), it retrieves the existing CreditInternalID without creating new records.

This procedure exists because credit events can arrive multiple times from payment systems. The CreditAccountMapping table provides the deduplication barrier, and the generated CreditID becomes the foreign key for both Credit and CreditCommission. The entire operation is wrapped in XACT_ABORT + explicit transaction for atomicity.

The @CreditID OUTPUT parameter always returns a valid CreditID - either newly generated or existing. This allows the caller to proceed with event creation regardless of whether the credit was new or duplicate.

---

## 2. Business Logic

### 2.1 CreditAccountMapping Deduplication

**What**: Uses a natural key in CreditAccountMapping to prevent duplicate credit records.

**Columns/Parameters Involved**: `@AccountTypeID`, `@TransactionID`, `@AccountID`, `@TrackingDate`

**Rules**:
- INSERT with WHERE NOT EXISTS on (AccountTypeID, TransactionID, AccountID, DateCreated=@TrackingDate)
- If @@ROWCOUNT > 0: new mapping, CreditID = SCOPE_IDENTITY(), proceed to create Credit + CreditCommission
- If @@ROWCOUNT = 0: duplicate detected, retrieve existing CreditInternalID from CreditAccountMapping
- @CreditID OUTPUT is set in both paths, ensuring the caller always gets a valid ID
- SET XACT_ABORT ON ensures any error rolls back the entire transaction

### 2.2 Atomic Credit + Commission Insert

**What**: Creates Credit and CreditCommission records in a single transaction when a new credit is detected.

**Columns/Parameters Involved**: `@AffiliateCommission` (CreditCommissionType TVP)

**Rules**:
- Credit record includes financial data (Amount, CreditDate, CreditTypeID) and attribution (CID, providers, CountryID)
- CreditCommission rows come from the TVP (AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID)
- ProductID supports ISA MoneyFarm commission (PART-5458)
- Error handling: conditional ROLLBACK/COMMIT for nested transactions, always re-THROW

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditTypeID | tinyint (IN) | NO | - | CODE-BACKED | Credit type: 1=Deposit, 4/5=Chargeback. Determines processing rules. |
| 2 | @CreditDate | datetime (IN) | NO | - | CODE-BACKED | When the credit event occurred. |
| 3 | @Amount | float (IN) | NO | - | CODE-BACKED | Credit amount (positive for deposits, negative for chargebacks). |
| 4 | @Valid | bit (IN) | NO | - | CODE-BACKED | Whether the credit is eligible for commission: 1=eligible, 0=disqualified. |
| 5 | @IsFirstDeposit | bit (IN) | NO | - | CODE-BACKED | Whether this is the customer's first deposit. Critical for CPA qualification. |
| 6 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID. |
| 7 | @ProviderID | bigint (IN) | NO | - | CODE-BACKED | Current provider. |
| 8 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | Original provider. |
| 9 | @RealProviderID | bigint (IN) | NO | - | CODE-BACKED | Actual executing provider. |
| 10 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country. |
| 11 | @TrackingDate | datetime (IN) | NO | - | CODE-BACKED | When the credit was first tracked. Also used as DateCreated in CreditAccountMapping for dedup. |
| 12 | @AccountID | varchar(50) (IN) | NO | - | CODE-BACKED | Account identifier for dedup. For options (AccountTypeID=2) this is GCID; for standard accounts this is CID. |
| 13 | @TransactionID | varchar(50) (IN) | NO | - | CODE-BACKED | External transaction identifier from the payment system. Part of the dedup natural key. |
| 14 | @AccountTypeID | int (IN) | NO | - | CODE-BACKED | Account type for dedup. 2=Options (uses GCID), other values use CID. |
| 15 | @ProductID | varchar(50) (IN) | YES | NULL | CODE-BACKED | ISA product identifier for ISA MoneyFarm commissions. Added PART-5458. |
| 16 | @AffiliateCommission | CreditCommissionType (IN, TVP) | NO | - | CODE-BACKED | TVP containing per-affiliate, per-tier commission rows. |
| 17 | @CreditID | bigint (OUTPUT) | NO | - | CODE-BACKED | Generated (new) or existing CreditID. Always set - caller can use for event creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditAccountMapping | WRITE (INSERT) + READ (EXISTS, SELECT) | Dedup registry; generates CreditID via IDENTITY |
| - | AffiliateCommission.Credit | WRITE (INSERT) | Creates the credit record with financial and attribution data |
| - | AffiliateCommission.CreditCommission | WRITE (INSERT) | Creates commission rows from TVP |
| @AffiliateCommission | AffiliateCommission.CreditCommissionType | TVP | Table-valued parameter type for commission rows |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the credit processing pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertCredit (procedure)
+-- AffiliateCommission.CreditAccountMapping (table)
+-- AffiliateCommission.Credit (table)
+-- AffiliateCommission.CreditCommission (table)
+-- AffiliateCommission.CreditCommissionType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditAccountMapping | Table | INSERT for dedup + SCOPE_IDENTITY() for CreditID generation |
| AffiliateCommission.Credit | Table | INSERT with generated CreditID |
| AffiliateCommission.CreditCommission | Table | INSERT from TVP with generated CreditID |
| AffiliateCommission.CreditCommissionType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit processing pipeline) | External | Persists processed credit events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT | Setting | Any error automatically rolls back the transaction |
| Transaction | TRAN | Atomic insert of CreditAccountMapping + Credit + CreditCommission |

---

## 8. Sample Queries

### 8.1 Insert a credit (deposit)
```sql
DECLARE @CommData AffiliateCommission.CreditCommissionType
INSERT @CommData (AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID)
VALUES (3, 5.00, 1, 0, 0, 1)

DECLARE @NewCreditID BIGINT
EXEC [AffiliateCommission].[InsertCredit]
    @CreditTypeID = 1, @CreditDate = '2026-04-12', @Amount = 100.00,
    @Valid = 1, @IsFirstDeposit = 1, @CID = 12345,
    @ProviderID = 1, @OriginalProviderID = 1, @RealProviderID = 1,
    @CountryID = 1, @TrackingDate = '2026-04-12',
    @AccountID = '12345', @TransactionID = 'DEP-999', @AccountTypeID = 1,
    @AffiliateCommission = @CommData, @CreditID = @NewCreditID OUTPUT

SELECT @NewCreditID AS GeneratedCreditID
```

### 8.2 Check if a credit was already created
```sql
SELECT CreditInternalID, AccountTypeID, TransactionID, AccountID, DateCreated
FROM [AffiliateCommission].[CreditAccountMapping] WITH (NOLOCK)
WHERE TransactionID = 'DEP-999'
```

### 8.3 View credit with commission breakdown
```sql
SELECT c.CreditID, c.CID, c.Amount, c.CreditTypeID, c.IsFirstDeposit,
       cc.AffiliateID, cc.Commission, cc.Tier
FROM [AffiliateCommission].[Credit] AS c WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK)
    ON c.CreditID = cc.CreditID
WHERE c.CreditID = 100
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-5458: ISA MoneyFarm support (2026-01-29)
- PART-3405: CreditAccountMapping-based CreditID generation (2025-01-08, 2025-02-23)
- PART-2448: CPA New Compensation Design + CountryID (2023-12-17)
- PART-294: Added return value for FTDE fix (2022-06-07)
- Unlabeled: Added XACT_ABORT ON, EXISTS check (2021-12-26, 2022-02-28)
- Unlabeled: Fixed wrong datatype AccountTypeID & AccountID (2025-03-20)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertCredit | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertCredit.sql*
