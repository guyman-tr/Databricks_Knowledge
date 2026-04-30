# Customer.SynchronizeAccount

> Reconciles an IB (Introducing Broker) customer's credit balance with an externally provided value, calling SetBalance only when a discrepancy exists - and blocking execution for non-IB accounts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to synchronize; @Credit - expected balance in cents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SynchronizeAccount is an IB (Introducing Broker) balance synchronization procedure. Introducing Brokers are partner accounts that earn commissions, and their credit balances may be managed externally (e.g., via an IB portal). This procedure receives the externally-authoritative credit value and reconciles the database balance to match it - but only when the stored value differs, and only for accounts on an IB provider.

The procedure exists as a safe, conditional sync operation. It calculates the difference between the external value and what the database holds. If already in sync (difference = 0), it returns immediately without any write. If a discrepancy exists, it calls Customer.SetBalance with ActionType=10 (IB sync) to apply the correction. The pre-check blocks execution for non-IB accounts, preventing accidental application of IB sync logic to regular retail customers.

Data flow: called from IB management systems when an external IB portal updates a broker's commission/credit balance and the DB needs to catch up. Checks Trade.Provider.IsIB to gate IB-only execution. Delegates the actual balance change to Customer.SetBalance (which handles the accounting journal entries). @Difference OUTPUT tells the caller how much was adjusted.

---

## 2. Business Logic

### 2.1 IB Account Guard

**What**: Prevents this sync from running for retail accounts - only IB accounts (linked to a provider with IsIB=0... actually checking non-IB):

**Columns/Parameters Involved**: `@CID`, Trade.Provider.IsIB, Customer.Customer.ProviderID

**Rules**:
- IF EXISTS (Customer.Customer JOIN Trade.Provider WHERE CID=@CID AND IsIB=0) -> RAISERROR(60015), RETURN 60015
- NOTE: The guard checks IsIB=0 (non-IB provider). If the customer IS linked to a non-IB provider, the procedure refuses. This means the procedure only runs for customers whose ProviderID links to a provider with IsIB=1 (IB provider) - or who have no provider link at all.
- Error 60015 signals "not an IB account" to the caller

### 2.2 Difference Calculation and Conditional Update

**What**: Calculates the gap between the external credit value and the stored value, updating only when a difference exists.

**Columns/Parameters Involved**: `@Credit`, `@Difference OUTPUT`, Customer.Customer.Credit

**Rules**:
- @Difference = @Credit - CAST(Credit*100 AS INTEGER) - converts stored Credit (decimal dollars) to cents before comparing with @Credit (cents)
- IF @Difference = 0: RETURN 0 (already in sync, no balance change performed)
- IF @Difference != 0: EXEC Customer.SetBalance @CID, @Credit, 10 (ActionType=10 = IB sync)
- @Difference OUTPUT allows the caller to see how much correction was applied

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. Must be an IB account (ProviderID links to Trade.Provider with IsIB=1). Used to look up Customer.Customer.Credit and pass to SetBalance. |
| 2 | @Credit | int | NO | - | CODE-BACKED | The externally-authoritative credit balance for the IB account, in cents. Compared against the stored Credit*100 to compute @Difference. Passed to Customer.SetBalance as the new balance value if a discrepancy is found. |
| 3 | @Difference | int | YES (OUTPUT) | - | CODE-BACKED | Output: the difference in cents between @Credit and the stored balance (Credit*100). 0 means already in sync (no SetBalance call made). Non-zero means the stored balance was corrected by that amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Reader | SELECT Credit for difference calculation |
| @CID | Trade.Provider | Reader (validation) | JOIN via ProviderID to check IsIB flag |
| @CID | Customer.SetBalance | EXEC (callee) | Delegates balance correction with ActionType=10 (IB sync) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external IB system) | - | - | No intra-DB callers found; called from IB management portal/service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SynchronizeAccount (procedure)
├── Customer.Customer (view - Credit lookup + ProviderID)
├── Trade.Provider (table - IsIB check)
└── Customer.SetBalance (procedure - balance correction, ActionType=10)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT Credit; JOIN with Trade.Provider for IB check |
| Trade.Provider | Table | IsIB flag check (IsIB=0 -> not IB, reject) |
| Customer.SetBalance | Stored Procedure | Balance correction call with ActionType=10 (IB sync) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsIB guard | Business rule | RAISERROR(60015) + RETURN 60015 if customer is on a non-IB provider |
| Difference check | Optimization | RETURN 0 immediately if @Difference=0 (prevents unnecessary SetBalance call) |

---

## 8. Sample Queries

### 8.1 Synchronize an IB account's credit balance
```sql
DECLARE @Diff INT;
EXEC Customer.SynchronizeAccount
    @CID = 12345,
    @Credit = 500000,  -- $5,000 in cents
    @Difference = @Diff OUTPUT;
SELECT @Diff AS CentsAdjusted;
```

### 8.2 Check current credit balance for an IB account
```sql
SELECT c.CID, c.Credit, CAST(c.Credit * 100 AS INT) AS CreditInCents,
       c.ProviderID, p.IsIB
FROM Customer.Customer c WITH (NOLOCK)
JOIN Trade.Provider p WITH (NOLOCK) ON c.ProviderID = p.ProviderID
WHERE c.CID = 12345;
```

### 8.3 Find all IB accounts (IsIB=1 provider)
```sql
SELECT c.CID, c.ProviderID, p.IsIB
FROM Customer.Customer c WITH (NOLOCK)
JOIN Trade.Provider p WITH (NOLOCK) ON c.ProviderID = p.ProviderID
WHERE p.IsIB = 1
ORDER BY c.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (SetBalance) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SynchronizeAccount | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SynchronizeAccount.sql*
