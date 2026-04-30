# Billing.FundingGetByID

> Retrieves a single Billing.Funding record by its primary key - the standard direct lookup for a known payment instrument ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID INT - PK of Billing.Funding |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingGetByID` is the direct PK fetch for a payment instrument record. Given a known `FundingID`, it returns the complete details of that payment method from `Billing.Funding`: type, blocking status, raw data, computed fields, and display fields.

This is the primary "load a payment instrument by ID" procedure used when the application already has a `FundingID` from a deposit, withdrawal, or customer-funding record and needs the full instrument details to process or display it. Unlike `Billing.FundingGetByData` (which finds instruments by matching submitted data), this procedure is used when the FundingID is already known.

The procedure uses the fully qualified table reference `[etoro].[Billing].[Funding]` (database-qualified) and does NOT use `WITH (NOLOCK)`, making reads fully isolated - important when reading sensitive payment data that must be current.

---

## 2. Business Logic

### 2.1 Direct PK Lookup Pattern

**What**: The simplest Billing.Funding access pattern - fetch one record by primary key.

**Columns/Parameters Involved**: `@FundingID`, `Billing.Funding.FundingID`

**Rules**:
- `FundingID` is the CLUSTERED PRIMARY KEY of `Billing.Funding` - this query uses the optimal access path.
- Returns 0 rows if the FundingID does not exist (no error raised). Callers must handle empty result sets.
- No WITH (NOLOCK) - reads use default isolation level to ensure payment data is not stale mid-transaction.
- Database-qualified reference `[etoro].[Billing].[Funding]` - explicitly names the database, allowing this SP to be called from cross-database contexts.

### 2.2 Column Set Parity with FundingGetByData

**What**: This procedure returns the same 16 columns as `Billing.FundingGetByData` - both are "full Funding record" lookups.

**Rules**:
- Both procedures were updated together when PaymentDetails (Nov 2022) and KeyVersion (Jul 2023) were added to the Billing.Funding table.
- Application code consuming either procedure receives the same shape - enabling a unified result handler.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | Primary key of the Billing.Funding record to retrieve. FundingID starts at 1000 (IDENTITY(1000,1)). Passed directly to the WHERE clause against the clustered PK index. |

**Return columns** (from Billing.Funding - inherited from Billing.Funding.md):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | FundingID | int | CODE-BACKED | PK of the funding record. Will equal @FundingID. |
| R2 | FundingTypeID | int | CODE-BACKED | Payment method type (e.g., 1=CreditCard, 2=WireTransfer). FK to Dictionary.FundingType. |
| R3 | ManagerID | int | CODE-BACKED | BO manager who last modified the record; NULL = system/customer-created. |
| R4 | IsBlocked | bit | CODE-BACKED | 1 = payment instrument is blocked from further use; 0 = active. |
| R5 | BlockedDescription | varchar | CODE-BACKED | Reason for blocking. NULL if not blocked. |
| R6 | BlockedAt | datetime | CODE-BACKED | UTC timestamp when instrument was blocked. NULL if not blocked. |
| R7 | FundingData | xml | CODE-BACKED | Full XML payment instrument data (DDM-masked to 'xxxx' for non-privileged callers). Schema varies by FundingTypeID. |
| R8 | IsRefundExcluded | bit | CODE-BACKED | 1 = refunds cannot be sent to this instrument; 0 = refunds allowed. |
| R9 | DocumentRequired | bit | CODE-BACKED | 1 = compliance document required before this instrument can be used; 0 = no document required. |
| R10 | FundingDataCheckSum | int | CODE-BACKED | CHECKSUM of FundingData XML for change detection. |
| R11 | SecuredCardData | varchar | CODE-BACKED | Secured card token extracted from FundingData (computed column). PCI-compliant card reference. |
| R12 | Parameter | varchar | CODE-BACKED | Primary identifying parameter from FundingData (card hash for CC, account number for wire). |
| R13 | FundingHash | char(32) | CODE-BACKED | Canonical 32-char hash of FundingData for deduplication (Billing.OrderedSmallCaseFundingHash). |
| R14 | DateCreated | datetime | CODE-BACKED | UTC timestamp when the payment instrument was registered. |
| R15 | PaymentDetails | nvarchar | CODE-BACKED | Pre-computed display representation of the payment instrument (added Nov 2022, PAYIL-5369). |
| R16 | KeyVersion | int | CODE-BACKED | Encryption key version for this card record (added Jul 2023, PAYIL-6869). Used in PCI key rotation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | PK Lookup | Direct SELECT by primary key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| FundingUser (DB role) | EXECUTE | Permission | Called by Billing/Funding application service to load a funding record by ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingGetByID (procedure)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECTed by PK (FundingID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing/Funding application service | External | Calls to load full payment instrument details by ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. No SET NOCOUNT ON (implicit). No WITH (NOLOCK) - uses full isolation. Database-qualified reference `[etoro].[Billing].[Funding]`. No transaction block. Created PAYIL-975 (Jun 2020).

---

## 8. Sample Queries

### 8.1 Retrieve a specific funding record by ID

```sql
EXEC [Billing].[FundingGetByID] @FundingID = 123456;
```

### 8.2 Check if a funding instrument is blocked before a transaction

```sql
DECLARE @IsBlocked BIT, @BlockedDescription VARCHAR(MAX);
-- First get the funding record
-- Then inspect the IsBlocked column:
SELECT IsBlocked, BlockedDescription, BlockedAt
FROM [Billing].[Funding] WITH (NOLOCK)
WHERE FundingID = 123456;
```

### 8.3 Compare with FundingGetByData - same column set, different lookup strategy

```sql
-- FundingGetByID: known FundingID
EXEC [Billing].[FundingGetByID] @FundingID = 123456;

-- FundingGetByData: unknown FundingID, match by data hash
EXEC [Billing].[FundingGetByData]
    @FundingTypeID = 1,
    @FundingData = '<Funding>...</Funding>';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-975 (Jun 2020) | Jira | Original procedure creation |
| PAYIL-6869 (Jul 2023) | Jira | Added KeyVersion column to SELECT list (same ticket as FundingGetByData) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 2 Jira (from code comments) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingGetByID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingGetByID.sql*
