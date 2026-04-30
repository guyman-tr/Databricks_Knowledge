# Billing.GetNonWithdrawableFundsConfig

> Returns all depot/funding-type combinations where deposited funds are subject to a non-withdrawable holding period - the configuration that prevents immediate withdrawal of newly deposited funds from specific payment methods.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns the full non-withdrawable funds configuration table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetNonWithdrawableFundsConfig` returns the configuration that defines which payment methods create "non-withdrawable" fund periods - deposits that cannot be immediately withdrawn after being received. This is a compliance and risk management control: certain payment methods (e.g., credit cards) are subject to chargeback risk, so eToro holds the deposited funds as non-withdrawable for a number of days (`DeltaInDays`) after the deposit is made.

The procedure returns only rows where `IsNonWithdrawableFunds=1`, making it a filtered view of `Billing.DepotConfig` for the cashout validation use case. The `DeltaInDays` column tells the cashout service how long after a deposit the funds become withdrawable. `EXECUTE` is commented-out granted to `CashoutTool` - confirming the calling context.

There are no parameters - the procedure always returns the full non-withdrawable configuration, which is then used by the cashout service to enforce withdrawal eligibility rules.

---

## 2. Business Logic

### 2.1 Non-Withdrawable Configuration Lookup

**What**: Returns all (depot, funding type) combinations that impose a post-deposit holding period.

**Columns/Parameters Involved**: `DC.IsNonWithdrawableFunds=1`, `DC.DepotID`, `DC.FundingTypeID`, `DC.DeltaInDays`

**Rules**:
- `WHERE IsNonWithdrawableFunds = 1` - only rows with the holding period active
- `INNER JOIN Dictionary.FundingType FT ON DC.FundingTypeID = FT.FundingTypeID` - adds the human-readable FundingType name
- Results cover all depots and funding types where the hold applies
- `DeltaInDays`: the number of days after a deposit via this (depot, funding type) combination during which the funds cannot be withdrawn
- Used by cashout validation: "has the customer's deposit via this payment method aged past `DeltaInDays`?"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

None. The procedure returns the complete non-withdrawable funds configuration without filtering.

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepotID | int | NO | - | CODE-BACKED | Payment depot identifier (FK to Billing.Depot). Identifies the payment gateway/processor. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type (FK to Dictionary.FundingType). Examples: 1=Credit Card, 2=Wire Transfer. |
| 3 | Name | varchar | NO | - | CODE-BACKED | Human-readable name of the funding type (from Dictionary.FundingType.Name). Makes the result self-describing for the cashout service. |
| 4 | IsNonWithdrawableFunds | bit | NO | - | CODE-BACKED | Always 1 for all returned rows (filtered by WHERE clause). Confirms this (depot, fundingtype) combination has a holding period. |
| 5 | DeltaInDays | int | YES | NULL | CODE-BACKED | Number of days after deposit before funds become withdrawable. The cashout service checks: if (DepositDate + DeltaInDays) > today -> funds not yet withdrawable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.DepotConfig | Direct Read | Source of non-withdrawable fund configuration (IsNonWithdrawableFunds=1 rows) |
| INNER JOIN | Dictionary.FundingType | Direct Read | Provides FundingType.Name for human-readable output |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool (permissions) | EXECUTE grant | Permission | The cashout processing tool that enforces withdrawal eligibility rules. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetNonWithdrawableFundsConfig (procedure)
├── Billing.DepotConfig (table)
└── Dictionary.FundingType (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepotConfig | Table | FROM - reads non-withdrawable fund configurations (IsNonWithdrawableFunds=1) |
| Dictionary.FundingType | Table | INNER JOIN - retrieves FundingType Name for the result |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|------------|
| CashoutTool | External Tool | EXECUTE permission - uses configuration to enforce withdrawal holding periods |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note**: The EXECUTE grant to `CashoutTool` is commented out in the DDL (`-- GRANT EXECUTE ON ...`), suggesting the permission is managed outside of this script (possibly via the deployment pipeline or a separate permissions script).

---

## 8. Sample Queries

### 8.1 Get the non-withdrawable funds configuration

```sql
EXEC Billing.GetNonWithdrawableFundsConfig
-- Returns: all (DepotID, FundingTypeID, Name, IsNonWithdrawableFunds=1, DeltaInDays) rows
-- Used by cashout service to determine withdrawal eligibility
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT DC.DepotID, DC.FundingTypeID, FT.Name,
       DC.IsNonWithdrawableFunds, DC.DeltaInDays
FROM Billing.DepotConfig AS DC WITH (NOLOCK)
INNER JOIN Dictionary.FundingType AS FT WITH (NOLOCK)
    ON DC.FundingTypeID = FT.FundingTypeID
WHERE DC.IsNonWithdrawableFunds = 1
```

### 8.3 Check if a specific deposit's funds are still non-withdrawable

```sql
-- Get config first:
EXEC Billing.GetNonWithdrawableFundsConfig

-- Then apply to a deposit:
-- SELECT CASE WHEN DATEADD(DAY, @DeltaInDays, d.PaymentDate) > GETDATE()
--             THEN 'Non-withdrawable'
--             ELSE 'Withdrawable'
--        END
-- FROM Billing.Deposit d WHERE DepositID = @DepositID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetNonWithdrawableFundsConfig | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetNonWithdrawableFundsConfig.sql*
