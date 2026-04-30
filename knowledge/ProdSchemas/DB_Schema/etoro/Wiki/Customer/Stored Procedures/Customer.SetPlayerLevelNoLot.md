# Customer.SetPlayerLevelNoLot

> Upgrades a customer's player level based on total deposits when the deposit-derived tier is higher than the current tier; skips Internal (test) accounts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (input) - the customer to evaluate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.SetPlayerLevelNoLot` evaluates whether a customer's total deposit amount qualifies them for a higher player level tier than their current assignment. It represents a deposit-based upgrade path: distinct from the realized-equity-based path used by the automated batch job, this path upgrades customers based purely on how much they have deposited.

The "NoLot" in the name is historical - it refers to the fact that this procedure defers the lot count group assignment to `Customer.SetPlayerLevel` rather than computing it independently. It is called during customer logout processing (History.LogOutByCID, History.LogOutByLoginID) to recalculate whether the customer earned a tier upgrade based on new deposits during the session.

Internal/test accounts (PlayerLevelID = 4) are explicitly excluded from the calculation.

---

## 2. Business Logic

### 2.1 Deposit-Based Tier Upgrade (Upgrade-Only)

**What**: Calculates the player level implied by total deposits and upgrades only if the deposit-implied level is higher than the current level.

**Columns/Parameters Involved**: `@CurrentPlayerLevelID`, `@CurrentPlayerLevelSort`, `@TotalDeposited`, `@SortFromDeposit`, `@NewPlayerLevel`

**Rules**:
- Skip if @CurrentPlayerLevelID = 4 (Internal test accounts).
- Computes @TotalDeposited = SUM(Billing.Deposit.Amount * ExchangeRate) WHERE PaymentStatusID = 2 (confirmed deposits).
- Looks up Dictionary.PlayerLevel WHERE @TotalDeposited BETWEEN FromSumDeposit AND ToSumDeposit to find the deposit-implied tier (OrderBy Sort DESC TOP 1).
- Upgrade condition: @SortFromDeposit > @CurrentPlayerLevelSort (deposit tier ranks higher than current tier).
- If upgrade needed: calls Customer.SetPlayerLevel(@CID, @NewPlayerLevel).
- **Downgrade is never performed**: if deposit total implies a lower tier, no change is made.

```
IF Current level = Internal (4): SKIP
ELSE:
  TotalDeposited = SUM(confirmed deposits with exchange rate)
  DepositImpliedLevel = PlayerLevel WHERE TotalDeposited IN [FromSumDeposit, ToSumDeposit]
  IF DepositImpliedLevel.Sort > CurrentLevel.Sort:
    EXEC Customer.SetPlayerLevel @CID, @DepositImpliedLevelID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to evaluate for deposit-based tier upgrade. Internal accounts (PlayerLevelID=4) are skipped. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | READ | Gets current PlayerLevelID for comparison |
| @CID | Billing.Deposit | READ | Sums confirmed deposits (PaymentStatusID=2) with ExchangeRate |
| (lookup) | Dictionary.PlayerLevel | Lookup | Maps TotalDeposited to deposit-implied tier via FromSumDeposit/ToSumDeposit |
| (EXEC) | Customer.SetPlayerLevel | Callee | Called when deposit-implied tier exceeds current tier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (PROD_BIadmins script) | Reference | Permission | BI admin role has permission to call this |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetPlayerLevelNoLot (procedure)
├── Customer.Customer (view) [READ - get current PlayerLevelID]
├── Dictionary.PlayerLevel (table) [READ - get current sort; match deposit total to tier]
├── Billing.Deposit (table) [READ - sum confirmed deposits]
└── Customer.SetPlayerLevel (procedure) [EXEC - if upgrade needed]
      ├── Dictionary.LotCountGroup (table)
      └── Customer.Customer (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | READ current PlayerLevelID |
| Dictionary.PlayerLevel | Table | READ current tier's Sort; match total deposits to implied tier |
| Billing.Deposit | Table | READ - SUM(Amount * ExchangeRate) WHERE PaymentStatusID = 2 |
| Customer.SetPlayerLevel | Procedure | EXEC - performs the actual upgrade |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no callers found in SSDT) | - | Called externally (application or job scheduler) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Internal account guard | Application | Skips upgrade calculation if PlayerLevelID = 4 (Internal/test) |
| Upgrade-only | Application | Only upgrades (SortFromDeposit > CurrentSort); never downgrades based on deposits |
| PaymentStatusID = 2 | Application | Only confirmed/approved deposits are counted toward tier qualification |

---

## 8. Sample Queries

### 8.1 Calculate deposit-implied tier for a customer manually

```sql
DECLARE @CID INT = 12345

SELECT
    SUM(d.Amount * d.ExchangeRate) AS TotalDeposited
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.CID = @CID
  AND d.PaymentStatusID = 2
```

### 8.2 Find the tier implied by a deposit total

```sql
DECLARE @TotalDeposited MONEY = 12500

SELECT TOP 1
    PlayerLevelID,
    Name,
    Sort,
    FromSumDeposit,
    ToSumDeposit
FROM Dictionary.PlayerLevel WITH (NOLOCK)
WHERE @TotalDeposited BETWEEN FromSumDeposit AND ToSumDeposit
ORDER BY Sort DESC
```

### 8.3 Find customers eligible for deposit-based upgrade

```sql
SELECT
    c.CID,
    c.PlayerLevelID,
    pl.Name AS CurrentTier,
    pl.Sort AS CurrentSort,
    SUM(d.Amount * d.ExchangeRate) AS TotalDeposited,
    implied_pl.PlayerLevelID AS ImpliedTierID,
    implied_pl.Name AS ImpliedTierName,
    implied_pl.Sort AS ImpliedSort
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pl.PlayerLevelID = c.PlayerLevelID
JOIN Billing.Deposit d WITH (NOLOCK) ON d.CID = c.CID AND d.PaymentStatusID = 2
JOIN Dictionary.PlayerLevel implied_pl WITH (NOLOCK)
    ON SUM(d.Amount * d.ExchangeRate) BETWEEN implied_pl.FromSumDeposit AND implied_pl.ToSumDeposit
WHERE c.PlayerLevelID <> 4
  AND implied_pl.Sort > pl.Sort
GROUP BY c.CID, c.PlayerLevelID, pl.Name, pl.Sort, implied_pl.PlayerLevelID, implied_pl.Name, implied_pl.Sort
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetPlayerLevelNoLot | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetPlayerLevelNoLot.sql*
