# Wallet.GetCustomerTermsAndConditions

> Determines a customer's Terms & Conditions status (FirstTime, UpdateRequired, or Signed) by comparing the latest T&C version against the customer's acceptance history, returning the current version URL and acceptance status.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns T&C version info + TandCStatus |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks whether a customer needs to accept Terms & Conditions for the crypto wallet service. It determines one of three states: "FirstTime" (customer has never accepted any T&C), "UpdateRequired" (customer accepted a previous version but a new one is available), or "Signed" (customer has accepted the current version). The procedure supports optional T&C types via @TypeId for different T&C categories.

Without this procedure, the application could not enforce T&C acceptance before allowing crypto operations, exposing eToro to legal liability.

The procedure finds the latest T&C version (optionally filtered by type), checks the customer's acceptance history, and returns the version details with the computed status.

---

## 2. Business Logic

### 2.1 Three-State T&C Status

**What**: Computes the customer's T&C acceptance status.

**Columns/Parameters Involved**: `@Gcid`, `@TypeId`, TermsAndConditions, CustomerTermsAndConditions

**Rules**:
- FirstTime: No rows exist in CustomerTermsAndConditions for this GCID (never accepted anything)
- UpdateRequired: Customer has accepted T&C before, but NOT the current version
- Signed: Customer has accepted the current version
- Current version = latest TermsAndConditions row matching the @TypeId (ORDER BY Occured DESC)
- Type matching uses COALESCE(@TypeId, -1) pattern for NULL-safe comparison

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID whose T&C status to check. |
| 2 | @TypeId | int | YES | NULL | CODE-BACKED | Optional T&C type filter. NULL returns the default/general T&C. Non-null returns the type-specific T&C (e.g., staking terms, specific jurisdiction terms). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.TermsAndConditions | Reader | Gets current T&C version |
| - | Wallet.CustomerTermsAndConditions | Reader | Checks customer's acceptance history |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCustomerTermsAndConditions (procedure)
  ├── Wallet.TermsAndConditions (table)
  └── Wallet.CustomerTermsAndConditions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TermsAndConditions | Table | Gets latest T&C version |
| Wallet.CustomerTermsAndConditions | Table | Checks acceptance history |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses temp table #TermsAndConditions
- COALESCE/ISNULL pattern for NULL-safe TypeId matching
- NOLOCK hints

---

## 8. Sample Queries

### 8.1 Check T&C status for a customer
```sql
EXEC Wallet.GetCustomerTermsAndConditions @Gcid = 12345678
```

### 8.2 Check type-specific T&C status
```sql
EXEC Wallet.GetCustomerTermsAndConditions @Gcid = 12345678, @TypeId = 2
```

### 8.3 View latest T&C versions
```sql
SELECT Id, Url, TypeId, Occured
FROM Wallet.TermsAndConditions WITH (NOLOCK)
ORDER BY Occured DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCustomerTermsAndConditions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCustomerTermsAndConditions.sql*
