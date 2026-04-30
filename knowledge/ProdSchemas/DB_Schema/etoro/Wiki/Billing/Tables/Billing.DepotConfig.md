# Billing.DepotConfig

> Per-depot non-withdrawable funds configuration. Each row defines a depot's primary funding type and the holding period (DeltaInDays) before deposits via this depot can be withdrawn. 9 rows; all have IsNonWithdrawableFunds=true and negative DeltaInDays values representing withdrawal lock-up periods.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | DepotID - PRIMARY KEY NONCLUSTERED (heap) |
| **Row Count** | 9 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 NONCLUSTERED PK on DepotID |

---

## 1. Business Meaning

`Billing.DepotConfig` configures the withdrawal restriction policy for specific payment depots. When a customer deposits via a depot listed in this table, those funds are marked as "non-withdrawable" for a period defined by `|DeltaInDays|`. This is a fraud prevention measure - certain payment methods (e.g., ACH/bank debit, crypto, digital wallets) have chargeback windows, and eToro prevents withdrawal of such funds until the chargeback risk window has passed.

**Primary reader**: `Billing.GetNonWithdrawableFundsConfig` - returns all rows where `IsNonWithdrawableFunds=1`, joined to `Dictionary.FundingType` for the type name. Called by the Cashout Tool to check if a customer's funds are locked.

**All 9 rows** have `IsNonWithdrawableFunds=true`. The DeltaInDays values are all negative, representing how many days back from today a deposit must have occurred to be considered withdrawable. For example, DeltaInDays=-6 means deposits within the last 6 days cannot be withdrawn.

---

## 2. Business Logic

### 2.1 Non-Withdrawable Funds Window

| DepotID | FundingTypeID | DeltaInDays | Meaning |
|---------|---------------|-------------|---------|
| 4 | 11 | -6 | Deposits via this depot locked for 6 days |
| 9 | 15 | -6 | 6-day lock |
| 75 | 29 | -6 | 6-day lock |
| 86 | 32 | -7 | 7-day lock |
| 93 | 35 | -6 | 6-day lock |
| 103 | 37 | -2 | 2-day lock |
| 165 | 43 | -3 | 3-day lock |
| 173 | 28 | -3 | 3-day lock |
| 174 | 28 | -3 | 3-day lock (same funding type, different depot) |

The negative sign convention: `DeltaInDays=-6` means `DATEADD(day, -6, GETDATE())` is used as the cutoff. Deposits after that date are non-withdrawable.

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) [implicit] | [CODE-BACKED] Payment depot; PK. No explicit FK constraint defined. References the depot whose deposits are restricted. |
| **FundingTypeID** | int | NOT NULL | - | Dictionary.FundingType(FundingTypeID) [implicit] | [CODE-BACKED] The payment method type this depot handles. Joined in GetNonWithdrawableFundsConfig for the type name. |
| **IsNonWithdrawableFunds** | bit | NOT NULL | (1) | - | [CODE-BACKED] Always true in all 9 rows. Marks deposits via this depot as non-withdrawable within the DeltaInDays window. Default is 1. |
| **DeltaInDays** | int | NOT NULL | - | - | [CODE-BACKED] Negative integer. Number of days for the withdrawal lock. -6=6-day hold, -7=7-day hold, -3=3-day hold, -2=2-day hold. Applied as DATEADD(day, DeltaInDays, GETDATE()) to get the earliest eligible deposit date for withdrawal. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_DepotConfig | NONCLUSTERED | DepotID ASC | FILLFACTOR=95. Heap table (no clustered index). |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.GetNonWithdrawableFundsConfig` | Returns all non-withdrawable configs joined to FundingType name |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | DepotConfig.DepotID = Depot.DepotID | Implicit (no FK). One config row per depot. |
| Dictionary.FundingType | Many-to-one | DepotConfig.FundingTypeID = FundingType.FundingTypeID | Implicit (no FK). Used in procedure join. |

---

*Quality: 9.0/10 | 4 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,6,8,9,11*
