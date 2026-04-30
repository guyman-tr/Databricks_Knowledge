# Billing.GetNFDetailsByRedeemID

> Returns NFT redemption details for a specific RedeemID - CID, OperationID, instrument/units, and the customer's crypto wallet address extracted from FundingData XML.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID - returns NFT redemption details with wallet address |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetNFDetailsByRedeemID` retrieves the core details of an NFT crypto redemption request. "NF" in the name refers to NFT (Non-Fungible Token) or crypto asset redemption - the process by which a customer liquidates a crypto position and receives the assets in their external blockchain wallet.

The procedure is scoped to `RedeemTypeID=1` (NFT/crypto withdrawal to external wallet), which is distinct from other redeem types. It extracts the customer's wallet address from the `FundingData` XML using an XPath expression (`Funding[1]/WalletAddressAsString[1]`), making the destination wallet address available without requiring the caller to parse XML.

The primary use case is the crypto redemption processing pipeline: after a customer initiates an NFT withdrawal, this procedure is called to confirm the destination wallet and associated position details before executing the blockchain transfer.

---

## 2. Business Logic

### 2.1 NFT Redemption Details with Wallet Extraction

**What**: Retrieves the redemption record and extracts the destination wallet address from the linked Funding record's XML.

**Columns/Parameters Involved**: `@RedeemID`, `BR.RedeemTypeID=1`, `BFUN.FundingData`

**Rules**:
- `WHERE BR.RedeemID = @RedeemID AND BR.RedeemTypeID = 1` - only NFT type redemptions
- `RedeemTypeID=1` = NFT/crypto withdrawal to external blockchain wallet (distinct from fiat withdrawal)
- `INNER JOIN Billing.Funding` - required; if no linked Funding, no rows returned
- `BFUN.FundingData.value('Funding[1]/WalletAddressAsString[1]', 'NVARCHAR(MAX)')` - XPath extraction of the destination blockchain wallet address from the payment instrument XML
- `WalletAddressAsString` is stored inside the FundingData XML for crypto funding types (not a top-level column)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemID | INT | NO | - | CODE-BACKED | The redemption request to retrieve. FK to Billing.Redeem.RedeemID. Only returns a row if RedeemTypeID=1 (NFT/crypto). |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the redemption requestor. FK to Customer.CustomerStatic.CID. |
| 3 | RedeemID | int | NO | - | CODE-BACKED | The redemption request ID (echoed from input). |
| 4 | RedeemTypeID | int | NO | - | CODE-BACKED | Always 1 for rows returned by this procedure (NFT/crypto type). |
| 5 | OperationID | uniqueidentifier | YES | NULL | CODE-BACKED | Application-level GUID correlating this redemption to a business operation. Used for cross-system tracing. |
| 6 | Units | decimal | YES | NULL | CODE-BACKED | Quantity of the crypto asset being redeemed (number of tokens/coins). |
| 7 | InstrumentID | int | YES | NULL | CODE-BACKED | The crypto instrument being redeemed (FK to Trade.Instrument). |
| 8 | Wallet | nvarchar(MAX) | YES | NULL | CODE-BACKED | The customer's destination blockchain wallet address, extracted from FundingData XML (XPath: Funding[1]/WalletAddressAsString[1]). NULL if the wallet address is not present in the XML. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.Redeem | Direct Read | NFT redemption request record (RedeemTypeID=1 filter) |
| INNER JOIN | Billing.Funding | Direct Read | Customer's payment instrument record containing the blockchain wallet address in FundingData XML |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Called from the NFT redemption processing service. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetNFDetailsByRedeemID (procedure)
├── Billing.Redeem (table)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | FROM - reads NFT redemption record (RedeemTypeID=1) |
| Billing.Funding | Table | INNER JOIN - extracts destination wallet address from FundingData XML |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get NFT redemption details

```sql
EXEC Billing.GetNFDetailsByRedeemID @RedeemID = 12345
-- Returns: CID, RedeemID, RedeemTypeID=1, OperationID, Units, InstrumentID, Wallet address
-- Returns empty if RedeemID doesn't exist or is not RedeemTypeID=1
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT BR.CID, BR.RedeemID, BR.RedeemTypeID, BR.OperationID, BR.Units, BR.InstrumentID,
       BFUN.FundingData.value('Funding[1]/WalletAddressAsString[1]', 'NVARCHAR(MAX)') AS Wallet
FROM Billing.Redeem AS BR WITH (NOLOCK)
INNER JOIN Billing.Funding AS BFUN WITH (NOLOCK) ON BR.FundingID = BFUN.FundingID
WHERE BR.RedeemID = 12345
  AND BR.RedeemTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetNFDetailsByRedeemID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetNFDetailsByRedeemID.sql*
