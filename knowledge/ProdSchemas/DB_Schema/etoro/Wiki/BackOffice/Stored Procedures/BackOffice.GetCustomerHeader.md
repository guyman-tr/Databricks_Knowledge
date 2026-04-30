# BackOffice.GetCustomerHeader

> Returns the customer summary header row used at the top of the BackOffice customer profile: name, identity, account state, lifetime financials, and resolved country/state names.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerID - single customer lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a BackOffice agent opens a customer record, the header panel at the top of the page shows a concise summary: the customer's name, regulation, total deposits and cashouts, current balance and bonus credit, verification level, and resolved geographic fields (country name, state name). This procedure populates that header.

It is lighter than `GetCustomerByCID` (no equity calculation, no in-memory credit TVP, no PnL functions) - designed specifically for the fast header load. The country and state names are resolved via dictionary JOINs so the UI can display them without additional lookups.

Added progressively: country/state (Aug 2020, MIMOPS-1977), birth date (Sep 2020, MIMOPS-2244), customer status (Nov 2022, MIMOPSA-7044).

Note: `PlayerStatusID` appears twice - once as `PlayerStatusID` and once as `[CustomerStatus]`. This is a duplicate alias artifact from the 2022 addition of CustomerStatus.

---

## 2. Business Logic

### 2.1 State Name Conditional

**What**: State name is only shown if StateID is non-zero.

**Columns/Parameters Involved**: `[State]`, `CCS.StateID`, `Dictionary.State`

**Rules**:
- `CASE WHEN CCS.StateID <> 0 THEN DS.Name ELSE '' END`
- StateID=0 means no state assigned (customers outside states/provinces)
- Returns empty string (not NULL) when no state applies

### 2.2 NWA and Balance Aliases

**What**: BonusCredit is aliased as [NWA] (Net Worth Amount) and Credit is aliased as [Balance].

**Rules**:
- `BonusCredit` = any non-trading bonus/promotional credit balance
- `Credit` = the cash account balance (same as in GetCustomerByCID)
- Both cast to DECIMAL(16,2)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CustomerID | INTEGER | NO | - | CODE-BACKED | Customer ID to look up. |
| **Output Columns** | | | | | | |
| 2 | CustomerId | INT | NO | - | CODE-BACKED | Customer ID from BackOffice.Customer.CID. |
| 3 | FirstName | NVARCHAR | NO | - | CODE-BACKED | Customer first name. |
| 4 | MiddleName | NVARCHAR | YES | - | CODE-BACKED | Customer middle name. |
| 5 | LastName | NVARCHAR | NO | - | CODE-BACKED | Customer last name. |
| 6 | CountryId | INT | YES | - | CODE-BACKED | Customer's declared country ID. |
| 7 | RegulationId | INT | YES | - | CODE-BACKED | Regulatory jurisdiction ID. From BackOffice.Customer.RegulationID. |
| 8 | Comment | NVARCHAR | YES | - | CODE-BACKED | Internal BO comment. From Customer.Customer.Comments. |
| 9 | AccountTypeId | INT | YES | - | CODE-BACKED | Account type (individual, corporate). From BackOffice.Customer.AccountTypeID. |
| 10 | ThirdPartyManagerComment | NVARCHAR | YES | - | CODE-BACKED | Comment from third-party/white-label manager. From BackOffice.Customer.ThirdPartyManagerComment. |
| 11 | WhiteLabelId | INT | YES | - | CODE-BACKED | White-label partner ID. From Customer.Customer.LabelID. |
| 12 | TotalDeposit | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Lifetime total deposits. ISNULL(BCAD.TotalDeposit, 0). |
| 13 | TotalCashout | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Lifetime total cashouts. ISNULL(BCAD.TotalCashout, 0). |
| 14 | Email | NVARCHAR | YES | - | CODE-BACKED | Customer email address. |
| 15 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID. |
| 16 | NWA | DECIMAL(16,2) | YES | - | CODE-BACKED | Net Worth Amount - the customer's bonus credit balance. From Customer.Customer.BonusCredit. |
| 17 | Balance | DECIMAL(16,2) | YES | - | CODE-BACKED | Current cash account balance. From Customer.Customer.Credit. |
| 18 | PlayerStatusID | INT | YES | - | CODE-BACKED | Customer trading status ID. FK to Dictionary.PlayerStatus. |
| 19 | VerificationLevelID | INT | YES | - | CODE-BACKED | Current KYC verification level. From BackOffice.Customer.VerificationLevelID. |
| 20 | Address | NVARCHAR | YES | - | CODE-BACKED | Street address. |
| 21 | City | NVARCHAR | YES | - | CODE-BACKED | City of residence. |
| 22 | Zip | NVARCHAR | YES | - | CODE-BACKED | Postal code. |
| 23 | State | NVARCHAR | YES | '' | CODE-BACKED | State/province name. From Dictionary.State.Name. Empty string if StateID=0. |
| 24 | Country | NVARCHAR | YES | - | CODE-BACKED | Country name. From Dictionary.Country.Name via CountryID. |
| 25 | BirthDate | DATE | YES | - | CODE-BACKED | Customer date of birth. Added Sep 2020 (MIMOPS-2244). |
| 26 | CustomerStatus | INT | YES | - | CODE-BACKED | Duplicate of PlayerStatusID (same source: CCS.PlayerStatusID). Added Nov 2022 (MIMOPSA-7044). Historical artifact of incremental column addition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CustomerID | Customer.Customer | Primary Source | Core customer fields |
| CID | BackOffice.Customer | INNER JOIN | BO administrative state |
| CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN | Lifetime deposit/cashout totals |
| StateID | Dictionary.State | LEFT JOIN | State name resolution |
| CountryID | Dictionary.Country | LEFT JOIN | Country name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Customer profile header panel |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerHeader (procedure)
|- Customer.Customer (identity + balance)
|- BackOffice.Customer (BO state)
|- BackOffice.CustomerAllTimeAggregatedData (lifetime totals)
|- Dictionary.State (state name)
+-- Dictionary.Country (country name)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Primary source - name, contact, balance, GCID, dates |
| BackOffice.Customer | Table | INNER JOINed for RegulationID, AccountTypeID, VerificationLevelID, comments |
| BackOffice.CustomerAllTimeAggregatedData | Table | LEFT JOINed for TotalDeposit and TotalCashout |
| Dictionary.State | Table | LEFT JOINed to resolve StateID to name |
| Dictionary.Country | Table | LEFT JOINed to resolve CountryID to name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Customer profile header panel |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; `WITH(NOLOCK)` on all tables.

---

## 8. Sample Queries

### 8.1 Get customer header

```sql
EXEC BackOffice.GetCustomerHeader @CustomerID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-1977 | Jira (inferred from comment) | Added country and state fields to header, Aug 2020 |
| MIMOPS-2244 | Jira (inferred from comment) | Added BirthDate, Sep 2020 |
| MIMOPSA-7044 | Jira (inferred from comment) | Added CustomerStatus (PlayerStatusID duplicate), Nov 2022 |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerHeader | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerHeader.sql*
