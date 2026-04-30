# Billing.CashoutProcessToWesternUnion

> Western Union wrapper for Billing.CashoutProcess: processes a legacy cashout as a Western Union payment (FundingTypeID=5) and records the Western Union transfer details (CountryID, MTCN, City) in Billing.WesternUnionToCashout.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN @Answer (from CashoutProcess), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutProcessToWesternUnion` is the Western Union-specific wrapper in the CashoutProcess family. It calls `Billing.CashoutProcess` with FundingTypeID=5 (Western Union) and then inserts a record into `Billing.WesternUnionToCashout` with the transfer details: the destination country, the Money Transfer Control Number (MTCN), and the destination city. This is a legacy procedure operating on the ~2007-2011 Billing.Cashout table.

The MTCN is the unique identifier assigned by Western Union to each money transfer - the recipient uses it to collect the cash at a Western Union agent location.

---

## 2. Business Logic

### 2.1 Wrapper Pattern

**What**: Calls CashoutProcess with FundingTypeID=5 (Western Union), then records the WU transfer details.

**Rules**:
- `EXECUTE @Answer = Billing.CashoutProcess(@CashoutID, ..., 5 /* WesternUnion */, ...)`
- If @Answer != 0: RETURN @Answer.
- INSERT INTO Billing.WesternUnionToCashout (CashoutID, CountryID, MTCN, City).
- On INSERT error: ROLLBACK + RAISERROR(60000) + RETURN @LocalError.
- On success: COMMIT + RETURN 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to process. Passed to CashoutProcess and written to WesternUnionToCashout. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Operations manager authorizing the processing. Passed to CashoutProcess. |
| 3 | @ProcessCurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the Western Union payment. Passed to CashoutProcess. |
| 4 | @CashoutActionStatusID | INTEGER | NO | - | CODE-BACKED | Legacy parameter passed to CashoutProcess but not used there (hardcodes 2). |
| 5 | @CountryID | INTEGER | NO | - | CODE-BACKED | Destination country for the Western Union transfer. Written to Billing.WesternUnionToCashout.CountryID. References a country dictionary table. |
| 6 | @MTCN | VARCHAR(15) | NO | - | CODE-BACKED | Money Transfer Control Number - the unique WU tracking number assigned to this transfer. The recipient presents this to collect cash at a WU agent. Written to Billing.WesternUnionToCashout.MTCN. Max 15 characters. |
| 7 | @City | NVARCHAR(50) | NO | - | CODE-BACKED | Destination city where the customer will collect the Western Union transfer. Stored as NVARCHAR to support non-Latin city names. Written to Billing.WesternUnionToCashout.City. Max 50 characters. |
| 8 | @ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate for currency conversion. Passed to CashoutProcess. |
| 9 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Processing description. Passed to CashoutProcess for history and balance records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Billing.CashoutProcess | EXEC (callee) | Core processing with FundingTypeID=5 |
| @CashoutID + @CountryID + @MTCN + @City | Billing.WesternUnionToCashout | WRITER | Records WU transfer details for this cashout |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutProcessToWesternUnion (procedure)
+-- Billing.CashoutProcess (procedure)        [EXEC - core processing with FundingTypeID=5]
+-- Billing.WesternUnionToCashout (table)     [INSERT - WU transfer details for cashout]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcess | Stored Procedure | EXEC - core cashout processing (FundingTypeID=5) |
| Billing.WesternUnionToCashout | Table | INSERT - records WU country, MTCN, and city for this cashout |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **FundingTypeID=5 hardcoded**: This wrapper always sets Western Union (5) as the funding type.
- **Most parameters of the five wrappers**: This wrapper has 9 parameters vs. 7 for the other wrappers, because Western Union transfers require the MTCN, CountryID, and City that are unique to cash pickup transfers.
- **NVARCHAR for City**: City uses NVARCHAR(50) to support international city names with non-Latin characters - the only NVARCHAR parameter across the CashoutProcessTo* wrapper family.
- **Part of a five-wrapper family**: See also CashoutProcessToCreditCard (1), CashoutProcessToWireTransfer (2), CashoutProcessToPayPal (3), CashoutProcessToNeteller (6).

---

## 8. Sample Queries

### 8.1 Process a cashout via Western Union
```sql
DECLARE @Answer INT;
EXEC @Answer = Billing.CashoutProcessToWesternUnion
    @CashoutID             = 5003,
    @ManagerID             = 12345,
    @ProcessCurrencyID     = 1,
    @CashoutActionStatusID = 2,
    @CountryID             = 78,
    @MTCN                  = '123456789012345',
    @City                  = N'Cairo',
    @ExchangeRate          = 1.0,
    @Description           = 'Western Union cashout approved';
SELECT @Answer AS ReturnCode;
```

### 8.2 Verify WU transfer details were recorded
```sql
SELECT CashoutID, CountryID, MTCN, City
FROM Billing.WesternUnionToCashout WITH (NOLOCK)
WHERE CashoutID = 5003;
```

### 8.3 View cashout history
```sql
SELECT CashoutID, PreviousCashoutStatusID, NewCashoutStatusID, UpdateDate, Remark
FROM History.Cashout WITH (NOLOCK)
WHERE CashoutID = 5003
ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutProcessToWesternUnion | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutProcessToWesternUnion.sql*
