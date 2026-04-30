# BackOffice.GetUserAdditionalDetails

> Returns supplemental financial and identity details for a single customer - credit card count, pending/net withdrawal amounts, last login country, phone country, and AML comment - used to enrich Back Office customer views.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (required); returns single-row Customer.Customer enrichment with calculated cashout metrics |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetUserAdditionalDetails` provides additional customer details not typically available in the main customer profile views. It calculates the customer's pending withdrawal amount (total requested but not yet processed), net cashout amount (actually completed cashouts), number of unique non-expired credit cards, last login country via IP geolocation, and phone country from phone prefix lookup. It also surfaces the customer's AML comment and risk classification from the BackOffice profile.

The procedure returns a single row (TOP 1 with WHERE cc.CID = @CID). The calculated metrics use multiple subqueries against Billing.Withdraw, Billing.WithdrawToFunding, and Billing.Deposit/Funding to derive cashout-related financial exposures.

---

## 2. Business Logic

### 2.1 Pending Withdrawal Calculation

**What**: Calculates the amount the customer has requested to withdraw but has not yet received.

**Columns/Parameters Involved**: `PendingWithdraw`, `OriginalCORequestsAfterFees`, `NetCashouts`

**Rules**:
- `OriginalCORequestsAfterFees` = SUM(Billing.Withdraw.Amount) WHERE CID=@CID AND CashoutStatusID <> 4 (excludes rejected/cancelled status 4)
- `NetCashouts` = SUM(Billing.WithdrawToFunding.Amount) WHERE CID=@CID AND CashoutStatusID=3 (completed/processed)
- `PendingWithdraw = ABS(OriginalCORequestsAfterFees) - ABS(NetCashouts)` (both cast to DECIMAL(16,2))
- Positive PendingWithdraw = amount in the pipeline waiting to be paid out
- TotalWithdraw = `ABS(NetCashouts)` - the amount already successfully processed

### 2.2 Active Credit Card Count

**What**: Counts the number of unique non-expired credit cards the customer has used for deposits.

**Columns/Parameters Involved**: `CreditCardsCount.creditCardsCount`, `dbo.SecuredCardData()`, `CTE.FundingTypeID=1`, `CTE.ExpireDate`

**Rules**:
- CTE pre-computes per-FundingID: `dbo.SecuredCardData(FundingData)` (PCI-safe card fingerprint) and `dbo.CardExpiredDate(FundingData)` (expiry date)
- Subquery: JOIN Billing.Deposit ON FundingID WHERE CID=@CID AND FundingTypeID=1 (credit card) AND PaymentStatusID <> 2 (not rejected/declined) AND ExpireDate > GETUTCDATE()
- COUNT(DISTINCT SecureData) = unique non-expired card count
- `dbo.SecuredCardData` returns a masked/hashed card identifier (PCI-safe, not the actual card number)

### 2.3 Last Login Country

**What**: Determines the country from which the customer last logged in, based on IP address.

**Columns/Parameters Involved**: `LastLoginCountryId`, `Internal.GetCountryIDByIP()`, `AggrData.LastClientIp`

**Rules**:
- Calls `Internal.GetCountryIDByIP(AggrData.LastClientIp)` scalar function
- `AggrData.LastClientIp` comes from `BackOffice.CustomerAllTimeAggregatedData.LastClientIp`
- Returns a CountryID (integer), not a country name - caller must join Dictionary.Country for display

### 2.4 Phone Country

**What**: Determines the country from the customer's phone prefix.

**Columns/Parameters Involved**: `PhoneCountry.CountryID`, `Dictionary.Country.PhonePrefix`, `Customer.Customer.PhonePrefix`

**Rules**:
- LEFT JOIN Dictionary.Country ON PhonePrefix = cc.PhonePrefix
- Returns CountryID - the country associated with the customer's phone prefix
- May be NULL if the phone prefix doesn't match any country in Dictionary.Country

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve additional details for. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Comments | NVARCHAR | YES | - | CODE-BACKED | Customer account-level comment field (Customer.Customer.Comments). Free-text note by BO agents. |
| 2 | AMLComment | NVARCHAR | YES | - | CODE-BACKED | Anti-money-laundering specific comment (BackOffice.Customer.AMLComment). Used by compliance team to note AML investigation findings. |
| 3 | LastLoginCountryId | INT | YES | - | CODE-BACKED | CountryID of customer's last login location, resolved from LastClientIp via Internal.GetCountryIDByIP(). Integer ID - join Dictionary.Country for name. |
| 4 | PhoneCountry | INT | YES | - | CODE-BACKED | CountryID matching the customer's phone prefix (Dictionary.Country.CountryID via PhonePrefix match). NULL if prefix not in dictionary. |
| 5 | TotalDeposit | MONEY | YES | - | CODE-BACKED | Customer's all-time cumulative deposit amount (BackOffice.CustomerAllTimeAggregatedData.TotalDeposit). |
| 6 | RiskClassificationID | INT | YES | - | CODE-BACKED | Numeric risk classification assigned to the customer (BackOffice.Customer.RiskClassificationID). Raw ID - lookup table not joined. |
| 7 | creditCardsCount | INT | YES | - | CODE-BACKED | Count of unique non-expired credit cards used by this customer for deposits. Derived from Billing.Funding via dbo.SecuredCardData fingerprint (PCI-safe). |
| 8 | TotalWithdraw | DECIMAL(16,2) | NO | - | CODE-BACKED | Total amount the customer has successfully withdrawn (ABS of SUM(WithdrawToFunding.Amount) WHERE CashoutStatusID=3). 0 if no completed cashouts. |
| 9 | PendingWithdraw | DECIMAL(16,2) | NO | - | CODE-BACKED | Amount the customer has requested to withdraw but not yet received: OriginalCORequestsAfterFees - NetCashouts. 0 if no pending amounts. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cc.CID = @CID | Customer.Customer | Read (primary) | Core customer record |
| bc.CID | BackOffice.Customer | LEFT JOIN | AML comment, risk classification |
| AggrData.CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN | TotalDeposit, LastClientIp |
| cc.PhonePrefix | Dictionary.Country | LEFT JOIN | Phone country ID |
| BWDR.CID = @CID | Billing.Withdraw | Subquery | Cashout request amounts |
| BWTF.WithdrawID | Billing.WithdrawToFunding | Subquery JOIN | Completed cashout amounts |
| d.CID = @CID | Billing.Deposit | Subquery JOIN | Deposit records for card count |
| f.FundingID | Billing.Funding | CTE | Card expiry + secured data |
| AggrData.LastClientIp | Internal.GetCountryIDByIP | Scalar function | IP -> CountryID |
| f.FundingData | dbo.SecuredCardData | Scalar function | PCI-safe card fingerprint |
| f.FundingData | dbo.CardExpiredDate | Scalar function | Card expiry date |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO customer detail screen) | @CID | Application | Supplemental data panel in BO customer view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUserAdditionalDetails (procedure)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── Dictionary.Country (table) - phone prefix
├── Billing.Withdraw (table - 2 subqueries)
├── Billing.WithdrawToFunding (table - subquery)
├── Billing.Deposit (table - subquery)
├── Billing.Funding (table - CTE)
├── Internal.GetCountryIDByIP (scalar function)
├── dbo.SecuredCardData (scalar function)
└── dbo.CardExpiredDate (scalar function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Primary customer record |
| BackOffice.Customer | Table | AML comment, risk classification |
| BackOffice.CustomerAllTimeAggregatedData | Table | TotalDeposit, LastClientIp |
| Dictionary.Country | Table | Phone prefix -> CountryID |
| Billing.Withdraw | Table | Two subqueries: original request amount and (via WithdrawToFunding) net cashout |
| Billing.WithdrawToFunding | Table | Net cashout amount subquery |
| Billing.Deposit | Table | Credit card deposit history |
| Billing.Funding | Table | FundingData for card secured data + expiry |
| Internal.GetCountryIDByIP | Scalar Function | IP address -> CountryID |
| dbo.SecuredCardData | Scalar Function | PCI-safe card fingerprint from FundingData XML |
| dbo.CardExpiredDate | Scalar Function | Card expiry date from FundingData XML |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO customer detail screens. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1 | Implementation | SELECT TOP 1 with WHERE cc.CID = @CID - CID is a PK so always 0 or 1 rows; TOP 1 is defensive |
| CashoutStatusID <> 4 for requests | Logic | Excludes status=4 (rejected/cancelled) from OriginalCORequestsAfterFees - only counts active or pending cashout requests |
| CashoutStatusID = 3 for net | Logic | Only CashoutStatusID=3 (processed/completed) is counted as a completed cashout in NetCashouts |
| PCI-safe card counting | Security | dbo.SecuredCardData returns a masked fingerprint (not raw card numbers) to safely COUNT(DISTINCT) unique cards |

---

## 8. Sample Queries

### 8.1 Get additional details for a customer
```sql
EXEC [BackOffice].[GetUserAdditionalDetails] @CID = 123456
```

### 8.2 Direct pending withdrawal query
```sql
SELECT
    SUM(CASE WHEN CashoutStatusID <> 4 THEN Amount ELSE 0 END) AS TotalRequested,
    (SELECT SUM(BWTF.Amount) FROM Billing.WithdrawToFunding BWTF WITH (NOLOCK)
     JOIN Billing.Withdraw BW WITH (NOLOCK) ON BWTF.WithdrawID = BW.WithdrawID
     WHERE BW.CID = 123456 AND BWTF.CashoutStatusID = 3) AS NetCashouts
FROM Billing.Withdraw WITH (NOLOCK)
WHERE CID = 123456
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUserAdditionalDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetUserAdditionalDetails.sql*
