# BackOffice.GetCustomersInfo

> Batch lookup that returns compliance-relevant customer details (verification level, email, username, regulation) for a given set of CIDs, used during wire deposit processing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns one row per CID in the @CIDs TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomersInfo is a batch customer data lookup procedure created as part of the mass wire deposit processing flow (MIMOPSA-3192, Jan 2021). Given a set of CIDs passed as a table-valued parameter, it returns the compliance-critical customer profile fields needed to process or route wire deposits: KYC verification level, email address, username, and the regulatory jurisdiction governing the account.

The procedure exists to give the wire deposit processing system a single efficient call to retrieve multi-customer compliance data without querying each customer individually. The TVP design (`BackOffice.IDs READONLY`) allows the caller to pass tens or hundreds of CIDs in a single batch and receive all their profiles in one result set.

RegulationID was added to the output in a subsequent enhancement (MIMOPSA-3267, Jan 2021) as part of a wire deposit improvement, reflecting the need to route or validate wire deposits differently based on the customer's regulatory entity (e.g., CySEC vs FCA vs BVI rules differ for wire transfer processing).

---

## 2. Business Logic

### 2.1 Batch CID Lookup via TVP

**What**: The procedure uses a Table-Valued Parameter to filter results to only the requested CIDs, enabling efficient batch processing.

**Columns/Parameters Involved**: `@CIDs` (BackOffice.IDs TVP)

**Rules**:
- Caller passes a set of CIDs as a `BackOffice.IDs` TVP (INT table with clustered PK, IGNORE_DUP_KEY=OFF)
- Procedure JOINs `@CIDs` against both `BackOffice.Customer` and `Customer.Customer` on CID
- Uses INNER JOIN to both - CIDs not present in either table are silently excluded
- Result is one row per valid CID in the input set
- BackOffice.IDs type enforces uniqueness at insert time, so no duplicate rows in output

**Diagram**:
```
Caller provides: @CIDs = {1001, 1002, 1003, ...}
                      |
                      v
BackOffice.Customer (KYC state, RegulationID)
         INNER JOIN Customer.Customer (Email, UserName)
         INNER JOIN @CIDs (filter to requested set)
                      |
                      v
Result: {CID, VerificationLevelID, Email, UserName, RegulationID} per CID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the set of CIDs to retrieve. Each row has one INT column `ID` (the CID). READONLY - procedure cannot modify it. Duplicates are rejected at caller side by the TVP's clustered PK. See BackOffice.IDs for the full type definition. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | int | NO | - | CODE-BACKED | Customer account ID - the primary key from both BackOffice.Customer and Customer.Customer. Uniquely identifies one trading account. From BackOffice.Customer.CID. |
| R2 | VerificationLevelID | - | NO | - | VERIFIED | KYC verification stage reached by this customer: 0=Unverified, 1=Partial, 2=Intermediate, 3=Fully Verified. FK to Dictionary.VerificationLevel. Determines which financial services the customer may access. From BackOffice.Customer. See BackOffice.Customer Section 2.2 for full KYC logic. |
| R3 | Email | varchar | YES | - | CODE-BACKED | Customer's registered email address. From Customer.Customer.Email. Used for contact and identity matching in wire deposit processing. |
| R4 | UserName | nvarchar | NO | - | CODE-BACKED | Customer's platform username. From Customer.Customer.UserName. Used for identification in the wire processing workflow. |
| R5 | RegulationID | - | NO | - | VERIFIED | Regulatory jurisdiction governing this account: CySEC, BVI, FCA, eToroUS, FSA Seychelles, ASIC, etc. Added Jan 2021 (MIMOPSA-3267) for wire deposit routing - different regulatory entities apply different wire transfer rules, limits, and compliance requirements. From BackOffice.Customer.RegulationID. See BackOffice.Customer Section 2.1 for regulation values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs | BackOffice.IDs | TVP (UDT) | Input filter - set of CIDs to look up |
| BC | BackOffice.Customer | INNER JOIN | Source of VerificationLevelID and RegulationID |
| CC | Customer.Customer | INNER JOIN | Source of Email and UserName |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the wire deposit processing system. No stored procedure callers found in BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomersInfo (procedure)
├── BackOffice.Customer (table)
├── Customer.Customer (table - cross-schema)
└── BackOffice.IDs (user defined type - TVP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | INNER JOIN on CID - provides VerificationLevelID and RegulationID |
| Customer.Customer | Table | INNER JOIN on CID - provides Email and UserName |
| BackOffice.IDs | User Defined Type | TVP parameter type - the IN-list of CIDs to retrieve |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wire deposit processing system (MIMOPSA-3192) | External | READER - calls this to batch-retrieve customer compliance info for wire processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Notable: `SET NOCOUNT ON` suppresses row-count messages for performance in batch contexts.

---

## 8. Sample Queries

### 8.1 Retrieve info for a small set of CIDs
```sql
DECLARE @CIDs BackOffice.IDs
INSERT INTO @CIDs VALUES (1001), (1002), (1003)

EXEC BackOffice.GetCustomersInfo @CIDs = @CIDs
```

### 8.2 Check verification levels for a batch of wire applicants
```sql
DECLARE @CIDs BackOffice.IDs
INSERT INTO @CIDs
SELECT CID FROM Billing.WireTransferToPayment WITH (NOLOCK)
WHERE PaymentStatusID = 1  -- pending

EXEC BackOffice.GetCustomersInfo @CIDs = @CIDs
```

### 8.3 Equivalent query for ad-hoc inspection
```sql
SELECT
    BC.CID,
    BC.VerificationLevelID,
    CC.Email,
    CC.UserName,
    BC.RegulationID
FROM BackOffice.Customer BC WITH (NOLOCK)
INNER JOIN Customer.Customer CC WITH (NOLOCK) ON BC.CID = CC.CID
WHERE BC.CID IN (1001, 1002, 1003)  -- replace with target CIDs
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-3197](https://etoro-jira.atlassian.net/browse/MIMOPSA-3197) | Jira | Procedure created by Ran Ovadia (Jan 2021) as part of "fix mass wire process flow" (MIMOPSA-3192) |
| [MIMOPSA-3267](https://etoro-jira.atlassian.net/browse/MIMOPSA-3267) | Jira | RegulationID added to select list by Stav R. (Jan 2021) as part of "Wire Deposit improvement" (MIMOPSA-3265) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 callers | App Code: SKIPPED (no BackOffice repos) | Corrections: 0 applied*
*Object: BackOffice.GetCustomersInfo | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomersInfo.sql*
