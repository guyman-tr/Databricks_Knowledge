# Billing.GetDepositAmountsForUser

> Returns the full deposit amount configuration (min, max, three suggested package amounts, and package visibility flag) for a customer, auto-detecting FTD status and falling back to global defaults when no country is specified.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from Billing.DepositAmount keyed by (FTD status, CountryID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositAmountsForUser` retrieves the complete deposit amount configuration displayed to a customer in the eToro deposit UI. Unlike `GetDefaultDepositSettingsForUser` which returns per-funding-type defaults, this procedure returns the customer-level deposit constraints and suggested "package" amounts (three pre-set amounts shown as clickable buttons on the deposit form).

The `@CountryID` parameter is optional. If omitted, the global default configuration (CountryID=0 in `Billing.DepositAmount`) is returned. If provided, the country-specific configuration is returned. This dual-mode behavior allows callers to use the country-specific amounts when known and fall back gracefully to global defaults otherwise.

It is called by the `DepositUser` database user, the service account used for the general deposit flow. It determines whether the customer is making their first-ever deposit (`@IsFTD=1`) or is a returning depositor (`@IsFTD=0`) by checking for any existing approved deposit.

---

## 2. Business Logic

### 2.1 FTD Auto-Detection via Approved Deposit Check

**What**: The procedure automatically determines whether this customer is a first-time depositor, selecting the appropriate configuration row from `Billing.DepositAmount`.

**Columns/Parameters Involved**: `@CID`, `Billing.Deposit.PaymentStatusID`, `@IsFTD`

**Rules**:
- `@IsFTD = 0` if `EXISTS (SELECT 1 FROM Billing.Deposit WHERE PaymentStatusID=2 AND CID=@CID)` - at least one approved deposit found
- `@IsFTD = 1` if no approved deposit exists for @CID - this will be their first deposit
- `Billing.DepositAmount` has separate rows for FTD=0 and FTD=1 for each country, allowing different amount configurations for first-timers vs. returning depositors

### 2.2 Country Fallback to Global Default (CountryID=0)

**What**: When no country is provided, the procedure uses the global configuration row (CountryID=0), avoiding a null result.

**Columns/Parameters Involved**: `@CountryID`, `Billing.DepositAmount.CountryID`

**Rules**:
- `mda.CountryID = ISNULL(@CountryID, 0)`
- `@CountryID = NULL` -> uses CountryID=0 (global default row)
- `@CountryID = 81` (UK) -> uses UK-specific configuration row
- This is a key difference from `GetDefaultDepositSettingsByCountryAndFtd` which lacks the CountryID=0 fallback
- Result: single row from Billing.DepositAmount matching (FTD, CountryID)

### 2.3 Three-Package Suggested Amount Structure

**What**: Returns three pre-set deposit amounts shown as buttons in the deposit UI, plus a visibility flag controlling whether to show them.

**Columns/Parameters Involved**: `Package1Amount`, `Package2Amount`, `Package3Amount`, `IsPackageVisible`

**Rules**:
- `IsPackageVisible=1`: three package buttons are shown to the user
- `IsPackageVisible=0`: package buttons are hidden; only the freeform input field is shown
- Package amounts represent common deposit levels (e.g., $200, $500, $1000) that a customer can click to auto-fill the deposit amount
- Packages differ by country and FTD status (new depositors may see lower amounts to reduce friction)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used only to determine FTD status via approved deposit check in Billing.Deposit. Does not filter the main result - CountryID drives the row selection. |
| 2 | @CountryID | INT | YES | NULL | CODE-BACKED | Optional country ID. If provided, returns country-specific amounts. If NULL, returns global default amounts (CountryID=0 in Billing.DepositAmount). Allows caller to use country-specific config when known, global fallback otherwise. |
| 3 | MinAmount (output) | MONEY | YES | - | CODE-BACKED | Minimum allowed deposit amount for this country and FTD combination. From Billing.DepositAmount.MinAmount. |
| 4 | Package1Amount (output) | MONEY | YES | - | CODE-BACKED | First suggested deposit amount shown as a clickable button in the deposit UI. Typically the lowest of the three suggested amounts. From Billing.DepositAmount.Package1Amount. |
| 5 | Package2Amount (output) | MONEY | YES | - | CODE-BACKED | Second suggested deposit amount (medium option). From Billing.DepositAmount.Package2Amount. |
| 6 | Package3Amount (output) | MONEY | YES | - | CODE-BACKED | Third suggested deposit amount (highest option). From Billing.DepositAmount.Package3Amount. |
| 7 | IsPackageVisible (output) | BIT | YES | - | CODE-BACKED | Controls whether the three package-amount buttons are displayed in the deposit UI. 1=show buttons, 0=hide buttons (freeform input only). From Billing.DepositAmount.IsPackageVisible. |
| 8 | MaxAmount (output) | MONEY | YES | - | CODE-BACKED | Maximum allowed deposit amount for this country and FTD combination. From Billing.DepositAmount.MaxAmount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | EXISTS check to determine FTD status (PaymentStatusID=2) |
| @CountryID (with ISNULL fallback) | Billing.DepositAmount.CountryID | Lookup | Selects country-specific row or global default (CountryID=0) |
| @IsFTD (derived) | Billing.DepositAmount.FTD | Lookup | Filters by FTD vs. returning depositor |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Called by the main deposit service during deposit flow initialization |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositAmountsForUser (procedure)
├── Billing.Deposit (table)
└── Billing.DepositAmount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | EXISTS check - determines FTD status by checking for approved deposits |
| Billing.DepositAmount | Table | SELECT - retrieves full deposit amount configuration row by (FTD, CountryID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Calls this SP to get deposit amount limits and suggested package amounts for the deposit UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(@CountryID, 0) | Logic | Null-safe country lookup - falls back to global default (CountryID=0) when country is not provided |
| SET NOCOUNT ON | Setting | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Get deposit packages for an authenticated customer (country known)

```sql
EXEC Billing.GetDepositAmountsForUser @CID = 12345, @CountryID = 81;  -- UK
```

### 8.2 Get deposit packages using global defaults (no country)

```sql
EXEC Billing.GetDepositAmountsForUser @CID = 12345;  -- @CountryID defaults to NULL -> uses CountryID=0
```

### 8.3 View deposit amount configuration for a country

```sql
SELECT
    CountryID,
    FTD,
    MinAmount,
    Package1Amount,
    Package2Amount,
    Package3Amount,
    IsPackageVisible,
    MaxAmount
FROM Billing.DepositAmount WITH (NOLOCK)
WHERE CountryID IN (0, 81)  -- global default + UK
ORDER BY CountryID, FTD;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositAmountsForUser | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositAmountsForUser.sql*
