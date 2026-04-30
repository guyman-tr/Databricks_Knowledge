# Billing.MerchantEntityFundsTransferGet

> Reader procedure that resolves the eToro legal entity for a funds transfer based on regulatory framework and card country, throwing error 51445 if the regulation is not supported.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @regulationId INT, @binCountryId INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.MerchantEntityFundsTransferGet returns the eToro legal entity record for a wire or domestic funds transfer. Given the customer's regulatory framework (@regulationId) and their card's issuing country (@binCountryId), it looks up the appropriate eToro legal entity (e.g., "eToro EU", "eToro UK", "eToro US") from Billing.MerchantEntityFundsTransfer.

This procedure is the runtime resolution layer for cross-jurisdictional funds transfer routing. eToro operates regulated entities in Cyprus (CySEC), UK (FCA), Australia (ASIC), USA (eToroUS/FinCEN/NYDFS), UAE (FSRA), and Singapore (MAS). When a customer initiates a wire transfer, the billing system must direct the funds to the correct legal entity's bank account. This procedure provides the answer.

The logic is a two-step query:
1. Check if the regulation is supported at all (count rows for @regulationId). If none: THROW 51445 ("Regulation Not Supported").
2. Filter by both @regulationId AND @binCountryId to return the specific legal entity for that regulation+country combination.

If the regulation exists but no row matches the country (step 2 returns empty), the caller receives an empty resultset - no error. The caller must handle this as "no domestic routing available" (cross-border transfer applies).

Example usage in the code comment: `[Billing].[MerchantEntityFundsTransferGet] 1, 19` (CySEC regulation, country 19).

---

## 2. Business Logic

### 2.1 Regulation Validation

**What**: Validates that the given regulation is supported before attempting country resolution.

**Columns/Parameters Involved**: `@regulationId`

**Rules**:
- First query: `SELECT @records=Count(*) FROM Billing.MerchantEntityFundsTransfer WHERE RegulationID=@regulationId`
- If @records=0: `THROW 51445, 'Regulation Not Supported', 1` - hard stop, no resultset returned.
- This ensures callers receive a clear error for unsupported regulations (e.g., a new regulation not yet configured in the table).
- Currently supported RegulationIDs: 1 (CySEC), 2 (FCA), 4 (ASIC), 6 (eToroUS), 7 (FinCEN), 8 (FinCEN+FINRA), 9 (FSA Seychelles), 10 (ASIC+GAML), 11 (FSRA), 13 (MAS), 14 (NYDFS+FINRA).

### 2.2 Entity Resolution

**What**: Returns the specific legal entity for the regulation+country combination.

**Columns/Parameters Involved**: `@regulationId`, `@binCountryId`

**Rules**:
- Second query: `SELECT ID, RegulationID, LegalEntity, SupportedDomesticCountryID FROM Billing.MerchantEntityFundsTransfer WHERE RegulationID=@regulationId AND SupportedDomesticCountryID=@binCountryId`
- Returns: ID, RegulationID, LegalEntity (entity name), SupportedDomesticCountryID.
- If a row matches: returns 1 row with the legal entity to use for this transfer.
- If no row matches the country (regulation exists but no domestic route for this country): returns 0 rows. Caller handles as "no domestic entity available" - cross-border transfer or different routing logic applies.

**Entity examples from live data**:
- RegulationID=1 (CySEC), CountryID=54 (Cyprus) -> "eToro EU"
- RegulationID=2 (FCA), CountryID=218 (UK) -> "eToro UK"
- RegulationID=6 (eToroUS), CountryID=219 (USA) -> "eToro US"
- RegulationID=11 (FSRA), CountryID=217 (UAE) -> "eToro ME"
- RegulationID=13 (MAS), CountryID=183 (Singapore) -> "eToro SG"

**Diagram**:
```
Billing.MerchantEntityFundsTransferGet(@regulationId=2, @binCountryId=218)
    |
    Step 1: Count rows WHERE RegulationID=2
        |
        +-- @records=0 -> THROW 51445 'Regulation Not Supported'
        |
        +-- @records>0 -> continue
    |
    Step 2: SELECT WHERE RegulationID=2 AND SupportedDomesticCountryID=218
        |
        +-- Row found: ID=31, RegulationID=2, LegalEntity='eToro UK', SupportedDomesticCountryID=218
        |
        +-- No row: empty resultset (no domestic route for this country under FCA)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @regulationId | int | NO | - | CODE-BACKED | The regulatory framework under which the customer operates. Implicit FK to Dictionary.Regulation. Supported values: 1=CySEC, 2=FCA, 4=ASIC, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC+GAML, 11=FSRA, 13=MAS, 14=NYDFS+FINRA. THROW 51445 if not in Billing.MerchantEntityFundsTransfer. |
| 2 | @binCountryId | int | NO | - | CODE-BACKED | Country ID of the customer's card's BIN (Bank Identification Number) - the issuing bank's country. Implicit FK to Dictionary.Country. Used to select the "domestic" eToro entity for the customer's card country. If no matching row exists for this country under the regulation, returns an empty resultset. |
| RETURN | resultset | YES | - | CODE-BACKED | Returns 0 or 1 rows: (ID int, RegulationID int, LegalEntity varchar(50), SupportedDomesticCountryID int). 0 rows: no domestic route for this regulation+country. 1 row: the eToro legal entity to use. On error: THROW 51445 if regulation not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (count) | Billing.MerchantEntityFundsTransfer | READ | Validates regulation is supported. |
| SELECT (result) | Billing.MerchantEntityFundsTransfer | READ | Returns the matching legal entity row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing funds transfer / wire processing layer | @regulationId, @binCountryId | EXEC | Called to resolve the correct eToro legal entity for a domestic funds transfer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MerchantEntityFundsTransferGet (procedure)
└── Billing.MerchantEntityFundsTransfer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantEntityFundsTransfer | Table | SELECT - validates regulation and resolves legal entity for the given regulation+country. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing funds transfer processing | Application | EXEC - resolves the eToro legal entity for wire/domestic transfer routing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get the legal entity for a UK FCA customer with a UK card
```sql
-- Resolves to eToro UK (LegalEntity='eToro UK')
EXEC Billing.MerchantEntityFundsTransferGet
    @regulationId = 2,    -- FCA
    @binCountryId = 218;  -- United Kingdom
```

### 8.2 Get the legal entity for a CySEC customer with a Cyprus card
```sql
-- Resolves to eToro EU
EXEC Billing.MerchantEntityFundsTransferGet
    @regulationId = 1,   -- CySEC
    @binCountryId = 54;  -- Cyprus
```

### 8.3 Test with an unsupported regulation (will throw 51445)
```sql
BEGIN TRY
    EXEC Billing.MerchantEntityFundsTransferGet
        @regulationId = 99,  -- does not exist
        @binCountryId = 218;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
    -- ErrorCode=51445, ErrorMessage='Regulation Not Supported'
END CATCH
```

### 8.4 View all supported regulation+country combinations
```sql
SELECT r.Name AS Regulation, meft.LegalEntity, c.Name AS DomesticCountry
FROM Billing.MerchantEntityFundsTransfer meft WITH (NOLOCK)
LEFT JOIN Dictionary.Regulation r WITH (NOLOCK) ON meft.RegulationID = r.ID
LEFT JOIN Dictionary.Country c WITH (NOLOCK) ON meft.SupportedDomesticCountryID = c.CountryID
ORDER BY r.Name, c.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.MerchantEntityFundsTransferGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.MerchantEntityFundsTransferGet.sql*
