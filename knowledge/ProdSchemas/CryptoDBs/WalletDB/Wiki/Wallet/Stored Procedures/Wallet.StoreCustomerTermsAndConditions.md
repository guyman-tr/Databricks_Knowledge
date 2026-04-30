# Wallet.StoreCustomerTermsAndConditions

> Records a customer's acceptance of specific terms and conditions with idempotency, used by the back-office API and executer to track regulatory compliance acceptance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into CustomerTermsAndConditions with idempotency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records that a customer has accepted specific terms and conditions. The back-office API and executer service call this when a customer agrees to T&C (e.g., during wallet creation or first transaction). Idempotent: duplicate Gcid+TermsAndConditionId combinations are silently skipped.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Idempotent INSERT with NOT EXISTS check on Gcid + TermsAndConditionId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer accepting the terms. |
| 2 | @TermsAndConditionId | int | NO | - | VERIFIED | T&C version being accepted. FK to Dictionary.TermsAndConditions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerTermsAndConditions | INSERT | T&C acceptance record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser, ExecuterUser | - | EXECUTE | T&C acceptance tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreCustomerTermsAndConditions (procedure)
+-- Wallet.CustomerTermsAndConditions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerTermsAndConditions | Table | INSERT with idempotency |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, ExecuterUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record T&C acceptance
```sql
EXEC Wallet.StoreCustomerTermsAndConditions @Gcid = 30351701, @TermsAndConditionId = 3;
```

### 8.2 Check customer's accepted T&Cs
```sql
SELECT * FROM Wallet.CustomerTermsAndConditions WITH (NOLOCK) WHERE Gcid = 30351701;
```

### 8.3 Direct equivalent
```sql
INSERT INTO Wallet.CustomerTermsAndConditions(Gcid, TermsAndConditionId)
SELECT 30351701, 3 WHERE NOT EXISTS (SELECT 1 FROM Wallet.CustomerTermsAndConditions WHERE Gcid = 30351701 AND TermsAndConditionId = 3);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreCustomerTermsAndConditions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreCustomerTermsAndConditions.sql*
