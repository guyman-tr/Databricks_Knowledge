# BackOffice.BillingDepositsPCIVersion_Old

> Legacy predecessor to BackOffice.BillingDepositsPCIVersion: the prior version of the deposit management report, retained for reference/rollback, superseded by BillingDepositsPCIVersion which adds ExchangeFeePercentage and fixes duplicate column and correlation ID issues.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (date range required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the retained prior version of `BackOffice.BillingDepositsPCIVersion`. It was preserved to allow rollback or comparison when the current version was updated. It shares the same architecture, parameters, and core result set as the active version but differs in three specific areas.

The procedure generates the same BackOffice deposit management report: a filterable, pageable result set of deposit records enriched with customer profile, funding, merchant, risk, and 3DS data. For full business context, see `BackOffice.BillingDepositsPCIVersion`.

This `_Old` variant was the last stable version before the following changes were applied to the active procedure: (1) addition of `[Exchange Fee Percentage]` column (MIMOPSA-16636); (2) refactoring of the PIPs-in-USD calculation from an `OUTER APPLY` to an inline scalar function call; (3) renaming of the last column from an erroneous backtick alias to `[Correlation ID (C2F)]`; (4) deduplication of the `[Processed By]` column (which appears twice in `_Old`'s SELECT list due to a copy-paste error).

Data flows identically to the active version. See `BackOffice.BillingDepositsPCIVersion` Section 1 for the full flow description.

---

## 2. Business Logic

### 2.1 Differences from BillingDepositsPCIVersion (Active Version)

**What**: This `_Old` variant differs from the current active version in four specific ways.

**Rules**:
- **Missing ExchangeFeePercentage**: `_Old` does NOT include `BDEP.ExchangeFeePercentage AS [Exchange Fee Percentage]` (added in MIMOPSA-16636 to the active version)
- **PIPs in USD calculation**: `_Old` uses `OUTER APPLY BackOffice.CalculateDepositPIPsUSD(FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, Amount, CurrencyID)` with multi-parameter signature; active version uses `[Billing].[CalculateDepositPIPsUSD](BDEP.DepositID)` (single DepositID parameter - simplified interface). Output column named `[PIPs in USD]` in `_Old` vs `[Exchange Fee In USD]` in active
- **Duplicate [Processed By] column**: `_Old` has `[Processed By]` listed twice in the final SELECT due to a copy-paste error
- **Correlation ID column**: `_Old`'s last column uses a backtick alias (`` `1` ``) for the FundingTypeID=27 correlation ID; active version correctly names it `[Correlation ID (C2F)]`
- All dynamic SQL mechanics, filter parameters, temp tables, and core business logic are identical to the active version

### 2.2 Core Business Logic

All other business logic (dynamic credit table selection, two ordering modes, optional filter injection, MID resolution, payment details extraction, rollback calculation, 3DS extraction) is identical to `BackOffice.BillingDepositsPCIVersion`. See that procedure's Section 2 for the full business logic documentation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters (identical to BillingDepositsPCIVersion):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of date range. See BillingDepositsPCIVersion for full description. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of date range. See BillingDepositsPCIVersion for full description. |
| 3 | @CID | INTEGER | YES | NULL | CODE-BACKED | Optional single customer filter. |
| 4 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | Excludes customers with this PlayerLevelID when non-zero. |
| 5 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated regulation IDs to filter by. |
| 6 | @WhiteLabels | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated white label/brand IDs to filter by. |
| 7 | @FundingTypeIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated funding type IDs to filter by. |
| 8 | @PaymentStatusIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated payment status IDs to filter by. |
| 9 | @currenciesIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated currency IDs to filter by. |
| 10 | @OrderByClause | NVARCHAR(100) | YES | 'First Approved Time' | CODE-BACKED | Sort mode: 'First Approved Time' or 'Status Modification Time'. |
| 11 | @IsLimit | BIT | YES | 1 | CODE-BACKED | 1 = TOP 1000 limit; 0 = all rows. |

**Result Set - Differences from BillingDepositsPCIVersion:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 12-35 | (same as BillingDepositsPCIVersion) | - | - | - | - | All columns identical except those listed below |
| 36 | [PIPs in USD] | MONEY | YES | - | CODE-BACKED | Exchange fee in USD. Calculated via OUTER APPLY BackOffice.CalculateDepositPIPsUSD with multi-parameter signature (FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, Amount, CurrencyID). Named [PIPs in USD] in this version vs [Exchange Fee In USD] in the active version. |
| 37 | [Exchange Fee Percentage] | - | - | - | CODE-BACKED | NOT PRESENT in this _Old version. Added in MIMOPSA-16636 to the active BillingDepositsPCIVersion. |
| 38 | [Processed By] | NVARCHAR | YES | - | CODE-BACKED | Duplicated in SELECT list due to copy-paste error. Active version has it only once. |
| 39 | (Correlation ID) | NVARCHAR | YES | - | CODE-BACKED | Last column aliased with backtick character (`1`) instead of [Correlation ID (C2F)]. FundingTypeID=27 crypto-to-USD correlation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `BackOffice.BillingDepositsPCIVersion`. See that document's Section 5.1 for the full reference list.

The only functional difference: this version calls `BackOffice.CalculateDepositPIPsUSD` (multi-parameter version) via OUTER APPLY instead of `Billing.CalculateDepositPIPsUSD(DepositID)`.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice operations team | External | Rollback/comparison reference | Retained as the prior stable version before the MIMOPSA-16636 update |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BillingDepositsPCIVersion_Old (procedure)
|- (same dependency tree as BackOffice.BillingDepositsPCIVersion)
|- BackOffice.CalculateDepositPIPsUSD (function) [OUTER APPLY - multi-parameter version]
   NOTE: active version uses Billing.CalculateDepositPIPsUSD(DepositID) instead
```

### 6.1 Objects This Depends On

See `BackOffice.BillingDepositsPCIVersion` Section 6.1. Differences:
- Uses `BackOffice.CalculateDepositPIPsUSD` (multi-parameter: FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, Amount, CurrencyID) instead of `Billing.CalculateDepositPIPsUSD(DepositID)`

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice operations team | External | Legacy reference/rollback copy |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Same as `BackOffice.BillingDepositsPCIVersion`. Additional note:
- Contains a known bug: `[Processed By]` column appears twice in the final SELECT due to copy-paste error

---

## 8. Sample Queries

### 8.1 Compare _Old vs active for exchange fee calculation

```sql
-- Active version uses Billing.CalculateDepositPIPsUSD(DepositID)
-- _Old version uses BackOffice.CalculateDepositPIPsUSD(FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, Amount, CurrencyID)
-- Verify equivalence for a specific deposit:
SELECT [Billing].[CalculateDepositPIPsUSD](DepositID) AS ActiveVersion,
       DepositID, ExchangeRate, BaseExchangeRate, ExchangeFee, Amount, CurrencyID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 12345
```

### 8.2 Run _Old version for comparison with active version

```sql
EXEC BackOffice.BillingDepositsPCIVersion_Old
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-01',
    @CID = 99999,
    @IsLimit = 0
-- Compare output with BillingDepositsPCIVersion for same parameters
```

### 8.3 Check which deposits have ExchangeFeePercentage (active version only)

```sql
SELECT TOP 100 DepositID, ExchangeFee, ExchangeFeePercentage
FROM Billing.Deposit WITH (NOLOCK)
WHERE ExchangeFeePercentage IS NOT NULL
ORDER BY DepositID DESC
-- ExchangeFeePercentage column only exposed in the active BillingDepositsPCIVersion
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for BillingDepositsPCIVersion_Old. See `BackOffice.BillingDepositsPCIVersion` Section 9 for shared change history.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.BillingDepositsPCIVersion_Old | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BillingDepositsPCIVersion_Old.sql*
