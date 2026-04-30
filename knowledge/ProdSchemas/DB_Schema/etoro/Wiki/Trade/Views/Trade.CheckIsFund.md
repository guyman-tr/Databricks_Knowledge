# Trade.CheckIsFund

> View that identifies fund accounts (customers with AccountTypeID=9) and returns them with a constant FundID for downstream JOIN logic in CopyTrader and BSL flows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | FundAccountID (from BackOffice.Customer.CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckIsFund is a **lookup view** that answers: "Which customers are fund accounts?" It selects from BackOffice.Customer where AccountTypeID = 9 and exposes CID as FundAccountID plus a constant FundID=1. The view exists to support CopyTrader and Balance Sheet Liability (BSL) logic that needs to distinguish fund accounts (institutional/corporate) from retail customers - for example, when determining if a parent in a mirror hierarchy is a fund and should be treated differently for fee or exposure aggregation.

Without this view, procedures like Trade.GetMirrorHierarchyIncludeOpenedPositions and Trade.GetPositionDataFromReal would need to replicate the AccountTypeID=9 filter. The synonym dbo.RealFund points to this view, so code references RealFund as the canonical source for fund-account identification.

Data flows: Read-only. BackOffice.Customer is the source. Consumers JOIN on ParentCID = FundAccountID (or CID = FundAccountID) to test whether a customer is a fund. No procedure writes to this view.

---

## 2. Business Logic

### 2.1 Fund Account Definition

**What**: Fund accounts are customers whose AccountTypeID equals 9 in BackOffice.Customer.

**Columns/Parameters Involved**: `CID`, `AccountTypeID`, `FundAccountID`, `FundID`

**Rules**:
- AccountTypeID = 9 identifies fund/institutional accounts (distinct from retail AccountTypeIDs).
- CID is renamed to FundAccountID for semantic clarity in JOIN predicates.
- FundID is always 1 - a constant for compatibility with downstream logic expecting a FundID column.

**Diagram**:
```
BackOffice.Customer (AccountTypeID=9) --> Trade.CheckIsFund
       |
       v
FundAccountID = CID, FundID = 1
       |
       v
JOIN ParentCID = FundAccountID --> "Is this customer's parent a fund?"
```

---

## 3. Data Overview

| FundAccountID | FundID | Meaning |
|---------------|--------|---------|
| 28 | 1 | Legacy/system fund account. Often used for internal or test funds. |
| 2303275 | 1 | Institutional fund account - CopyTrader leader or BSL participant. |
| 2304154 | 1 | Institutional fund account. |
| 2304194 | 1 | Institutional fund account. |
| 2304196 | 1 | Institutional fund account. |

**Selection criteria**: Live data TOP 5. All rows show FundID=1. FundAccountID values are BackOffice.Customer.CID for customers with AccountTypeID=9.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundAccountID | int | NO | - | CODE-BACKED | Customer ID from BackOffice.Customer.CID. Renamed for semantic clarity. Represents a fund account (AccountTypeID=9). Used in JOINs: ParentCID = FundAccountID to test if a parent in a mirror hierarchy is a fund. |
| 2 | FundID | int | NO | - | CODE-BACKED | Constant 1. Provides a FundID column for compatibility with downstream logic. Always 1 in this view. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundAccountID | BackOffice.Customer | Implicit | CID where AccountTypeID=9. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.RealFund | Synonym | Synonym target | Points to Trade.CheckIsFund. |
| Trade.GetMirrorHierarchyIncludeOpenedPositions | ParentCID = FundAccountID | JOIN | Tests if parent in mirror hierarchy is a fund. |
| Trade.GetPositionDataFromReal | TPOS.CID = FundAccountID | JOIN | Tests if position holder is a fund. |
| Trade.GetEstimatedTreeUnitsByCID | (commented) | JOIN | Legacy commented reference to RealFund. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckIsFund (view)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FROM, filtered by AccountTypeID=9 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealFund | Synonym | Target |
| Trade.GetMirrorHierarchyIncludeOpenedPositions | Procedure | LEFT JOIN dbo.RealFund |
| Trade.GetPositionDataFromReal | Procedure | LEFT JOIN dbo.RealFund |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all fund accounts
```sql
SELECT FundAccountID, FundID
  FROM Trade.CheckIsFund WITH (NOLOCK)
 ORDER BY FundAccountID;
```

### 8.2 Check if a specific customer is a fund
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM Trade.CheckIsFund WITH (NOLOCK) WHERE FundAccountID = 2303275) 
            THEN 1 ELSE 0 END AS IsFund;
```

### 8.3 Resolve fund accounts with customer details
```sql
SELECT cf.FundAccountID, cf.FundID, c.AccountTypeID, c.CID
  FROM Trade.CheckIsFund cf WITH (NOLOCK)
  JOIN BackOffice.Customer c WITH (NOLOCK) ON c.CID = cf.FundAccountID AND c.AccountTypeID = 9
 ORDER BY cf.FundAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.CheckIsFund | Type: View | Source: etoro/etoro/Trade/Views/Trade.CheckIsFund.sql*
