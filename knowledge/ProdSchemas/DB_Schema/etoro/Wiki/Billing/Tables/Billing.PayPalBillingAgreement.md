# Billing.PayPalBillingAgreement

> System-versioned temporal table storing the active PayPal Billing Agreement ID for each customer's PayPal funding method, enabling eToro to charge future deposits against a pre-authorized PayPal agreement without re-authentication.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table (SYSTEM_VERSIONED temporal - current state) |
| **Key Identifier** | PayPalBillingAgreementID (INT IDENTITY, PK CLUSTERED) - natural key: (CID, FundingID) via NC index |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 2 active (PK clustered + NC on CID+FundingID) |
| **History Table** | History.PayPalBillingAgreement |

---

## 1. Business Meaning

Billing.PayPalBillingAgreement stores the active PayPal Billing Agreement token for each customer-funding method combination. A PayPal Billing Agreement (ID format "B-xxxx") is a pre-authorization that allows eToro to initiate future charges against a customer's PayPal account without the customer having to log in and approve each individual transaction. This enables one-click deposits via PayPal after the initial agreement is established.

The agreement is created when a customer makes their first PayPal deposit (DepositID links to the qualifying deposit). The MERGE upsert in PayPalBillingAgreementInsert ensures each (CID, FundingID) pair has only one active agreement - if the agreement ID changes (e.g., customer re-authorizes), the existing row is updated. Historical agreement IDs are preserved in History.PayPalBillingAgreement via SQL Server's system-versioning engine.

With 5,958 rows, this table represents eToro customers who have set up recurring PayPal authorization. The table includes the Trace computed column - eToro's standard diagnostic pattern capturing host, application, user, SPID, DB, and calling object at the time of modification.

---

## 2. Business Logic

### 2.1 Agreement Registration (MERGE Upsert)

**What**: PayPalBillingAgreementInsert creates or updates a billing agreement for a (CID, FundingID) pair.

**Columns/Parameters Involved**: `CID`, `FundingID`, `BillingAgreementID`, `DepositID`

**Rules**:
- MERGE match condition: PPBA.CID = dest.CID AND PPBA.FundingID = dest.FundingID.
- Source data: FundingID is looked up from Billing.Deposit WHERE DepositID = @DepositID (not passed directly - derived from the qualifying deposit).
- WHEN MATCHED AND BillingAgreementID NOT LIKE dest.BillingAgreementID: Updates only if the agreement ID has changed. Prevents redundant updates when the same agreement is re-submitted.
- WHEN NOT MATCHED: Inserts the new agreement with the FundingID from the qualifying deposit.
- System versioning: Any UPDATE or DELETE automatically writes the old row to History.PayPalBillingAgreement with SysEndTime = moment of change.
- OUTPUT Inserted.*: Returns the new/updated row to the caller.

### 2.2 Agreement Retrieval and Deletion

**What**: PayPalBillingAgreementGet retrieves the current agreement; PayPalBillingAgreementDelete removes it.

**Columns/Parameters Involved**: `CID`, `FundingID`, `BillingAgreementID`

**Rules**:
- Lookup by CID+FundingID (covered by NC index) to find the active agreement token.
- Deletion removes the current agreement row (moved to history by system versioning).
- GetPreferredPayPalAccount SP may read this table to determine the customer's preferred PayPal account for deposit.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 5,958 |
| Agreement ID format | "B-{alphanumeric}" (PayPal standard format) |
| Unique per | (CID, FundingID) combination |
| History table | History.PayPalBillingAgreement |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PayPalBillingAgreementID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Business lookups use the NC index on (CID, FundingID). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. Implicit FK to Customer.CustomerStatic. Links the billing agreement to the eToro account holder. Part of the natural key (CID, FundingID). |
| 3 | FundingID | int | NO | - | CODE-BACKED | PayPal funding method record. FK to Billing.Funding (no constraint declared). Identifies which of the customer's PayPal accounts this agreement covers. Part of the natural key with CID. Derived from the qualifying deposit's FundingID on creation. |
| 4 | BillingAgreementID | nvarchar(255) | NO | - | VERIFIED | PayPal-issued billing agreement token. Format: "B-{alphanumeric}" (e.g., "B-9A799191869348008"). This is the token eToro uses when initiating charges against the customer's pre-authorized PayPal account. Only updated if the agreement ID changes (MERGE condition: NOT LIKE). |
| 5 | DepositID | int | NO | - | CODE-BACKED | The deposit that established or last renewed this billing agreement. FK to Billing.Deposit (no constraint). Links the agreement to its origin deposit - important for tracing when the agreement was authorized and under what transaction. |
| 6 | Trace | computed | - | - | CODE-BACKED | Diagnostic computed column (not persisted): JSON string capturing host_name(), app_name(), suser_name(), @@spid, db_name(), object_name(@@procid) at DML execution time. eToro's standard audit pattern to identify the application/service/stored procedure that last modified the row. Read-only - computed on each access. |
| 7 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | System-versioning temporal column (HIDDEN). UTC timestamp when the current row version became active. Set by SQL Server automatically. Used for point-in-time queries via FOR SYSTEM_TIME AS OF. |
| 8 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59 | CODE-BACKED | System-versioning temporal column (HIDDEN). For current rows: 9999-12-31 23:59:59 (far future = still active). When a row is updated or deleted, SQL Server sets this to the change timestamp and moves the old version to History.PayPalBillingAgreement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer who owns the billing agreement. |
| FundingID | Billing.Funding | Implicit | PayPal payment account linked to the agreement. |
| DepositID | Billing.Deposit | Implicit | Origin deposit that established the agreement. |
| (table) | History.PayPalBillingAgreement | Temporal History | SQL Server writes old row versions to this history table on UPDATE/DELETE. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayPalBillingAgreementInsert | CID, FundingID, BillingAgreementID, DepositID | MERGE writer | Creates or updates the billing agreement. PAYUSOLA-4629, Inna A., Mar 2022. |
| Billing.PayPalBillingAgreementGet | CID, FundingID | SELECT reader | Retrieves the current billing agreement token for a customer+funding method. |
| Billing.PayPalBillingAgreementDelete | - | DELETE writer | Removes the billing agreement (moves to history via system versioning). |
| Billing.GetPreferredPayPalAccount | - | SELECT reader | Reads billing agreements to find the customer's preferred PayPal account. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalBillingAgreement (table)
  (leaf - tables have no code-level dependencies)
  -> History.PayPalBillingAgreement (temporal history - auto-maintained by SQL Server)
```

---

### 6.1 Objects This Depends On

No FK constraints declared.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayPalBillingAgreementInsert | Stored Procedure | MERGE writer |
| Billing.PayPalBillingAgreementGet | Stored Procedure | SELECT reader |
| Billing.PayPalBillingAgreementDelete | Stored Procedure | DELETE writer |
| Billing.GetPreferredPayPalAccount | Stored Procedure | SELECT reader |
| History.PayPalBillingAgreement | Table | System-versioned history table (auto-maintained) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PayPalBillingAggreement | CLUSTERED PK | PayPalBillingAgreementID ASC | - | - | Active (note: typo "Aggreement" in constraint name) |
| IX_PayPalBillingAgreement_CID_FundingID | NC | CID ASC, FundingID ASC | - | - | Active - supports natural key lookup for MERGE and GET operations |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PayPalBillingAggreement | PRIMARY KEY | PayPalBillingAgreementID clustered (note typo in name) |
| PERIOD FOR SYSTEM_TIME | Temporal | SysStartTime/SysEndTime define row validity period |
| SYSTEM_VERSIONING = ON | Temporal | History table: History.PayPalBillingAgreement |
| DF_Payment_SysStart | DEFAULT | sysutcdatetime() for SysStartTime |
| DF_Payment_SysEnd | DEFAULT | 9999-12-31 23:59:59.9999999 for SysEndTime |

---

## 8. Sample Queries

### 8.1 Get current billing agreement for a customer+funding method

```sql
SELECT BillingAgreementID, DepositID, SysStartTime
FROM Billing.PayPalBillingAgreement WITH (NOLOCK)
WHERE CID = @CID AND FundingID = @FundingID
```

### 8.2 Get all PayPal billing agreements for a customer

```sql
SELECT ppba.PayPalBillingAgreementID, ppba.FundingID, ppba.BillingAgreementID, ppba.DepositID
FROM Billing.PayPalBillingAgreement ppba WITH (NOLOCK)
WHERE ppba.CID = @CID
```

### 8.3 View agreement history for audit

```sql
SELECT BillingAgreementID, DepositID, SysStartTime, SysEndTime
FROM Billing.PayPalBillingAgreement FOR SYSTEM_TIME ALL
WHERE CID = @CID AND FundingID = @FundingID
ORDER BY SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

Code comment in Billing.PayPalBillingAgreementInsert references Jira PAYUSOLA-4629 (Inna A., 27/03/2022 - Initial version). This was the initial implementation of PayPal Billing Agreement support.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PayPalBillingAgreement | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PayPalBillingAgreement.sql*
