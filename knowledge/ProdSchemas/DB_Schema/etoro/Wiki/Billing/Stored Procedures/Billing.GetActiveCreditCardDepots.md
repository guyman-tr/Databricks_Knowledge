# Billing.GetActiveCreditCardDepots

> Returns DepotIDs of all active credit card depots that support BOTH primary card types (CardTypeID 1 and 2 - Visa and Mastercard), used to determine which depots are fully capable for CC routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DepotID list - no parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetActiveCreditCardDepots` identifies which payment depots are fully operational for credit card processing. A depot qualifies only if it simultaneously satisfies:
1. Is a Credit Card depot (`FundingTypeID=1` in `Billing.Depot`)
2. Is marked active (`Billing.Depot.IsActive=1`)
3. Its associated bank has **both** CardTypeID=1 (Visa) and CardTypeID=2 (Mastercard) active in `Dictionary.CardTypeToBank`

The `HAVING COUNT(DISTINCT ctb.CardTypeID) = 2` clause is the critical filter - it enforces that a depot must support BOTH major card types to be considered "fully active." A depot whose bank only supports one card type (e.g., Mastercard only) is excluded. This ensures the routing engine only selects depots with complete dual-brand capability.

The routing chain traversed: `Dictionary.CardTypeToBank` (card-type-to-bank mapping) -> `Billing.BankToDepot` (bank-to-depot mapping) -> `Billing.Depot` (depot configuration). This three-table join resolves which depots are backed by banks that can handle both Visa and Mastercard.

---

## 2. Business Logic

### 2.1 Dual-Card-Type Depot Discovery

**What**: Identifies active CC depots with both Visa and Mastercard routing capability.

**Columns/Parameters Involved**: `d.FundingTypeID`, `d.IsActive`, `ctb.IsActive`, `ctb.CardTypeID`, `ctb.BankID`, `btd.BankID`, `btd.DepotID`

**Rules**:
- `d.FundingTypeID = 1`: restricts to Credit Card depots only (FundingTypeID=1 = CreditCard).
- `d.IsActive = 1`: only active depots.
- `ctb.IsActive = 1`: only active card-type-to-bank routes (inactive routes are deactivated not deleted).
- `ctb.CardTypeID IN (1, 2)`: considers only Visa (CardTypeID=1) and Mastercard (CardTypeID=2) - the two primary card brands.
- `HAVING COUNT(DISTINCT ctb.CardTypeID) = 2`: the depot's bank must have BOTH card types active. A depot whose bank only supports one of Visa or Mastercard is excluded.
- Three-table join routing path: `CardTypeToBank.BankID = BankToDepot.BankID` -> `BankToDepot.DepotID = Depot.DepotID`.
- Result: only `DepotID` is returned - callers use this list to filter routing eligibility.

### 2.2 Routing Chain Resolution

**What**: Traces the card -> bank -> depot routing chain.

**Rules**:
- `Dictionary.CardTypeToBank`: defines which banks can process which card types. An UPDATE trigger fires when routes become active (notifies ops team via email).
- `Billing.BankToDepot`: maps each bank to one or more depots with routing priority. A bank can map to multiple depots (different priorities).
- `Billing.Depot`: the actual payment gateway endpoint. FundingTypeID=1 marks it as CC-capable.
- All three must have active/matching records for a depot to appear in results.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Return columns**:

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | DepotID | INT | CODE-BACKED | ID of a fully active credit card depot with both Visa (CardTypeID=1) and Mastercard (CardTypeID=2) routing enabled. FK to Billing.Depot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardTypeToBank | Dictionary.CardTypeToBank | Reader | Filters active card-type-bank pairs for CardTypeID IN (1,2) |
| BankToDepot | Billing.BankToDepot | Reader | Maps bank to depot via BankID |
| Depot | Billing.Depot | Reader | Filters CC depots: FundingTypeID=1, IsActive=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Credit card routing engine | External | Caller | Called to get the list of eligible CC depots for routing decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetActiveCreditCardDepots (procedure)
├── Dictionary.CardTypeToBank (table) [cross-schema]
├── Billing.BankToDepot (table)
└── Billing.Depot (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CardTypeToBank | Table (cross-schema) | Filters active card-type/bank pairs for CardTypeID 1 and 2 |
| Billing.BankToDepot | Table | Maps BankID to DepotID for the routing chain |
| Billing.Depot | Table | Final filter: FundingTypeID=1 AND IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CC routing engine | External | Uses DepotID list to determine eligible routing targets |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. SET NOCOUNT ON. All three tables use WITH (NOLOCK). HAVING COUNT(DISTINCT ctb.CardTypeID) = 2 enforces dual-card-type requirement. No parameters - returns the global set of qualified depots. No RETURN statement.

---

## 8. Sample Queries

### 8.1 Get all active CC depots supporting both Visa and Mastercard

```sql
EXEC [Billing].[GetActiveCreditCardDepots];
-- Returns list of DepotIDs for fully active CC depots
```

### 8.2 Reproduce the logic ad-hoc

```sql
SELECT d.DepotID
FROM Dictionary.CardTypeToBank AS ctb WITH (NOLOCK)
INNER JOIN Billing.BankToDepot AS btd WITH (NOLOCK) ON btd.BankID = ctb.BankID
INNER JOIN Billing.Depot AS d WITH (NOLOCK) ON d.DepotID = btd.DepotID
WHERE d.FundingTypeID = 1
  AND d.IsActive = 1
  AND ctb.IsActive = 1
  AND ctb.CardTypeID IN (1, 2)
GROUP BY d.DepotID
HAVING COUNT(DISTINCT ctb.CardTypeID) = 2;
```

### 8.3 See all card-type-to-bank routes currently active

```sql
SELECT ctb.CardTypeID, ctb.BankID, btd.DepotID, btd.Priority, d.Name AS DepotName
FROM [Dictionary].[CardTypeToBank] ctb WITH (NOLOCK)
INNER JOIN [Billing].[BankToDepot] btd WITH (NOLOCK) ON btd.BankID = ctb.BankID
INNER JOIN [Billing].[Depot] d WITH (NOLOCK) ON d.DepotID = btd.DepotID
WHERE ctb.IsActive = 1
  AND d.FundingTypeID = 1
  AND d.IsActive = 1
ORDER BY d.DepotID, ctb.CardTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetActiveCreditCardDepots | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetActiveCreditCardDepots.sql*
