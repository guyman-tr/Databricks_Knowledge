# Dictionary.FinancialDiscrepancyType

> Lookup table classifying the 17 types of financial discrepancies detected by eToro's billing reconciliation — from duplicated deposits and cashouts to wrong exchange rates, conversion fee errors, and credit card data leakage alerts.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FinancialDiscrepancyType catalogs every type of financial anomaly that eToro's automated reconciliation processes can detect. Each type represents a specific category of billing inconsistency — duplicate transactions, balance update failures, incorrect exchange rates, fee miscalculations, and even credit card data leakage alerts. These classifications drive the investigation workflow and determine the urgency and team responsible for resolution.

This table is essential for eToro's financial integrity and regulatory compliance. Automated reconciliation jobs run continuously to compare expected vs actual balances, validate fee calculations against business settings, and detect security incidents. When a discrepancy is found, a record is created in Billing.FinancialDiscrepancy with a reference to the type (FK to this table) and direction (FK to Dictionary.FinancialDiscrepancyDirection). Each type has a Meaning field that explains the discrepancy in business terms for the operations team.

The IsHaveFinancialImpact flag was designed to distinguish discrepancies that affect actual money (e.g., duplicate deposits) from those that are informational (e.g., data leakage alerts). Currently all production values have this field as NULL, suggesting the classification may not yet be actively used in automation.

---

## 2. Business Logic

### 2.1 Discrepancy Categories

**What**: Discrepancy types fall into five functional categories based on what billing operation went wrong.

**Columns/Parameters Involved**: `ID`, `Name`, `Meaning`, `IsHaveFinancialImpact`

**Rules**:
- **Duplicate transaction detection** (IDs 1, 4, 5): Balance updated more than once for a single operation, or multiple FTDs assigned
- **Balance update failures** (IDs 2, 3): Customer balance not updated during deposit or recovered via disaster recovery
- **Exchange rate errors** (IDs 7, 8, 9): Wrong dealing rate used during deposit/cashout processing — requires extra investigation
- **Fee mismatches** (IDs 10-15): Deducted fees (PIPS, conversion, withdrawal) don't match business settings
- **Security incidents** (ID 16): Credit card data leakage detected in database logs — triggers security response
- **3DS authentication failures** (ID 6): Transaction processed without completing 3DS authorization
- **Test entries** (ID 17): Non-production test record

**Diagram**:
```
Financial Discrepancy Types
├── Duplicate Transactions (1, 4, 5)
│     └── Deposit/Cashout/FTD duplicated
├── Balance Failures (2, 3)
│     └── Update missed or disaster recovery applied
├── Exchange Rate Errors (7, 8, 9)
│     └── Wrong rate during deposit/cashout/override
├── Fee Mismatches (10, 11, 12, 13, 14, 15)
│     └── PIPS/conversion/withdrawal fees ≠ settings
├── Security (16)
│     └── Credit card data leakage
└── Authentication (6)
      └── 3DS not authorized
```

---

## 3. Data Overview

| ID | Name | Meaning | Business Context |
|---|---|---|---|
| 1 | Duplicated Deposit | Balance of Deposit was updated more than once | A deposit's balance credit was applied twice — the customer received double the intended amount. Requires immediate investigation to reverse the duplicate credit and prevent withdrawal of unearned funds. |
| 6 | 3DS Not Authorized Transaction | Credit Card Transaction did not Pass 3DS Auth Process | A credit card deposit was processed without completing 3D Secure authentication. Represents a compliance and chargeback risk — the transaction may not be covered by the liability shift. |
| 12 | Wrong Conversion Fees | Deducted Conversion Fee not aligned to Basic Threshold | The currency conversion fee charged during a deposit or cashout differs from the configured fee threshold. May indicate a configuration change that wasn't propagated correctly or a race condition during processing. |
| 16 | Credit Card Data Leakage | CreditCard Data Leakage was Identified inside DB Logs | Sensitive credit card data (full PAN, CVV) was found in database logs where it should not appear. Triggers PCI-DSS security incident response. |
| 7 | Wrong Base Exchange Rate during Deposit Processing | Wrong Dealing Rate received during Deposit processing, need extra investigation | The exchange rate used for currency conversion during deposit processing doesn't match the expected market rate, potentially overcharging or undercharging the customer. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the discrepancy type. 1=Duplicated Deposit, 2=Update Customer Balance Discrepancy, 3=Customer Balance Recovery, 4=Duplicated Cashouts, 5=Duplicated FTD, 6=3DS Not Authorized, 7=Wrong Rate (Deposit), 8=Wrong Rate (Cashout), 9=Override Exchange Rate, 10=Deposit PIPS Mismatch, 11=Cashout PIPS Mismatch, 12=Wrong Conversion Fees, 13=eToroMoney Transfer Deposit Discrepancy, 14=Wrong Redeem Conversion Fees, 15=Wrong Withdraw Request Fees, 16=Credit Card Data Leakage, 17=Test. Referenced by Billing.FinancialDiscrepancy via explicit FK. |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Short label for the discrepancy type. Used in BackOffice investigation UI and reconciliation reports. Describes the anomaly category concisely. |
| 3 | Meaning | varchar(max) | NO | - | VERIFIED | Extended description explaining the discrepancy in business terms. Provides investigation context for operations staff — what went wrong and what needs to be checked. |
| 4 | IsHaveFinancialImpact | bit | YES | - | CODE-BACKED | Flag indicating whether this discrepancy type has a direct monetary impact on the customer's balance (1=yes) versus being informational/security-only (0=no). Currently NULL for all production types (1-16) and false for the test entry (17), suggesting this classification is not yet actively used in automated workflows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FinancialDiscrepancy | FinancialDiscrepancyTypeID | FK | Each discrepancy record is classified by type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.FinancialDiscrepancy | Table | FK to ID — classifies each discrepancy record by type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinancialDiscrepancyType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinancialDiscrepancyType | PRIMARY KEY | Unique discrepancy type identifier |

---

## 8. Sample Queries

### 8.1 List all discrepancy types with their meanings
```sql
SELECT  ID,
        Name,
        Meaning,
        IsHaveFinancialImpact
FROM    [Dictionary].[FinancialDiscrepancyType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count discrepancies by type
```sql
SELECT  dt.Name         AS DiscrepancyType,
        COUNT(*)        AS Total
FROM    [Billing].[FinancialDiscrepancy] fd WITH (NOLOCK)
JOIN    [Dictionary].[FinancialDiscrepancyType] dt WITH (NOLOCK)
        ON fd.FinancialDiscrepancyTypeID = dt.ID
GROUP BY dt.Name
ORDER BY Total DESC;
```

### 8.3 Find discrepancies with full type and direction labels
```sql
SELECT  fd.FinancialDiscrepancyID,
        dt.Name             AS DiscrepancyType,
        dd.Name             AS Direction,
        dt.IsHaveFinancialImpact,
        fd.CreatedDate
FROM    [Billing].[FinancialDiscrepancy] fd WITH (NOLOCK)
JOIN    [Dictionary].[FinancialDiscrepancyType] dt WITH (NOLOCK)
        ON fd.FinancialDiscrepancyTypeID = dt.ID
LEFT JOIN [Dictionary].[FinancialDiscrepancyDirection] dd WITH (NOLOCK)
        ON fd.FinancialDiscrepancyDirectionID = dd.ID
ORDER BY fd.CreatedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FinancialDiscrepancyType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FinancialDiscrepancyType.sql*
