# BackOffice.GetEtoroMoneyByPlatformAccountId

> Returns the FundingID for an eToro Money wallet account by its platform account UUID - looks up FundingTypeID=33 records in Billing.Funding by extracting PlatformAccountIDAsString from the FundingData XML.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlatformAccountId lookup via XML value extraction against Billing.Funding FundingTypeID=33 (150,127 rows) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetEtoroMoneyByPlatformAccountId resolves an eToro Money platform account UUID to the corresponding Billing.Funding record. eToro Money is eToro's own e-money wallet service (FundingTypeID=33); each customer's eToro Money account is identified by a UUID (`PlatformAccountIDAsString`) stored in the FundingData XML column alongside the customer's GCID.

When a payment event arrives through the eToro Money channel, the payment system passes a platform account UUID that needs to be resolved to a FundingID for billing and reconciliation. This procedure performs that reverse lookup: given the UUID, find the FundingID.

FundingData XML structure for FundingTypeID=33:
```xml
<Funding>
  <GCIDAsLong>20308343</GCIDAsLong>
  <PlatformAccountIDAsString>844355eb-c668-4465-9d12-9b4d6d0689e5</PlatformAccountIDAsString>
</Funding>
```

As of 2026-03-17 there are 150,127 eToro Money funding records in Billing.Funding.

---

## 2. Business Logic

### 2.1 XML Value Extraction Filter

**What**: Both the WHERE filter and the SELECT extract the same XML value from FundingData, meaning the XML is parsed twice per row during a scan.

**Columns/Parameters Involved**: `@PlatformAccountId`, `BFUN.FundingData.value('/Funding[1]/PlatformAccountIDAsString[1]','VARCHAR(MAX)')`

**Rules**:
- `FundingTypeID = 33` narrows the scan to eToro Money fundings only (150,127 rows vs the much larger total Funding table)
- The XML `.value()` expression `/Funding[1]/PlatformAccountIDAsString[1]` extracts the UUID string from the XML column
- The same extraction appears in both WHERE and SELECT - XML is parsed twice per row (no ability to alias in WHERE)
- PlatformAccountIDAsString values are UUIDs (GUIDs) formatted as lowercase hex strings with dashes: `844355eb-c668-4465-9d12-9b4d6d0689e5`
- One FundingRecord per eToro Money account (PlatformAccountIDAsString is unique per customer/account)
- The FundingData XML also contains `GCIDAsLong` (customer GCID) but this is not returned by the procedure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlatformAccountId | NVARCHAR(255) | NO | - | CODE-BACKED | eToro Money platform account UUID to look up. Matched against PlatformAccountIDAsString in FundingData XML of FundingTypeID=33 records. Format: lowercase GUID string (e.g., '844355eb-c668-4465-9d12-9b4d6d0689e5'). |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | int | NO | - | CODE-BACKED | Billing.Funding PK for the matching eToro Money funding record. Used for deposit/withdrawal transactions against this eToro Money account. |
| R2 | PlatformAccountId | varchar(MAX) | YES | - | CODE-BACKED | The eToro Money platform account UUID, re-extracted from FundingData XML. Matches @PlatformAccountId (assuming a match was found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BFUN | Billing.Funding | SELECT | Source of eToro Money funding records; filtered to FundingTypeID=33 with XML value match |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from BackOffice operations and payment reconciliation workflows when processing eToro Money transactions by platform account UUID.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetEtoroMoneyByPlatformAccountId (procedure)
└── Billing.Funding (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT FundingID WHERE FundingTypeID=33 AND XML value = @PlatformAccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro Money payment service | External | READER - resolves platform account UUID to FundingID for payment processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Performance note: This procedure scans all 150,127 FundingTypeID=33 rows and applies XML value extraction on each row. There is no XML index on FundingData for PlatformAccountIDAsString. The FundingTypeID filter reduces the scan domain, but the XML parsing per row makes this O(n) relative to the number of eToro Money fundings. The procedure may be slow under high call volume.

### 7.2 Constraints

N/A for Stored Procedure. The XML is parsed twice per qualifying row (once in WHERE, once in SELECT) because SQL Server does not allow column alias reuse in WHERE. An XML index on `FundingData` for the `/Funding[1]/PlatformAccountIDAsString[1]` path would improve performance.

---

## 8. Sample Queries

### 8.1 Look up eToro Money funding by platform account UUID
```sql
EXEC BackOffice.GetEtoroMoneyByPlatformAccountId
    @PlatformAccountId = '844355eb-c668-4465-9d12-9b4d6d0689e5'
-- Returns: FundingID, PlatformAccountId
```

### 8.2 Ad-hoc equivalent
```sql
SELECT
    FundingID,
    FundingData.value('/Funding[1]/PlatformAccountIDAsString[1]', 'VARCHAR(MAX)') AS PlatformAccountId,
    FundingData.value('/Funding[1]/GCIDAsLong[1]', 'BIGINT') AS GCID
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 33
  AND FundingData.value('/Funding[1]/PlatformAccountIDAsString[1]', 'VARCHAR(MAX)') = '844355eb-c668-4465-9d12-9b4d6d0689e5'
```

### 8.3 Count eToro Money funding records
```sql
SELECT COUNT(*) AS TotalEtoroMoneyFundings
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 33
-- 150,127 records as of 2026-03-17
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetEtoroMoneyByPlatformAccountId | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetEtoroMoneyByPlatformAccountId.sql*
