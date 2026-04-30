# Billing.UnionPayBanks

> Registry of Chinese bank identifiers used in the UnionPay payment network, including bank abbreviations (in English and Chinese), and credit/debit bank codes for routing transactions through UnionPay terminals.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | BankID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.UnionPayBanks is the lookup table for Chinese bank entities supported by the UnionPay payment system. UnionPay is a Chinese payment card network (FundingTypeID=22) that allows Chinese customers to deposit using their domestic bank cards. This table provides the bank identifier, abbreviated name (English and Chinese), and the bank-specific routing codes required by the UnionPay payment processor.

The table serves two functions: (1) powering the bank picker UI shown to Chinese customers when they select UnionPay as their deposit method, and (2) providing the BankCodeCredit/BankCodeDebit values used by the terminal to route transactions to the correct issuing bank.

**29 rows**: 24 active Chinese banks + 4 inactive + BankID=0 (Unknown sentinel). BankID=0 is used by Zotapay as the universal routing destination (no specific bank selection required).

---

## 2. Business Logic

### 2.1 Bank Eligibility for Customer Display

**What**: `UnionPaySupportedBanksGet` returns the banks available to customers by JOINing this table with UnionPayRouting and UnionPayTerminal, filtering for all three IsActive=1.

**Rules**:
- Banks shown to customer = UnionPayRouting.IsActive=1 AND UnionPayTerminal.IsActive=1 AND UnionPayBanks.IsActive=1 AND BankID<>0
- BankID=0 (Unknown) is excluded from customer display
- Currently: only TerminalID=3 (Zotapay) is active, but its only routing entry has BankID=0, so the current effective result is 0 selectable banks
- The BaoFoo (TerminalID=1) routing entries are active but the terminal itself is inactive, so those 20 banks are not shown

---

## 3. Data Overview

| BankID | BankAbbreviation | Description | BankCodeCredit | BankCodeDebit | IsActive |
|--------|-----------------|-------------|----------------|---------------|----------|
| 0 | Unknown | Unknown | NULL | NULL | true |
| 1 | ICBC | China Industrial and Commercial Bank | 4002 | 3002 | true |
| 2 | ABC | Agricultural Bank of China | 4005 | 3005 | true |
| 3 | BOC | Bank of China | 4026 | 3026 | true |
| 4 | CCB | China Construction Bank | 4003 | 3003 | true |
| ... | ... | ... (24 total active) | ... | ... | true |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BankID | INT | NO | - | CODE-BACKED | Surrogate primary key and bank identifier. BankID=0 is the "Unknown" sentinel used when no specific bank is selected (Zotapay routing). |
| 2 | BankAbbreviation | VARCHAR(10) | NO | - | CODE-BACKED | Short English code for the bank. Examples: ICBC, ABC, BOC, CCB, CMB. Used in the `UnionPaySupportedBanksGet` result set for display to the application. |
| 3 | BankCodeCredit | INT | YES | - | CODE-BACKED | Bank-specific numeric code for credit card transactions via this bank. NULL for Unknown(BankID=0). Used by the UnionPay terminal to route credit card payments. Example: ICBC credit = 4002. |
| 4 | BankCodeDebit | INT | YES | - | CODE-BACKED | Bank-specific numeric code for debit card transactions via this bank. NULL for Unknown. Range: 3002-3xxx. Example: ICBC debit = 3002. Pattern: credit codes are 4xxx, debit codes are 3xxx. |
| 5 | Description | NVARCHAR(50) | NO | - | CODE-BACKED | Full English name of the bank. Example: "China Industrial and Commercial Bank of China", "Agricultural Bank of China". |
| 6 | IsActive | BIT | NO | - | CODE-BACKED | Whether this bank is currently offered to customers. 24 of 29 rows are active. Inactive banks are excluded from UnionPaySupportedBanksGet. No DEFAULT defined - must be set on INSERT. |
| 7 | ChineseAbbreviation | NVARCHAR(50) | YES | - | CODE-BACKED | Chinese language name of the bank. Used for display to Chinese-speaking customers. Examples: "中国工商银行" (ICBC), "中国银行" (BOC). NULL for Unknown(BankID=0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. This is a standalone reference/dictionary table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UnionPayRouting | BankID | READER (implicit FK) | Routing table references BankID for bank-terminal combinations |
| Billing.UnionPaySupportedBanksGet | BankID, BankAbbreviation | READER | JOINs all three UnionPay tables to return active bank list |
| Billing.GetCustomerDepositInfo | - | READER | Retrieves customer's UnionPay bank info during deposit lookup |

---

## 6. Technical Details

### 6.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_Billing]].[UnionPayBanks | CLUSTERED PK | BankID ASC | Active |

Note: PK constraint name has a syntax anomaly `]].[` - likely a historical typo in the DDL.

---

## 7. Sample Queries

```sql
-- Get all active Chinese banks available for UnionPay
SELECT upb.BankID, upb.BankAbbreviation, upb.Description, upb.ChineseAbbreviation,
       upb.BankCodeCredit, upb.BankCodeDebit
FROM [Billing].[UnionPayBanks] upb WITH (NOLOCK)
WHERE upb.IsActive = 1 AND upb.BankID <> 0
ORDER BY upb.BankAbbreviation
```

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.2/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UnionPayBanks | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.UnionPayBanks.sql*
