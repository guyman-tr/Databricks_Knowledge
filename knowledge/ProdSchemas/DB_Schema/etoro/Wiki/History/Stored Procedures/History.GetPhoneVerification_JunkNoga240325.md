# History.GetPhoneVerification_JunkNoga240325

> Retrieves historical phone verification records for a customer over a date range, with optional filtering by verification status - marked for deletion (Junk) as of 2024-03-25.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - customer ID to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.GetPhoneVerification_JunkNoga240325` queries the temporal history of `Customer.PhoneVerificationDetails` to return phone verification records for a given customer within a specified date range. The name suffix `_JunkNoga240325` indicates this procedure was flagged for deletion by Noga on 2024-03-25 and is considered obsolete; it should not be used for new development.

The procedure originally served as the read-side of phone verification history queries, likely used by back-office or compliance tooling to audit phone verification changes over time. Created under Jira ticket OPSS-1483, it was subsequently modified to remove `ValidFrom` and `ValidTo` columns from the result set.

Data flows from `Customer.PhoneVerificationDetails` (a temporal table), queried with `FOR SYSTEM_TIME BETWEEN` to access point-in-time history. An optional TVP parameter allows filtering by one or more phone verification status IDs, enabling the caller to retrieve only records with specific verification outcomes.

---

## 2. Business Logic

### 2.1 Temporal History Query with Optional Status Filter

**What**: Uses SQL Server temporal `FOR SYSTEM_TIME BETWEEN` to retrieve historical phone verification states for a customer within a date window.

**Columns/Parameters Involved**: `@dateFrom`, `@dateTo`, `@phoneVerifiedStatusIds`, `@hasStatusDefined`

**Rules**:
- `@dateTo` defaults to `GETUTCDATE()` if NULL - open-ended date range uses current UTC time
- `@hasStatusDefined` is set to 1 if the TVP `@phoneVerifiedStatusIds` contains any rows, 0 if empty
- When `@hasStatusDefined = 0`: returns all verification records regardless of status
- When `@hasStatusDefined = 1`: only returns records where `PhoneVerifiedID` is in the provided TVP
- `FOR SYSTEM_TIME BETWEEN @dateFrom AND @dateTo` queries temporal history rows (not just current state)
- An additional `WHERE VerifacationDate >= @dateFrom AND VerifacationDate <= @dateTo` further restricts by the actual verification event date (note: `VerifacationDate` is a typo in the source table column name)
- `SELECT DISTINCT` de-duplicates rows that may arise from temporal overlap

**Diagram**:
```
@cid + @dateFrom + [@dateTo] + [@phoneVerifiedStatusIds]
         |
         v
Customer.PhoneVerificationDetails
  FOR SYSTEM_TIME BETWEEN @dateFrom AND @dateTo
         |
         +-- WHERE CID = @cid
         +-- WHERE VerifacationDate IN [@dateFrom, @dateTo]
         +-- WHERE PhoneVerifiedID IN @phoneVerifiedStatusIds (if TVP not empty)
         |
         v
SELECT DISTINCT Id, Cid, PhoneNo, PhoneTypeId, PhoneVerifiedId, VerificationDate
```

### 2.2 Obsolescence - Junk Procedure

**What**: This procedure is flagged as obsolete and pending deletion.

**Columns/Parameters Involved**: N/A

**Rules**:
- The `_JunkNoga240325` suffix is a naming convention marking the procedure for removal
- No callers exist in the etoro SSDT repository - it is already unused
- Created under OPSS-1483; removed `ValidFrom` / `ValidTo` output columns in a later revision
- Do not use for new development; do not reference in new procedures or application code

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Filters Customer.PhoneVerificationDetails to only return phone verification records belonging to this customer. Maps to the CID column in the temporal table. |
| 2 | @dateFrom | DATETIME | NO | - | CODE-BACKED | Start of the temporal history window (inclusive). Used both in FOR SYSTEM_TIME BETWEEN (temporal row visibility) and WHERE VerifacationDate >= @dateFrom (verification event date filter). |
| 3 | @dateTo | DATETIME | YES | NULL (defaults to GETUTCDATE()) | CODE-BACKED | End of the temporal history window (inclusive). Defaults to current UTC time when NULL, creating an open-ended query through to the present. Used in FOR SYSTEM_TIME BETWEEN and WHERE VerifacationDate <= @dateTo. |
| 4 | @phoneVerifiedStatusIds | BackOffice.IDs | YES | READONLY TVP (empty = no filter) | CODE-BACKED | Optional table-valued parameter containing a list of PhoneVerifiedID values to filter by. When empty (no rows), all verification status types are returned. When populated, only records with PhoneVerifiedID matching one of the provided IDs are returned. BackOffice.IDs is a UDT representing a table of integer IDs. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | (INT, from source ID column) | NO | - | CODE-BACKED | The unique identifier of the phone verification record in Customer.PhoneVerificationDetails. Aliased from ID. |
| 2 | Cid | (INT) | NO | - | CODE-BACKED | The customer ID. Aliased from CID. Echoed in the result set to identify the customer whose records are returned. |
| 3 | PhoneNo | (varchar) | YES | - | CODE-BACKED | The phone number that was verified. Aliased from PhoneNumber column. |
| 4 | PhoneTypeId | (INT) | YES | - | CODE-BACKED | Identifier for the type of phone (e.g., mobile, landline). Aliased from PhoneType column. References a phone type lookup. |
| 5 | PhoneVerifiedId | (INT) | YES | - | CODE-BACKED | Verification status identifier indicating the outcome of the phone verification event. Aliased from PhoneVerifiedID. Used as the filter target when @phoneVerifiedStatusIds is provided. |
| 6 | VerificationDate | (DATETIME) | YES | - | CODE-BACKED | The timestamp of the phone verification event. Aliased from VerifacationDate (note: source column has a typo - "Verifacation" instead of "Verification"). Used as the date range filter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.PhoneVerificationDetails | Reads (temporal) | SELECT with FOR SYSTEM_TIME BETWEEN to query phone verification history |
| @phoneVerifiedStatusIds | BackOffice.IDs | TVP parameter type | User-defined table type used to pass a list of filter IDs |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository. This procedure is unused (marked Junk).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetPhoneVerification_JunkNoga240325 (procedure)
├── Customer.PhoneVerificationDetails (table - temporal)
└── BackOffice.IDs (user defined type - TVP parameter)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails | Table (temporal) | SELECT with FOR SYSTEM_TIME BETWEEN - reads historical phone verification records |
| BackOffice.IDs | User Defined Type | Parameter type for @phoneVerifiedStatusIds TVP |

### 6.2 Objects That Depend On This

No dependents found. Procedure is unused (Junk-flagged).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: `SET NOCOUNT ON` is applied at the start of the procedure body.

---

## 8. Sample Queries

### 8.1 Get all phone verification history for a customer in a date range

```sql
DECLARE @statusIds BackOffice.IDs
EXEC History.GetPhoneVerification_JunkNoga240325
    @cid = 12345,
    @dateFrom = '2023-01-01',
    @dateTo = '2023-12-31',
    @phoneVerifiedStatusIds = @statusIds
```

### 8.2 Get phone verification history filtered to specific statuses

```sql
DECLARE @statusIds BackOffice.IDs
INSERT INTO @statusIds (ID) VALUES (1), (2)

EXEC History.GetPhoneVerification_JunkNoga240325
    @cid = 12345,
    @dateFrom = '2023-01-01',
    @dateTo = NULL,  -- defaults to now
    @phoneVerifiedStatusIds = @statusIds
```

### 8.3 Direct query equivalent (use instead of this obsolete procedure)

```sql
SELECT DISTINCT
    [ID] AS Id,
    CID AS Cid,
    [PhoneNumber] AS PhoneNo,
    [PhoneType] AS PhoneTypeId,
    [PhoneVerifiedID] AS PhoneVerifiedId,
    [VerifacationDate] AS VerificationDate
FROM [Customer].[PhoneVerificationDetails] WITH (NOLOCK)
FOR SYSTEM_TIME BETWEEN '2023-01-01' AND '2023-12-31'
WHERE CID = 12345
  AND [VerifacationDate] >= '2023-01-01'
  AND [VerifacationDate] <= '2023-12-31'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.GetPhoneVerification_JunkNoga240325 | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetPhoneVerification_JunkNoga240325.sql*
