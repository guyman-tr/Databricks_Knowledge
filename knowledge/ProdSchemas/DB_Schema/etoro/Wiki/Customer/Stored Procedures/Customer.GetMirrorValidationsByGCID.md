# Customer.GetMirrorValidationsByGCID

> Returns a customer's financial snapshot (Credit, RealizedEquity) and active mirror count for copy-trading eligibility validation, looking up the customer by GCID instead of CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (group customer ID used to identify the customer) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetMirrorValidationsByGCID is the GCID-based counterpart to Customer.GetMirrorValidationsByCID. It aggregates the financial data required to validate a customer's eligibility to start or continue a copy-trading relationship (called "mirroring" in eToro's system), accepting a GCID as input and returning the internal CID alongside the financial snapshot.

The procedure is used when the caller knows the customer by their GCID (Global Customer ID - the cross-product identity key) rather than their internal CID. Before allowing a customer to copy a trader, the system checks Credit (cash balance), NumberOfActiveMirrors (platform copy limits), and RealizedEquity (minimum equity threshold).

Data flows from Customer.Customer (filtered by GCID) and two Trade schema tables: Trade.Mirror (active copy count and allocated mirror capital) and Trade.Position (open direct positions). The result gives the platform a full picture of the customer's economic position across all copy-trading and direct-trading activity.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution

**What**: Accepts the cross-product GCID and resolves to the internal CID for Trade schema lookups.

**Columns/Parameters Involved**: `@GCID`, `CID`

**Rules**:
- Filters Customer.Customer WHERE GCID = @GCID
- Returns CID in the result set - callers use this for subsequent CID-based operations
- If GCID does not exist in Customer.Customer, returns empty result set (no error)

### 2.2 Active Mirror Count

**What**: Counts how many copy-trading portfolios the customer is currently copying.

**Columns/Parameters Involved**: `NumberOfActiveMirrors`, `Trade.Mirror.IsActive`

**Rules**:
- Subquery: `SELECT COUNT(*) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = CCST.CID AND IsActive = 1`
- Only mirrors with IsActive=1 are counted (active copy relationships only)
- Used against platform copy limits (e.g., max mirrors per customer enforced in application layer)

### 2.3 RealizedEquity Compound Calculation

**What**: Computes the customer's total economic value across cash, direct positions, and ALL mirror allocations.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `Trade.Position.Amount`, `Trade.Mirror.Amount`

**Rules**:
- Formula: `ISNULL(Credit, 0) + SUM(Trade.Position.Amount WHERE CID) + SUM(Trade.Mirror.Amount WHERE CID)`
- Credit: cash balance from Customer.Customer
- SUM(Position.Amount): total open position amounts from Trade.Position (all positions, no status filter)
- SUM(Mirror.Amount): ALL mirror amounts - NOTE: unlike GetMirrorValidationsByCID, this version does NOT filter IsActive=1 on mirror amounts. All mirror rows (active and inactive) are included in the equity sum.

**IMPORTANT behavioral difference vs. GetMirrorValidationsByCID**:
```
GetMirrorValidationsByCID:  Mirror.Amount WHERE IsActive=1  (active mirrors only)
GetMirrorValidationsByGCID: Mirror.Amount (no IsActive filter) (ALL mirrors)
```
This means the GCID version may return a higher RealizedEquity if a customer has inactive/closed mirrors with non-zero Amount values.

**Diagram**:
```
@GCID
  |
  v
Customer.Customer (GCID filter) -> CID, Credit
  |
  +--[subquery]--> COUNT(Trade.Mirror WHERE CID AND IsActive=1) -> NumberOfActiveMirrors
  |
  +--[subquery]--> SUM(Trade.Position.Amount WHERE CID) -> position component
  |
  +--[subquery]--> SUM(Trade.Mirror.Amount WHERE CID)   -> mirror component (ALL mirrors)
  |
  v
RealizedEquity = Credit + position component + mirror component
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: Group Customer ID - the cross-product identity key linking the same person across eToro products. Used to look up the customer in Customer.Customer. Inherited from Customer.Customer.GCID: "Cross-product identity key linking same person across eToro products." |
| 2 | CID | int (output) | NO | - | VERIFIED | Customer's internal platform ID, returned for caller use in subsequent operations. Sourced from Customer.Customer.CID. |
| 3 | Credit | money (output) | YES | - | VERIFIED | Customer's current cash balance. From Customer.CustomerMoney via Customer.Customer. NULL if no CustomerMoney row exists. Used to assess whether the customer has sufficient cash to copy. |
| 4 | NumberOfActiveMirrors | int (output) | NO | - | CODE-BACKED | Count of currently active copy-trading relationships (Trade.Mirror rows WHERE IsActive=1 for this CID). Used to check against platform mirror limits before allowing new copy relationships. |
| 5 | RealizedEquity | money (output) | NO | - | CODE-BACKED | Computed total portfolio value: ISNULL(Credit,0) + SUM(Trade.Position.Amount) + SUM(Trade.Mirror.Amount for ALL mirrors). NOTE: includes inactive mirror amounts unlike the CID variant. See Business Logic 2.3. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID / CID | Customer.Customer | FROM + WHERE filter | Source of CID, Credit; filtered by GCID |
| CID | Trade.Mirror | Subquery (COUNT) | Active mirror count for copy validation |
| CID | Trade.Mirror | Subquery (SUM Amount) | Total mirror capital allocation (all mirrors) |
| CID | Trade.Position | Subquery (SUM Amount) | Open position value for equity calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin users have execute access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetMirrorValidationsByGCID (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Trade.Mirror (table)
└── Trade.Position (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM with GCID filter - source of CID and Credit |
| Trade.Mirror | Table | Two subqueries: COUNT(IsActive=1) for mirror count; SUM(Amount) for equity (no IsActive filter) |
| Trade.Position | Table | Subquery: SUM(Amount) for open position equity component |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | DB Role/User | EXECUTE permission granted |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run mirror validations for a customer by GCID
```sql
EXEC Customer.GetMirrorValidationsByGCID @GCID = 1983785;
```

### 8.2 Direct query equivalent
```sql
SELECT
    CCST.CID,
    CCST.Credit,
    (SELECT COUNT(*) FROM Trade.Mirror TMRR WITH (NOLOCK)
     WHERE TMRR.CID = CCST.CID AND TMRR.IsActive = 1) AS NumberOfActiveMirrors,
    (ISNULL(CCST.Credit, 0)
        + (SELECT ISNULL(SUM(Amount), 0) FROM Trade.Position TP WITH (NOLOCK) WHERE TP.CID = CCST.CID)
        + (SELECT ISNULL(SUM(Amount), 0) FROM Trade.Mirror TM WITH (NOLOCK) WHERE TM.CID = CCST.CID)
    ) AS RealizedEquity
FROM Customer.Customer CCST WITH (NOLOCK)
WHERE CCST.GCID = 1983785;
```

### 8.3 Compare GCID vs CID variant results for same customer
```sql
-- By GCID
EXEC Customer.GetMirrorValidationsByGCID @GCID = 1983785;

-- By CID (note: CID variant filters IsActive=1 on Mirror.Amount)
EXEC Customer.GetMirrorValidationsByCID @CID = 245;
-- If these return different RealizedEquity, it means customer has inactive mirrors with non-zero Amount
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related SP compared | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetMirrorValidationsByGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetMirrorValidationsByGCID.sql*
