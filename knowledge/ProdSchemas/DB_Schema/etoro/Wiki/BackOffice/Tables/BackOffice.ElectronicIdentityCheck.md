# BackOffice.ElectronicIdentityCheck

> One row per customer (43,216 rows) recording the result and provider of their electronic identity verification (eIDV) check. Two providers used: GDC (Global Data Corporation, 65.3%) and GB (GBGroup, 34.7%). Check results: Two Sources (50.2%), No Match (25.4%), One Source (24.4%). Data dates exclusively from 2013-11-04 to 2014-05-03, indicating this feature was active for ~6 months.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.ElectronicIdentityCheck stores the result of automated electronic identity verification (eIDV) for each customer. Unlike document-based KYC (passports, utility bills), eIDV checks customer-provided personal details (name, date of birth, address) against data held by third-party data bureaus and public record aggregators. A match against two independent data sources ("Two Sources") is the strongest verification outcome; "One Source" is a partial match; "No Match" indicates the customer's identity could not be confirmed electronically.

This table was created as part of Facebook Case 17883, which migrated the GDCCheckID column from BackOffice.Customer into a dedicated table to support multiple providers. It is referenced by GetCustomerByCID (as `GDCCheckID`) confirming this data was surfaced in the BackOffice customer profile view.

**Providers**:
- **GDC (ID=1)**: Global Data Corporation - a data aggregation and identity verification service. The dominant provider (65.3% of rows). GDC rows have NULL TransactionID and TransactionDate, meaning only the outcome was recorded (no transaction reference).
- **GB (ID=2)**: GBGroup (GBG) - a UK-based identity data intelligence company. All 15,005 GB rows have TransactionID and TransactionDate populated, providing a full audit trail.
- **Au10tix (ID=3)**: Israeli identity document verification company (also used in DocumentVendors for document-based KYC). Defined in the lookup but 0 rows in the data - never used for eIDV.

**Check outcomes**:
- **0 = None**: No check performed (1 row).
- **1 = One Source**: Identity matched against one data source - partial verification.
- **2 = Two Sources**: Identity matched against two independent data sources - full eIDV pass.
- **3 = No Match**: No data source match found - eIDV failed.

The data range (2013-11-04 to 2014-05-03) places this firmly in the early eToro regulatory compliance era. The narrow date window suggests either the eIDV feature was later superseded by document-based KYC processes, or records beyond this window were purged/migrated.

---

## 2. Business Logic

### 2.1 UPSERT via SetElectronicIdentityCheck

**What**: Creates or updates a customer's eIDV record. One record per customer.

**Columns Involved**: All columns.

**Rules**:
- SetElectronicIdentityCheck(@CID, @ElectronicIdentityCheckID, @ElectronicIdentityProviderID, @TransactionID=NULL, @TransactionDate=NULL):
  - If CID exists: UPDATE all fields.
  - If CID does not exist: INSERT new row.
- No FK constraints declared - ElectronicIdentityCheckID and ElectronicIdentityProviderID are logically FK to Dictionary tables but enforced only by application code.
- @ElectronicIdentityCheckID defaults to 0 (None) if not supplied.
- @TransactionID and @TransactionDate are optional (NULL-able) - GDC does not provide transaction references.

### 2.2 Read via GetElectronicIdentityCheck

**What**: Returns all eIDV fields (except CID) for a given customer.

**Columns Involved**: ElectronicIdentityCheckID, ElectronicIdentityProviderID, TransactionID, TransactionDate.

**Rules**:
- Simple SELECT WHERE CID = @CID.
- Returns empty result set if no eIDV record exists for the customer (no default row).

### 2.3 Exposure via GetCustomerByCID

**What**: ElectronicIdentityCheckID is exposed as `GDCCheckID` in the master customer profile query.

**Rules**:
- GetCustomerByCID LEFT JOINs BackOffice.ElectronicIdentityCheck ON CID, returning ElectronicIdentityCheckID aliased as GDCCheckID.
- NULL if no eIDV record exists.

---

## 3. Data Overview

43,216 rows as of 2026-03-17. One row per customer (43,216 distinct CIDs).

**By provider**:

| ElectronicIdentityProviderID | Name | Rows | Pct |
|------------------------------|------|------|-----|
| 1 | GDC | 28,211 | 65.3% |
| 2 | GB | 15,005 | 34.7% |

**By check result**:

| ElectronicIdentityCheckID | Name | Rows | Pct |
|---------------------------|------|------|-----|
| 2 | Two Sources | 21,686 | 50.2% |
| 3 | No Match | 10,958 | 25.4% |
| 1 | One Source | 10,571 | 24.4% |
| 0 | None | 1 | 0.0% |

**TransactionID/TransactionDate**: NULL for 28,178 rows (aligned with GDC rows - GDC does not return transaction references). All 15,005 GB rows have non-NULL transaction data.

**Date range**: 2013-11-04 to 2014-05-03.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. CLUSTERED PK. One row per customer. Logical FK to BackOffice.Customer (no declared constraint). 43,216 distinct values. |
| 2 | ElectronicIdentityCheckID | int | YES | NULL | VERIFIED | eIDV result code. Logical FK to Dictionary.ElectronicIdentityCheck. Values: 0=None (1 row), 1=One Source (24.4%), 2=Two Sources (50.2%), 3=No Match (25.4%). "Two Sources" is the passing outcome confirming identity against two independent data bureaus. |
| 3 | ElectronicIdentityProviderID | int | YES | NULL | VERIFIED | eIDV service provider. Logical FK to Dictionary.ElectronicIdentityProvider. Values: 1=GDC (Global Data Corporation, 65.3%), 2=GB (GBGroup, 34.7%), 3=Au10tix (defined but 0 rows). |
| 4 | TransactionID | varchar(50) | YES | NULL | VERIFIED | External transaction reference from the eIDV provider. NULL for all GDC rows (GDC does not return transaction IDs). Populated for all GB rows - allows querying GBGroup for the original verification record. Max 50 chars. |
| 5 | TransactionDate | datetime | YES | NULL | VERIFIED | UTC timestamp of the eIDV transaction. NULL for all GDC rows. Populated for all GB rows. Range: 2013-11-04 to 2014-05-03. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | Implicit FK | One eIDV record per customer |
| ElectronicIdentityCheckID | Dictionary.ElectronicIdentityCheck | Implicit FK | eIDV outcome (None/One Source/Two Sources/No Match) |
| ElectronicIdentityProviderID | Dictionary.ElectronicIdentityProvider | Implicit FK | eIDV provider (GDC/GB/Au10tix) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetElectronicIdentityCheck | CID | WRITER (UPSERT) | Creates or updates the eIDV record |
| BackOffice.GetElectronicIdentityCheck | CID | READER | Returns eIDV result for a customer |
| BackOffice.GetCustomerByCID | CID | READER (LEFT JOIN) | Exposes ElectronicIdentityCheckID as GDCCheckID in master customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ElectronicIdentityCheck (table)
- Logical FK targets (no declared constraints):
  |- BackOffice.Customer (CID)
  |- Dictionary.ElectronicIdentityCheck (ElectronicIdentityCheckID)
  |- Dictionary.ElectronicIdentityProvider (ElectronicIdentityProviderID)
- Writers: BackOffice.SetElectronicIdentityCheck
- Readers: BackOffice.GetElectronicIdentityCheck, BackOffice.GetCustomerByCID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Implicit FK on CID |
| Dictionary.ElectronicIdentityCheck | Table | Implicit FK on ElectronicIdentityCheckID (4 values) |
| Dictionary.ElectronicIdentityProvider | Table | Implicit FK on ElectronicIdentityProviderID (3 values: GDC, GB, Au10tix) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetElectronicIdentityCheck | Procedure | WRITER - UPSERT eIDV result |
| BackOffice.GetElectronicIdentityCheck | Procedure | READER - retrieve eIDV result |
| BackOffice.GetCustomerByCID | Procedure | READER - LEFT JOIN, exposes as GDCCheckID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BackOfficeElectronicIdentityCheck | CLUSTERED PK | CID ASC | Active (FILLFACTOR=90, ON [MAIN]) |

Single-column clustered PK on CID - optimal for the primary access pattern (lookup by CID). No additional NC indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOfficeElectronicIdentityCheck | PK | CID uniqueness (one eIDV record per customer) |

No FK constraints declared despite logical relationships to Dictionary.ElectronicIdentityCheck, Dictionary.ElectronicIdentityProvider, and BackOffice.Customer. Referential integrity enforced by application code only.

---

## 8. Sample Queries

### 8.1 Get eIDV result for a customer
```sql
SELECT eic.CID,
       dic.Name AS CheckResult,
       dip.Name AS Provider,
       eic.TransactionID,
       eic.TransactionDate
FROM BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
JOIN Dictionary.ElectronicIdentityCheck dic WITH (NOLOCK)
    ON dic.ElectronicIdentityCheckID = eic.ElectronicIdentityCheckID
JOIN Dictionary.ElectronicIdentityProvider dip WITH (NOLOCK)
    ON dip.ElectronicIdentityProviderID = eic.ElectronicIdentityProviderID
WHERE eic.CID = @CID
```

### 8.2 eIDV pass rate by provider
```sql
SELECT dip.Name AS Provider,
       dic.Name AS CheckResult,
       COUNT(*) AS CustomerCount,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY dip.Name) AS DECIMAL(5,1)) AS PctOfProvider
FROM BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
JOIN Dictionary.ElectronicIdentityCheck dic WITH (NOLOCK)
    ON dic.ElectronicIdentityCheckID = eic.ElectronicIdentityCheckID
JOIN Dictionary.ElectronicIdentityProvider dip WITH (NOLOCK)
    ON dip.ElectronicIdentityProviderID = eic.ElectronicIdentityProviderID
GROUP BY dip.Name, dic.Name
ORDER BY dip.Name, CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The 2013-2014 data range predates most Confluence documentation. The `FB case 17883` reference in GetCustomerByCID comment indicates the table was created in response to a specific product requirement to support multi-provider eIDV checks, migrating GDCCheckID out of BackOffice.Customer.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ElectronicIdentityCheck | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.ElectronicIdentityCheck.sql*
