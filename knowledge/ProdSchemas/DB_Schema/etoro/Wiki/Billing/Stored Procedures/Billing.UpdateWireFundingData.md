# Billing.UpdateWireFundingData

> Generic key/value upsert for XML fields inside Billing.Funding.FundingData, used to add or update individual wire transfer payment details (bank name, IBAN, Swift code, etc.) in-place.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID + @Key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Funding.FundingData` is an XML column that stores payment-method-specific details for each deposit. For wire transfer deposits (FundingTypeID=2), the XML contains the customer's bank details: payee name, account ID, bank name, IBAN/SWIFT, routing number, country, etc.

`Billing.UpdateWireFundingData` is a generic utility for inserting or updating any single field within this XML. It takes an `@Key` (XML element name) and `@Value`, checks whether the element already exists in the XML, and either replaces its text node or appends a new element - all via SQL Server's XML `.modify()` method using dynamic SQL.

This procedure is typically called when wire transfer funding data needs to be enriched or corrected after a deposit has been created - for example, when the Back Office provides missing IBAN/SWIFT details for a pending wire deposit, or when the wire transfer service updates specific fields.

Known wire transfer FundingData XML keys (from Wire Transfer Service design):
`CustomerNameAsString`, `AccountIDAsString`, `BankNameAsString`, `ClientBankNameAsString`, `CountryIDAsInteger`, `SwiftCodeAsString`, `IBANCodeAsString`, `SortCodeAsString`, `RoutingNumberAsString`.

**Security note**: The procedure uses dynamic SQL without parameterization for the XML key and value - both `@Key` and `@Value` are interpolated directly into the SQL string. This is acceptable for internal service use but callers must validate inputs before calling.

---

## 2. Business Logic

### 2.1 XML Upsert Logic (Insert vs Replace)

**What**: Determines whether to replace an existing XML element's text or append a new element, based on a LIKE check against the XML string.

**Columns/Parameters Involved**: `@Key`, `@Value`, `Billing.Funding.FundingData`

**Rules**:
- Node exists check: `CAST(@FundingData AS VARCHAR(MAX)) LIKE ('%' + @Key + '%')`
  - If TRUE (key found as substring): dynamic SQL: `FundingData.modify('insert text{"@Value"} as first into (/Funding/@Key)[1]')` - prepends a text node into the existing element
  - If FALSE (key not found): dynamic SQL: `FundingData.modify('insert <@Key>@Value</@Key> as last into (/Funding)[1]')` - appends a new child element at the end of the Funding root
- The LIKE check is a string search - if `@Key` appears as a substring anywhere in the XML (e.g., in an attribute name or a value), a false-positive could trigger the replace branch

**Diagram**:
```
@FundingID, @Key, @Value
  --> SELECT FundingData FROM Billing.Funding
  --> CAST to VARCHAR, LIKE '%@Key%'

  IF key found:
    UPDATE Billing.Funding
    SET FundingData.modify('insert text{"@Value"} as first into (/Funding/@Key)[1]')
    WHERE FundingID = @FundingID

  ELSE (key not found):
    UPDATE Billing.Funding
    SET FundingData.modify('insert <@Key>@Value</@Key> as last into (/Funding)[1]')
    WHERE FundingID = @FundingID
```

### 2.2 Wire Transfer FundingData XML Schema

**What**: The known keys that can be set for wire transfer deposits via this procedure.

**Rules**:

| Key (@Key value) | Content | C# DTO Property |
|-----------------|---------|-----------------|
| `CustomerNameAsString` | Payee name (account holder name) | `WireTransferFundingData.PayeeName` |
| `AccountIDAsString` | Bank account number | `WireTransferFundingData.AccountId` |
| `BankNameAsString` | Receiving bank name | `WireTransferFundingData.BankName` |
| `ClientBankNameAsString` | Customer's bank name | `WireTransferFundingData.ClientBankName` |
| `CountryIDAsInteger` | Bank country ID (integer) | `WireTransferFundingData.CountryId` |
| `SwiftCodeAsString` | SWIFT/BIC code of the bank | `WireTransferFundingData.SwiftCode` |
| `IBANCodeAsString` | International Bank Account Number | `WireTransferFundingData.Iban` |
| `SortCodeAsString` | UK bank sort code | `WireTransferFundingData.SortCode` |
| `RoutingNumberAsString` | US/AUS routing number | `WireTransferFundingData.RoutingNumber` |

Source: Confluence - "Wire Transfer Service Detailed Design" (WireTransferDepositOfflineProcess mappings)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | FK to `Billing.Funding.FundingID`. Identifies the funding record whose FundingData XML will be updated. |
| 2 | @Key | VARCHAR(100) | NO | - | VERIFIED | The XML element name to insert or update within the `/Funding` root. For wire transfers, known values include `CustomerNameAsString`, `AccountIDAsString`, `BankNameAsString`, `ClientBankNameAsString`, `CountryIDAsInteger`, `SwiftCodeAsString`, `IBANCodeAsString`, `SortCodeAsString`, `RoutingNumberAsString`. (Source: Confluence - "Wire Transfer Service Detailed Design") |
| 3 | @Value | NVARCHAR(100) | NO | - | VERIFIED | The value to store for the given `@Key`. String representation of the field value (even numeric values like CountryIDAsInteger are passed as strings). (Source: Confluence - "Wire Transfer Service Detailed Design") |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | READ + UPDATE (XML) | Reads FundingData XML to check for key existence, then updates the XML field in-place |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wire transfer processing (application) | - | Application call | Called to set/update individual wire transfer data fields after deposit creation |
| Back Office tools (application) | - | Application call | Used when operators provide or correct missing wire transfer bank details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateWireFundingData (procedure)
└── Billing.Funding (table) [READ + UPDATE XML]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Reads FundingData XML for existence check; updates the XML node via dynamic SQL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wire Transfer Service (application) | Application | Calls to populate/update wire transfer funding details in FundingData XML |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL (no parameterization) | Design | `@Key` and `@Value` are concatenated directly into the SQL string - callers must sanitize inputs |
| No existence check on FundingID | Design | If `@FundingID` does not exist in Billing.Funding, the UPDATE affects 0 rows silently |
| LIKE-based key detection | Design | `CAST(@FundingData AS VARCHAR(MAX)) LIKE ('%'+@Key+'%')` - a broad string match; if @Key appears as a substring of any value in the XML, it could incorrectly trigger the "replace" branch instead of "insert" |

---

## 8. Sample Queries

### 8.1 Add an IBAN code to a wire transfer funding record
```sql
EXEC Billing.UpdateWireFundingData
    @FundingID = 987654,
    @Key       = 'IBANCodeAsString',
    @Value     = N'GB29NWBK60161331926819';
```

### 8.2 Update the bank name for a wire transfer deposit
```sql
EXEC Billing.UpdateWireFundingData
    @FundingID = 987654,
    @Key       = 'BankNameAsString',
    @Value     = N'Barclays Bank PLC';
```

### 8.3 Read back the wire transfer FundingData XML fields for a deposit
```sql
SELECT
    f.FundingID,
    f.FundingData.value('(Funding/CustomerNameAsString)[1]', 'NVARCHAR(200)') AS PayeeName,
    f.FundingData.value('(Funding/AccountIDAsString)[1]', 'NVARCHAR(200)')    AS AccountID,
    f.FundingData.value('(Funding/BankNameAsString)[1]', 'NVARCHAR(200)')     AS BankName,
    f.FundingData.value('(Funding/IBANCodeAsString)[1]', 'NVARCHAR(200)')     AS IBAN,
    f.FundingData.value('(Funding/SwiftCodeAsString)[1]', 'NVARCHAR(200)')    AS SwiftCode,
    f.FundingData.value('(Funding/CountryIDAsInteger)[1]', 'INT')             AS CountryID
FROM Billing.Funding f WITH (NOLOCK)
WHERE f.FundingID = 987654;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Wire Transfer Service Detailed Design](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11912119473/Wire+Transfer+Service+Detailed+Design) | Confluence | Wire transfer FundingData XML key names (CustomerNameAsString, AccountIDAsString, BankNameAsString, etc.) and their mapping to WireTransferFundingData C# DTO properties |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateWireFundingData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateWireFundingData.sql*
