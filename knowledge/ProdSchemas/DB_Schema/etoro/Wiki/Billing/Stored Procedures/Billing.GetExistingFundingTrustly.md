# Billing.GetExistingFundingTrustly

> Checks whether a Trustly bank account funding method already exists for a customer by matching customer name and IBAN or AccountID from the funding XML, returning block status and validity.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerName + @Val (IBAN or AccountID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trustly is a bank-transfer payment provider that links customer bank accounts via IBAN or account identifiers. Unlike credit cards which use a hash of all card data, Trustly fundings require a specific deduplication approach: matching by customer name AND either IBAN or AccountID extracted from the XML funding data.

When a customer attempts to add a Trustly bank account that may already exist in the system, this procedure checks Billing.Funding (FundingTypeID=35 = Trustly) for an existing record matching the same customer name and account identifier. The result includes the same three-way block assessment (CidBlocked, SystemBlocked, IsThirdParty) as GetExistingFunding, and computes IsValid accordingly.

Note: This procedure requires a CustomerToFunding link (INNER JOIN vs. LEFT JOIN in GetExistingFunding), meaning it only matches fundings already associated with some customer. @CID defaults to 0 and is used only for third-party claim detection.

---

## 2. Business Logic

### 2.1 Trustly-Specific Deduplication Logic

**What**: Matches by CustomerName + IBAN or AccountID from XML data (Trustly FundingTypeID=35).

**Columns/Parameters Involved**: `@CustomerName`, `@Val`

**Rules**:
- `BFUN.FundingTypeID = 35` - Trustly-only search
- `FundingData.value('(/Funding/CustomerNameAsString)[1]', 'NVARCHAR(MAX)') = @CustomerName` - customer name must match
- IBAN OR AccountID match: `FundingData.value('(/Funding/IBANCodeAsString)[1]', ...) = @Val OR FundingData.value('(/Funding/AccountIDAsString)[1]', ...) = @Val`
- The same @Val is compared against both IBANCodeAsString and AccountIDAsString (the caller passes whichever identifier is available)
- INNER JOIN CustomerToFunding: only fundings already linked to a customer are searched

### 2.2 Multi-dimensional Validity Assessment (same as GetExistingFunding)

**What**: Three independent block conditions determine whether the found funding is usable.

**Rules**:
- CidBlocked = CustomerToFunding.IsRefundExcluded
- SystemBlocked = Funding.IsRefundExcluded
- IsThirdParty = BackOffice.CustomerToThirdPartyFundings.FundingID (not NULL if third-party claim exists)
- IsValid = 1 when CidBlocked=0, SystemBlocked=0, IsThirdParty IS NULL

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerName | NVARCHAR(MAX) | NO | - | CODE-BACKED | Customer's full name as registered with Trustly. Matched against FundingData.value('(/Funding/CustomerNameAsString)[1]', ...) in Billing.Funding. Name must match exactly. |
| 2 | @Val | NVARCHAR(MAX) | NO | - | CODE-BACKED | Either an IBAN code or a Trustly AccountID. Compared against both IBANCodeAsString and AccountIDAsString in the FundingData XML (OR condition). The caller passes whichever identifier is available. |
| 3 | @CID | INT | YES | 0 | CODE-BACKED | Customer identifier. Used ONLY to check BackOffice.CustomerToThirdPartyFundings for third-party claims. Defaults to 0 (no customer context). The INNER JOIN to CustomerToFunding uses the CID from the matched funding record, not @CID. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of the matched Trustly Billing.Funding record. |
| R2 | CID | INT | YES | NULL | CODE-BACKED | Customer ID from the matched CustomerToFunding record. The owner of this Trustly account in the system. |
| R3 | CidBlocked | BIT | YES | NULL | CODE-BACKED | CustomerToFunding.IsRefundExcluded. 1 = this customer's refund/withdrawal access is blocked for this funding. |
| R4 | SystemBlocked | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsRefundExcluded. 1 = funding globally suspended system-wide. |
| R5 | IsThirdParty | INT | YES | NULL | CODE-BACKED | FundingID from BackOffice.CustomerToThirdPartyFundings if a third-party claim exists for @CID. NOT NULL = third-party restriction. |
| R6 | IsValid | BIT | NO | - | CODE-BACKED | 1 = funding can be used (no blocks, no third-party claim). 0 = blocked for one or more reasons. CAST(CASE WHEN CidBlocked=1 THEN 0 WHEN SystemBlocked=1 THEN 0 WHEN IsThirdParty IS NOT NULL THEN 0 ELSE 1 END AS BIT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=35 | Billing.Funding | JOIN | Trustly fundings only (FundingTypeID=35) |
| FundingID | Billing.CustomerToFunding | INNER JOIN | Only fundings already linked to a customer |
| FundingID + @CID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN | Third-party claim check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services (Trustly registration) | @CustomerName + @Val | EXEC | Trustly deduplication before new funding registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExistingFundingTrustly (procedure)
├── Billing.Funding (table)
├── Billing.CustomerToFunding (table)
└── BackOffice.CustomerToThirdPartyFundings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | INNER JOIN - search FundingTypeID=35, match CustomerName + IBAN/AccountID from XML |
| Billing.CustomerToFunding | Table | INNER JOIN on FundingID - CidBlocked (IsRefundExcluded) |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN - third-party claim detection for @CID |

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

### 8.1 Check if a Trustly account exists by IBAN

```sql
EXEC Billing.GetExistingFundingTrustly
    @CustomerName = 'John Smith',
    @Val = 'DE89370400440532013000',  -- IBAN
    @CID = 1234567;
```

### 8.2 Check if a Trustly account exists by AccountID

```sql
EXEC Billing.GetExistingFundingTrustly
    @CustomerName = 'John Smith',
    @Val = 'TRUSTLY_ACCT_12345',
    @CID = 0;  -- No CID context, just deduplication
```

### 8.3 Find all Trustly fundings by customer name

```sql
SELECT f.FundingID,
       f.FundingData.value('(/Funding/CustomerNameAsString)[1]', 'NVARCHAR(MAX)') AS CustomerName,
       f.FundingData.value('(/Funding/IBANCodeAsString)[1]', 'NVARCHAR(MAX)') AS IBAN
FROM Billing.Funding f WITH (NOLOCK)
WHERE f.FundingTypeID = 35
ORDER BY f.DateCreated DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExistingFundingTrustly | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExistingFundingTrustly.sql*
