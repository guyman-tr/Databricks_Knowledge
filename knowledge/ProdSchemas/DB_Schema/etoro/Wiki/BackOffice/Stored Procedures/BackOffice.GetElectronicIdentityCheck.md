# BackOffice.GetElectronicIdentityCheck

> Returns the electronic identity verification (eIDV) result for a customer - the check outcome, provider, and transaction reference from the 2013-2014 GDC/GBGroup eIDV program.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Single CID lookup against BackOffice.ElectronicIdentityCheck; returns zero or one row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetElectronicIdentityCheck retrieves a customer's electronic identity verification (eIDV) record from the BackOffice.ElectronicIdentityCheck table. eIDV checks customer-provided personal details (name, date of birth, address) against third-party data bureaus and public record aggregators - an automated alternative to document-based KYC that was active at eToro from November 2013 to May 2014.

The procedure returns the check outcome (how well the customer's identity matched public data sources), the verification provider (GDC or GBGroup), and, for GBGroup checks, the transaction reference for auditing. It is exposed as `GDCCheckID` in the broader customer profile view (BackOffice.GetCustomerByCID).

This is the read-side counterpart of BackOffice.SetElectronicIdentityCheck which performs the UPSERT.

---

## 2. Business Logic

### 2.1 Single Customer eIDV Record Retrieval

**What**: Returns zero or one row for the given CID - either the customer has an eIDV record or they do not.

**Columns/Parameters Involved**: `@CID`, `BackOffice.ElectronicIdentityCheck.CID` (CLUSTERED PK)

**Rules**:
- Returns an empty result set if the customer has no eIDV record (no eIDV check was ever performed for them)
- The table contains 43,216 rows covering customers verified during Nov 2013 - May 2014 only; most customers registered after May 2014 will return empty results
- CID is the clustered PK of BackOffice.ElectronicIdentityCheck, so this is a single-row point lookup

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID whose eIDV result is to be retrieved. Clustered PK of BackOffice.ElectronicIdentityCheck. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | ElectronicIdentityCheckID | int | YES | - | VERIFIED | eIDV check outcome. Logical FK to Dictionary.ElectronicIdentityCheck. Values: 0=None (1 row), 1=One Source (24.4% - identity matched against one data bureau), 2=Two Sources (50.2% - full eIDV pass, matched against two independent sources), 3=No Match (25.4% - identity could not be confirmed). |
| R2 | ElectronicIdentityProviderID | int | YES | - | VERIFIED | eIDV service provider. Logical FK to Dictionary.ElectronicIdentityProvider. Values: 1=GDC (Global Data Corporation, 65.3% of records), 2=GB (GBGroup, 34.7%), 3=Au10tix (defined but 0 rows used for eIDV). |
| R3 | TransactionID | varchar(50) | YES | - | VERIFIED | External transaction reference from the eIDV provider. NULL for all GDC records (GDC does not return transaction IDs). Populated for all GBGroup records - allows querying GBGroup for the original verification response. |
| R4 | TransactionDate | datetime | YES | - | VERIFIED | UTC timestamp of the eIDV transaction. NULL for all GDC records. Populated for all GBGroup records. Historical range: 2013-11-04 to 2014-05-03. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.ElectronicIdentityCheck | SELECT | Source of eIDV record; point lookup on CID (CLUSTERED PK) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Consumed by BackOffice UI and APIs that display a customer's eIDV history. Also referenced as part of the GetCustomerByCID pipeline (ElectronicIdentityCheckID exposed as GDCCheckID).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetElectronicIdentityCheck (procedure)
└── BackOffice.ElectronicIdentityCheck (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ElectronicIdentityCheck | Table | SELECT of all 4 non-CID columns WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice UI / eIDV display | External | READER - displays eIDV result in customer profile |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Underlying table has a CLUSTERED PK on CID - this procedure executes as a single-row point lookup.

### 7.2 Constraints

N/A for Stored Procedure. SET NOCOUNT ON is present (suppresses row-count messages). The procedure returns an empty result set (not NULL or error) when no eIDV record exists for the CID.

---

## 8. Sample Queries

### 8.1 Get eIDV result for a customer
```sql
EXEC BackOffice.GetElectronicIdentityCheck @CID = 12345
-- Returns: ElectronicIdentityCheckID, ElectronicIdentityProviderID, TransactionID, TransactionDate
-- Empty result if customer has no eIDV record
```

### 8.2 Ad-hoc equivalent with decoded values
```sql
SELECT
    dic.Name AS CheckResult,
    dip.Name AS Provider,
    eic.TransactionID,
    eic.TransactionDate
FROM BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
JOIN Dictionary.ElectronicIdentityCheck dic WITH (NOLOCK)
    ON dic.ElectronicIdentityCheckID = eic.ElectronicIdentityCheckID
JOIN Dictionary.ElectronicIdentityProvider dip WITH (NOLOCK)
    ON dip.ElectronicIdentityProviderID = eic.ElectronicIdentityProviderID
WHERE eic.CID = 12345
```

### 8.3 Check eIDV pass rate for a set of customers
```sql
SELECT
    eic.ElectronicIdentityCheckID,
    dic.Name AS CheckResult,
    COUNT(*) AS Customers
FROM BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
LEFT JOIN Dictionary.ElectronicIdentityCheck dic WITH (NOLOCK)
    ON dic.ElectronicIdentityCheckID = eic.ElectronicIdentityCheckID
GROUP BY eic.ElectronicIdentityCheckID, dic.Name
ORDER BY Customers DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. eIDV data dates from 2013-2014, predating current Confluence documentation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetElectronicIdentityCheck | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetElectronicIdentityCheck.sql*
