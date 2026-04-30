# Billing.WireTransferBankDetailsGet

> Returns the supported currencies and bank name for a given wire transfer bank, optionally filtered by regulation region. Used to populate bank detail forms during wire transfer deposit initiation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BankID + @RegulationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WireTransferBankDetailsGet` retrieves the available currency options and bank information for a specific wire transfer receiving bank, identified by `@BankID`. It joins `Billing.WireTransferBankInfo` (which stores per-bank, per-currency, per-regulation configuration) with `Billing.WireTransferBanks` (which stores the bank's name and default currency).

The optional `@RegulationID` parameter filters results to a specific regulatory jurisdiction. When NULL (default), all regulation groups for the bank are returned via the ISNULL self-comparison trick (`WTBI.RegulationID = ISNULL(NULL, WTBI.RegulationID)` is always true).

This procedure is typically called when a customer selects a bank for a wire transfer deposit, to determine which currencies are accepted and what the default currency is.

---

## 2. Business Logic

### 2.1 Bank-Currency-Regulation Query

**What**: Returns distinct rows of BankID, CurrencyID, DefaultCurrencyID, BankName for the given bank and optional regulation filter.

**Rules**:
- JOIN: `Billing.WireTransferBankInfo WTBI INNER JOIN Billing.WireTransferBanks WTB ON WTBI.BankID = WTB.ID`
- WHERE: `@BankID = WTBI.BankID AND WTBI.RegulationID = ISNULL(@RegulationID, WTBI.RegulationID)`
- When `@RegulationID IS NULL`: `ISNULL(NULL, WTBI.RegulationID) = WTBI.RegulationID` → always true → returns all regulation groups for this bank
- When `@RegulationID IS NOT NULL`: strict filter to that specific regulation
- SELECT DISTINCT: prevents duplicate rows if a bank has multiple BankInfo entries per currency

**Result Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| BankID | WTBI.BankID | The wire transfer bank identifier |
| CurrencyID | WTBI.CurrencyID | Accepted currency for this bank+regulation combination |
| DefaultCurrencyID | WTB.DefaultCurrencyID | The bank's default currency |
| BankName | WTB.BankName | Display name of the bank |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BankID | INT | NO | - | CODE-BACKED | PK of `Billing.WireTransferBanks`. Identifies the wire transfer receiving bank. All result rows share this BankID. |
| 2 | @RegulationID | INT | YES | NULL | CODE-BACKED | Optional regulatory jurisdiction filter. When NULL, returns all currency/regulation combinations for the bank. When provided, restricts to that regulation group only. FK to a regulation lookup table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BankID | Billing.WireTransferBankInfo | SELECT (filtered) | Provides CurrencyID and RegulationID per bank configuration |
| @BankID | Billing.WireTransferBanks | JOIN | Provides BankName and DefaultCurrencyID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wire transfer deposit flow (application) | Bank selection UI | Application call | Called when a customer selects a bank to populate currency options |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WireTransferBankDetailsGet (procedure)
+-- Billing.WireTransferBankInfo (table) [SELECT - bank/currency/regulation config]
+-- Billing.WireTransferBanks (table) [JOIN - bank name and default currency]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferBankInfo | Table | SELECT: provides CurrencyID and RegulationID per bank entry |
| Billing.WireTransferBanks | Table | JOIN: provides BankName and DefaultCurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wire transfer service (application) | Application | Queries bank currency options during deposit initiation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL regulation filter | Design | `ISNULL(@RegulationID, WTBI.RegulationID)` returns all rows when @RegulationID is NULL |
| SELECT DISTINCT | Design | Prevents duplicate rows from multiple BankInfo entries per currency |
| No error handling | Design | No TRY/CATCH; if @BankID not found, returns empty result set |

---

## 8. Sample Queries

### 8.1 Get all currencies for a bank (no regulation filter)
```sql
EXEC Billing.WireTransferBankDetailsGet
    @BankID       = 5,
    @RegulationID = NULL;
```

### 8.2 Get currencies for a bank in a specific regulation
```sql
EXEC Billing.WireTransferBankDetailsGet
    @BankID       = 5,
    @RegulationID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WireTransferBankDetailsGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WireTransferBankDetailsGet.sql*
