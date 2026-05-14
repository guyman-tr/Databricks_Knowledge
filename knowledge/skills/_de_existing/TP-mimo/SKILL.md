# Trading Platform MIMO Skill

## When to Use
Load this skill when the user asks about:
* Trading Platform Money In Money Out (MIMO) - deposits, withdrawals, cashouts
* Inter-platform transfers between eToro Money, Options, MoneyFarm and Trading Platform
* Trade from IBAN transactions
* Conversion fees, PIPsCalculation, or Merchant IDs (MID)
* First-time deposits (FTD) - Global vs Platform-specific
* Chargebacks, refunds, reversals, or net deposits
* Payment methods, payment statuses, or cashout statuses
* Affiliate payments or compensation
* Crypto withdrawals (redeems)

## Scope
**Covers**: eToro Trading Platform MIMO only
**Does NOT cover**: eMoney/IBAN platform billing, Options platform billing, MoneyFarm billing, Spaceship billing (separate skills)

---

## 🎯 CRITICAL UNDERSTANDING

### Primary vs Metadata Tables
* **fact_customeraction** = PRIMARY source for MIMO transaction amounts
* **fact_billingdeposit/withdraw** = METADATA only (state machine of current state)
* **BI_DB_DepositWithdrawFee** = Conversion fees (PIPsCalculation) + Merchant IDs (MID)
* **BI_DB_DepositWithdrawFee_Reversals** = Reversal tracking for net deposits
* **BI_DB_DDR_Fact_MIMO_AllPlatforms** = Semantic layer with business flags

### Data Flow Architecture
```
Genie Layer (Analytics)
  ↓ bi_output.vg_mimo
Semantic Layer (Business Logic)
  ↓ BI_DB_DDR_Fact_MIMO_AllPlatforms, v_semantic_mimo_tradingplatform
BI_DB Layer (Enriched)
  ↓ BI_DB_DepositWithdrawFee, BI_DB_DepositWithdrawFee_Reversals
DWH Layer (Dimensional)
  ↓ fact_customeraction (PRIMARY), fact_billingdeposit/withdraw (METADATA)
```

---

## 📊 TABLE REFERENCE

### 1. fact_customeraction (PRIMARY MIMO SOURCE)
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`

**Purpose**: PRIMARY source for MIMO transaction amounts

**Granularity**: One row per customer action

**⚠️ NO UNIQUE KEY**: HistoryID is NOT unique

**Partitioning**: `etr_y`, `etr_ym`, `etr_ymd`

**Key Columns**:
| Column | Type | Description |
|--------|------|-------------|
| HistoryID | BIGINT | Action identifier (NOT unique!) |
| GCID | INT | Global Customer ID |
| RealCID | INT | Real account CID |
| ActionTypeID | INT | Type of action (see ActionType reference) |
| Amount | DECIMAL(11,2) | Transaction amount in USD |
| Occurred | TIMESTAMP | When action occurred |
| DateID | INT | Date dimension key (yyyyMMdd) |
| DepositID | INT | Links to fact_billingdeposit |
| WithdrawID | INT | Withdrawal request ID |
| WithdrawPaymentID | INT | WPID/W2FID (links to fact_billingwithdraw) |
| RedeemID | INT | Links to fact_billingredeem |
| IsRedeem | INT | Is crypto withdrawal? (1=Yes, 0=No) |
| IsFTD | INT | Is first-time deposit? (1=Yes, 0=No) |
| PaymentStatusID | INT | Payment status (for deposits) |
| Commission | DECIMAL(19,4) | Commission charged |
| FullCommission | DECIMAL(19,4) | Full commission |
| CompensationReasonID | INT | Reason for compensation (ActionTypeID=36) |
| etr_y | INT | Partition: year |
| etr_ym | INT | Partition: year-month |
| etr_ymd | INT | Partition: year-month-day |

**MIMO ActionTypeIDs** (filter on these):
| ActionTypeID | Name | Use Case |
|--------------|------|----------|
| 7 | Deposit | Regular deposits + inter-platform (FundingType 33/42/44) |
| 8 | Cashout | Regular withdrawals + inter-platform + redeems (IsRedeem=1) |
| 11 | Chargeback | Chargebacks |
| 12 | Refund | Refunds |
| 13 | Refund As ChargeBack | Refunds processed as chargebacks |
| 37 | Reverse cashout | Reversed withdrawals |
| 42 | Cashout Rollback | Withdrawal rollbacks |
| 43 | Reverse Deposit | Reversed deposits |
| 44 | InternalDeposit | Trade from IBAN - opening position |
| 45 | InternalWithdraw | Trade from IBAN - closing position |

**Compensation ActionTypeID** (for affiliate payments):
| ActionTypeID | CompensationReasonID | Use Case |
|--------------|---------------------|----------|
| 36 | 41, 51 | Affiliate payments (subtract from net deposits) |

---

### 2. fact_billingdeposit (METADATA ONLY)
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`

**Purpose**: Deposit metadata (payment methods, statuses, BIN codes)

**⚠️ CRITICAL**: This is a STATE MACHINE of current state - use for metadata ONLY, NOT amounts

**Granularity**: One row per deposit

**Key Columns**:
| Column | Type | Description |
|--------|------|-------------|
| DepositID | INT | Primary key, links to fact_customeraction |
| RealCID | INT | Customer ID |
| FundingTypeID | INT | Payment method (see FundingType reference) |
| DepotID | INT | Payment processor |
| PaymentStatusID | INT | Payment status (2=Approved) |
| RiskManagementStatusID | INT | Risk/fraud status |
| BinCodeAsString | STRING | Card BIN code |
| BinCountryIDAsInteger | INT | Card issuing country |
| CardTypeIDAsInteger | INT | Card type (Visa, Mastercard) |
| IsFTD | INT | Platform-specific FTD flag |
| IsRecurring | INT | Recurring deposit flag |
| BonusAmount | DECIMAL(19,4) | Bonus awarded |
| BonusStatusID | INT | Bonus status |
| Created | TIMESTAMP | When deposit was created |
| Updated | TIMESTAMP | Last update timestamp |

**Inter-Platform FundingTypeIDs** (money stays in eToro):
| FundingTypeID | Platform | Shows as ActionTypeID |
|---------------|----------|----------------------|
| 33 | eToro Money (eMoney/IBAN) | 7 (Deposit) or 8 (Cashout) |
| 42 | eToro Options | 7 (Deposit) or 8 (Cashout) |
| 44 | MoneyFarm | 7 (Deposit) or 8 (Cashout) |

**Key PaymentStatusID**:
| PaymentStatusID | Name | Meaning |
|-----------------|------|---------|
| 2 | Approved | Successful deposit |
| 11 | Chargeback | Customer disputed |
| 12 | Refund | eToro refunded |

---

### 3. fact_billingwithdraw (METADATA ONLY)
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`

**Purpose**: Withdrawal metadata (payment methods, statuses, WPID)

**⚠️ CRITICAL**: This is a STATE MACHINE of current state - use for metadata ONLY, NOT amounts

**Granularity**: One row per withdrawal

**Key Columns**:
| Column | Type | Description |
|--------|------|-------------|
| WithdrawPaymentID | INT | TRUE unique identifier (WPID/W2FID) |
| WithdrawID | INT | Withdrawal request ID |
| RealCID | INT | Customer ID |
| FundingTypeID_Funding | INT | Payment method (see FundingType reference) |
| DepotID | INT | Payment processor |
| CashoutStatusID_Funding | INT | Cashout status (3=Processed) |
| CashoutReasonID | INT | Reason for withdrawal |
| DepositID | INT | Original deposit (for refunds) |
| Created | TIMESTAMP | When withdrawal was created |
| Updated | TIMESTAMP | Last update timestamp |

**Inter-Platform FundingTypeIDs** (money stays in eToro):
| FundingTypeID_Funding | Platform | Shows as ActionTypeID |
|----------------------|----------|----------------------|
| 33 | eToro Money (eMoney/IBAN) | 7 (Deposit) or 8 (Cashout) |
| 42 | eToro Options | 7 (Deposit) or 8 (Cashout) |
| 44 | MoneyFarm | 7 (Deposit) or 8 (Cashout) |

**Key CashoutStatusID**:
| CashoutStatusID | Name | Meaning |
|-----------------|------|---------|
| 3 | Processed | Successful withdrawal |

---

### 4. BI_DB_DepositWithdrawFee (CONVERSION FEES + MID)
**Unity Catalog**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`

**Purpose**: Conversion fees (PIPsCalculation), Trade from IBAN identification, Merchant IDs

**Granularity**: One row per deposit/withdrawal transaction

**Partitioning**: `etr_y`, `etr_ym`, `etr_ymd`

**Key Columns**:
| Column | Type | Description |
|--------|------|-------------|
| DateID | INT | Date in yyyyMMdd format |
| Date | DATE | Transaction date |
| CID | INT | Customer ID |
| DepositWithdrawID | INT | Transaction ID |
| CreditID | BIGINT | Links to history_credit |
| DepositID | INT | Links to fact_billingdeposit |
| WithdrawPaymentID | INT | Links to fact_billingwithdraw (WPID) |
| TransactionType | STRING | "Deposit" or "Withdraw" |
| AmountUSD | DECIMAL(38,8) | Transaction amount in USD |
| PIPsCalculation | DECIMAL(38,8) | **Conversion fee amount** |
| IsIBANTrade | INT | **Is Trade from IBAN?** (1=Yes, 0=No) |
| MID | STRING | **Merchant ID (payment gateway)** - ONLY exists here |
| PaymentMethod | STRING | Payment method name |
| Currency | STRING | Original currency |
| ExchangeRate | DECIMAL(38,8) | Exchange rate applied |
| BaseExchangeRate | DECIMAL(38,8) | Base exchange rate |
| ExchangeFee | DECIMAL(38,8) | Exchange fee |
| etr_y | INT | Partition: year |
| etr_ym | INT | Partition: year-month |
| etr_ymd | INT | Partition: year-month-day |

**Key Insights**:
* **PIPsCalculation** = Actual conversion fee charged (also called PIPsInUSD)
* **IsIBANTrade** = Identifies Trade from IBAN transactions (subset of ActionTypeID 44/45)
* **MID** = Merchant ID from payment gateways - does NOT exist anywhere else in DWH

---

### 5. BI_DB_DepositWithdrawFee_Reversals (REVERSAL TRACKING)
**Unity Catalog**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals`

**Purpose**: Tracks reversals (chargebacks, refunds, reversed deposits) for net deposit calculations

**Granularity**: One row per reversal transaction

**Key Columns**:
| Column | Type | Description |
|--------|------|-------------|
| DateID | INT | Date in yyyyMMdd format |
| Date | DATE | Reversal date |
| CID | INT | Customer ID |
| ReversalID | INT | Reversal transaction ID |
| OriginalDepositWithdrawID | INT | Original transaction ID |
| ReversalType | STRING | Type of reversal |
| AmountUSD | DECIMAL(38,8) | Reversal amount in USD |
| Currency | STRING | Original currency |

**Use For**: Net deposit calculations (Deposits - Cashouts + Net Reversals - Affiliate Payments)

---

### 6. BI_DB_DDR_Fact_MIMO_AllPlatforms (SEMANTIC LAYER)
**Unity Catalog**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`

**Purpose**: Semantic layer with pre-computed business logic and flags

**Granularity**: One row per MIMO transaction

**Partitioning**: `etr_y`, `etr_ym`, `etr_ymd`

**Key Columns**:
| Column | Type | Description |
|--------|------|-------------|
| DateID | INT | Date in yyyyMMdd format |
| Date | DATE | Transaction date |
| RealCID | INT | Customer ID |
| MIMOAction | STRING | "Deposit" or "Withdrawal" |
| OrigIdentifier | STRING | Original transaction ID |
| TransactionID | STRING | Transaction reference |
| AmountUSD | DECIMAL(38,4) | Amount in USD |
| AmountOrigCurrency | DECIMAL(38,4) | Amount in original currency |
| FundingTypeID | INT | Payment method type |
| CurrencyID | INT | Currency ID |
| Currency | STRING | Currency code |
| IsPlatformFTD | BOOLEAN | Platform-specific FTD |
| IsGlobalFTD | BOOLEAN | Global FTD (any platform) |
| IsInternalTransfer | BOOLEAN | **ALL inter-platform transfers (ActionTypeID 7/8 with FundingType 33/42/44)** |
| IsRedeem | BOOLEAN | Crypto withdrawal flag |
| IsTradeFromIBAN | BOOLEAN | **Trade from IBAN flag (ActionTypeID 44/45)** |
| IsCryptoToFiat | BOOLEAN | Crypto to fiat conversion |
| IsRecurring | BOOLEAN | Recurring payment |
| IsIBANQuickTransfer | BOOLEAN | Instant SEPA transfer |
| MIMOPlatform | STRING | Platform name |
| etr_y | INT | Partition: year |
| etr_ym | INT | Partition: year-month |
| etr_ymd | INT | Partition: year-month-day |

**⚠️ CRITICAL DISTINCTION**:
* **IsInternalTransfer** = ALL inter-platform transfers (FundingTypeID 33/42/44 → ActionTypeID 7/8)
* **IsTradeFromIBAN** = ONLY Trade from IBAN (ActionTypeID 44/45 - subset of inter-platform)

---

### 7. dim_customer_masked (GLOBAL FTD)
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

**Purpose**: Customer dimension with Global FTD tracking

**Key FTD Columns**:
| Column | Type | Description |
|--------|------|-------------|
| GCID | INT | Global Customer ID |
| FirstDepositDate | TIMESTAMP | **First deposit across ALL platforms** |
| FirstDepositAmount | DECIMAL(19,4) | Amount of first deposit |
| FTDPlatformID | INT | **Platform where FTD occurred** (see below) |
| FTDTransactionID | STRING | Transaction ID of FTD |
| FTDRecoveryDate | TIMESTAMP | Recovery date (if different) |
| IsValidCustomer | INT | Valid customer flag |

**FTDPlatformID Values**:
| FTDPlatformID | Platform Name |
|---------------|---------------|
| 1 | TradingPlatform |
| 2 | Options |
| 3 | eMoney |
| 4 | MoneyFarm |

**Source**: 
* Lake: `MoneyBusDB_Dictionary_AccountTypes` (AccountType = FTDPlatformID)
* Synapse: `BI_DB_dbo.V_Dim_FTDPlatform` view (NOT in Unity Catalog)

**Global FTD vs Platform-Specific FTD**:
* **Global FTD** = dim_customer_masked.FirstDepositDate (first deposit across ALL platforms)
* **Platform FTD** = fact_billingdeposit.IsFTD (first deposit on specific platform)
* Example: User deposits on eMoney first (Global FTD, FTDPlatformID=3), then Trading (Platform FTD=1 for Trading)

---

### 8. dim_actiontype
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype`

**Purpose**: Action type dimension (45 total action types)

**MIMO-Related ActionTypes**:
| ActionTypeID | Name | Category |
|--------------|------|----------|
| 7 | Deposit | Deposit |
| 8 | Cashout | Cashout |
| 11 | Chargeback | Chargeback |
| 12 | Refund | Refund |
| 13 | Refund As ChargeBack | Refund |
| 37 | Reverse cashout | Reverse cashout |
| 42 | Cashout Rollback | Chargeback |
| 43 | Reverse Deposit | Reverse Deposit |
| 44 | InternalDeposit | Deposit |
| 45 | InternalWithdraw | Withdraw |

---

### 9. dim_fundingtype
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype`

**Purpose**: Payment method dimension

**Inter-Platform FundingTypes** (money stays in eToro):
| FundingTypeID | FundingTypeName | Platform |
|---------------|-----------------|----------|
| 33 | eToro Money | eMoney/IBAN platform |
| 42 | eToro Options | Options platform |
| 44 | MoneyFarm | MoneyFarm platform |

---

### 10. dim_paymentstatus
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus`

**Purpose**: Payment status dimension (40 status codes)

**Key Statuses**:
| PaymentStatusID | Name | Meaning |
|-----------------|------|---------|
| 2 | Approved | Successful deposit |
| 11 | Chargeback | Customer disputed |
| 12 | Refund | eToro refunded |

---

### 11. dim_cashoutstatus
**Unity Catalog**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`

**Purpose**: Cashout status dimension (18 status codes)

**Key Statuses**:
| CashoutStatusID | Name | Meaning |
|-----------------|------|---------|
| 3 | Processed | Successful withdrawal |

---

## 🔑 CRITICAL CONCEPTS

### Inter-Platform MIMO vs Trade from IBAN

**The Hierarchy**:
```
TRADING PLATFORM MIMO
│
├── ActionTypeID 7 (Deposit)
│   ├── External: from banks/cards (FundingTypeID ≠ 33/42/44)
│   └── Inter-Platform: from eToro Money/Options/MoneyFarm (FundingTypeID = 33/42/44)
│
├── ActionTypeID 8 (Cashout)
│   ├── External: to banks/cards (FundingTypeID ≠ 33/42/44, IsRedeem=0)
│   ├── Inter-Platform: to eToro Money/Options/MoneyFarm (FundingTypeID = 33/42/44)
│   └── Crypto Redeems: to external wallets (IsRedeem=1)
│
├── ActionTypeID 44 (InternalDeposit)
│   └── Trade from IBAN - opening position (back rails of trading)
│
├── ActionTypeID 45 (InternalWithdraw)
│   └── Trade from IBAN - closing position (back rails of trading)
│
└── ActionTypeID 11/12/13/37/42/43 (Reversals)
    └── Chargebacks, refunds, reversed deposits/withdrawals
```

**Key Insight**: 
* ActionTypeID 7/8 can be EITHER external OR inter-platform (check FundingTypeID to distinguish)
* ActionTypeID 44/45 are ALWAYS Trade from IBAN (subset of inter-platform)
* To identify inter-platform: FundingTypeID IN (33, 42, 44)

**Trading Platform MIMO (ActionTypeID 7/8)**:
* **ActionTypeID 7 (Deposit)** = Money coming INTO Trading Platform
  * Can be **External**: from banks/cards (FundingTypeID ≠ 33/42/44)
  * Can be **Inter-Platform**: from eToro Money/Options/MoneyFarm (FundingTypeID = 33/42/44)
* **ActionTypeID 8 (Cashout)** = Money going OUT of Trading Platform
  * Can be **External**: to banks/cards (FundingTypeID ≠ 33/42/44, IsRedeem=0)
  * Can be **Inter-Platform**: to eToro Money/Options/MoneyFarm (FundingTypeID = 33/42/44)
  * Can be **Crypto Redeem**: to external wallets (IsRedeem=1)

**Inter-Platform FundingTypeIDs** (money stays within eToro ecosystem):
* **FundingTypeID 33** = eToro Money (eMoney/IBAN platform)
* **FundingTypeID 42** = eToro Options
* **FundingTypeID 44** = MoneyFarm
* When these FundingTypeIDs appear with ActionTypeID 7/8, it's inter-platform MIMO
* No money enters or leaves the eToro ecosystem

**Trade from IBAN (ActionTypeID 44/45)**:
* **ActionTypeID 44 (InternalDeposit)** = MIMO is the "back rails" of opening a trading position
* **ActionTypeID 45 (InternalWithdraw)** = MIMO is the "back rails" of closing a trading position
* **IsIBANTrade=1** (from BI_DB_DepositWithdrawFee) identifies this trading subset
* This is a **subset** of inter-platform MIMO where the transfer supports a trading transaction

**When users ask about "internal transfers"**:
1. **Ask for clarification**: Do they want ALL inter-platform MIMO (FundingTypeID 33/42/44 with ActionTypeID 7/8)?
2. **Or ONLY Trade from IBAN** (ActionTypeID 44/45)?

---

### Net Deposits Formula

```
Net Deposits = Deposits - Cashouts + Net Reversals - Affiliate Payments
```

**Components**:
* **Deposits** = ActionTypeID IN (7, 44)
* **Cashouts** = ActionTypeID IN (8, 45) AND IsRedeem = 0
* **Net Reversals** = From BI_DB_DepositWithdrawFee_Reversals
* **Affiliate Payments** = ActionTypeID = 36 AND CompensationReasonID IN (41, 51)

---

## 📝 QUERY PATTERNS

### 1. Regular Deposits (ActionTypeID = 7)
```sql
SELECT 
  CAST(Occurred AS DATE) as date,
  COUNT(DISTINCT RealCID) as unique_customers,
  COUNT(*) as deposit_count,
  SUM(Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 7  -- Regular deposits
  AND etr_ymd >= '20260201'
GROUP BY CAST(Occurred AS DATE)
ORDER BY date DESC;
```

### 2. Regular Withdrawals (ActionTypeID = 8, IsRedeem = 0)
```sql
SELECT 
  CAST(Occurred AS DATE) as date,
  COUNT(DISTINCT RealCID) as unique_customers,
  COUNT(*) as withdrawal_count,
  SUM(Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 8  -- Cashout
  AND COALESCE(IsRedeem, 0) = 0  -- Exclude crypto withdrawals
  AND etr_ymd >= '20260201'
GROUP BY CAST(Occurred AS DATE)
ORDER BY date DESC;
```

### 3. ALL Inter-Platform MIMO IN (FundingTypeID 33/42/44)
```sql
SELECT 
  CAST(ca.Occurred AS DATE) as date,
  ft.FundingTypeName as source_platform,
  COUNT(DISTINCT ca.RealCID) as unique_customers,
  COUNT(*) as inter_platform_deposit_count,
  SUM(ca.Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit d
  ON ca.DepositID = d.DepositID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft
  ON d.FundingTypeID = ft.FundingTypeID
WHERE ca.ActionTypeID = 7  -- Deposit
  AND d.FundingTypeID IN (33, 42, 44)  -- eToro Money, Options, MoneyFarm
  AND ca.etr_ymd >= '20260201'
GROUP BY CAST(ca.Occurred AS DATE), ft.FundingTypeName
ORDER BY date DESC;
```

### 4. ONLY Trade from IBAN - Open Position (ActionTypeID = 44)
```sql
SELECT 
  CAST(Occurred AS DATE) as date,
  COUNT(DISTINCT RealCID) as unique_customers,
  COUNT(*) as iban_trade_open_count,
  SUM(Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 44  -- InternalDeposit (Trade from IBAN)
  AND etr_ymd >= '20260201'
GROUP BY CAST(Occurred AS DATE)
ORDER BY date DESC;
```

### 5. ALL Inter-Platform MIMO OUT (FundingTypeID 33/42/44)
```sql
SELECT 
  CAST(ca.Occurred AS DATE) as date,
  ft.FundingTypeName as destination_platform,
  COUNT(DISTINCT ca.RealCID) as unique_customers,
  COUNT(*) as inter_platform_withdrawal_count,
  SUM(ca.Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw w
  ON ca.WithdrawPaymentID = w.WithdrawPaymentID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft
  ON w.FundingTypeID_Funding = ft.FundingTypeID
WHERE ca.ActionTypeID = 8  -- Cashout
  AND w.FundingTypeID_Funding IN (33, 42, 44)  -- eToro Money, Options, MoneyFarm
  AND COALESCE(ca.IsRedeem, 0) = 0  -- Exclude crypto withdrawals
  AND ca.etr_ymd >= '20260201'
GROUP BY CAST(ca.Occurred AS DATE), ft.FundingTypeName
ORDER BY date DESC;
```

### 6. ONLY Trade from IBAN - Close to IBAN (ActionTypeID = 45)
```sql
SELECT 
  CAST(Occurred AS DATE) as date,
  COUNT(DISTINCT RealCID) as unique_customers,
  COUNT(*) as iban_trade_close_count,
  SUM(Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 45  -- InternalWithdraw (Trade from IBAN)
  AND etr_ymd >= '20260201'
GROUP BY CAST(Occurred AS DATE)
ORDER BY date DESC;
```

### 7. Crypto Withdrawals / Redeems (ActionTypeID = 8, IsRedeem = 1)
```sql
SELECT 
  CAST(Occurred AS DATE) as date,
  COUNT(DISTINCT RealCID) as unique_customers,
  COUNT(*) as redeem_count,
  SUM(Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 8  -- Cashout
  AND IsRedeem = 1  -- Crypto withdrawal
  AND etr_ymd >= '20260201'
GROUP BY CAST(Occurred AS DATE)
ORDER BY date DESC;
```

### 8. Chargebacks and Refunds (ActionTypeID 11, 12, 13, 43)
```sql
SELECT 
  CAST(ca.Occurred AS DATE) as date,
  ca.ActionTypeID,
  at.Name as action_name,
  COUNT(*) as reversal_count,
  SUM(ca.Amount) as total_amount_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype at
  ON ca.ActionTypeID = at.ActionTypeID
WHERE ca.ActionTypeID IN (11, 12, 13, 43)  -- Chargeback, Refund, Refund As ChargeBack, Reverse Deposit
  AND ca.etr_ymd >= '20260201'
GROUP BY CAST(ca.Occurred AS DATE), ca.ActionTypeID, at.Name
ORDER BY date DESC, ca.ActionTypeID;
```

### 9. Affiliate Payments (for Net Deposit Calculation)
```sql
SELECT 
  CAST(Occurred AS DATE) as date,
  COUNT(*) as affiliate_payment_count,
  SUM(Amount) as total_affiliate_payments_usd
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 36  -- Compensation
  AND CompensationReasonID IN (41, 51)  -- Affiliate payment reasons
  AND etr_ymd >= '20260201'
GROUP BY CAST(Occurred AS DATE)
ORDER BY date DESC;
```

### 10. Net Deposits Calculation (Complete Formula)
```sql
WITH deposits AS (
  SELECT 
    CAST(Occurred AS DATE) as date,
    SUM(Amount) as deposit_amount
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  WHERE ActionTypeID IN (7, 44)  -- Regular + Inter-platform deposits
    AND etr_ymd >= '20260201'
  GROUP BY CAST(Occurred AS DATE)
),
cashouts AS (
  SELECT 
    CAST(Occurred AS DATE) as date,
    SUM(Amount) as cashout_amount
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  WHERE ActionTypeID IN (8, 45)  -- Regular + Inter-platform withdrawals
    AND COALESCE(IsRedeem, 0) = 0  -- Exclude redeems
    AND etr_ymd >= '20260201'
  GROUP BY CAST(Occurred AS DATE)
),
reversals AS (
  SELECT 
    Date,
    SUM(AmountUSD) as net_reversal_amount
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
  WHERE etr_ymd >= '20260201'
  GROUP BY Date
),
affiliate_payments AS (
  SELECT 
    CAST(Occurred AS DATE) as date,
    SUM(Amount) as affiliate_amount
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  WHERE ActionTypeID = 36  -- Compensation
    AND CompensationReasonID IN (41, 51)  -- Affiliate payment reasons
    AND etr_ymd >= '20260201'
  GROUP BY CAST(Occurred AS DATE)
)
SELECT 
  COALESCE(d.date, c.date, r.Date, a.date) as date,
  COALESCE(d.deposit_amount, 0) as deposits,
  COALESCE(c.cashout_amount, 0) as cashouts,
  COALESCE(r.net_reversal_amount, 0) as net_reversals,
  COALESCE(a.affiliate_amount, 0) as affiliate_payments,
  COALESCE(d.deposit_amount, 0) 
    - COALESCE(c.cashout_amount, 0) 
    + COALESCE(r.net_reversal_amount, 0) 
    - COALESCE(a.affiliate_amount, 0) as net_deposits
FROM deposits d
FULL OUTER JOIN cashouts c ON d.date = c.date
FULL OUTER JOIN reversals r ON COALESCE(d.date, c.date) = r.Date
FULL OUTER JOIN affiliate_payments a ON COALESCE(d.date, c.date) = a.date
ORDER BY date DESC;
```

### 11. Conversion Fees Analysis (PIPsCalculation)
```sql
SELECT 
  Date,
  TransactionType,
  COUNT(*) as transaction_count,
  SUM(AmountUSD) as total_amount_usd,
  SUM(PIPsCalculation) as total_conversion_fees,
  AVG(PIPsCalculation) as avg_conversion_fee,
  SUM(PIPsCalculation) / NULLIF(SUM(AmountUSD), 0) * 100 as fee_percentage
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
WHERE etr_ymd >= '20260201'
  AND PIPsCalculation > 0
GROUP BY Date, TransactionType
ORDER BY Date DESC;
```

### 12. Merchant ID (MID) Analysis
```sql
SELECT 
  MID as merchant_id,
  PaymentMethod,
  COUNT(*) as transaction_count,
  SUM(AmountUSD) as total_amount_usd,
  SUM(PIPsCalculation) as total_conversion_fees
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
WHERE etr_ymd >= '20260201'
  AND MID IS NOT NULL
GROUP BY MID, PaymentMethod
ORDER BY transaction_count DESC;
```

### 13. MIMO with Metadata Enrichment
```sql
SELECT 
  CAST(ca.Occurred AS DATE) as date,
  ft.FundingTypeName as payment_method,
  COUNT(DISTINCT ca.RealCID) as unique_customers,
  COUNT(*) as deposit_count,
  SUM(ca.Amount) as total_amount_usd,  -- From fact_customeraction
  SUM(CASE WHEN d.IsFTD = 1 THEN 1 ELSE 0 END) as ftd_count,
  SUM(d.BonusAmount) as total_bonus
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit d
  ON ca.DepositID = d.DepositID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft
  ON d.FundingTypeID = ft.FundingTypeID
WHERE ca.ActionTypeID = 7  -- Regular deposits
  AND d.PaymentStatusID = 2  -- Approved
  AND ca.etr_ymd >= '20260201'
GROUP BY CAST(ca.Occurred AS DATE), ft.FundingTypeName
ORDER BY date DESC, deposit_count DESC;
```

### 14. Global FTD by Platform
```sql
SELECT 
  c.FTDPlatformID,
  CASE 
    WHEN c.FTDPlatformID = 1 THEN 'TradingPlatform'
    WHEN c.FTDPlatformID = 2 THEN 'Options'
    WHEN c.FTDPlatformID = 3 THEN 'eMoney'
    WHEN c.FTDPlatformID = 4 THEN 'MoneyFarm'
    ELSE 'NA'
  END as platform_name,
  CAST(c.FirstDepositDate AS DATE) as ftd_date,
  COUNT(*) as ftd_count,
  SUM(c.FirstDepositAmount) as total_ftd_amount
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
WHERE c.FirstDepositDate >= '2026-02-01'
  AND c.FirstDepositDate < '2026-03-01'
  AND c.IsValidCustomer = 1
GROUP BY c.FTDPlatformID, 
  CASE 
    WHEN c.FTDPlatformID = 1 THEN 'TradingPlatform'
    WHEN c.FTDPlatformID = 2 THEN 'Options'
    WHEN c.FTDPlatformID = 3 THEN 'eMoney'
    WHEN c.FTDPlatformID = 4 THEN 'MoneyFarm'
    ELSE 'NA'
  END,
  CAST(c.FirstDepositDate AS DATE)
ORDER BY ftd_date DESC;
```

### 15. Complete MIMO Breakdown by Type
```sql
SELECT 
  CAST(ca.Occurred AS DATE) as date,
  at.Name as transaction_type,
  CASE 
    WHEN ca.ActionTypeID IN (7, 44) THEN 'Deposit'
    WHEN ca.ActionTypeID IN (8, 45) THEN 'Withdrawal'
    ELSE 'Reversal'
  END as mimo_category,
  COUNT(DISTINCT ca.RealCID) as unique_customers,
  COUNT(*) as transaction_count,
  SUM(ca.Amount) as total_amount_usd,
  SUM(COALESCE(dwf.PIPsCalculation, 0)) as total_conversion_fees
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype at
  ON ca.ActionTypeID = at.ActionTypeID
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee dwf
  ON ca.DepositID = dwf.DepositID 
  OR ca.WithdrawPaymentID = dwf.WithdrawPaymentID
WHERE ca.ActionTypeID IN (7, 8, 11, 12, 13, 37, 42, 43, 44, 45)
  AND ca.etr_ymd >= '20260201'
GROUP BY CAST(ca.Occurred AS DATE), at.Name, 
  CASE 
    WHEN ca.ActionTypeID IN (7, 44) THEN 'Deposit'
    WHEN ca.ActionTypeID IN (8, 45) THEN 'Withdrawal'
    ELSE 'Reversal'
  END
ORDER BY date DESC, transaction_count DESC;
```

---

## 🎓 KEY TAKEAWAYS

### The Correct MIMO Approach
1. ✅ **fact_customeraction** = PRIMARY source for transaction amounts
2. ✅ **fact_billingdeposit/withdraw** = METADATA only (state machine of current state)
3. ✅ **BI_DB_DepositWithdrawFee** = Conversion fees (PIPsCalculation) + Merchant IDs (MID)
4. ✅ **BI_DB_DepositWithdrawFee_Reversals** = Reversal tracking for net deposits
5. ✅ **BI_DB_DDR_Fact_MIMO_AllPlatforms** = Semantic layer with business flags
6. ✅ **Filter by ActionTypeID** to identify MIMO vs non-MIMO transactions
7. ✅ **No unique key** in fact_customeraction - HistoryID is NOT unique

### Critical ActionTypeIDs
* **7** = Regular deposits (+ inter-platform via FundingTypeID 33/42/44)
* **8** = Regular withdrawals (+ inter-platform via FundingTypeID 33/42/44, + redeems when IsRedeem=1)
* **44** = Trade from IBAN - opening position (back rails of trading)
* **45** = Trade from IBAN - closing position (back rails of trading)
* **11, 12, 13, 43** = Chargebacks, refunds, reversed deposits
* **36** = Compensation (CompensationReasonID 41, 51 = affiliate payments)

### Inter-Platform MIMO vs Trade from IBAN
* **Inter-Platform MIMO** = FundingTypeID 33/42/44 → ActionTypeID 7/8 (money stays in eToro)
* **Trade from IBAN** = ActionTypeID 44/45 (subset where MIMO is back rails of trading)
* **Always clarify** which the user needs when they ask about "internal transfers"

### Net Deposits Formula
```
Net Deposits = Deposits - Cashouts + Net Reversals - Affiliate Payments
```
Where:
* **Deposits** = ActionTypeID IN (7, 44)
* **Cashouts** = ActionTypeID IN (8, 45) AND IsRedeem = 0
* **Net Reversals** = From BI_DB_DepositWithdrawFee_Reversals
* **Affiliate Payments** = ActionTypeID = 36 AND CompensationReasonID IN (41, 51)

### FTD Platform Dictionary
| FTDPlatformID | Platform Name |
|---------------|---------------|
| 1 | TradingPlatform |
| 2 | Options |
| 3 | eMoney |
| 4 | MoneyFarm |

---

## 🚨 COMMON GOTCHAS

### 1. No Unique Key in fact_customeraction
* HistoryID is NOT unique
* Always use appropriate GROUP BY or DISTINCT when needed

### 2. State Machine Tables
* fact_billingdeposit and fact_billingwithdraw are state machines
* They track current state, not historical amounts
* Use fact_customeraction for amounts

### 3. Partition Filters
* Always use `etr_ymd >= 'YYYYMMDD'` format for partition pruning
* Example: `etr_ymd >= '20260201'` (not `etr_ymd >= '2026-02-01'`)

### 4. IsRedeem Flag
* ActionTypeID 8 includes both regular withdrawals AND crypto redeems
* Always filter `COALESCE(IsRedeem, 0) = 0` to exclude redeems
* Or filter `IsRedeem = 1` to get ONLY redeems

### 5. Inter-Platform Transfers Confusion
* Users may say "internal transfers" meaning different things
* Always clarify: ALL inter-platform (FundingType 33/42/44) OR ONLY Trade from IBAN (ActionType 44/45)?

### 6. MID Only Exists in BI_DB_DepositWithdrawFee
* Merchant ID (MID) does NOT exist in fact_billingdeposit or fact_billingwithdraw
* Must use BI_DB_DepositWithdrawFee for payment gateway analysis

### 7. Global FTD vs Platform FTD
* dim_customer_masked.FirstDepositDate = Global FTD (first deposit across ALL platforms)
* fact_billingdeposit.IsFTD = Platform-specific FTD (first deposit on that platform)
* A user can have Platform FTD=1 on Trading but Global FTD on eMoney (FTDPlatformID=3)
