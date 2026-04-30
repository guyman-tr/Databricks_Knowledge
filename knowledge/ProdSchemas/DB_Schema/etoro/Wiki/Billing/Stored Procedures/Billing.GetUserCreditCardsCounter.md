# Billing.GetUserCreditCardsCounter

> Counts unverified new credit cards used since @PointDate: returns how many credit card FundingIDs were first used after @PointDate, have DocumentRequired=1, and have NOT yet had a verification document uploaded (not in BackOffice.CustomerDocumentToDocumentType).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PointDate; returns scalar CC_Number |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetUserCreditCardsCounter is a compliance gate check: it answers "how many NEW credit cards has this customer used since a given point in time that still require document verification and have NOT been verified yet?" The count is used to determine whether a customer must upload card verification documents before being allowed to deposit again.

The procedure implements a three-stage logic:

1. **Before set** (`#AllCCUsedBefore`): All distinct credit cards used by the customer before @PointDate - these are established, known cards.
2. **After set** (`#CCUsedForTimePeriod`): All distinct credit cards used from @PointDate to now - these are the candidate new cards.
3. **Unverified new cards**: Cards in the After set that are NOT in the Before set (genuinely new since @PointDate), NOT already verified (not in `BackOffice.CustomerDocumentToDocumentType`), and have `DocumentRequired=1` on the Funding record.

The result `CC_Number` is the count of cards requiring user action. A value > 0 triggers a document upload requirement; 0 means no unverified new cards exist.

Referenced in:
- "Billing Service Database Readonly Separation" (Confluence MG) - read-only billing service API
- "Doc Api DB Migration Mapping" (Confluence CR) - document API migration context (BackOffice.CustomerDocumentToDocumentType involvement)

---

## 2. Business Logic

### 2.1 Stage 1 - Cards Used Before @PointDate

**What**: Identifies all distinct credit card numbers and FundingIDs used by the customer before @PointDate.

**Columns/Parameters Involved**: `@CID`, `@PointDate`, `Billing.Deposit.PaymentDate`, `Billing.Funding.FundingTypeID`, `Billing.Funding.FundingData`

**Rules**:
- `WHERE Customer.CID = @CID AND BDEP.PaymentDate < @PointDate`
- `BFUN.FundingTypeID = 1` - credit cards only
- CardNumberAsString extracted from `FundingData.value('(/Funding/CardNumberAsString)[1]', 'varchar(350)')` as `FundCN`
- `SELECT DISTINCT FundCN, FundingID ... GROUP BY FundingID, FundCN` - deduplicates by card+FundingID pair
- These are "established" cards - using one of these post-@PointDate is not a new card event

### 2.2 Stage 2 - Cards Used After @PointDate

**What**: Identifies all distinct credit cards used by the customer from @PointDate to now.

**Columns/Parameters Involved**: `@CID`, `@PointDate`, `Billing.Deposit.PaymentDate`, `getDate()`

**Rules**:
- `WHERE Customer.CID = @CID AND BDEP.PaymentDate BETWEEN @PointDate AND getDate()`
- Same CardNumberAsString extraction, same credit card type filter (FundingTypeID=1)
- `SELECT DISTINCT FundCN, FundingID ... GROUP BY CID, FundCN, FundingID` - deduplicates (CID added to GROUP BY vs Stage 1, but functionally equivalent since always @CID)
- These are "candidate" cards - might be new (not in Before set)

### 2.3 Stage 3 - Count Unverified New Cards

**What**: Counts cards from Stage 2 that are new, unverified, and require documentation.

**Columns/Parameters Involved**: `#CCUsedForTimePeriod`, `#AllCCUsedBefore`, `BackOffice.CustomerDocumentToDocumentType`, `Billing.Funding.DocumentRequired`

**Rules**:
```
Count cards in #CCUsedForTimePeriod WHERE FundingID NOT IN:
  (SELECT DISTINCT FundingID FROM #AllCCUsedBefore)       -- not an old card
  UNION
  (SELECT DISTINCT FundingID FROM CustomerDocumentToDocumentType WHERE FundingID IS NOT NULL)  -- not already verified
AND Billing.Funding.DocumentRequired = 1                   -- requires document
```
- Exclusion via NOT IN on UNION of two sources: old cards + verified cards
- `DocumentRequired=1` on Billing.Funding: only cards flagged as requiring verification are counted
- Result: scalar `CC_Number` - count of cards needing action

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. All deposit and funding lookups are scoped to this customer. |
| 2 | @PointDate | DATETIME | NO | - | CODE-BACKED | The dividing point in time. Cards used before this date are considered "established". Cards first used on or after this date are checked for verification status. Typically set to a deposit cutoff or account creation date. |
| - | CC_Number | INT | NO | - | CODE-BACKED | Count of new credit cards used since @PointDate that have DocumentRequired=1 and have NOT been verified via document upload. 0 means no action required. Greater than 0 triggers document upload requirement for the customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentDate, FundingID | Billing.Deposit | JOIN (twice - before + after sets) | Source of deposit dates for time-split |
| FundingID, FundingTypeID=1, FundingData, DocumentRequired | Billing.Funding | JOIN + final filter | Credit card type filter, CardNumberAsString extraction, DocumentRequired flag |
| CID | Customer.Customer | JOIN | CID validation join |
| FundingID | BackOffice.CustomerDocumentToDocumentType | NOT IN subquery | Excludes already-verified cards from the count |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing service (read-only API) | @CID, @PointDate | EXEC | New unverified card count for document upload requirement checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetUserCreditCardsCounter (procedure)
+-- Billing.Deposit (table) [deposit dates for time-split]
+-- Billing.Funding (table) [FundingTypeID=1, CardNumberAsString XML, DocumentRequired]
+-- Customer.Customer (table) [CID join]
+-- BackOffice.CustomerDocumentToDocumentType (table) [verified card exclusion]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Deposit date filter for before/after @PointDate split; provides FundingID |
| Billing.Funding | Table | Credit card type filter (FundingTypeID=1); CardNumberAsString from FundingData XML; DocumentRequired flag |
| Customer.Customer | Table | CID join (validates and scopes the customer) |
| BackOffice.CustomerDocumentToDocumentType | Table | NOT IN subquery: FundingIDs with uploaded documents are excluded from the unverified count |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing service (read-only API) | External | Card verification compliance check before allowing new deposits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID=1 | Design | Credit cards only; other payment methods are excluded from the counter |
| getDate() as upper bound | Design | Uses local server time (not GETUTCDATE()) for the "after" window upper bound; consistent with PaymentDate storage convention |
| NOT IN with UNION | Performance | NOT IN on UNION of two subqueries; acceptable for small-to-medium result sets; may be slow for customers with many deposits |
| CardNumberAsString from XML | Performance | XML value extraction per row; may be slow on large FundingData volumes - consider index or computed column if called frequently |
| NOLOCK throughout | Concurrency | All base table reads use WITH (NOLOCK) |
| DocumentRequired=1 | Business rule | Only Funding records requiring document upload contribute to the count; cards with DocumentRequired=0 are excluded even if new and unverified |
| Doc API Migration context | Change history | BackOffice.CustomerDocumentToDocumentType involvement links this procedure to the Doc API DB migration (Confluence CR) |

---

## 8. Sample Queries

### 8.1 Check unverified new card count for a customer since their first deposit

```sql
-- Count new unverified cards since a specific date
EXEC [Billing].[GetUserCreditCardsCounter]
    @CID = 12345,
    @PointDate = '2026-01-01 00:00:00'
-- Returns: CC_Number (0 = no action needed, >0 = document upload required)
```

### 8.2 Find customers with unverified new cards (equivalent query fragment)

```sql
-- Cards used after cutoff that need verification
SELECT f.FundingID, f.FundingData.value('(/Funding/CardNumberAsString)[1]', 'varchar(350)') AS CardNumber
FROM [Billing].[Deposit] d WITH (NOLOCK)
INNER JOIN [Billing].[Funding] f WITH (NOLOCK) ON d.FundingID = f.FundingID AND f.FundingTypeID = 1
WHERE d.CID = 12345
  AND d.PaymentDate >= '2026-01-01'
  AND f.DocumentRequired = 1
  AND f.FundingID NOT IN (
      SELECT DISTINCT FundingID FROM [BackOffice].[CustomerDocumentToDocumentType] WITH (NOLOCK)
      WHERE FundingID IS NOT NULL
  )
```

---

## 9. Atlassian Knowledge Sources

**Confluence**:
- "Billing Service Database Readonly Separation" (/spaces/MG) - this procedure is part of the read-only billing service API
- "Doc Api DB Migration Mapping" (/spaces/CR) - references BackOffice.CustomerDocumentToDocumentType; procedure is affected by the document API migration
- "DocApi DB Migration - Mapping (new)" (/spaces/CR) - updated migration mapping
- "Doc Api DB Migration Mapping ---deprecated---" (/spaces/CR) - prior version of migration mapping

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 4 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetUserCreditCardsCounter | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetUserCreditCardsCounter.sql*
