# dbo.BalanceReports

> Balance reconciliation table that captures calculated, provider-reported, and CUG-reported balances side-by-side for each account, enabling discrepancy detection between the three balance sources.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

BalanceReports is a reconciliation table that stores three independent views of each account's balance: the platform's calculated balance (Calc), the raw provider balance (Provider - from Tribe in minor units), and the CUG (Closed User Group) balance. By comparing these three sources, operations teams can detect and investigate discrepancies that could indicate data sync issues, failed transactions, or accounting errors.

This table exists because the fiat platform receives balance information from multiple sources that should agree but sometimes diverge. Tribe reports balances in minor units (cents), the CUG layer normalizes them, and the platform calculates its own balance from transaction history. This table captures all three for audit and alerting. Confluence documents a dedicated SP alert ("Available/Settled Balance Discrepancies Cug Vs Provider") that monitors this data.

Data is created by dbo.AddBalanceReports and is continuously populated as balance snapshots are captured. The Confluence query for discrepancy detection compares `ProviderSettled/100` against `CugSettled` (converting provider minor units to major units).

---

## 2. Business Logic

### 2.1 Three-Way Balance Reconciliation

**What**: Compares calculated, provider, and CUG balances to detect discrepancies.

**Columns/Parameters Involved**: `CalcAvailable`, `CalcSettled`, `ProviderAvailable`, `ProviderSettled`, `CugAvailable`, `CugSettled`

**Rules**:
- Provider balances are in MINOR UNITS (cents) - divide by 100 to get major units
- CUG balances are in MAJOR UNITS (same as Calc)
- Expected: ProviderSettled/100 = CugSettled = CalcSettled (within rounding tolerance)
- Available vs Settled: Available = what customer can spend now; Settled = what has fully cleared
- Discrepancy = ProviderSettled/100 != CugSettled indicates sync issue between provider and CUG

**Diagram**:
```
Three Balance Sources:
  CalcSettled     = Platform calculation from transaction history
  ProviderSettled = Tribe's raw balance (in MINOR UNITS, /100 for major)
  CugSettled      = CUG layer's normalized balance

Reconciliation Check:
  ProviderSettled/100 == CugSettled?  -> OK or DISCREPANCY
  CalcSettled == CugSettled?          -> OK or CALC DRIFT
```

---

## 3. Data Overview

| Id | AccountId | CurrencyIson | CalcSettled | ProviderSettled | CugSettled | Meaning |
|---|---|---|---|---|---|---|
| 31269828 | 410569 | 978 | -1.15 | 1810 | 18.10 | DISCREPANCY: Calc shows -1.15 EUR but Provider/CUG show 18.10 EUR |
| 31269827 | 1345333 | 978 | 998.17 | 99817 | 998.17 | MATCH: All three agree at EUR 998.17 (Provider 99817/100 = 998.17) |
| 31269826 | 919091 | 978 | 2476.78 | 247678 | 2476.78 | MATCH: All three agree at EUR 2,476.78 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account being reconciled. |
| 3 | CurrencyIson | nvarchar(128) | NO | - | CODE-BACKED | ISO currency code for this balance snapshot. E.g., "978" for EUR. See [ISO Currency Info](../../_glossary.md#iso-currency-info). |
| 4 | CalcAvailable | decimal(36,18) | YES | - | CODE-BACKED | Platform-calculated available balance in major currency units. What the customer can spend based on transaction history calculations. |
| 5 | CalcSettled | decimal(36,18) | YES | - | CODE-BACKED | Platform-calculated settled balance in major currency units. The fully cleared balance from transaction history. |
| 6 | CalcReserved | decimal(36,18) | YES | - | CODE-BACKED | Platform-calculated reserved/held amount in major currency units. Funds held for pending authorizations. |
| 7 | ProviderAvailable | decimal(36,18) | YES | - | VERIFIED | Provider-reported (Tribe) available balance in MINOR UNITS (cents). Divide by 100 for major units. Confirmed by Confluence discrepancy query: `ProviderAvailable/100`. |
| 8 | ProviderSettled | decimal(36,18) | YES | - | VERIFIED | Provider-reported (Tribe) settled balance in MINOR UNITS (cents). Divide by 100 for major units. Confirmed by Confluence: `ProviderSettled/100 = CugSettled` check. |
| 9 | ProviderReserved | decimal(36,18) | YES | - | CODE-BACKED | Provider-reported reserved/held amount in MINOR UNITS. |
| 10 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this balance snapshot was recorded. |
| 11 | CugAvailable | decimal(36,18) | YES | NULL | CODE-BACKED | CUG (Closed User Group) layer available balance in MAJOR currency units. The normalized provider balance as maintained by the CUG system. |
| 12 | CugSettled | decimal(36,18) | YES | NULL | CODE-BACKED | CUG layer settled balance in MAJOR currency units. Should equal ProviderSettled/100 when in sync. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | The account being reconciled |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddBalanceReports | INSERT | Writer | Creates balance reconciliation snapshots |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.BalanceReports (table)
└── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddBalanceReports | Stored Procedure | Writes balance snapshots |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BalanceReports | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BalanceReports_AccountId_FiatAccount_Id | FK | AccountId -> dbo.FiatAccount.Id |
| (default) | DEFAULT | CugAvailable defaults to NULL |
| (default) | DEFAULT | CugSettled defaults to NULL |

---

## 8. Sample Queries

### 8.1 Detect balance discrepancies for an account (from Confluence)
```sql
SELECT Created, CalcSettled, ProviderSettled, CugSettled,
       CASE WHEN (ProviderSettled/100) = CugSettled THEN 'ok' ELSE 'WRONG' END AS SettledEqual,
       ((ProviderSettled/100) - CugSettled) AS SettledDiff,
       ProviderAvailable, CugAvailable,
       CASE WHEN (ProviderAvailable/100) = CugAvailable THEN 'ok' ELSE 'WRONG' END AS AvailableEqual
FROM dbo.BalanceReports WITH (NOLOCK)
WHERE AccountId = 410569 ORDER BY Created DESC;
```

### 8.2 Find all accounts with settled discrepancies
```sql
SELECT TOP 20 AccountId, CurrencyIson, CalcSettled, ProviderSettled/100 AS ProviderMajor, CugSettled,
       ABS((ProviderSettled/100) - CugSettled) AS Discrepancy
FROM dbo.BalanceReports WITH (NOLOCK)
WHERE (ProviderSettled/100) <> CugSettled AND Created >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY ABS((ProviderSettled/100) - CugSettled) DESC;
```

### 8.3 Latest balance snapshot per account
```sql
SELECT br.AccountId, a.Gcid, br.CurrencyIson, br.CugSettled, br.CugAvailable, br.Created
FROM dbo.BalanceReports br WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = br.AccountId
WHERE br.Id = (SELECT MAX(Id) FROM dbo.BalanceReports WITH (NOLOCK) WHERE AccountId = br.AccountId)
ORDER BY br.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Discrepancy detection query: compares ProviderSettled/100 vs CugSettled, confirms Provider values are in minor units |
| [Available and Settled Balance Discrepancies Cug Vs Provider](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13380452511) | Confluence | Dedicated monitoring page for balance discrepancies between CUG and Provider |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.BalanceReports | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.BalanceReports.sql*
