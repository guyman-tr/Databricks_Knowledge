# Trade.GetCustomersDataWithRestirctions

> Retrieves customer profile data (credit, equity, player level, labels, regulation) plus copy-trade blocking restrictions for a set of customers. Extended version of GetCustomersDataWithCopyRestirctions with RegulationID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCIDs (CSV) + @CopiedCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCustomersDataWithRestirctions (note: "Restrictions" is intentionally misspelled in the object name) collects comprehensive customer profile data including their regulatory jurisdiction, then retrieves copy-trade blocking restrictions. It is nearly identical to Trade.GetCustomersDataWithCopyRestirctions but adds RegulationID to the output, making it useful for workflows that need regulatory context alongside customer profile data.

This procedure exists to serve the CopyTrader feature and back-office tools that require knowing which regulation a customer falls under (e.g., CySEC, FCA, ASIC) in addition to their profile and copy-trade block status.

Data flow: The caller passes a CSV of GCIDs and/or a single CopiedCID. The procedure splits the CSV, calls Trade.GetUserInfoByGCIDs or Trade.GetUserInfo, collects results into a temp table, then calls Trade.GetCustomersRestrictionsByTypesForAPI with OperationTypeID=2 for copy blocks. The temp table includes RegulationID (not present in the CopyRestrictions variant).

---

## 2. Business Logic

### 2.1 Dual Input Paths

**What**: Supports two ways to identify customers - by a CSV of GCIDs or by a single CopiedCID.

**Columns/Parameters Involved**: `@GCIDs`, `@CopiedCID`

**Rules**:
- If @GCIDs is provided: splits by comma into Trade.CidList TVP, calls Trade.GetUserInfoByGCIDs
- If @CopiedCID is provided: calls Trade.GetUserInfo for that single CID
- Both can be provided - results are combined in #GCID_Based_T

### 2.2 Copy Block Restriction Filter

**What**: Retrieves copy-trade-specific blocking restrictions (OperationTypeID=2).

**Columns/Parameters Involved**: `OperationTypeID`

**Rules**:
- OperationTypeID=2 means "copy block" - the customer is blocked from being copied
- Second result set from Trade.GetCustomersRestrictionsByTypesForAPI

**Diagram**:
```
Input: @GCIDs (CSV) + @CopiedCID
  |
  +-- Trade.GetUserInfoByGCIDs (for GCID list)
  +-- Trade.GetUserInfo (for single CID)
  |     -> #GCID_Based_T (includes RegulationID)
  |
  Result Set 1: Customer profile with RegulationID
  Result Set 2: Copy block restrictions (OperationTypeID=2)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDs | varchar(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of Global Customer IDs. |
| 2 | @CopiedCID | int | YES | NULL | CODE-BACKED | Single Customer ID of a copied trader. |

### Output - Result Set 1 (Customer Profile)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Credit | bigint | YES | - | CODE-BACKED | Customer's credit/bonus balance. |
| 2 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assignment. |
| 3 | LotCountGroupID | int | YES | - | CODE-BACKED | Lot count group assignment. |
| 4 | PlayerStatusID | int | YES | - | CODE-BACKED | Player status. FK to Dictionary.PlayerStatus. |
| 5 | LabelID | int | YES | - | CODE-BACKED | Customer label/tag. |
| 6 | IsCupon | bit | YES | - | CODE-BACKED | Whether customer has an active coupon/promotion. |
| 7 | TotalCash | decimal(16,8) | YES | - | CODE-BACKED | Total cash balance. |
| 8 | PlayerLevelID | int | YES | - | CODE-BACKED | Player tier level. FK to Dictionary.PlayerLevel. |
| 9 | RealizedEquity | money | YES | - | CODE-BACKED | Realized equity (cash + closed PnL). |
| 10 | IsCopyBlocked | bit | YES | - | CODE-BACKED | Whether this customer is blocked from copy trading. |
| 11 | CopyBlockReasonID | int | YES | - | CODE-BACKED | Reason for the copy block. |
| 12 | IsBeingCopied | bit | YES | - | CODE-BACKED | Whether other customers are currently copying this customer. |
| 13 | CountryID | int | YES | - | CODE-BACKED | Customer's country. FK to Dictionary.Country. |
| 14 | UserName | varchar(max) | YES | - | CODE-BACKED | Customer's platform username. |
| 15 | CountryName | varchar(max) | YES | - | CODE-BACKED | Human-readable country name. |
| 16 | AffiliateID | int | YES | - | CODE-BACKED | Affiliate/referral partner ID. |
| 17 | GCID | bigint | YES | - | CODE-BACKED | Global Customer ID. |
| 18 | CID | bigint | YES | - | CODE-BACKED | Customer ID. |
| 19 | IsFund | bit | YES | - | CODE-BACKED | Whether this is a fund/portfolio account. |
| 20 | TradingRiskStatusID | int | YES | - | CODE-BACKED | Trading risk status classification. |
| 21 | RegulationID | int | YES | - | CODE-BACKED | Regulatory jurisdiction for this customer. FK to Dictionary.Regulation. Distinguishes this SP from GetCustomersDataWithCopyRestirctions. |
| 22 | Registered | datetime | YES | - | CODE-BACKED | Customer registration date. |
| 23 | GuruStatusID | int | YES | - | CODE-BACKED | Popular Investor (guru) program status. |
| 24 | AccountTypeID | int | YES | - | CODE-BACKED | Account type. FK to Dictionary.AccountType. |

### Output - Result Set 2 (Copy Restrictions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID with a copy block restriction. |
| 2 | OperationTypeID | int | NO | - | CODE-BACKED | Always 2 (copy block) in this context. |
| 3 | Occurred | datetime | YES | - | CODE-BACKED | When the block was applied. |
| 4 | BlockReasonID | int | YES | - | CODE-BACKED | Reason for the block. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCIDs | Trade.GetUserInfoByGCIDs | EXEC | Customer profile data for GCID list |
| @CopiedCID | Trade.GetUserInfo | EXEC | Customer profile data for single CID |
| CIDs | Trade.GetCustomersRestrictionsByTypesForAPI | EXEC | Copy block restrictions |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomersDataWithRestirctions (procedure)
+-- Trade.GetUserInfoByGCIDs (procedure)
+-- Trade.GetUserInfo (procedure)
+-- Trade.GetCustomersRestrictionsByTypesForAPI (procedure)
|     +-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserInfoByGCIDs | Stored Procedure | EXEC - customer profile for GCID list |
| Trade.GetUserInfo | Stored Procedure | EXEC - customer profile for single CID |
| Trade.GetCustomersRestrictionsByTypesForAPI | Stored Procedure | EXEC - copy block restrictions |
| Trade.CidList | User Defined Type | TVP for CID lists |
| Trade.BlockedCustomerOperationTypeIDs | User Defined Type | TVP for operation type filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get data for multiple GCIDs

```sql
EXEC Trade.GetCustomersDataWithRestirctions @GCIDs = '100001,100002,100003', @CopiedCID = NULL;
```

### 8.2 Get data for a single copied CID

```sql
EXEC Trade.GetCustomersDataWithRestirctions @GCIDs = NULL, @CopiedCID = 54321;
```

### 8.3 Compare with CopyRestrictions variant

```sql
-- This SP includes RegulationID; the CopyRestrictions variant does not
EXEC Trade.GetCustomersDataWithRestirctions @GCIDs = '100001', @CopiedCID = NULL;
EXEC Trade.GetCustomersDataWithCopyRestirctions @GCIDs = '100001', @CopiedCID = NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomersDataWithRestirctions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomersDataWithRestirctions.sql*
