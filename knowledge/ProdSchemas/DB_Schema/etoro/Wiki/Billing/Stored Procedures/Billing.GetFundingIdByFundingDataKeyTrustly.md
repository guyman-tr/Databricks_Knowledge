# Billing.GetFundingIdByFundingDataKeyTrustly

> Finds the most recently created Trustly (FundingTypeID=35) funding for a customer by matching a single value against either the IBAN or AccountID stored in the funding XML.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @Val |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trustly is a bank-transfer payment provider (FundingTypeID=35) where the customer's bank account is identified by either an IBAN or an internal Trustly AccountID. When a Trustly operation needs to locate an existing funding record - for example when processing a new deposit or cashout and the system only has the raw IBAN or AccountID from the Trustly callback - this procedure resolves it to a FundingID.

The procedure accepts a single @Val string and searches it against both IBAN and AccountID fields simultaneously (OR condition), accommodating the fact that Trustly may supply either identifier depending on the bank/country. When multiple funding records match (e.g., the customer re-registered the same bank account), the most recently created one is returned (ORDER BY DateCreated DESC).

This is the "key lookup" variant for Trustly, complementing GetExistingFundingTrustly (which matches by CustomerName + IBAN + AccountID simultaneously). This simpler version is used when only one identifier is available.

---

## 2. Business Logic

### 2.1 Dual-Field IBAN/AccountID Match

**What**: Matches @Val against either IBANCodeAsString or AccountIDAsString from the funding XML, returning the most recent match.

**Rules**:
- `FundingTypeID = 35` - Trustly-only search
- `ctf.CID = @CID` - scoped to this customer only
- `FundingData.value('(/Funding/IBANCodeAsString)[1]', 'NVARCHAR(MAX)') = @Val` OR `FundingData.value('(/Funding/AccountIDAsString)[1]', 'NVARCHAR(MAX)') = @Val` - either field can match
- `TOP (1) ... ORDER BY BFUN.DateCreated DESC` - returns the newest funding if multiple match
- No status filter (CustomerFundingStatusID not checked) - returns any status including inactive

### 2.2 Default Value for @CID

**What**: @CID has a default value of 0 (no default in spirit, but defined as `= 0`).

**Rules**:
- Callers should always provide @CID explicitly
- A value of 0 would match no real customer (no CID=0 in the system)
- The default exists to allow future flexibility or programmatic calling patterns

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | 0 | CODE-BACKED | Customer identifier. Matched against Billing.CustomerToFunding.CID. Scopes the search to this customer's Trustly fundings only. |
| 2 | @Val | NVARCHAR(MAX) | NO | - | CODE-BACKED | The IBAN or Trustly AccountID to search for. Compared against FundingData XML fields IBANCodeAsString and AccountIDAsString using an OR condition. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of the matched Billing.Funding record (FundingTypeID=35, Trustly). The most recently created match is returned if multiple records share the same IBAN/AccountID. Returns no rows if no match. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=35 + XML fields | Billing.Funding | JOIN | Trustly fundings matching IBAN or AccountID |
| @CID | Billing.CustomerToFunding | JOIN | Scopes search to this customer's fundings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application Trustly payment service | @CID + @Val (IBAN or AccountID) | EXEC | Key lookup before Trustly deposit or cashout operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingIdByFundingDataKeyTrustly (procedure)
├── Billing.Funding (table)
└── Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | TOP(1) SELECT - FundingTypeID=35, XML IBAN/AccountID match, ORDER BY DateCreated DESC |
| Billing.CustomerToFunding | Table | INNER JOIN - CID filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from Trustly payment service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up Trustly funding by IBAN

```sql
EXEC Billing.GetFundingIdByFundingDataKeyTrustly
    @CID = 1234567,
    @Val = 'SE3550000000054910000003';
```

### 8.2 Look up Trustly funding by AccountID

```sql
EXEC Billing.GetFundingIdByFundingDataKeyTrustly
    @CID = 1234567,
    @Val = 'TRU-ACCT-123456';
```

### 8.3 Direct equivalent query

```sql
SELECT TOP 1 f.FundingID
FROM Billing.Funding f WITH (NOLOCK)
INNER JOIN Billing.CustomerToFunding ctf WITH (NOLOCK) ON f.FundingID = ctf.FundingID
WHERE f.FundingTypeID = 35
  AND ctf.CID = 1234567
  AND (f.FundingData.value('(/Funding/IBANCodeAsString)[1]', 'NVARCHAR(MAX)') = 'SE3550000000054910000003'
    OR f.FundingData.value('(/Funding/AccountIDAsString)[1]', 'NVARCHAR(MAX)') = 'SE3550000000054910000003')
ORDER BY f.DateCreated DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingIdByFundingDataKeyTrustly | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingIdByFundingDataKeyTrustly.sql*
