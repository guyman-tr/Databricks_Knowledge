# BackOffice.SetCustomerLeiDetails

> Sets or clears the Legal Entity Identifier (LEI) on a customer's BackOffice profile, used for corporate account regulatory identification under MiFID II reporting requirements.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetCustomerLeiDetails records or removes the Legal Entity Identifier (LEI) for a customer account. LEI is a 20-character alphanumeric global standard (ISO 17442) that uniquely identifies legal entities participating in financial transactions. Under MiFID II (Markets in Financial Instruments Directive II), investment firms must report LEIs for corporate/institutional clients in transaction reports submitted to regulators.

This procedure was introduced in November 2017 (ticket OPS0351: "Corporate account LEI - BackOffice UI & Backend changes") to support regulatory reporting for corporate accounts. When a BackOffice agent classifies a customer as a corporate entity or processes a business account, they record the customer's LEI via the BackOffice UI, which calls this procedure.

The @Lei parameter accepts NULL to clear a previously set LEI - for example if an account is reclassified from corporate back to retail, or if the LEI was entered in error.

---

## 2. Business Logic

### 2.1 LEI Assignment and Clearing

**What**: A single UPDATE writes or clears the LEI on the BackOffice customer profile.

**Columns/Parameters Involved**: `@CID`, `@Lei`, `@UPDATED`

**Rules**:
- UPDATE BackOffice.Customer SET Lei=@Lei WHERE CID=@CID
- @Lei=NULL clears the LEI (sets the column to NULL, removing corporate entity designation)
- @Lei is NVARCHAR(50) to accommodate the 20-char LEI plus potential future format changes
- @UPDATED OUTPUT is set to 1 on successful UPDATE (regardless of whether any row was actually affected - CID not found still sets @UPDATED=1 since no exception is raised)
- Wrapped in TRY/CATCH: if an exception occurs, any open transaction is rolled back and the error is re-thrown to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer whose LEI is being set. Must correspond to a CID in BackOffice.Customer. No explicit FK check in the procedure - CID not found results in a no-op UPDATE (0 rows affected) with @UPDATED still set to 1. |
| 2 | @Lei | NVARCHAR(50) | YES | NULL | VERIFIED | The Legal Entity Identifier to assign. NULL clears the LEI. Valid LEIs are 20-character alphanumeric codes (ISO 17442 format). No format validation in the procedure - validation is enforced in the application layer before calling. |
| 3 | @UPDATED | BIT | - | 0 | CODE-BACKED | OUTPUT parameter. Set to 1 on successful execution of the TRY block. Returns to the caller indicating the operation completed without exception. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER (UPDATE Lei) | Sets or clears the Lei column for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice UI (Corporate Account module) | - | Caller | Called by BackOffice agents when assigning or clearing LEI for corporate customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetCustomerLeiDetails (procedure)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: SET Lei=@Lei WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice UI | External | Calls to set/clear LEI on corporate customer accounts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Change History

- **OPS0351** (Nov 2017, Geri Reshef): Initial implementation - "Corporate account LEI - BackOffice UI & Backend changes - DB Changes"

---

## 8. Sample Queries

### 8.1 Assign an LEI to a corporate customer
```sql
DECLARE @Updated BIT = 0
EXEC BackOffice.SetCustomerLeiDetails
    @CID     = 12345678,
    @Lei     = N'529900T8BM49AURSDO55',
    @UPDATED = @Updated OUTPUT
SELECT @Updated AS UpdatedFlag
```

### 8.2 Clear a previously set LEI
```sql
DECLARE @Updated BIT = 0
EXEC BackOffice.SetCustomerLeiDetails
    @CID     = 12345678,
    @Lei     = NULL,
    @UPDATED = @Updated OUTPUT
SELECT @Updated AS UpdatedFlag
```

### 8.3 Find customers with LEI set
```sql
SELECT CID, Lei
FROM BackOffice.Customer WITH (NOLOCK)
WHERE Lei IS NOT NULL
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetCustomerLeiDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetCustomerLeiDetails.sql*
