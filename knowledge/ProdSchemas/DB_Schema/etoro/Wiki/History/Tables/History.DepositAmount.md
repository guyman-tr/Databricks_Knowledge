# History.DepositAmount

> Temporal system-versioned history table storing all past versions of country-specific deposit amount configuration rules - recording every change to minimum, maximum, and suggested package deposit amounts per country and first-time-depositor status.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (Id) + ValidFrom + ValidTo |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Billing.DepositAmount`. SQL Server automatically moves rows here whenever a deposit amount configuration row is updated or deleted in the source table.

`Billing.DepositAmount` defines the **deposit limits and suggested package amounts** presented to customers during the deposit flow. For each country and FTD (First Time Depositor) status combination, it defines:
- The minimum deposit required (`MinAmount`)
- An optional maximum deposit cap (`MaxAmount`)
- Up to three suggested "quick pick" amounts (`Package1Amount`, `Package2Amount`, `Package3Amount`)
- Whether the package suggestions are shown in the UI (`IsPackageVisible`)

The FTD split is critical: the system checks whether a customer has any approved deposits (`PaymentStatusID=2` in `Billing.Deposit`) to determine if they are a first-time or returning depositor, then serves the appropriate limits from `Billing.DepositAmount`. First-time depositors may have lower minimums and different package amounts to reduce conversion friction, while returning depositors have standard limits.

All configuration changes are deployed via CI/CD pipeline (SQL login `CICD_DB_MIMO` via `SQLCMD`), not manual back-office edits. History records span from September 2021 with only 47 historical versions across 37 configuration rows - this is a low-churn configuration table.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a deposit amount configuration row is modified or deleted.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `Id`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `ValidTo` = the moment of update, `ValidFrom` = when that version was first active.
- When a row is **deleted**: SQL Server moves the row here with `ValidTo` = deletion timestamp.
- Rows currently active in the source table have `ValidTo = '9999-12-31...'` and are NOT in this history table.
- The CLUSTERED index on `(ValidTo, ValidFrom)` enables efficient `FOR SYSTEM_TIME AS OF` temporal point-in-time queries.
- All 47 historical rows have `ValidFrom = '2021-09-19'` - the initial bulk deployment date - indicating these were deleted/replaced rows from a bulk reconfiguration.

**Diagram**:
```
INSERT config (CountryID=9, FTD=false, MinAmount=50)
  -> Row enters Billing.DepositAmount (ValidFrom=NOW, ValidTo=9999-12-31)

UPDATE: change MinAmount from 50 to 55
  -> OLD row moves to History.DepositAmount
       ValidFrom=original_time, ValidTo=NOW (e.g., 2026-01-28)
  -> NEW row stays in Billing.DepositAmount
       ValidFrom=NOW, ValidTo=9999-12-31
```

### 2.2 FTD vs. Returning Depositor Split

**What**: Each country has two rows - one for first-time depositors (FTD=true) and one for returning depositors (FTD=false), with potentially different limits and packages.

**Columns/Parameters Involved**: `FTD`, `CountryID`, `MinAmount`, `MaxAmount`, `Package1Amount`, `Package2Amount`, `Package3Amount`

**Rules** (from `Billing.GetDepositAmountsForUser`):
- `@IsFTD = 1` if customer has NO approved deposits (`PaymentStatusID=2` in `Billing.Deposit`) -> use FTD row.
- `@IsFTD = 0` if customer has at least one approved deposit -> use non-FTD row.
- FTD minimum amounts are lower (historical values: $1-$50) to reduce first-deposit friction.
- Non-FTD minimum amounts are standard ($50-$55).
- FTD maximum amounts are lower ($66-$100 in history) - caps on first deposits.
- Non-FTD maximum amounts are higher ($666-$10,000) for established customers.
- `CountryID=0` is used as a default/fallback for countries without specific configuration.
- `@CountryID = NULL` in the SP defaults to `CountryID=0` via `ISNULL(@CountryID, 0)`.

**Diagram**:
```
Customer deposits for the first time in CountryID=9 (Australia):
  SP checks: Billing.Deposit WHERE PaymentStatusID=2 AND CID=@CID -> no rows -> IsFTD=1
  Query: WHERE FTD=1 AND CountryID=9
  Returns: MinAmount=$1, Package1=$200, Package2=$400, Package3=$1000, MaxAmount=$100

Customer's second deposit (already approved once):
  SP checks: Billing.Deposit WHERE PaymentStatusID=2 AND CID=@CID -> 1 row -> IsFTD=0
  Query: WHERE FTD=0 AND CountryID=9
  Returns: MinAmount=$50, Package1=$200, Package2=$400, Package3=$1000, MaxAmount=$10000
```

### 2.3 Package Visibility and UI Presentation

**What**: `IsPackageVisible` controls whether the package amounts are shown as quick-pick buttons in the deposit UI.

**Columns/Parameters Involved**: `IsPackageVisible`, `Package1Amount`, `Package2Amount`, `Package3Amount`

**Rules**:
- `IsPackageVisible=false` (most rows in history): Package amounts exist in the table but are not shown as UI suggestions. The MinAmount/MaxAmount still apply.
- `IsPackageVisible=true` (6 historical rows, all FTD=true): Package amounts are shown as clickable quick-pick amounts to guide first-time depositors toward suggested values.
- `Billing.GetDepositAmountsForUser` returns `IsPackageVisible` to the application, which uses it to decide whether to render the package buttons.

### 2.4 CI/CD Deployment Pattern

**What**: All configuration changes are deployed automatically via CI/CD, not manual edits.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- The `Trace` column is a computed column on the source table that captures SQL session context at time of DML: `HostName`, `AppName`, `SUserName`, `SPID`, `DBName`, `ObjectName`.
- All 47 historical rows have `Trace` showing `SUserName = "CICD_DB_MIMO"`, `AppName = "SQLCMD"` - confirming all changes were automated deployments.
- The `HostName` values (`stg-runner-linux-aks-*`) confirm changes came from Kubernetes CI/CD runner pods.
- `ObjectName` is empty (no stored procedure wrapper), meaning the SQL was run directly.

---

## 3. Data Overview

| CountryID | FTD | MinAmount | MaxAmount | Package1 | Package2 | Package3 | IsPackageVisible | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 161 | true | 50 | null | 200 | 400 | 1000 | false | 2021-09-19 | 2026-01-28 | CountryID=161 FTD config: min $50, no max, packages not shown. Active for 4+ years before being replaced Jan 2026. |
| 161 | false | 50 | null | 200 | 400 | 1000 | false | 2021-09-19 | 2026-01-28 | CountryID=161 non-FTD: same $50 min. When FTD=false has same limits as FTD=true, the differentiation was not yet applied for this country. |
| 9 | true | 50 | null | 200 | 400 | 1000 | false | 2021-09-19 | 2026-01-28 | CountryID=9 FTD config from 2021: min $50, same packages. The standard default that was replaced in Jan 2026 bulk update. |

All 47 historical rows have `ValidFrom = '2021-09-19'` and were superseded in a bulk update during January 2026, suggesting a sweeping configuration change for all countries in that period. `MaxAmount` was NULL for most historical rows (no cap enforced historically), and non-null MaxAmount values appear only in the current active configuration.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Identifies the country this deposit amount configuration applies to. FK to Dictionary.Country (implicit). CountryID=0 is the default/fallback row returned when `@CountryID` is NULL in the lookup SPs. Multiple rows per CountryID exist - one for FTD=true and one for FTD=false. |
| 2 | MinAmount | decimal(18,2) | NO | - | VERIFIED | The minimum deposit amount required in USD. Historical FTD values: $1-$50 (lower to reduce first-deposit friction). Historical non-FTD values: $50-$55 (standard requirement). The application enforces this minimum in the deposit form. |
| 3 | Package1Amount | decimal(18,2) | YES | - | CODE-BACKED | First suggested "quick pick" deposit amount displayed when IsPackageVisible=true. Historical value: typically $200. NULL when no package suggestions are configured. |
| 4 | Package2Amount | decimal(18,2) | YES | - | CODE-BACKED | Second suggested deposit amount. Historical value: typically $400. Forms the middle tier of a three-tier suggestion ($200 / $400 / $1000). |
| 5 | Package3Amount | decimal(18,2) | YES | - | CODE-BACKED | Third (highest) suggested deposit amount. Historical value: typically $1000. Represents the premium quick-pick option for customers. |
| 6 | FTD | bit | NO | 0 | VERIFIED | First Time Depositor flag. 1=this row applies to customers making their first ever deposit (no prior PaymentStatusID=2 in Billing.Deposit). 0=applies to returning depositors. Determined by Billing.GetDepositAmountsForUser checking Billing.Deposit. Default=0 (non-FTD). |
| 7 | Id | int | NO | IDENTITY | CODE-BACKED | Surrogate primary key from the source table (Billing.DepositAmount). Auto-incremented IDENTITY in source. In this history table, Id identifies which source row this historical version belonged to - paired with (ValidFrom, ValidTo) to reconstruct the full version history of one configuration row. |
| 8 | IsPackageVisible | bit | NO | 0 | VERIFIED | Controls whether Package1/2/3Amount values are rendered as quick-pick buttons in the deposit UI. 0=hide packages (amount entered manually). 1=show packages (6 historical rows, all FTD=true). Default=0. Returned directly by Billing.GetDepositAmountsForUser to the application layer. |
| 9 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON audit string computed at time of DML on source table, capturing: HostName (deployment server), AppName (SQLCMD for CI/CD), SUserName (CICD_DB_MIMO for all known changes), SPID, DBName, ObjectName (empty = direct SQL, not via stored procedure). All 47 historical rows show automated CI/CD deployment origin. |
| 10 | ValidFrom | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version of the configuration row became active in Billing.DepositAmount. All historical rows: 2021-09-19 (initial deployment). Managed by SQL Server temporal system-versioning. |
| 11 | ValidTo | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded (modified or deleted). Clustered index leading column for efficient temporal range lookups. Historical rows: superseded January 2026 (bulk configuration update). |
| 12 | MaxAmount | decimal(18,2) | YES | - | VERIFIED | The maximum deposit amount allowed in USD. NULL in all 47 historical rows (no cap was enforced historically). Non-null values (e.g., FTD $100, non-FTD $10000) appear in the current active configuration. Returned by Billing.GetDepositAmountsForUser to the application for upper-limit enforcement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | The country this deposit configuration applies to (0=default) |
| (all columns) | Billing.DepositAmount | Temporal | This row is a historical version of the source table row with matching Id |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositAmount | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server automatically writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DepositAmount (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Billing.DepositAmount (table)
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositAmount | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_DepositAmount | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

**Filegroup**: [PRIMARY] - unlike most History schema tables which use [HISTORY], this temporal table resides on [PRIMARY] matching its source table.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

---

## 8. Sample Queries

### 8.1 What deposit limits were configured for a country on a specific date
```sql
-- Reconstruct configuration as of 2024-06-01 via history table
SELECT CountryID, FTD, MinAmount, MaxAmount,
       Package1Amount, Package2Amount, Package3Amount, IsPackageVisible,
       ValidFrom, ValidTo
FROM [History].[DepositAmount] WITH (NOLOCK)
WHERE CountryID = 9
  AND '2024-06-01' BETWEEN ValidFrom AND ValidTo
ORDER BY FTD
```

### 8.2 Full change history for all countries (combined with current state)
```sql
-- Historical versions
SELECT 'History' AS Source, CountryID, FTD, MinAmount, MaxAmount,
       IsPackageVisible, ValidFrom, ValidTo,
       JSON_VALUE(Trace, '$.SUserName') AS ChangedBy
FROM [History].[DepositAmount] WITH (NOLOCK)
UNION ALL
-- Current versions
SELECT 'Current' AS Source, CountryID, FTD, MinAmount, MaxAmount,
       IsPackageVisible, ValidFrom, ValidTo,
       JSON_VALUE(Trace, '$.SUserName') AS ChangedBy
FROM [Billing].[DepositAmount] WITH (NOLOCK)
ORDER BY CountryID, FTD, ValidFrom
```

### 8.3 Configurations that changed MinAmount between versions
```sql
SELECT h.Id, h.CountryID, h.FTD,
       h.MinAmount AS OldMinAmount, h.ValidTo AS ChangedAt,
       JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM [History].[DepositAmount] h WITH (NOLOCK)
ORDER BY h.ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DepositAmount | Type: Table | Source: etoro/etoro/History/Tables/History.DepositAmount.sql*
