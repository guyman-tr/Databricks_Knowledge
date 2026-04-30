# Trade.GetUserInfoByGCIDs

> Batch version of Trade.GetUserInfo - accepts a TVP of GCIDs (Trade.CidList) and returns the same user context columns for multiple customers in a single call, without the per-call credit adjustment for pending orders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCIDs - TVP of type Trade.CidList (GCID values) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserInfoByGCIDs` is the batch counterpart to `Trade.GetUserInfo`. Where the single-customer version loads context for one CID during trade pre-execution, this procedure accepts a table-valued parameter (TVP) of GCIDs and returns the same profile columns for a set of customers in one round-trip.

The batch design is optimized for scenarios where multiple customers' contexts must be evaluated together - for example, when processing a copy-trade open that affects multiple copiers, or in bulk risk reporting. The join to `@GCIDs` via `CC.GCID = GC.CID` means the input TVP is keyed on GCID values.

Notable differences from single-customer GetUserInfo:
- **No order-amount credit adjustment**: Credit = `CAST(Credit * 100 AS BIGINT)` without subtracting TotalManualOrdersForOpen. This is a simpler credit value appropriate for batch contexts where individual order reservation is not needed.
- **CopyBlocked uses OperationTypeID=1 only** (not IN(21,1)) via OUTER APPLY.
- **IsBeingCopied computed via OUTER APPLY** (not pre-computed variable) since we need per-row computation across multiple CIDs.

---

## 2. Business Logic

### 2.1 TVP Batch Join

**What**: Input is a set of GCIDs joined to Customer.Customer via GCID.

**Rules**:
- `@GCIDs` is of type `Trade.CidList` (READ ONLY TVP with column `CID` containing GCID values)
- `INNER JOIN @GCIDs GC ON CC.GCID = GC.CID` - returns one row per matched customer
- Unmatched GCIDs (unknown customers) are silently excluded

### 2.2 Credit in Cents (No Order Adjustment)

**What**: Credit is returned as BIGINT cents without pending order deduction.

**Rules**:
- `CAST(Credit * 100 AS BIGINT)` - same cents conversion as GetUserInfo
- No call to Trade.GetTotalManualOrdersForOpenAmount - batch context does not adjust per-customer
- Callers needing precise available credit should use single-customer GetUserInfo

### 2.3 CopyBlocked via OUTER APPLY (OperationTypeID=1 Only)

**What**: Copy block check uses OUTER APPLY with TOP 1, restricted to OperationTypeID=1.

**Rules**:
- `OUTER APPLY (SELECT TOP 1 OperationTypeID, BlockReasonID FROM Customer.BlockedCustomerOperations WHERE CID = CC.CID AND OperationTypeID = 1) CBO`
- OperationTypeID=1 only (differs from GetUserInfo which uses IN(21,1))
- OUTER APPLY returns NULL columns when no block exists -> ISNULL to 0

### 2.4 IsBeingCopied via OUTER APPLY

**What**: Per-row IsBeingCopied computed via correlated OUTER APPLY.

**Rules**:
- `OUTER APPLY (SELECT TOP 1 1 AS Miror FROM Trade.Mirror WHERE ParentCID = CC.CID) m`
- `IsBeingCopied = CAST(ISNULL(Miror, 0) AS BIT)`: 1 if any mirror row exists with ParentCID=CC.CID
- Note the typo "Miror" (single r) in column alias - harmless but consistent with original code

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDs | Trade.CidList READONLY | NO | - | CODE-BACKED | TVP of GCIDs (column name: CID). One row per GCID to look up. Joined to Customer.Customer.GCID. |

**Output columns (one row per matched GCID):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Credit | BIGINT | NO | - | CODE-BACKED | Available credit in cents (x100). No pending order deduction (unlike GetUserInfo single-CID version). |
| 3 | SpreadGroupID | INT | NO | - | CODE-BACKED | Spread group assignment. From Customer.Customer. |
| 4 | LotCountGroupID | INT | YES | - | CODE-BACKED | Lot size group assignment. From Customer.Customer. |
| 5 | PlayerStatusID | INT | NO | - | CODE-BACKED | Current player status. FK to Dictionary.PlayerStatus. |
| 6 | LabelID | INT | YES | - | CODE-BACKED | Marketing label. From Customer.Customer. |
| 7 | IsCupon | BIT | NO | - | CODE-BACKED | 1 = bonus-only customer; 0 = normal. From BackOffice.BonusOnlyCustomers. |
| 8 | TotalCash | MONEY | NO | - | CODE-BACKED | ISNULL(TotalCash, 0). Total cash balance. |
| 9 | PlayerLevelID | INT | NO | - | CODE-BACKED | Customer tier. FK to Dictionary.PlayerLevel. |
| 10 | RealizedEquity | MONEY | NO | - | CODE-BACKED | Cumulative realized P&L. |
| 11 | IsCopyBlocked | INT | NO | - | CODE-BACKED | ISNULL(CBO.OperationTypeID, 0). Non-zero = copy blocked. Only OperationTypeID=1 checked (vs IN(21,1) in GetUserInfo). |
| 12 | CopyBlockReasonID | INT | NO | - | CODE-BACKED | ISNULL(CBO.BlockReasonID, 0). Block reason code. 0 = no block. |
| 13 | IsBeingCopied | BIT | NO | - | CODE-BACKED | 1 = has copiers (any Mirror with ParentCID=CID); 0 = not copied. Computed via OUTER APPLY per row. |
| 14 | CountryID | INT | NO | - | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 15 | UserName | VARCHAR | NO | - | CODE-BACKED | Customer username. |
| 16 | CountryName | VARCHAR | NO | - | CODE-BACKED | Country name from Dictionary.Country. |
| 17 | AffiliateID | INT | YES | - | CODE-BACKED | Affiliate SerialID. |
| 18 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID. |
| 19 | CID | INT | NO | - | CODE-BACKED | Database-local Customer ID. |
| 20 | IsFund | BIT | NO | - | CODE-BACKED | 1 = AccountTypeID=9 (fund account); 0 = standard. |
| 21 | TradingRiskStatusID | INT | NO | - | CODE-BACKED | Trading risk classification. FK to Dictionary.TradingRiskStatus. |
| 22 | RegulationID | INT | YES | - | CODE-BACKED | BC.DesignatedRegulationID (no ISNULL to 0 here - may be NULL). Designated regulation override. |
| 23 | Registered | DATETIME | NO | - | CODE-BACKED | Customer registration date. |
| 24 | GuruStatusID | INT | YES | - | CODE-BACKED | Popular Investor program status. |
| 25 | AccountTypeID | INT | NO | - | CODE-BACKED | Account type ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP | Trade.CidList | User Defined Type | Input TVP type for batch GCID list |
| FROM | Customer.Customer | FROM | Primary customer data source |
| JOIN | @GCIDs | INNER JOIN | Filters to requested GCIDs |
| JOIN | BackOffice.Customer | INNER JOIN | Account type, risk, regulation |
| JOIN | Dictionary.Country | INNER JOIN | Country name |
| LEFT JOIN | BackOffice.BonusOnlyCustomers | LEFT JOIN | Bonus-only flag |
| OUTER APPLY | Customer.BlockedCustomerOperations | OUTER APPLY | Copy block status (OperationTypeID=1) |
| OUTER APPLY | Trade.Mirror | OUTER APPLY | IsBeingCopied per customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (batch copy processing) | @GCIDs TVP | EXEC caller | Called when loading user context for multiple customers at once |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserInfoByGCIDs (procedure)
+-- Trade.CidList (UDT - TVP type)
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- Dictionary.Country (table)
+-- BackOffice.BonusOnlyCustomers (table)
+-- Customer.BlockedCustomerOperations (table)
+-- Trade.Mirror (table) [IsBeingCopied OUTER APPLY]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidList | User Defined Type | TVP parameter type |
| Customer.Customer | Table | Primary customer data |
| BackOffice.Customer | Table | Account type, risk, regulation |
| Dictionary.Country | Table | Country name |
| BackOffice.BonusOnlyCustomers | Table | IsCupon flag |
| Customer.BlockedCustomerOperations | Table | Copy block check |
| Trade.Mirror | Table | IsBeingCopied per customer |

### 6.2 Objects That Depend On This

No documented dependents. Called by batch processing components.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Trade.CidList READONLY | TVP param | TVP cannot be modified inside the SP |
| INNER JOIN @GCIDs | Filter | Silently excludes unmatched GCIDs |
| OperationTypeID = 1 | Block filter | Only general operation blocks checked (not copy-specific type 21) |
| Credit * 100 as BIGINT | Format | Cents conversion, no order reservation deduction |

---

## 8. Sample Queries

### 8.1 Batch user info load
```sql
DECLARE @ids Trade.CidList;
INSERT INTO @ids VALUES (12345678), (23456789), (34567890);
EXEC Trade.GetUserInfoByGCIDs @GCIDs = @ids;
```

### 8.2 Compare to single-customer version
```sql
-- Single (with order adjustment, OperationTypeID IN (21,1)):
EXEC Trade.GetUserInfo @CID = 123456;

-- Batch (no order adjustment, OperationTypeID = 1 only):
DECLARE @ids Trade.CidList;
INSERT INTO @ids VALUES (12345678);  -- GCID, not CID
EXEC Trade.GetUserInfoByGCIDs @GCIDs = @ids;
```

### 8.3 N/A - third query not applicable for this procedure

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian documentation found. Batch variant of GetUserInfo not separately documented in TRAD/DB Confluence folder.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserInfoByGCIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserInfoByGCIDs.sql*
