# Billing.GetWireDepositsCountries

> Returns the list of country IDs from which a customer has made approved wire transfer deposits within a time window (default: last 1 year), extracted from FundingData XML; used to validate wire transfer deposit origin eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PayDate; returns one row per approved wire deposit with CountryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWireDepositsCountries retrieves the set of country IDs associated with a customer's approved wire transfer deposits within a rolling time window. The country is extracted from the `FundingData` XML field (`/Funding/CountryIDAsInteger`), which records the country of the wire transfer origin.

Use cases:
- **Wire transfer eligibility**: Verify that the sending country is on an approved list before processing a new wire deposit
- **Regulatory country checks**: Identify all countries from which a customer has historically wired funds (AML origin tracing)
- **Refund routing**: Determine which countries a refund might be sent back to

`@PayDate` defaults to `DATEADD(year, -1, GETDATE())` if not supplied, creating a 1-year rolling window. Callers can pass a specific date to extend or restrict the window.

---

## 2. Business Logic

### 2.1 Wire Deposit Country Extraction

**What**: Extracts CountryID from the FundingData XML for each approved wire transfer deposit in the time window.

**Columns/Parameters Involved**: `@CID`, `@PayDate`, `Billing.Deposit.PaymentDate`, `Billing.Deposit.PaymentStatusID`, `Billing.Funding.FundingTypeID`, `Billing.Funding.FundingData`

**Rules**:
- `WHERE bd.CID = @CID` - single customer
- `AND bd.PaymentDate > ISNULL(@PayDate, DATEADD(year, -1, GETDATE()))` - after cutoff (default: 1 year ago); note `>` not `>=`
- `AND bd.PaymentStatusID = 2` - approved deposits only
- `AND FundingTypeID = 2` - wire transfer only (FundingTypeID=2)
- `bf.FundingData.value('(/Funding/CountryIDAsInteger)[1]', 'INT')` - extracts country ID from XML payload as integer
- Returns one row per deposit (not deduplicated) - caller receives the full list including duplicate countries

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Billing.Deposit to this customer's deposits only. |
| 2 | @PayDate | DATETIME | YES | NULL (defaults to 1 year ago) | CODE-BACKED | Lower bound cutoff for PaymentDate. If NULL, defaults to DATEADD(year, -1, GETDATE()). Deposits with PaymentDate strictly greater than this value are included. |
| - | CountryID | INT | YES | - | CODE-BACKED | Country ID extracted from FundingData XML node (/Funding/CountryIDAsInteger). Represents the country of origin for the wire transfer. NULL if the XML node is absent or unparseable. One row per qualifying deposit (not deduplicated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentDate, PaymentStatusID, FundingID | Billing.Deposit | SELECT | Source of deposit records; filtered to approved wire deposits in time window |
| FundingID, FundingTypeID=2, FundingData | Billing.Funding | INNER JOIN | Wire type filter; provides FundingData XML for country extraction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wire transfer deposit service | @CID, @PayDate | EXEC | Origin country validation for wire transfer eligibility and AML checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWireDepositsCountries (procedure)
+-- Billing.Deposit (table) [approved wire deposits in time window]
+-- Billing.Funding (table) [FundingTypeID=2 filter + FundingData XML]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | PaymentDate window, PaymentStatusID=2, CID filter; provides FundingID |
| Billing.Funding | Table | FundingTypeID=2 (wire) filter; FundingData XML extraction of CountryIDAsInteger |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wire transfer deposit service | External | Country origin set for eligibility and AML checks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID=2 hardcoded | Design | Wire transfer only; other funding types excluded |
| PaymentStatusID=2 hardcoded | Design | Approved only; pending/rejected wire deposits excluded |
| No NOLOCK | Concurrency | No WITH (NOLOCK) hints; reads committed data |
| Non-deduplicated result | Behavior | Returns one row per deposit, not per unique country; caller must DISTINCT if needed |
| Local time default | Design | GETDATE() (not GETUTCDATE()) used for default @PayDate; ensure consistency with PaymentDate storage convention |
| XML extraction | Performance | FundingData.value() per row; acceptable for small result sets |

---

## 8. Sample Queries

### 8.1 Get wire deposit countries for a customer (last year)

```sql
EXEC [Billing].[GetWireDepositsCountries] @CID = 12345
-- Returns: CountryID per approved wire deposit in last 12 months
```

### 8.2 Get wire deposit countries since a specific date

```sql
EXEC [Billing].[GetWireDepositsCountries]
    @CID = 12345,
    @PayDate = '2025-01-01'
-- Returns countries from wire deposits after 2025-01-01
```

### 8.3 Get distinct wire deposit countries (deduplicated)

```sql
SELECT DISTINCT
    bf.FundingData.value('(/Funding/CountryIDAsInteger)[1]', 'INT') AS CountryID
FROM [Billing].[Deposit] bd WITH (NOLOCK)
INNER JOIN [Billing].[Funding] bf WITH (NOLOCK) ON bd.FundingID = bf.FundingID
WHERE bd.CID = 12345
  AND bd.PaymentDate > DATEADD(year, -1, GETDATE())
  AND bd.PaymentStatusID = 2
  AND bf.FundingTypeID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWireDepositsCountries | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWireDepositsCountries.sql*
