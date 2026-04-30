# Dictionary.AccountType

> Lookup table classifying eToro accounts by ownership type and purpose, controlling features, regulatory treatment, and fee structures.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountTypeID (TINYINT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on AccountTypeName) |

---

## 1. Business Meaning

Dictionary.AccountType classifies every eToro account into one of 17 categories based on its ownership structure and operational purpose. This classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how the account is monitored for compliance.

This table is essential to the platform's multi-entity architecture. Without it, the system cannot differentiate between a retail individual's account and a corporate entity, between an employee and a custodian, or between a standard user and an introducing broker partner. Every customer-facing flow — registration, trading, funding, compliance, and reporting — checks account type.

Account types are assigned at registration time and stored in Customer.CustomerStatic. They are read by procedures across BackOffice (user management), Trade (order execution and BSL calculations), Hedge (liquidity account routing), Billing (payment formatting), and Compliance (KYC document requirements). The account type is rarely changed after initial assignment.

---

## 2. Business Logic

### 2.1 Account Category Groups

**What**: Account types naturally cluster into functional groups that determine system behavior.

**Columns/Parameters Involved**: `AccountTypeID`, `AccountTypeName`

**Rules**:
- **Retail accounts** (1=Private, 4=Joint, 14=SMSF, 16=Administrated): Standard users subject to full retail regulation
- **Corporate accounts** (2=Corporate, 15=Affiliate Corporate): Business entities with enhanced KYC and reporting
- **Partner accounts** (3=IB, 5=White Label, 6=Affiliate Private, 12=White List): Revenue-sharing arrangements with special fee/commission structures
- **Internal accounts** (7=Employee, 10=eToro Group, 11=News, 13=Analyst, 17=Funded Employee): eToro-operated accounts with enhanced compliance monitoring
- **Managed accounts** (8=Custodian, 9=Fund): Third-party managed accounts with fiduciary requirements

**Diagram**:
```
Dictionary.AccountType
├── Retail (standard users)
│   ├── 1: Private
│   ├── 4: Joint Account
│   ├── 14: SMSF
│   └── 16: Administrated
├── Corporate (business entities)
│   ├── 2: Corporate
│   └── 15: Affiliate Corporate
├── Partner (revenue-sharing)
│   ├── 3: IB Account
│   ├── 5: White Label
│   ├── 6: Affiliate Private
│   └── 12: White List
├── Internal (eToro-operated)
│   ├── 7: Employee Account
│   ├── 10: eToro Group Account
│   ├── 11: News
│   ├── 13: Analyst
│   └── 17: Funded Employee Account
└── Managed (third-party managed)
    ├── 8: Custodian
    └── 9: Fund
```

### 2.2 Fund and Copy Trading Routing

**What**: Account type determines how copy trading and fund management operations route.

**Columns/Parameters Involved**: `AccountTypeID`

**Rules**:
- AccountTypeID=9 (Fund) is used by Customer.IsCustomerFund view to identify managed fund accounts
- Fund accounts have special copy-trading settlement restrictions (Trade.CopyTradeSettlementRestrictions)
- Fund allocation procedures (Trade.Job_GenerateFundAllocation) route based on account type
- Hedge procedures use account type to route to correct liquidity accounts

---

## 3. Data Overview

| AccountTypeID | AccountTypeName | Meaning |
|---|---|---|
| 1 | Private | The default account type for individual retail users. Assigned automatically at registration. Subject to standard KYC, leverage limits per regulation, and retail investor protections. |
| 2 | Corporate | Business entity account requiring company registration documents, director identification, and UBO (Ultimate Beneficial Owner) verification. Separate fee tier and reporting. |
| 3 | IB Account | Introducing Broker partner account that refers clients to the platform. Earns commissions on referred client activity. Special back-office tracking for referral attribution. |
| 9 | Fund | Managed fund account where a professional trader manages pooled capital from multiple copiers. Triggers special settlement restrictions and allocation procedures. |
| 17 | Funded Employee Account | eToro employee account seeded with company-provided trading capital for training or product testing. Subject to enhanced compliance monitoring and trading restrictions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountTypeID | tinyint | NO | - | CODE-BACKED | Primary key identifying the account classification. 1=Private, 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. See [Account Type](_glossary.md#account-type). (Dictionary.AccountType) |
| 2 | AccountTypeName | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports. UNIQUE constraint ensures no duplicate names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | AccountTypeID | Implicit Lookup | Stores the account type for each customer |
| Customer.IsCustomerFund (view) | AccountTypeID | JOIN | Identifies fund accounts (AccountTypeID=9) |
| Price.GetPriceAccounts (view) | AccountTypeID | JOIN | Filters price feed accounts by type |
| Billing.FundingDataForDeposit (view) | AccountTypeID | JOIN | Includes account type in deposit data formatting |
| Trade.CopyTradeSettlementRestrictions | AccountTypeID | Implicit Lookup | Settlement rules vary by account type |
| Trade.Job_GenerateFundAllocation | AccountTypeID | Read | Routes fund allocation by account type |
| Trade.GetOrderForCloseContextData | AccountTypeID | Read | Includes account type in close order context |
| Trade.GetUserTradeStatusData | AccountTypeID | Read | Includes account type in trade status checks |
| BackOffice.GetCustomerByCIDVerification | AccountTypeID | Read | Reports account type in customer verification lookup |
| Hedge.GetActiveLiquidityAccounts | AccountTypeID | Read | Routes to liquidity accounts by type |
| Hedge.GetHedgeServerInfo | AccountTypeID | Read | Hedge server configuration per account type |
| Compliance.GetPOADocumentsExpirationPopulationFor3Years | AccountTypeID | Read | KYC document requirements vary by account type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores AccountTypeID per customer (implicit FK) |
| Trade.CopyTradeSettlementRestrictions | Table | Settlement rules per account type |
| Customer.IsCustomerFund | View | Identifies fund-type accounts |
| Price.GetPriceAccounts | View | Filters price accounts by type |
| Billing.FundingDataForDeposit | View | Formats deposit data with account type |
| Trade.Job_GenerateFundAllocation | Stored Procedure | Fund allocation routing |
| Trade.GetOrderForCloseContextData | Stored Procedure | Close order context includes account type |
| Hedge.GetActiveLiquidityAccounts | Stored Procedure | Liquidity account routing by type |
| Compliance.GetPOADocumentsExpirationPopulationFor3Years | Stored Procedure | KYC requirements per type |
| BackOffice.GetCustomerByCIDVerification | Stored Procedure | Customer verification lookup |
| DWH.BuildDWH_RiskMatrix | Stored Procedure | Risk matrix reporting by account type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DAT | CLUSTERED PK | AccountTypeID ASC | - | - | Active |
| UK_DAT_AccountTypeName | NC UNIQUE | AccountTypeName ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DAT | PRIMARY KEY | Unique account type identifier |
| UK_DAT_AccountTypeName | UNIQUE | Ensures no two account types share the same display name |

---

## 8. Sample Queries

### 8.1 List all account types
```sql
SELECT  AccountTypeID,
        AccountTypeName
FROM    [Dictionary].[AccountType] WITH (NOLOCK)
ORDER BY AccountTypeID;
```

### 8.2 Count customers per account type
```sql
SELECT  dat.AccountTypeName,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[AccountType] dat WITH (NOLOCK)
        ON cs.AccountTypeID = dat.AccountTypeID
GROUP BY dat.AccountTypeName
ORDER BY CustomerCount DESC;
```

### 8.3 Find all fund and custodian accounts with their owners
```sql
SELECT  cs.CID,
        cs.UserName,
        dat.AccountTypeName,
        cs.RegistrationDate
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[AccountType] dat WITH (NOLOCK)
        ON cs.AccountTypeID = dat.AccountTypeID
WHERE   cs.AccountTypeID IN (8, 9)
ORDER BY cs.RegistrationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.AccountType. Business meaning derived from codebase analysis of consuming procedures and views.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AccountType.sql*
