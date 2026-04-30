# Billing.GetExistingFundingWire

> Detects duplicate wire transfer bank accounts by computing a weighted match score across multiple bank identifier fields (AccountID, IBAN, SWIFT, BSB, SortCode, RoutingNumber) and returning existing fundings where more than one identifier matches.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingData (multi-field XML match) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wire transfer bank accounts present a unique deduplication challenge: unlike credit cards (where a single hash identifies the account), wire transfers can be described using different combinations of identifiers depending on the country and bank (IBAN in Europe, BSB+AccountID in Australia, RoutingNumber+AccountID in the US, SortCode+AccountID in the UK, SWIFT internationally).

This procedure detects likely duplicate wire transfer fundings by requiring that MORE THAN ONE identifier field matches - a threshold that balances false positives (rejecting genuinely different accounts that share one field) with false negatives (missing real duplicates). The logic parses the incoming XML to extract up to 6 identifiers, computes an IIF-based match score for each field (non-empty match = 1 point), and returns existing fundings where the total score exceeds 1.

Scope: Wire transfers only (FundingTypeID=2), IsNewStyle=1, IsSingleFunding=0. The customer must already have a CustomerToFunding link (INNER JOIN). Results are sorted by FundingID DESC (most recent first).

---

## 2. Business Logic

### 2.1 Weighted Multi-Field Match

**What**: Computes a score across 6 bank identifier fields and requires > 1 match to flag as duplicate.

**Columns/Parameters Involved**: `@AccountID`, `@IBan`, `@BSBNumber`, `@SortCode`, `@SwiftCode`, `@RoutingNumber`

**Rules**:
- Each field contributes 1 point if: (XML value in existing Billing.Funding = extracted value from @FundingData) AND (extracted value is not empty string)
- Empty strings from the XML are excluded from matching (AND @Field <> '') prevents empty-field matches
- Total score must be > 1 to be considered a duplicate candidate
- This prevents a single shared field (e.g., same SWIFT code for all accounts at one bank) from triggering a false duplicate match
- The 6 fields: AccountID, IBAN, SwiftCode, BSBNumber, SortCode, RoutingNumber

**Diagram**:
```
Score = IIF(AccountID matches AND non-empty, 1, 0)
      + IIF(IBAN matches AND non-empty, 1, 0)
      + IIF(SwiftCode matches AND non-empty, 1, 0)
      + IIF(BSBNumber matches AND non-empty, 1, 0)
      + IIF(SortCode matches AND non-empty, 1, 0)
      + IIF(RoutingNumber matches AND non-empty, 1, 0)

WHERE Score > 1 -> likely duplicate (2+ unique identifiers match)
```

### 2.2 Block Status Assessment (same pattern as GetExistingFunding)

Same three-way assessment:
- CidBlocked = CustomerToFunding.IsRefundExcluded
- SystemBlocked = Billing.Funding.IsRefundExcluded
- IsThirdParty = BackOffice.CustomerToThirdPartyFundings.CID (non-NULL = third party)
- IsValid = 1 when all three clear

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingData | XML | NO | - | CODE-BACKED | XML containing the wire transfer bank details. Parsed to extract: AccountIDAsString, IBANCodeAsString, BSBNumberAsString, SortCodeAsString, SwiftCodeAsString, RoutingNumberAsString. Each extracted value is compared against existing Billing.Funding records. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used for INNER JOIN to CustomerToFunding (only the customer's own linked fundings) and LEFT JOIN to BackOffice.CustomerToThirdPartyFundings (third-party detection). |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of the matched wire transfer Billing.Funding record (FundingTypeID=2). |
| R2 | CidBlocked | BIT | YES | NULL | CODE-BACKED | CustomerToFunding.IsRefundExcluded. 1 = customer's refund/withdrawal access to this funding is blocked. |
| R3 | SystemBlocked | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsRefundExcluded. 1 = funding globally suspended. |
| R4 | IsThirdParty | INT | YES | NULL | CODE-BACKED | BackOffice.CustomerToThirdPartyFundings.CID. NOT NULL means a third party has a claim on this funding. |
| R5 | CID | INT | NO | - | CODE-BACKED | Customer ID from the matched CustomerToFunding record. |
| R6 | IsValid | BIT | NO | - | CODE-BACKED | 1 = funding usable (no blocks). 0 = blocked (CidBlocked=1 OR SystemBlocked=1 OR IsThirdParty IS NOT NULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=2 | Billing.Funding | JOIN | Wire transfer fundings only |
| FundingID + @CID | Billing.CustomerToFunding | INNER JOIN | Customer-specific funding link |
| FundingTypeID=2 | Dictionary.FundingType | JOIN | Validates IsNewStyle=1, IsSingleFunding=0 |
| FundingID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN | Third-party claim detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services (wire transfer registration) | @FundingData + @CID | EXEC | Wire deduplication before new funding registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExistingFundingWire (procedure)
├── Billing.Funding (table)
├── Billing.CustomerToFunding (table)
├── Dictionary.FundingType (table)
└── BackOffice.CustomerToThirdPartyFundings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Main search target - FundingTypeID=2, multi-field XML match |
| Billing.CustomerToFunding | Table | INNER JOIN - customer's linked fundings only |
| Dictionary.FundingType | Table | JOIN - IsNewStyle=1, IsSingleFunding=0 filter |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN - third-party claim |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from wire transfer payment service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for duplicate wire transfer with IBAN + SWIFT

```sql
DECLARE @xml XML = '<Funding>
    <AccountIDAsString></AccountIDAsString>
    <IBANCodeAsString>GB29NWBK60161331926819</IBANCodeAsString>
    <SwiftCodeAsString>NWBKGB2L</SwiftCodeAsString>
    <BSBNumberAsString></BSBNumberAsString>
    <SortCodeAsString></SortCodeAsString>
    <RoutingNumberAsString></RoutingNumberAsString>
</Funding>';

EXEC Billing.GetExistingFundingWire
    @FundingData = @xml,
    @CID = 1234567;
```

### 8.2 Find all wire transfer fundings for a customer

```sql
SELECT bf.FundingID, bf.FundingData
FROM Billing.Funding bf WITH (NOLOCK)
INNER JOIN Billing.CustomerToFunding ctf WITH (NOLOCK) ON bf.FundingID = ctf.FundingID
WHERE bf.FundingTypeID = 2 AND ctf.CID = 1234567
ORDER BY bf.FundingID DESC;
```

### 8.3 Check the match score formula for a known funding

```sql
-- Evaluate how many identifiers match between two fundings
SELECT bf.FundingID,
    IIF(bf.FundingData.value('(/Funding/IBANCodeAsString)[1]', 'NVARCHAR(MAX)') = 'GB29NWBK60161331926819'
        AND 'GB29NWBK60161331926819' <> '', 1, 0)
    + IIF(bf.FundingData.value('(/Funding/SwiftCodeAsString)[1]', 'NVARCHAR(MAX)') = 'NWBKGB2L'
        AND 'NWBKGB2L' <> '', 1, 0) AS MatchScore
FROM Billing.Funding bf WITH (NOLOCK)
WHERE bf.FundingTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExistingFundingWire | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExistingFundingWire.sql*
