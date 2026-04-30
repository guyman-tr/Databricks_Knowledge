# Billing.GetNFTRedeemDetailsByOperationID

> Returns full NFT redemption details for a specific customer operation - including the signing key for the blockchain transaction (from Billing.ProtocolValue) and the destination wallet address (from FundingData XML).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @OperationID - returns redemption amounts, position/instrument, signing key, and wallet |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetNFTRedeemDetailsByOperationID` provides the complete payload needed to execute an NFT blockchain transfer. Unlike `GetNFDetailsByRedeemID` (which looks up by RedeemID), this procedure looks up by the application-level `OperationID` (GUID), which is how the calling service tracks operations before a RedeemID is known.

The distinguishing feature is the signing key lookup: the procedure fetches a `Sign` value from `Billing.ProtocolValue` (ProtocolID=30=CryptoWallet, DepotModeID=@NFTDepotModeID, ParameterID=34) which is used to sign the blockchain transaction. The `@NFTDepotModeID` parameter selects between live and demo signing keys, reflecting that crypto transactions in demo mode use different credentials than live mode.

Like the other NFT procedures, it is scoped to `RedeemTypeID=1` (NFT/crypto withdrawal).

Created/modified by Alexei 30/06/2022 (PTL-76).

---

## 2. Business Logic

### 2.1 Signing Key Resolution from ProtocolValue

**What**: Retrieves the blockchain transaction signing credential for the appropriate depot mode.

**Columns/Parameters Involved**: `@NFTDepotModeID`, `@CryptoWalletProtocolID=30`, `Billing.ProtocolValue.ParameterID=34`, `@Sign`

**Rules**:
- `@CryptoWalletProtocolID = 30` - hardcoded constant: ProtocolID 30 = CryptoWallet protocol
- `@NFTDepotModeID` - caller-provided: 1=Live, 2=Demo (different signing keys per mode)
- `ParameterID=34` - the specific parameter within the CryptoWallet protocol that holds the signing credential
- Stored as `@Sign VARCHAR(250)` - the signing key/secret used for blockchain transaction signing
- `@Sign` is included in every result row as a constant

### 2.2 Redemption Record with Wallet Address

**What**: Returns the financial details of the redemption and the destination wallet.

**Columns/Parameters Involved**: `@CID`, `@OperationID`, `Billing.Redeem`, `Billing.Funding`

**Rules**:
- `WHERE Billing.Redeem.CID = @CID AND Billing.Redeem.OperationID = @OperationID AND Billing.Redeem.RedeemTypeID = 1`
- CID ownership check prevents cross-customer data exposure
- INNER JOIN to Billing.Funding - required; returns no rows if funding record missing
- Wallet extracted via XPath: `FundingData.value('Funding[1]/WalletAddressAsString[1]', 'NVARCHAR(MAX)')`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Ownership scope - only returns the redemption if it belongs to this customer. |
| 2 | @OperationID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Application-level GUID identifying the NFT withdrawal operation. Matches Billing.Redeem.OperationID. |
| 3 | @NFTDepotModeID | INT | NO | - | CODE-BACKED | Depot mode for signing key selection. 1=Live (production blockchain), 2=Demo (test/sandbox). Selects the appropriate signing credential from Billing.ProtocolValue. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | RedeemID | int | NO | - | CODE-BACKED | The redemption request PK. |
| 5 | AmountOnRequest | decimal | YES | NULL | CODE-BACKED | The fiat amount the customer requested to receive (in USD). Set at request creation. |
| 6 | PositionID | int | YES | NULL | CODE-BACKED | FK to Trade.Position - the crypto position being liquidated. |
| 7 | InstrumentID | int | YES | NULL | CODE-BACKED | FK to Trade.Instrument - the crypto asset (e.g., BTC, ETH). |
| 8 | Units | decimal | YES | NULL | CODE-BACKED | Quantity of the crypto asset being redeemed. |
| 9 | RedeemFee | decimal | YES | NULL | CODE-BACKED | Fee charged for the redemption (in USD or as percentage). |
| 10 | WTFID | int | YES | NULL | CODE-BACKED | WithdrawToFundingID - FK to Billing.WithdrawToFunding, referencing the payout instruction for the redeemed value. |
| 11 | Sign | varchar(250) | YES | NULL | CODE-BACKED | Blockchain transaction signing credential retrieved from Billing.ProtocolValue (ProtocolID=30, ParameterID=34, DepotModeID=@NFTDepotModeID). NULL if no signing key configured for this mode. |
| 12 | Wallet | nvarchar(MAX) | YES | NULL | CODE-BACKED | Destination blockchain wallet address from FundingData XML (XPath: Funding[1]/WalletAddressAsString[1]). The recipient address for the crypto transfer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (Sign) | Billing.ProtocolValue | Direct Read | Retrieves blockchain signing key for ProtocolID=30 (CryptoWallet), ParameterID=34, mode-specific |
| FROM | Billing.Redeem | Direct Read | NFT redemption request (RedeemTypeID=1, CID-scoped) |
| INNER JOIN | Billing.Funding | Direct Read | Payment instrument XML containing destination wallet address |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Called from NFT withdrawal service to prepare blockchain transaction payload. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetNFTRedeemDetailsByOperationID (procedure)
├── Billing.ProtocolValue (table)
├── Billing.Redeem (table)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolValue | Table | SELECT - reads blockchain signing key (ProtocolID=30, DepotModeID=@NFTDepotModeID, ParameterID=34) |
| Billing.Redeem | Table | FROM - NFT redemption record (CID, OperationID, RedeemTypeID=1) |
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

### 8.1 Get NFT redemption details for a live operation

```sql
EXEC Billing.GetNFTRedeemDetailsByOperationID
    @CID           = 12345678,
    @OperationID   = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @NFTDepotModeID = 1  -- Live
-- Returns: RedeemID, amounts, instrument, signing key, wallet address
```

### 8.2 Check the signing key for a depot mode

```sql
SELECT Value AS SigningKey
FROM Billing.ProtocolValue WITH (NOLOCK)
WHERE ProtocolID = 30      -- CryptoWallet
  AND DepotModeID = 1      -- Live
  AND ParameterID = 34     -- Signing credential
```

---

## 9. Atlassian Knowledge Sources

PTL-76 (Alexei, 30/06/2022): Added RedeemTypeID scoping to the NFT redemption procedures.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetNFTRedeemDetailsByOperationID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetNFTRedeemDetailsByOperationID.sql*
