# Billing.WithdrawalService_GetCustomerLastFundingPerFundingType

> Returns the most recent funding instrument (payment method) per funding type for a customer, combining deposit history and withdrawal history with special handling for UnionPay (FundingTypeID=22) and a geographic workaround for Chinese customers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT - the customer whose last funding per type is returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the withdrawal form pre-population feature: when a customer opens a withdrawal request, the UI shows their most recently used payment methods per type (credit card, bank transfer, UnionPay, etc.) so they do not need to re-enter details. The procedure returns the latest FundingData XML per FundingTypeID, allowing the UI to pre-fill payment forms with known account details.

The procedure covers two data sources: past deposits (where FundingTypeID IN mainstream payment types) and past completed withdrawals (for bank wire/online banking types 20 and 28). This dual-source approach is necessary because some payment instruments (e.g., wire transfer details, online banking details) are only registered through prior withdrawals, not through deposits.

Special logic handles UnionPay (FundingTypeID=22): the procedure first attempts to find UnionPay details from completed withdrawals (CashoutStatusID IN 3,5,6), and if not found, from completed deposits (PaymentStatusID=2), enriching the XML with the Chinese bank abbreviation from `Billing.UnionPayBanks`. A ZotaPay workaround synthesizes a default UnionPay XML for Chinese customers (CountryID=44) who have no prior UnionPay activity, ensuring the option is always presented to them.

Payoneer (FundingTypeID=14) support was removed on 22/04/2018 (ticket 51130: "Remove Payoneer Option") - commented-out code remains in the DDL.

---

## 2. Business Logic

### 2.1 Multi-Source Funding Lookup with Per-Type Latest Row

**What**: Returns the most recent payment instrument per funding type from both deposit history and withdrawal history.

**Columns/Parameters Involved**: `FundingTypeID`, `PaymentDate`, `FundingData`, `FundingID`, `rn` (ROW_NUMBER)

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY FundingTypeID ORDER BY PaymentDate DESC)` selects only the latest record per type (rn=1)
- **Deposits** (branch 1): PaymentStatusID=2 (approved/completed), excluding FundingTypeIDs 20 (wire), 22 (UnionPay), 28 (online banking), 3 (PayPal - excluded to avoid stale data)
- **UnionPay** (branch 2): Injected from pre-computed @UnionPayFunding variable (see Section 2.2)
- **Withdrawals** (branch 3): CashoutStatusID IN (3,5,6) = completed, for FundingTypeIDs 20 and 28 only - these types use withdrawal records as their "most recent usage" source
- DISTINCT on result eliminates duplicates from the UNION

**Diagram**:
```
@cid
  |
  +--[Branch 1: Deposits]--
  | SELECT FROM Billing.Deposit JOIN Billing.Funding
  | WHERE PaymentStatusID=2
  | AND FundingTypeID NOT IN (20,22,28,3)  -- mainstream payment types
  | PARTITION BY FundingTypeID -> latest 1 per type
  |
  +--[Branch 2: UnionPay special]--
  | Pre-computed @UnionPayFunding XML (see Section 2.2)
  | FundingTypeID=22, PaymentDate=GETDATE(), rn=1 always
  |
  +--[Branch 3: Withdrawals for wire/online banking]--
  | SELECT FROM Billing.Withdraw JOIN Billing.Funding
  | WHERE CashoutStatusID IN (3,5,6)        -- completed withdrawals
  | AND FundingTypeID IN (20,28)            -- wire + online banking
  | PARTITION BY FundingTypeID -> latest 1 per type
  |
  --> UNION ALL -> WHERE rn=1 -> DISTINCT
  --> Returns: PaymentDate, FundingTypeID, FundingData (as NVARCHAR), FundingID
```

### 2.2 UnionPay (FundingTypeID=22) Special Handling

**What**: UnionPay requires enriched XML with the Chinese bank abbreviation, resolved via a 2-step fallback chain.

**Columns/Parameters Involved**: `@BankID`, `@UnionPayFunding` (XML), `@ChineseBankName`, `@FundingID`

**Rules**:
- **Step 1 - withdrawal lookup**: Searches completed withdrawals (CashoutStatusID IN 3,5,6) for UnionPay funding. If found, @UnionPayFunding is set from the withdrawal's FundingData.
- **Step 2 - deposit fallback**: If no completed UnionPay withdrawal, searches completed deposits (PaymentStatusID=2). When found via deposit, the BankNameAsString XML element is replaced with the Chinese abbreviation from `Billing.UnionPayBanks` to ensure Chinese-language display.
- **Step 3 - ZotaPay workaround**: If the customer is from China (CountryID=44 or CountryIDByIP=44) AND no UnionPay funding was found in steps 1-2, a synthetic UnionPay XML is created with BankIDAsInteger=1 and the customer's CID as AccountIDAsDecimal. This ensures Chinese customers always see the UnionPay option even if they have never used it.

**Diagram**:
```
Search Withdraw (CashoutStatusID IN 3,5,6) for FundingTypeID=22
  |
  Found? --> @UnionPayFunding = FundingData from withdrawal
  |
  Not found? --> Search Deposit (PaymentStatusID=2) for FundingTypeID=22
                  |
                  Found? --> Get @ChineseBankName from Billing.UnionPayBanks
                             Replace BankNameAsString in XML with Chinese name
                             @UnionPayFunding = enriched FundingData
                  |
                  Not found AND CountryID=44? --> Synthesize default XML
                                                  BankIDAsInteger=1
                                                  AccountIDAsDecimal=@cid
```

### 2.3 CashoutStatus Values for "Completed" Withdrawals

**What**: FundingTypeIDs 20 and 28 use withdrawal history as their data source; only completed withdrawals qualify.

**Columns/Parameters Involved**: `CashoutStatusID` (filter: 3, 5, 6)

**Rules**:
- CashoutStatusID=3: Processed (payment completed/sent) - 26.4% of all withdrawals
- CashoutStatusID=5 and 6: Additional completed/approved statuses (per Billing.Withdraw distribution data)
- This filter ensures only successfully processed withdrawals contribute known-good bank details to the pre-fill

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Input parameter. Customer identifier. Used as the WHERE filter across all three data source branches (Billing.Deposit, Billing.Withdraw, Customer.CustomerStatic). |
| 2 | PaymentDate | datetime | YES | - | CODE-BACKED | Output column. Date of the most recent usage of the payment instrument for this type. From Billing.Deposit.PaymentDate (deposit branch) or Billing.Withdraw.RequestDate (withdrawal branch) or GETDATE() (UnionPay branch - always "now" to ensure it is treated as current). Used for ordering to select the latest per type. |
| 3 | FundingTypeID | int | NO | - | VERIFIED | Output column. Payment method type identifier. Each distinct value in the result represents one payment type the customer has used. 22=UnionPay (special handling), 20=Wire Transfer, 28=Online Banking, others from deposit history. See Billing.Funding.FundingTypeID for full type list. |
| 4 | FundingData | nvarchar(max) | YES | - | VERIFIED | Output column. XML payment instrument details cast to NVARCHAR(MAX). Structure varies by FundingTypeID: credit card XML contains card hash and BIN; bank transfer XML contains IBAN/SWIFT; UnionPay XML contains BankIDAsInteger, BankNameAsString (Chinese abbreviation), AccountIDAsDecimal, etc. Used by UI to pre-fill payment forms. Originally stored as XML in Billing.Funding.FundingData, cast here for transport. |
| 5 | FundingID | int | YES | - | VERIFIED | Output column. The FundingID from Billing.Funding for the selected payment instrument. Allows the caller to reference the exact funding record. 0 for the ZotaPay synthetic UnionPay case where no real FundingID exists (@FundingID defaults to ISNULL(@FundingID, 0)). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (JOIN) | Billing.Withdraw | Read | Source of completed withdrawal records (CashoutStatusID IN 3,5,6) for wire/online banking types and UnionPay lookup |
| (JOIN) | Billing.Funding | Read | Source of FundingData XML and FundingTypeID for all branches |
| (JOIN) | Billing.Deposit | Read | Source of completed deposit records (PaymentStatusID=2) for mainstream and UnionPay fallback |
| (SELECT) | Billing.UnionPayBanks | Lookup | Resolves @BankID to Chinese bank abbreviation for XML enrichment |
| (SELECT) | Customer.CustomerStatic | Read | Provides CountryID and CountryIDByIP for the ZotaPay China workaround check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Referenced in PROD_BIadmins permissions; called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_GetCustomerLastFundingPerFundingType (procedure)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
├── Billing.Deposit (table)
├── Billing.UnionPayBanks (table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | JOINed to Billing.Funding to find completed withdrawals (CashoutStatusID IN 3,5,6) for FundingTypeIDs 20, 28, and UnionPay fallback |
| Billing.Funding | Table | JOINed from Withdraw and Deposit to get FundingData XML and FundingTypeID |
| Billing.Deposit | Table | JOINed to Billing.Funding to find completed deposits (PaymentStatusID=2) for mainstream types and UnionPay fallback |
| Billing.UnionPayBanks | Table | Looked up by @BankID to get ChineseAbbreviation for XML enrichment |
| Customer.CustomerStatic | Table | Looked up by @cid to get CountryID and CountryIDByIP for ZotaPay China workaround |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code via PROD_BIadmins SQL login.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure for a specific customer

```sql
EXEC Billing.WithdrawalService_GetCustomerLastFundingPerFundingType @cid = 12345;
```

### 8.2 Equivalent deposit-side query (mainstream types only) without UnionPay special logic

```sql
SELECT  TOP 1 d.PaymentDate,
        f.FundingTypeID,
        CAST(f.FundingData AS NVARCHAR(MAX)) AS FundingData,
        f.FundingID
FROM    Billing.Deposit d WITH (NOLOCK)
JOIN    Billing.Funding f WITH (NOLOCK) ON d.FundingID = f.FundingID
WHERE   d.CID = 12345
        AND d.PaymentStatusID = 2
        AND f.FundingTypeID NOT IN (20, 22, 28, 3)
ORDER BY d.PaymentDate DESC;
```

### 8.3 Find all completed wire/online banking withdrawals for a customer (branch 3 equivalent)

```sql
SELECT  w.RequestDate    AS PaymentDate,
        f.FundingTypeID,
        CAST(f.FundingData AS NVARCHAR(MAX)) AS FundingData,
        f.FundingID
FROM    Billing.Withdraw w WITH (NOLOCK)
JOIN    Billing.Funding f WITH (NOLOCK) ON w.FundingID = f.FundingID
WHERE   w.CID = 12345
        AND w.CashoutStatusID IN (3, 5, 6)
        AND f.FundingTypeID IN (20, 28)
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawalService_GetCustomerLastFundingPerFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_GetCustomerLastFundingPerFundingType.sql*
