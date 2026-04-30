# Billing.GetCurrencyDisplayName

> Returns the display name(s) for currencies that have one defined, used by the CashoutTool to render human-readable currency labels for cashout operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CurrencyID optional - returns one or all display names |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCurrencyDisplayName` retrieves the `DisplayName` field from `Dictionary.Currency` for currencies that have one. Unlike `GetCurrencies` which returns ISO codes (USD, EUR) for all 145 payment currencies, this procedure returns a separate `DisplayName` field that exists for only 19 currencies - these are special display labels used by the `CashoutTool` when presenting cashout options to customers or operations staff.

The `DisplayName` is distinct from the `ISOName`: it appears to be a localized or provider-specific label used in cashout flows. For example, CurrencyID=17 has DisplayName="DOLLAR" (not the standard "USD" ISO code), and currencies like MYR, THB, IDR, VND, PHP represent Southeast Asian currencies commonly used in cashout operations via local payment methods.

Data flow: The `CashoutTool` (cashout processing service) calls this procedure to build a currency-display-name map used for rendering cashout currency options in the UI or for labeling cashout transactions. The optional @CurrencyID parameter allows both bulk load (all 19) and single-currency lookup.

---

## 2. Business Logic

### 2.1 Optional Single vs. Bulk Lookup

**What**: The procedure supports both full-list load and single-record lookup via the optional @CurrencyID parameter.

**Columns/Parameters Involved**: `@CurrencyID`

**Rules**:
- `@CurrencyID = NULL` (default): returns all 19 currencies with a non-NULL DisplayName. Used for bulk loading the display name map at service startup.
- `@CurrencyID = {value}`: `WHERE CurrencyID = ISNULL(@CurrencyID, CurrencyID)` evaluates to `WHERE CurrencyID = {value}`. Returns 0 or 1 row depending on whether the specified currency has a DisplayName.
- The `ISNULL(@CurrencyID, CurrencyID)` pattern is a compact way to make the filter optional without a dynamic WHERE clause.

### 2.2 DisplayName vs. ISOName

**What**: The DisplayName column contains alternative labels distinct from the standard ISO 4217 codes stored in ISOName.

**Rules**:
- Only 19 of 10,669 currencies in Dictionary.Currency have a DisplayName (0.18%).
- Known values: DOLLAR (CurrencyID=17), MYR, THB, IDR, VND, PHP, CZK, RON, and 11 others.
- These are specifically the currencies relevant to the CashoutTool - likely corresponding to local payment methods or regional cashout providers.
- A currency with ISOName IS NOT NULL (returned by GetCurrencies) may or may not have a DisplayName. The two sets are largely non-overlapping.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyID | INT | YES | NULL | CODE-BACKED | Optional currency filter. When NULL (default): returns all 19 currencies that have a DisplayName. When provided: returns DisplayName for that specific currency only (0-1 rows). |

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CurrencyID | INT | NO | CODE-BACKED | Internal integer identifier for the currency. Key values with DisplayName: 17=DOLLAR, 77=MYR, 78=THB, 79=IDR, 80=VND, 81=PHP, 82=CZK, 83=RON, and 11 others. |
| 2 | DisplayName | NVARCHAR/VARCHAR | NO | CODE-BACKED | Alternative display label for the currency as used by the CashoutTool. Distinct from the ISO code in ISOName. Examples: "DOLLAR" (not "USD"), "MYR" (same as ISO), "THB". Always non-NULL in this result set (filtered by WHERE DisplayName IS NOT NULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID, DisplayName | Dictionary.Currency | Direct read (SELECT) | Filtered to DisplayName IS NOT NULL - returns only the 19 of 10,669 rows with a display label |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool | EXECUTE grant | Permission | Cashout processing tool calls this to build currency display labels for cashout UI and operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCurrencyDisplayName (procedure)
└── Dictionary.Currency (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | SELECT CurrencyID, DisplayName WHERE DisplayName IS NOT NULL (and optionally CurrencyID = @CurrencyID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool | External service | Reads currency display names for cashout operation rendering |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all currencies with display names

```sql
-- Returns 19 rows - all currencies with a defined DisplayName
EXEC [Billing].[GetCurrencyDisplayName]
```

### 8.2 Get display name for a specific currency

```sql
-- Returns 1 row if currency 17 has a DisplayName (it does: "DOLLAR")
EXEC [Billing].[GetCurrencyDisplayName] @CurrencyID = 17
```

### 8.3 Compare DisplayName vs. ISOName for the same currencies

```sql
-- Shows how DisplayName differs from the standard ISO code
SELECT c.CurrencyID, c.ISOName, c.DisplayName
FROM [Dictionary].[Currency] WITH (NOLOCK) c
WHERE c.DisplayName IS NOT NULL
ORDER BY c.CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Live data: 19 currencies with DisplayName confirmed | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCurrencyDisplayName | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCurrencyDisplayName.sql*
