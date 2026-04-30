# Billing.CustomerStatusToBank

> Small configuration table mapping banking partners to a verification requirement flag; indicates whether a bank requires customer verification (KYC/status check) before processing transactions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | BankID - PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup (FILLFACTOR 90) |
| **Indexes** | 1 (PK on BankID) |

---

## 1. Business Meaning

`Billing.CustomerStatusToBank` is a 3-row configuration lookup that specifies whether a banking partner requires customer verification (KYC/identity verification) before transactions can be processed for that bank. The `Verified` bit column encodes this requirement: `1` = the bank requires verified customers, `0` = the bank does not require verification.

The table only covers 3 of the banks in Dictionary.Bank:
- BankID=1 (CAL, now inactive Israeli bank) -> Verified=true
- BankID=2 (WireCard Bank, active) -> Verified=false
- BankID=7 (LeumiCard, inactive Israeli bank) -> Verified=true

The pattern suggests that the Israeli banking partners (CAL, LeumiCard) historically required customers to have verified status before transactions were processed, while WireCard Bank did not enforce this requirement at the bank-routing level.

No stored procedures were found referencing this table - it may be loaded by an application layer or service as a configuration dataset, or it may be a legacy artifact from when the Israeli bank routing was active.

---

## 2. Business Logic

### 2.1 Bank-Level Verification Gate

**What**: Maps each banking partner to whether customer verification status must be checked before routing transactions to that bank.

**Columns/Parameters Involved**: `BankID`, `Verified`

**Rules**:
```
For a given bank routing decision:
  IF CustomerStatusToBank.Verified = 1 (CAL, LeumiCard):
    -> Customer must have verified status before transactions can be routed to this bank
  IF CustomerStatusToBank.Verified = 0 (WireCard):
    -> No verification check at bank routing level
  IF bank not in this table:
    -> No mapping defined (behavior depends on consumer)
```

**Current data state**:
```
BankID 1  (CAL - inactive)       -> Verified=true  (requires KYC before use)
BankID 2  (WireCard - active)    -> Verified=false (no KYC gate at bank level)
BankID 7  (LeumiCard - inactive) -> Verified=true  (requires KYC before use)
```

---

## 3. Data Overview

| BankID | BankName | IsActive | Verified | Meaning |
|--------|----------|----------|----------|---------|
| 1 | CAL | 0 (inactive) | true | Inactive Israeli bank (CAL card). Verification required - only verified customers could use CAL for transactions. |
| 2 | WireCard Bank | 1 (active) | false | Active German payment processor (WireCard). No verification gate at bank level for WireCard transactions. |
| 7 | LeumiCard | 0 (inactive) | true | Inactive Israeli bank (Leumi credit card). Verification required - only verified customers could use LeumiCard for transactions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BankID | int | NO | - | VERIFIED | Primary key. References Dictionary.Bank(BankID) via FK_DBNK_BCSB. Identifies which banking partner this verification rule applies to. Only 3 banks are configured: 1=CAL, 2=WireCard, 7=LeumiCard. |
| 2 | Verified | bit | NO | - | VERIFIED | Whether this bank requires customers to have verified status before transactions can be routed through it. 1=verification required (CAL, LeumiCard - both inactive Israeli banks), 0=no verification requirement at bank level (WireCard - active). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID | Dictionary.Bank | FK (explicit: FK_DBNK_BCSB) | Constrains BankID to valid banking partners in Dictionary.Bank |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views found in the SSDT repo that reference this table. The table may be consumed by application-layer services or used as a static configuration source.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CustomerStatusToBank (table)
|- Dictionary.Bank (table) [FK: BankID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FK target - valid bank set |

### 6.2 Objects That Depend On This

No stored procedure dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCSB | CLUSTERED PK | BankID ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BCSB | PRIMARY KEY CLUSTERED | BankID - one verification rule per bank |
| FK_DBNK_BCSB | FOREIGN KEY | BankID must exist in Dictionary.Bank |

---

## 8. Sample Queries

### 8.1 Get all bank verification requirements with bank names
```sql
SELECT  CSTB.BankID,
        DB.Name             AS BankName,
        DB.IsActive,
        CSTB.Verified
FROM    Billing.CustomerStatusToBank CSTB WITH (NOLOCK)
INNER JOIN Dictionary.Bank DB WITH (NOLOCK)
        ON CSTB.BankID = DB.BankID
ORDER BY CSTB.BankID;
```

### 8.2 Check if a specific bank requires customer verification
```sql
SELECT  CSTB.Verified
FROM    Billing.CustomerStatusToBank CSTB WITH (NOLOCK)
WHERE   CSTB.BankID = 2;  -- WireCard: returns 0 (no verification required)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CustomerStatusToBank | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CustomerStatusToBank.sql*
