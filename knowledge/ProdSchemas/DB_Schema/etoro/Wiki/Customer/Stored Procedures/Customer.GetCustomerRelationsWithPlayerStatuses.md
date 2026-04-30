# Customer.GetCustomerRelationsWithPlayerStatuses

> Returns all accounts related to a given customer (via duplicate-detection matching) enriched with full player status hierarchy - status, reason, and sub-reason names - for compliance investigation workflows.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer under investigation) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomerRelationsWithPlayerStatuses combines the duplicate-account detection logic of Customer.GetCustomerRelationExt with full player status information for each related account. It answers the compliance question: "What other accounts are related to this customer, and what is each account's current compliance status?"

The procedure exists as a convenience wrapper for the compliance BackOffice "Relations" tab. Rather than calling GetCustomerRelationExt and then resolving player status IDs manually, this procedure delivers a self-contained result with all status fields already resolved to human-readable names. Compliance officers see each related account's status, the reason, and the sub-reason in one query.

Match types returned (from GetCustomerRelationExt): Email, Original ProviderID and OriginalCID (migration origin), PersonalDetails (name+DOB+country+zip+gender), and payment method matches (credit card, PayPal, or any funding method). See Customer.GetCustomerRelationExt documentation for full matching logic.

---

## 2. Business Logic

### 2.1 Relationship Matching (Inherited from GetCustomerRelationExt)

**What**: Finds all accounts related to @CID via four matching strategies.

**Columns/Parameters Involved**: `@CID`, `CID`, `OriginalCID`, `CustomerStatus`, `VerificationLevel`, `MatchType`

**Rules**:
- Calls Customer.GetCustomerRelationExt(@CID) for the relationship foundation
- Match strategies: Email (case-insensitive LowerEmail), Migration origin (OriginalCID+OriginalProviderID), PersonalDetails (FirstName+LastName+BirthDate+CountryID+Zip+Gender), Any payment method
- CustomerStatus: the compliance status from GetCustomerRelationExt (from Dictionary.PlayerStatus)
- VerificationLevel: from BackOffice.Customer (KYC level)
- MatchType: the reason why this account was matched (e.g., 'Email', 'PersonalDetails', 'Credit Card')

### 2.2 Player Status Hierarchy Resolution

**What**: Resolves the three-level player status hierarchy to human-readable names.

**Columns/Parameters Involved**: `PlayerStatusID`, `PlayerStatusName`, `PlayerStatusReasonID`, `PlayerStatusReasonName`, `PlayerStatusSubReasonID`, `PlayerStatusSubReasonName`, `IsBlocked`

**Rules**:
- LEFT JOIN to Dictionary.PlayerStatus ON PlayerStatusID: adds PlayerStatusName and IsBlocked flag
- LEFT JOIN to Dictionary.PlayerStatusReasons ON PlayerStatusReasonID: adds PlayerStatusReasonName
- LEFT JOIN to Dictionary.PlayerStatusSubReasons ON PlayerStatusSubReasonID: adds PlayerStatusSubReasonName
- All three dictionary joins are LEFT JOIN: related accounts missing status codes return NULL for the name columns (rather than being excluded)
- IsBlocked: from Dictionary.PlayerStatus - indicates whether this status blocks trading/withdrawals

**Diagram**:
```
PlayerStatusID -> Dictionary.PlayerStatus
  PlayerStatusName (e.g., 'Blocked', 'Active')
  IsBlocked (1=account blocked, 0=not blocked)
    |
    +-> PlayerStatusReasonID -> Dictionary.PlayerStatusReasons
    |     PlayerStatusReasonName (e.g., 'Fraud', 'AML')
    |
    +-> PlayerStatusSubReasonID -> Dictionary.PlayerStatusSubReasons
          PlayerStatusSubReasonName (e.g., 'Duplicate Account', 'Chargeback')
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | CID of the customer under investigation. All returned rows are accounts related to this customer (not the customer themselves). |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| CID | GetCustomerRelationExt.CID | CID of the related account |
| OriginalCID | GetCustomerRelationExt.OriginalCID | Referring customer CID of the related account |
| CustomerStatus | GetCustomerRelationExt.CustomerStatus | Compliance status code from Dictionary.PlayerStatus (inherited from GetCustomerRelationExt) |
| VerificationLevel | GetCustomerRelationExt.VerificationLevel | KYC verification level from BackOffice.Customer |
| MatchType | GetCustomerRelationExt.MatchType | Why this account was matched: 'Email', 'PersonalDetails', 'Credit Card', 'Original ProviderID And OriginalCID', 'Any Funding' etc. |
| IsBlocked | Dictionary.PlayerStatus.IsBlocked | 1 = this related account is currently blocked; 0 = not blocked |
| PlayerStatusID | Customer.Customer.PlayerStatusID | Player status code of the related account. See Dictionary.PlayerStatus for all values. |
| PlayerStatusName | Dictionary.PlayerStatus.Name | Human-readable player status (e.g., 'Active', 'Blocked', 'Suspended') |
| PlayerStatusReasonID | Customer.Customer.PlayerStatusReasonID | Reason code for non-Active player statuses |
| PlayerStatusReasonName | Dictionary.PlayerStatusReasons.Name | Human-readable reason (e.g., 'Fraud', 'AML') |
| PlayerStatusSubReasonID | Customer.Customer.PlayerStatusSubReasonID | Sub-reason code providing additional detail |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons.Name | Human-readable sub-reason (e.g., 'Duplicate Account', 'Suspicious Activity') |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.GetCustomerRelationExt | Function call | Duplicate account matching engine; returns related CIDs with MatchType |
| CGCR.CID | Customer.Customer | JOIN | Reads PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID |
| PlayerStatusID | Dictionary.PlayerStatus | LEFT JOIN (lookup) | Resolves to PlayerStatusName and IsBlocked |
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | LEFT JOIN (lookup) | Resolves to reason name |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | LEFT JOIN (lookup) | Resolves to sub-reason name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (no internal SQL callers found; called via BackOffice compliance UI or direct execution).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomerRelationsWithPlayerStatuses (procedure)
├── Customer.GetCustomerRelationExt (function)
│     ├── Customer.CustomerStatic (table)
│     └── BackOffice.Customer (table - cross-schema)
├── Customer.Customer (view)
│     └── Customer.CustomerStatic (table)
├── Dictionary.PlayerStatus (table - cross-schema)
├── Dictionary.PlayerStatusReasons (table - cross-schema)
└── Dictionary.PlayerStatusSubReasons (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetCustomerRelationExt | Table-Valued Function | Provides related account list with CustomerStatus, VerificationLevel, MatchType |
| Customer.Customer | View | Reads PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID for each related CID |
| Dictionary.PlayerStatus | Table | LEFT JOIN to resolve PlayerStatusID -> name and IsBlocked flag |
| Dictionary.PlayerStatusReasons | Table | LEFT JOIN to resolve PlayerStatusReasonID -> reason name |
| Dictionary.PlayerStatusSubReasons | Table | LEFT JOIN to resolve PlayerStatusSubReasonID -> sub-reason name |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| LEFT JOIN to Dictionary | Nullable | Related accounts with no player status row return NULL names (not excluded) |
| JOIN to Customer.Customer | INNER JOIN | Related accounts with no Customer.Customer row would be excluded (should not occur) |

---

## 8. Sample Queries

### 8.1 Find all related accounts with their compliance status

```sql
EXEC Customer.GetCustomerRelationsWithPlayerStatuses @CID = 12345678
-- Returns all accounts related to CID 12345678 with full player status hierarchy
```

### 8.2 Find only blocked related accounts

```sql
CREATE TABLE #Relations (
    CID INT, OriginalCID INT, CustomerStatus VARCHAR(50), VerificationLevel INT,
    MatchType VARCHAR(100), IsBlocked BIT, PlayerStatusID INT, PlayerStatusName VARCHAR(100),
    PlayerStatusReasonID INT, PlayerStatusReasonName VARCHAR(100),
    PlayerStatusSubReasonID INT, PlayerStatusSubReasonName VARCHAR(100)
)
INSERT INTO #Relations EXEC Customer.GetCustomerRelationsWithPlayerStatuses @CID = 12345678
SELECT * FROM #Relations WITH (NOLOCK) WHERE IsBlocked = 1
DROP TABLE #Relations
```

### 8.3 Check player status codes directly

```sql
SELECT PlayerStatusID, Name, IsBlocked
FROM Dictionary.PlayerStatus WITH (NOLOCK)
ORDER BY PlayerStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomerRelationsWithPlayerStatuses | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCustomerRelationsWithPlayerStatuses.sql*
