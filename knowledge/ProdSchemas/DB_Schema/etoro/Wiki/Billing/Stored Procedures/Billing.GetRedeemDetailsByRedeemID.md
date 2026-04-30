# Billing.GetRedeemDetailsByRedeemID

> Returns the full operational details for a single crypto redemption request by its RedeemID, including the payout process record ID and the customer's target crypto wallet address extracted from the funding XML.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID (single record lookup); returns at most one row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemDetailsByRedeemID` is the primary detail-fetch procedure for a crypto redemption record. It is used when the system or an operator needs the full context of a specific redemption: who requested it, which instrument and units are being redeemed, what fee applies, which payment method receives the proceeds, and critically, what external crypto wallet address (if any) the customer wants the crypto sent to.

The procedure exists because `Billing.Redeem` stores the redemption request and `Billing.Funding` stores the payment instrument data (including the wallet address in XML), and `Billing.RedeemPayoutProcess` stores the execution record for the payout pipeline. Joining these three sources into one result is a common need for operators reviewing redemption details and for application services driving the payout workflow.

Data flow: the caller passes a `@RedeemID` (the PK of `Billing.Redeem`). The procedure returns one row with all key fields from `Billing.Redeem`, the `RedeemPayoutProcessID` from `Billing.RedeemPayoutProcess` (NULL if payout has not been initiated yet - LEFT JOIN), and the wallet address parsed out of `Billing.Funding.FundingData` XML. The wallet address is relevant for crypto-to-external-wallet redemptions where the customer wants to receive crypto rather than fiat.

---

## 2. Business Logic

### 2.1 Wallet Address Extraction from FundingData XML

**What**: The customer's target external crypto wallet address is stored inside the XML blob in `Billing.Funding.FundingData` and must be parsed at query time.

**Columns/Parameters Involved**: `Wallet`, `Billing.Funding.FundingData`

**Rules**:
- `FundingData.value('Funding[1]/WalletAddressAsString[1]','NVARCHAR(MAX)')` extracts the wallet address from the XML node `Funding/WalletAddressAsString`
- This field is populated only for crypto wallet funding types - for credit card or bank transfer redemptions, the XML does not contain `WalletAddressAsString` and the result is NULL
- The INNER JOIN on `Funding.FundingID = Redeem.FundingID` ensures the wallet address corresponds to the specific funding method chosen by the customer for this redemption

### 2.2 Optional Payout Process Context

**What**: The `Billing.RedeemPayoutProcess` record is LEFT-joined, meaning the procedure returns redemption details regardless of whether the payout pipeline has been initiated.

**Columns/Parameters Involved**: `ProcessID` (RedeemPayoutProcessID), `Billing.RedeemPayoutProcess`

**Rules**:
- `ProcessID = NULL` when no payout process record exists - this is expected for newly submitted redemptions (RedeemStatusID=100/New, 1/PositionPending, or 2/Rejected) that have not been approved and processed yet
- `ProcessID IS NOT NULL` confirms that `RedeemPayoutProcess_CreateRecords` has been called and the redemption has entered the payout pipeline (status >= ReadyToRedeem/4)
- The caller uses `ProcessID` to distinguish whether the redemption is in the pre-approval stage or in active payout execution

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemID | INT | NO | - | CODE-BACKED | Primary key of the `Billing.Redeem` record to retrieve. Identifies a single customer crypto redemption request. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | RedeemID | INT | NO | - | CODE-BACKED | Primary key of the redemption record. Echoed from `Billing.Redeem.RedeemID` - same as the input parameter. |
| 3 | RedeemTypeID | INT | YES | - | CODE-BACKED | Type of redemption request. FK to `Dictionary.RedeemType`. Distinguishes between full position redemption, partial redemption, NFT redemption, etc. See `Billing.Redeem` Section 4 for value map. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer identifier who submitted the redemption request. FK to `Customer.Customer.CID`. |
| 5 | FundingID | INT | YES | - | CODE-BACKED | Payment instrument the customer selected to receive the redemption proceeds (for fiat payout) or to identify the crypto wallet (for external wallet redemptions). FK to `Billing.Funding.FundingID`. |
| 6 | Units | DECIMAL | YES | - | CODE-BACKED | Number of crypto units being redeemed in this request. For a full position redemption this equals the position's full unit count. For partial redemptions it is the partial amount. |
| 7 | ProcessID | INT | YES | - | CODE-BACKED | `Billing.RedeemPayoutProcess.RedeemPayoutProcessID` - the payout pipeline execution record ID. NULL when no payout process has been initiated (redemption is pre-approval or terminated). Non-NULL confirms the redemption is in or has completed the active payout pipeline. |
| 8 | OperationID | INT | YES | - | CODE-BACKED | Operation reference ID linking this redemption to the trading/balance operation that funded it. Used for reconciliation between the billing and trading systems. |
| 9 | InstrumentID | INT | YES | - | CODE-BACKED | Trading instrument being redeemed (e.g., Bitcoin InstrumentID=X, Ethereum InstrumentID=Y). Identifies which crypto asset the customer is selling. FK to `Trade.Instrument`. |
| 10 | RedeemFee | DECIMAL | YES | - | CODE-BACKED | Fee charged for this redemption in the customer's account currency. Set during redemption processing based on `Billing.RedeemFeeSettings`. Zero for fee-exempt redemptions. |
| 11 | WithdrawToFundingID | INT | YES | - | CODE-BACKED | The specific `Billing.WithdrawToFunding` record ID that carries the fiat payout from this redemption. Populated once the redemption reaches TransactionDone state. FK to `Billing.WithdrawToFunding`. |
| 12 | Wallet | NVARCHAR(MAX) | YES | - | CODE-BACKED | External crypto wallet address to which the crypto units should be transferred. Parsed from `Billing.Funding.FundingData` XML node `Funding[1]/WalletAddressAsString[1]`. NULL for non-wallet funding types (credit cards, bank accounts) or when the customer has not provided a wallet address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemID | Billing.Redeem | INNER JOIN (PK lookup) | Primary source - retrieves all redemption request fields |
| FundingID | Billing.Funding | INNER JOIN | Source for FundingData XML containing the crypto wallet address |
| RedeemID | Billing.RedeemPayoutProcess | LEFT JOIN | Optional payout pipeline execution record; NULL if payout not yet initiated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application (redemption management / backoffice) | @RedeemID | EXEC | Called by application services and BO tools when displaying or processing a specific redemption record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemDetailsByRedeemID (procedure)
├── Billing.Redeem (table)
├── Billing.Funding (table)
└── Billing.RedeemPayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | INNER JOIN on RedeemID; primary source of all redemption request fields |
| Billing.Funding | Table | INNER JOIN on FundingID; XML-parsed for crypto wallet address |
| Billing.RedeemPayoutProcess | Table | LEFT JOIN on RedeemID; provides RedeemPayoutProcessID (ProcessID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application redemption service / BackOffice | External | Calls this procedure to retrieve full redemption details for display or pipeline processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Single record scope | Design | WHERE BR.RedeemID = @RedeemID - always returns at most one row (RedeemID is the PK of Billing.Redeem) |
| LEFT JOIN on RedeemPayoutProcess | Design | ProcessID may be NULL for pre-payout-pipeline redemptions; callers must handle NULL ProcessID |
| XML wallet parsing | Technical | `FundingData.value('Funding[1]/WalletAddressAsString[1]','NVARCHAR(MAX)')` - returns NULL if node absent; no error raised for missing XML path |

---

## 8. Sample Queries

### 8.1 Get full details for a specific redemption
```sql
EXEC Billing.GetRedeemDetailsByRedeemID @RedeemID = 100001;
```

### 8.2 View raw redemption with payout process status
```sql
SELECT
    r.RedeemID,
    r.RedeemStatusID,
    r.CID,
    r.FundingID,
    r.Units,
    r.RedeemFee,
    rpp.RedeemPayoutProcessID,
    rpp.InClosePositionProcess,
    rpp.InTransferUnitsProcess
FROM Billing.Redeem r WITH (NOLOCK)
LEFT JOIN Billing.RedeemPayoutProcess rpp WITH (NOLOCK) ON rpp.RedeemID = r.RedeemID
WHERE r.RedeemID = 100001;
```

### 8.3 Find redemptions for a customer with their wallet addresses
```sql
SELECT
    r.RedeemID,
    r.RedeemStatusID,
    r.InstrumentID,
    r.Units,
    f.FundingData.value('Funding[1]/WalletAddressAsString[1]','NVARCHAR(MAX)') AS Wallet
FROM Billing.Redeem r WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON r.FundingID = f.FundingID
WHERE r.CID = 12345678
ORDER BY r.RedeemID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemDetailsByRedeemID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemDetailsByRedeemID.sql*
