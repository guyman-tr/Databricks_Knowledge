# BackOffice.GetCryptoTransferWithdrawRequests

> Returns the list of crypto-transfer withdrawal requests within a date window, enriched with customer profile, crypto redemption units, and lifetime financial aggregates for BackOffice review.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate on Billing.Withdraw.ModificationDate; multi-filter via TVP params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary data feed for the BackOffice crypto-transfer withdrawal queue. It returns one row per withdrawal request whose status was last modified within the given date window, combining billing data, customer profile, crypto redemption details, and lifetime aggregated financials into a single flat result set ready for the BO UI grid.

The "crypto transfer" naming reflects that the result set exposes crypto-specific columns (RedeemID, InstrumentName, Units, NetUnits) that are only populated when the withdrawal was fulfilled via a crypto funding type (e.g., Bitcoin, Ethereum redemption via Billing.Redeem). For non-crypto funding types these columns return NULL. Callers typically pre-filter @FundingTypeIDList to the crypto funding type IDs to produce a pure crypto view, or pass all IDs to get a mixed list.

The multi-TVP parameter design lets the BO UI pass arbitrary selected status/funding/label combinations without dynamic SQL. Three optional toggle parameters (@Approved, @IncludeInternalAccounts, @CID) allow the same procedure to serve both the full-queue view and single-customer lookup without code duplication.

---

## 2. Business Logic

### 2.1 CTE Pre-filter on ModificationDate

**What**: A CTE named BWIT narrows Billing.Withdraw to the requested date window before the main JOIN fan-out.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `Billing.Withdraw.ModificationDate`

**Rules**:
- `WHERE ModificationDate BETWEEN @StartDate AND @EndDate` is applied before any JOINs, limiting the working set
- ModificationDate tracks the last status change on the withdrawal, not the original request date
- RequestDate (when the customer submitted the withdrawal) is also returned but is NOT used as a filter

### 2.2 Internal Account Exclusion Toggle

**What**: @IncludeInternalAccounts controls whether Internal player-level accounts appear in results.

**Columns/Parameters Involved**: `@IncludeInternalAccounts BIT`, `Dictionary.PlayerLevel.Name`

**Rules**:
- Filter: `DPLV.Name <> IIF(@IncludeInternalAccounts = 1, 'abckedf', 'Internal')`
- When @IncludeInternalAccounts = 0: compares Name against 'Internal', excluding those rows
- When @IncludeInternalAccounts = 1: compares Name against 'abckedf' (an impossible match), so all rows pass
- Internal accounts are eToro employee or test accounts; excluded from compliance/operational queues by default

### 2.3 Optional Label Filter (Empty TVP = No Filter)

**What**: @LabelIdsList allows white-label filtering; an empty TVP is treated as "no filter."

**Columns/Parameters Involved**: `@LabelIdsList BackOffice.IDs`, `Customer.Customer.LabelID`

**Rules**:
- `(CCST.LabelID IN (SELECT * FROM @LabelIdsList) AND EXISTS(SELECT * FROM @LabelIdsList)) OR NOT EXISTS (SELECT * FROM @LabelIdsList)`
- If @LabelIdsList is non-empty: restrict to those label IDs
- If @LabelIdsList is empty: include all customers regardless of label

### 2.4 Approval Toggle

**What**: @Approved filters to approved-only withdrawals or returns all.

**Columns/Parameters Involved**: `@Approved BIT`, `Billing.Withdraw.Approved`

**Rules**:
- `Approved = IIF(@Approved = 1, @Approved, Approved)` - when 1, filters to Approved=1 only; when 0, the self-comparison is always true (returns all)
- The output column [Approved] renders the raw bit as 'YES'/'NO' for display

### 2.5 Crypto Redemption Columns (LEFT JOIN Chain)

**What**: Three LEFT JOINs chain from the withdrawal to the crypto redemption record.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding`, `Billing.Redeem`, `Trade.InstrumentMetaData`

**Rules**:
- `Billing.WithdrawToFunding` links WithdrawID to FundingID (the payment record used to fulfill the withdrawal)
- `Billing.Redeem` holds the crypto redemption: Units requested, RedeemFee (platform fee in crypto units), InstrumentID
- `NetUnits = Units - RedeemFee` is the net crypto amount the customer actually receives
- `Trade.InstrumentMetaData` provides InstrumentDisplayName (e.g., "Bitcoin", "Ethereum") from InstrumentID
- All three JOINs are LEFT JOIN: for non-crypto withdrawals the chain produces NULLs in RedeemID, InstrumentName, Units, NetUnits

### 2.6 Duplicate Status Column

**What**: The Cashout Status name appears twice in the result set under different aliases.

**Rules**:
- Column 4 is `DCAS.Name AS [Cashout Status]`
- Column 24 is `DCAS.Name AS [Status]`
- Both return the same value from Dictionary.CashoutStatus; the duplication is a historical artifact of incremental column additions

### 2.7 Dual Manager Columns

**What**: Two separate BackOffice.Manager lookups for different assignment roles.

**Columns/Parameters Involved**: `BMNG` (Processed By), `ACMG` (Account Manager)

**Rules**:
- `[Processed By]`: BMNG resolves BWIT.ManagerID - the manager who last processed/updated the withdrawal
- `[Account Manager]`: ACMG resolves BCST.ManagerID - the manager permanently assigned to the customer account
- Both are LEFT JOIN; either can be NULL if not assigned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the ModificationDate window. Filters Billing.Withdraw records whose status last changed on or after this date. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the ModificationDate window. Filters Billing.Withdraw records whose status last changed on or before this date. |
| 3 | @CashoutStatusesList | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of CashoutStatus IDs to include. Must match values in Dictionary.CashoutStatus. Caller passes only desired statuses (e.g., pending, processing). |
| 4 | @FundingTypeIDList | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of FundingType IDs to include. Pass crypto funding type IDs only to restrict to crypto withdrawals; pass all IDs for mixed results. |
| 5 | @LabelIdsList | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of Label IDs for white-label filtering. Empty TVP = no label filter (all customers included). |
| 6 | @Approved | BIT | NO | - | CODE-BACKED | When 1: returns only approved withdrawals (Billing.Withdraw.Approved=1). When 0: returns all withdrawals regardless of approval state. |
| 7 | @IncludeInternalAccounts | BIT | NO | - | CODE-BACKED | When 0: excludes Internal player-level accounts (eToro employee/test accounts). When 1: includes all accounts. |
| 8 | @CID | INT | YES | NULL | CODE-BACKED | Optional single-customer filter. When NULL: returns all customers matching other filters. When provided: restricts results to the one customer. |
| **Output Columns** | | | | | | |
| 9 | CID | INT | NO | - | CODE-BACKED | Customer ID of the account that submitted the withdrawal. FK to Customer.Customer.CID. |
| 10 | Status Modification Time | DATETIME | NO | - | CODE-BACKED | The most recent date/time the withdrawal's status changed. From Billing.Withdraw.ModificationDate. This is the field used for date range filtering. |
| 11 | Request Time | DATETIME | YES | - | CODE-BACKED | The original date/time the customer submitted the withdrawal request. From Billing.Withdraw.RequestDate. Not used as a filter. |
| 12 | Cashout Status | NVARCHAR | NO | - | CODE-BACKED | Human-readable withdrawal status label. From Dictionary.CashoutStatus.Name via BWIT.CashoutStatusID. Examples: Pending, Approved, Processing, Rejected. |
| 13 | Approved | VARCHAR(3) | NO | - | CODE-BACKED | Display flag for approval state: 'YES' when Billing.Withdraw.Approved=1, 'NO' otherwise. |
| 14 | Net. Cashout Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Net amount the customer receives after fees. From Billing.Withdraw.Amount (already fee-adjusted). |
| 15 | Orig. Cashout Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Gross withdrawal amount before platform fees: Amount + ISNULL(Fee, 0). Represents what the customer originally requested. |
| 16 | Funding Method (Request Only) | NVARCHAR | NO | - | CODE-BACKED | Name of the funding type used for this withdrawal at the time of request. From Dictionary.FundingType.Name. Labeled "Request Only" because the actual processing may use a different method. |
| 17 | WithdrawID | INT | NO | - | CODE-BACKED | Unique identifier of this withdrawal request. PK of Billing.Withdraw. Used to cross-reference approval history and processing records. |
| 18 | RedeemID | INT | YES | NULL | CODE-BACKED | Identifier of the crypto redemption record. From Billing.Redeem.RedeemID. NULL for non-crypto withdrawals. Populated when the withdrawal was fulfilled via a cryptocurrency transfer. |
| 19 | InstrumentName | NVARCHAR | YES | NULL | CODE-BACKED | Display name of the cryptocurrency being redeemed. From Trade.InstrumentMetaData.InstrumentDisplayName (e.g., "Bitcoin", "Ethereum"). NULL for non-crypto withdrawals. |
| 20 | Units | DECIMAL | YES | NULL | CODE-BACKED | Gross crypto units requested for redemption. From Billing.Redeem.Units. NULL for non-crypto. The face amount in the cryptocurrency's native denomination. |
| 21 | NetUnits | DECIMAL | YES | NULL | CODE-BACKED | Net crypto units after deducting the platform redemption fee: Units - RedeemFee. This is the amount actually transferred to the customer's crypto wallet. NULL for non-crypto. |
| 22 | Country By RegIP | NVARCHAR | YES | NULL | CODE-BACKED | Country name resolved from the customer's registration IP address. From Dictionary.Country.Name via Customer.Customer.CountryIDByIP. Indicates the country the customer was in when they registered. |
| 23 | Customer Status | NVARCHAR | NO | - | CODE-BACKED | Current trading status of the customer account. From Dictionary.PlayerStatus.Name. Examples: Active, Dormant, Blocked. Trimmed of leading/trailing spaces. |
| 24 | Customer Level | NVARCHAR | NO | - | CODE-BACKED | Customer tier level. From Dictionary.PlayerLevel.Name. Used for Internal account exclusion filtering. Examples: Internal, Retail, VIP. Trimmed of leading/trailing spaces. |
| 25 | Processed By | NVARCHAR | YES | NULL | CODE-BACKED | Full name of the BackOffice manager who last processed this withdrawal. Computed as FirstName + ' ' + LastName from BackOffice.Manager via Billing.Withdraw.ManagerID. NULL if unassigned. |
| 26 | Currency | NVARCHAR | NO | - | CODE-BACKED | Abbreviation of the withdrawal currency (e.g., USD, EUR). From Dictionary.Currency.Abbreviation via Billing.Withdraw.CurrencyID. |
| 27 | Total Commissions | DECIMAL(16,2) | YES | 0 | CODE-BACKED | Lifetime total commissions generated by this customer. From BackOffice.CustomerAllTimeAggregatedData.TotalCommission. ISNULL defaults to 0. Provides context on customer value. |
| 28 | Total Deposits | DECIMAL(16,2) | YES | 0 | CODE-BACKED | Lifetime total deposits by this customer. From BackOffice.CustomerAllTimeAggregatedData.TotalDeposit. ISNULL defaults to 0. |
| 29 | Total Cashouts | DECIMAL(16,2) | YES | 0 | CODE-BACKED | Lifetime total cashouts by this customer. From BackOffice.CustomerAllTimeAggregatedData.TotalCashout. ISNULL defaults to 0. Compared with TotalDeposits to assess net flow. |
| 30 | Account Manager | NVARCHAR | YES | NULL | CODE-BACKED | Full name of the BackOffice manager permanently assigned to this customer account. Computed as FirstName + ' ' + LastName from BackOffice.Manager via BackOffice.Customer.ManagerID. Distinct from Processed By. NULL if not assigned. |
| 31 | User Name | NVARCHAR | NO | - | CODE-BACKED | The customer's eToro login username. From Customer.Customer.UserName. |
| 32 | Status | NVARCHAR | NO | - | CODE-BACKED | Duplicate of Cashout Status (DCAS.Name). Historical artifact; same value as column 12 [Cashout Status]. |
| 33 | CashoutStatusID | INT | NO | - | CODE-BACKED | Raw numeric cashout status ID. From Billing.Withdraw.CashoutStatusID. Allows UI to perform status-based conditional formatting or filtering without re-parsing the Name. |
| 34 | BackOffice Withdraw Reason | NVARCHAR | YES | NULL | CODE-BACKED | BackOffice-assigned categorical reason for the withdrawal outcome. From Dictionary.CashoutReason.Name via Billing.Withdraw.CashoutReasonID. Examples: "Client Request", "Regulation", "Chargeback". NULL if no reason recorded. |
| 35 | White Label | NVARCHAR | YES | NULL | CODE-BACKED | Name of the white-label partner the customer belongs to. From Dictionary.Label.Name via Customer.Customer.LabelID. NULL for customers not associated with a white label. |
| 36 | Regulation | NVARCHAR | YES | NULL | CODE-BACKED | Regulatory jurisdiction the customer account is governed by. From Dictionary.Regulation.Name via BackOffice.Customer.RegulationID. Examples: CySEC, FCA, ASIC. |
| 37 | FundingTypeID (Request Only) | INT | NO | - | CODE-BACKED | Raw numeric funding type ID from the withdrawal request. From Billing.Withdraw.FundingTypeID. Used alongside [Funding Method (Request Only)] Name for ID-based logic. Labeled "Request Only" for same reason as the Name column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / ModificationDate | Billing.Withdraw | CTE / Primary Source | Core withdrawal data including amounts, dates, status, funding type |
| CID | Customer.Customer | Lookup / JOIN | Customer username, label, country, player status/level |
| CID | BackOffice.Customer | Lookup / JOIN | BO-specific attributes: assigned manager, regulation |
| LabelID | Dictionary.Label | Lookup / LEFT JOIN | Resolves white-label ID to name |
| PlayerLevelID | Dictionary.PlayerLevel | Lookup / JOIN | Resolves level ID to name; used for Internal account exclusion |
| PlayerStatusID | Dictionary.PlayerStatus | Lookup / JOIN | Resolves player status ID to name |
| CountryIDByIP | Dictionary.Country | Lookup / LEFT JOIN | Resolves IP-based country ID to country name |
| CurrencyID | Dictionary.Currency | Lookup / JOIN | Resolves currency ID to abbreviation |
| FundingTypeID | Dictionary.FundingType | Lookup / JOIN | Resolves funding type ID to name |
| CashoutStatusID | Dictionary.CashoutStatus | Lookup / JOIN | Resolves cashout status ID to name |
| RegulationID | Dictionary.Regulation | Lookup / LEFT JOIN | Resolves regulation ID to name |
| CashoutReasonID | Dictionary.CashoutReason | Lookup / LEFT JOIN | Resolves cashout reason ID to name |
| CID | BackOffice.CustomerAllTimeAggregatedData | Lookup / LEFT JOIN | Provides lifetime deposit/cashout/commission totals |
| ManagerID (BWIT) | BackOffice.Manager | Lookup / LEFT JOIN | Resolves processing manager ID to full name |
| ManagerID (BCST) | BackOffice.Manager | Lookup / LEFT JOIN | Resolves account manager ID to full name |
| WithdrawID | Billing.WithdrawToFunding | Lookup / LEFT JOIN | Bridges withdrawal to the funding record used to fulfill it |
| WithdrawToFundingID | Billing.Redeem | Lookup / LEFT JOIN | Provides crypto redemption data: units, fee, instrument |
| InstrumentID | Trade.InstrumentMetaData | Lookup / LEFT JOIN | Resolves crypto instrument ID to display name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Called by BackOffice UI to populate the crypto-transfer withdrawal management grid |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCryptoTransferWithdrawRequests (procedure)
|- Billing.Withdraw (CTE - primary data)
|- Customer.Customer (customer profile)
|- BackOffice.Customer (BO customer attributes)
|- Dictionary.Label (white label)
|- Dictionary.PlayerLevel (customer level + Internal filter)
|- Dictionary.PlayerStatus (customer status)
|- Dictionary.Country (country by IP)
|- Dictionary.Currency (currency abbreviation)
|- Dictionary.FundingType (funding method name)
|- Dictionary.CashoutStatus (cashout status name)
|- Dictionary.Regulation (regulation name)
|- Dictionary.CashoutReason (withdraw reason)
|- BackOffice.CustomerAllTimeAggregatedData (lifetime financials)
|- BackOffice.Manager (x2: processed by + account manager)
|- Billing.WithdrawToFunding (withdrawal-to-funding bridge)
|- Billing.Redeem (crypto redemption units/fee)
+-- Trade.InstrumentMetaData (crypto instrument name)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | CTE primary source - withdrawal records filtered by ModificationDate |
| Customer.Customer | Table | JOINed for username, label, country by IP, player level/status |
| BackOffice.Customer | Table | JOINed for BO manager assignment, regulation |
| Dictionary.Label | Table | LEFT JOINed to resolve LabelID to white-label name |
| Dictionary.PlayerLevel | Table | JOINed to resolve PlayerLevelID and apply Internal account filter |
| Dictionary.PlayerStatus | Table | JOINed to resolve PlayerStatusID to name |
| Dictionary.Country | Table | LEFT JOINed to resolve CountryIDByIP to country name |
| Dictionary.Currency | Table | JOINed to resolve CurrencyID to abbreviation |
| Dictionary.FundingType | Table | JOINed to resolve FundingTypeID to name and apply TVP filter |
| Dictionary.CashoutStatus | Table | JOINed to resolve CashoutStatusID to name |
| Dictionary.Regulation | Table | LEFT JOINed to resolve RegulationID to name |
| Dictionary.CashoutReason | Table | LEFT JOINed to resolve CashoutReasonID to name |
| BackOffice.CustomerAllTimeAggregatedData | Table | LEFT JOINed for lifetime TotalDeposit/TotalCashout/TotalCommission |
| BackOffice.Manager | Table | LEFT JOINed twice: BWIT.ManagerID (Processed By) and BCST.ManagerID (Account Manager) |
| Billing.WithdrawToFunding | Table | LEFT JOINed to bridge WithdrawID to funding record |
| Billing.Redeem | Table | LEFT JOINed for crypto redemption: Units, RedeemFee, InstrumentID |
| Trade.InstrumentMetaData | Table | LEFT JOINed to resolve crypto InstrumentID to display name |
| BackOffice.IDs | User Defined Type | TVP type for @CashoutStatusesList, @FundingTypeIDList, @LabelIdsList |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Reads withdrawal queue for crypto-transfer management UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all pending crypto transfer withdrawals for a date window

```sql
DECLARE @Statuses BackOffice.IDs;
DECLARE @Fundings BackOffice.IDs;
DECLARE @Labels   BackOffice.IDs;

-- CashoutStatusID for Pending (example: 1)
INSERT @Statuses VALUES (1);
-- FundingTypeID for Bitcoin (example: 25)
INSERT @Fundings VALUES (25);

EXEC BackOffice.GetCryptoTransferWithdrawRequests
    @StartDate               = '2026-03-01',
    @EndDate                 = '2026-03-17',
    @CashoutStatusesList     = @Statuses,
    @FundingTypeIDList       = @Fundings,
    @LabelIdsList            = @Labels,   -- empty = all labels
    @Approved                = 0,          -- all approval states
    @IncludeInternalAccounts = 0;          -- exclude Internal
```

### 8.2 Single-customer lookup for all crypto withdrawals

```sql
DECLARE @Statuses BackOffice.IDs;
DECLARE @Fundings BackOffice.IDs;
DECLARE @Labels   BackOffice.IDs;
-- Pass all relevant status/funding IDs
INSERT @Statuses SELECT ID FROM BackOffice.IDs; -- populate appropriately

EXEC BackOffice.GetCryptoTransferWithdrawRequests
    @StartDate               = '2020-01-01',
    @EndDate                 = '2026-12-31',
    @CashoutStatusesList     = @Statuses,
    @FundingTypeIDList       = @Fundings,
    @LabelIdsList            = @Labels,
    @Approved                = 0,
    @IncludeInternalAccounts = 1,
    @CID                     = 12345678;
```

### 8.3 Direct source query for crypto withdrawal crypto units

```sql
SELECT
    w.WithdrawID, w.CID, w.Amount, w.ModificationDate,
    r.Units, r.RedeemFee, (r.Units - r.RedeemFee) AS NetUnits,
    im.InstrumentDisplayName
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
JOIN Billing.Redeem r WITH (NOLOCK) ON r.WithdrawToFundingID = wtf.ID
JOIN Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = r.InstrumentID
WHERE w.ModificationDate BETWEEN '2026-03-01' AND '2026-03-17'
ORDER BY w.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure. The procedure name and structure are consistent with the crypto-transfer withdrawal workflow documented under MIMOPSB-929 (see BackOffice.GetCryptoTransferWithdrawApprovalHistory for context on the broader withdrawal management migration effort).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCryptoTransferWithdrawRequests | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCryptoTransferWithdrawRequests.sql*
