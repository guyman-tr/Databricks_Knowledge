# Billing.IsFundingExists

> Returns the FundingID (ordered DESC) for existing funding records that match the supplied funding type and data hash - a deduplication lookup restricted to "new style" multi-funding instruments, used to prevent duplicate funding registrations during deposit setup.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.Funding.FundingID via FundingHash match |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.IsFundingExists` is the canonical deduplication check for payment instrument registration. Before a new funding record is created, the deposit setup service calls this procedure to detect whether the same payment instrument already exists in the system. The check is based on `FundingHash` - a deterministic canonical hash of the funding data (computed by `Billing.FundingHash` from the XML-converted funding data string) - ensuring that two registrations of the same card or account produce identical hashes and are treated as duplicates.

The procedure applies two important scope restrictions from `Dictionary.FundingType`:
- `IsNewStyle = 1`: Only checks "new style" funding types - payment instruments using the modern FundingHash-based deduplication model (as opposed to legacy single-funding types that use a different deduplication strategy)
- `IsSingleFunding = 0`: Explicitly excludes single-funding types (instruments where only one active record is allowed per customer) - those types have their own existence check logic

This means `IsFundingExists` is only relevant for multi-funding, new-style payment types. If the procedure returns a FundingID, the caller should use the existing funding record rather than creating a duplicate. If it returns empty, a new funding record may be safely created.

Data flows: the deposit setup service passes the funding type and the serialized funding data (e.g., card token, bank account details) and receives back the matching FundingID, or an empty result indicating no match.

Performance note: Confluence analysis identified repeated calls to this query pattern during deposit/funding flows as a performance concern; callers should cache or short-circuit where possible.

---

## 2. Business Logic

### 2.1 FundingHash Deduplication Check

**What**: A hash-based lookup to find an existing funding record matching the supplied data, restricted to new-style multi-funding types.

**Columns/Parameters Involved**: `@fundingTypeID`, `@fundingData`, `FundingTypeID`, `IsNewStyle`, `IsSingleFunding`, `FundingHash`

**Rules**:
- `@fundingData` is converted to XML before being passed to `Billing.FundingHash()`: `Billing.FundingHash(Convert(XML, @fundingData))`
- The hash function produces a canonical lowercase ordered hash of the XML funding data, ensuring consistent deduplication regardless of attribute ordering or casing in the input
- `IsNewStyle = 1` filter: only new-style funding types participate in hash-based deduplication
- `IsSingleFunding = 0` filter: single-funding types (one active instrument per customer) are excluded - they use separate logic
- `ORDER BY BFUN.FundingID DESC`: if multiple matches exist (data anomaly), the most recently created record is returned first
- Returns empty result set if no match -> safe to create a new funding record
- Returns one or more FundingID values if match(es) found -> caller should reuse the first (most recent) FundingID

**Diagram**:
```
Deposit setup: register new payment instrument (fundingTypeID=X, fundingData="...")
        |
        v
EXEC IsFundingExists @fundingTypeID=X, @fundingData="..."
        |
        v
Billing.FundingHash(Convert(XML, @fundingData)) -> canonical hash
        |
        v
SELECT FundingID FROM Dictionary.FundingType JOIN Billing.Funding
  WHERE FundingTypeID=X AND IsNewStyle=1 AND IsSingleFunding=0
    AND FundingHash = <computed hash>
  ORDER BY FundingID DESC
        |
        +-- Returns FundingID: funding already exists -> reuse it, skip INSERT
        +-- Returns empty: no duplicate found -> proceed to create new Billing.Funding record
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | - | CODE-BACKED | The payment instrument type to search within. Must match a Dictionary.FundingType record where IsNewStyle=1 AND IsSingleFunding=0 for any results to be returned. E.g., 1=Credit Card, 34=iDEAL, 35=Trustly. |
| 2 | @fundingData | NVARCHAR(1000) | NO | - | CODE-BACKED | Serialized funding instrument data as an XML-compatible string (card token, account details, etc.). Converted to XML and hashed by Billing.FundingHash() to produce the canonical deduplication key. The hash is deterministic: same logical instrument always produces the same hash regardless of XML attribute ordering or casing. |

### Output Column

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | FundingID | INT | CODE-BACKED | The Billing.Funding identity key of the matching existing funding record. Ordered DESC (most recently created first). Empty result set means no matching record exists. Callers use the first returned FundingID to reuse an existing instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN source | Dictionary.FundingType | READ | Provides IsNewStyle and IsSingleFunding flags; filters to new-style multi-funding types eligible for hash deduplication |
| SELECT target | Billing.Funding | READ | Source of FundingID and FundingHash; matched against the computed hash of @fundingData |
| Hash computation | Billing.FundingHash | FUNCTION CALL | Converts @fundingData to XML and computes the canonical deduplication hash for the WHERE clause comparison |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found within the Billing schema. Called from the application deposit setup service layer during payment instrument registration to prevent duplicate funding records.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.IsFundingExists (procedure)
├── Dictionary.FundingType (table - IsNewStyle/IsSingleFunding filter)
├── Billing.Funding (table - FundingID and FundingHash source)
└── Billing.FundingHash (scalar function - hash computation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | JOINed on FundingTypeID; WHERE IsNewStyle=1 AND IsSingleFunding=0 restricts scope to hash-dedup-eligible types |
| Billing.Funding | Table | Primary search target; matched by FundingTypeID and FundingHash; FundingID returned to caller |
| Billing.FundingHash | Scalar Function | Computes canonical hash from Convert(XML, @fundingData) for comparison against Billing.Funding.FundingHash computed column |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Both tables use `WITH (NOLOCK)` for non-blocking reads during high-concurrency deposit flows
- `Billing.FundingHash(Convert(XML, @fundingData))` - the XML conversion normalizes the input before hashing, ensuring deterministic output; this matches the `FundingHash` computed column definition on `Billing.Funding`
- `ORDER BY BFUN.FundingID DESC` - returns most recent match first; guards against rare data anomalies where multiple records share the same hash
- No `SET NOCOUNT ON` - row count messages are not suppressed (minor: callers should not rely on row count)
- No `TOP 1` - all matching FundingIDs are returned; callers typically use only the first
- Performance note (Confluence source): repeated calls to this query pattern during deposit/funding flows were identified as a performance concern; caching results where possible is recommended

---

## 8. Sample Queries

### 8.1 Check if a credit card funding record already exists
```sql
EXEC Billing.IsFundingExists
    @fundingTypeID = 1,    -- Credit card
    @fundingData   = N'<FundingData><Token>abc123xyz</Token></FundingData>'
-- Returns FundingID if exists, empty if not
```

### 8.2 Direct equivalent lookup
```sql
SELECT BFUN.FundingID
FROM Dictionary.FundingType DFNT WITH (NOLOCK)
JOIN Billing.Funding BFUN WITH (NOLOCK) ON DFNT.FundingTypeID = BFUN.FundingTypeID
WHERE BFUN.FundingTypeID = 1
  AND DFNT.IsNewStyle = 1
  AND DFNT.IsSingleFunding = 0
  AND BFUN.FundingHash = Billing.FundingHash(Convert(XML, N'<FundingData><Token>abc123xyz</Token></FundingData>'))
ORDER BY BFUN.FundingID DESC
```

### 8.3 List all funding types eligible for hash deduplication
```sql
SELECT FundingTypeID, FundingTypeName, IsNewStyle, IsSingleFunding
FROM Dictionary.FundingType WITH (NOLOCK)
WHERE IsNewStyle = 1
  AND IsSingleFunding = 0
ORDER BY FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

**Confluence - Multiple calls to same query in Deposit/Funding**: Performance analysis identifying this query pattern (FundingHash lookup joining Dictionary.FundingType and Billing.Funding) as being called repeatedly during deposit/funding flows, with a recommendation to cache or consolidate calls to reduce database load.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.IsFundingExists | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.IsFundingExists.sql*
