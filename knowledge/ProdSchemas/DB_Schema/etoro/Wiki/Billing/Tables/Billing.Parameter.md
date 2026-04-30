# Billing.Parameter

> Lookup catalog of payment provider integration parameter names; each row names one configuration key (URL, credential, identifier) used in `Billing.ProtocolMIDSettings`, `Billing.DepotValue`, and `Billing.MerchantAccountValues` to define per-protocol, per-depot payment gateway settings.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ParameterID (PRIMARY KEY CLUSTERED) |
| **Row Count** | ~167 rows (with gaps; IDs 1-167) |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK CLUSTERED on ParameterID; 1 - UNIQUE NC on Name |

---

## 1. Business Meaning

`Billing.Parameter` is the master catalog of configuration parameter names used in the etoro payment gateway integration layer. Each row defines one named configuration key - such as a callback URL (`returnUrl`), API credential (`apiUsername`, `apiPassword`), merchant identifier (`merchantID`), or endpoint URL (`paymentUrl`) - that payment providers require when establishing a connection.

These parameter names serve as the shared vocabulary between the payment orchestration layer and payment gateway adapters. The actual per-depot, per-protocol, per-regulation, per-currency values are stored in `Billing.ProtocolMIDSettings` (for MID/routing settings), `Billing.DepotValue` (for depot-level config), and `Billing.MerchantAccountValues` (for merchant account config) - all referencing `Billing.Parameter.ParameterID` as a FK.

`ParameterID=52` (`merchantID`) has special significance: `Billing.WithdrawToFundingProcess` accepts a `@MID` parameter (nvarchar) and resolves it to a `ProtocolMIDSettingsID` by querying `Billing.ProtocolMIDSettings WHERE Value = @MID AND ParameterID = 52`. This MID lookup is the mechanism that routes a withdrawal to the correct payment processor.

---

## 2. Business Logic

### 2.1 Parameter Name Registry

**What**: Acts as an enumeration of all valid configuration key names for payment provider integration. New parameters must be inserted here before they can be used in any gateway config table.

**Columns Involved**: `ParameterID`, `Name`

**Rules**:
- `ParameterID` is manually assigned (no IDENTITY) - values are assigned by operations/engineering when adding a new gateway integration
- `Name` is UNIQUE (enforced by BPRM_NAME index) - each parameter name appears exactly once
- Names are case-insensitive in lookup queries (varchar with default collation)
- Gaps in ParameterID sequence (e.g., 114-116, 121-122, 133, 147-149) indicate deleted or reserved entries

### 2.2 Parameter Categories (Observed)

| Category | Examples | ParameterIDs |
|----------|---------|--------------|
| Callback/redirect URLs | returnUrl, statusUrl, cancelUrl, paymentUrl, notificationUrl | 1, 2, 3, 7, 21, 37, 38, 41, 48, 51, 56, 90, 92 |
| API credentials | apiUsername, apiPassword, userName, password, secret, merch_key, secret_word | 23, 30, 35, 43, 49, 50, 55, 59, 79, 93, 94 |
| Merchant/terminal IDs | merchantID (52), MerchantID (57), MerchantId (66), TerminalID (87), shopId (72) | 52, 57, 66, 69, 72, 87 |
| Provider-specific (Zotapay) | zotapayUrl, zotapayEndpointId, zotapayMerchantControl, country-specific endpoints | 96-105, 112, 123-130, 134-135, 141-150 |
| Provider-specific (ezeebill) | ezeebillUrl, ezeebillMerchantID, ezeebillTerminalID | 106-111 |
| Gateway config | mode, environment, IsTest, version, language | 24, 28, 33, 36, 60, 71 |
| NFT/Redeem | RedeemAPIPositionSecret, AuthorizeSecret | 131, 132 |
| Money movement | LegalEntityType, MerchantAccountSourceList | 166, 167 |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 167 (with gaps in sequence) |
| ID range | 1-167 (non-contiguous) |
| Unique names | 167 (UNIQUE constraint enforced) |
| Special ID | 52 = 'merchantID' (MID routing key in WithdrawToFundingProcess) |
| Oldest params | IDs 1-13: early Moneybookers/Skrill integration (returnUrl, statusUrl, pay_to_email) |
| Newest params | IDs 160-167: eCommpay, FraudNet, Tapi, LegalEntityType (recent integrations) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParameterID | int | NO | - | CODE-BACKED | Primary key. Manually assigned integer - no IDENTITY. Stable identifier referenced by `Billing.ProtocolMIDSettings`, `Billing.DepotValue`, `Billing.MerchantAccountValues`, `Billing.GatewayEndpoint`. ParameterID=52 ('merchantID') is the key used by `WithdrawToFundingProcess` to resolve a MID string to a `ProtocolMIDSettingsID`. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | The parameter name as it appears in payment provider API contracts. UNIQUE (enforced by BPRM_NAME index). Used as the lookup key when gateway adapters retrieve config values. Case-sensitive in binary collation contexts. Examples: 'returnUrl' (1), 'pay_to_email' (4), 'merchantID' (52), 'apiPassword' (35), 'zotapayUrl' (97). |

---

## 5. Relationships

### 5.1 References To (this object points to)

No outbound FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ProtocolMIDSettings | ParameterID | FK (FK_BPMIDS_ParameterID) | Each MID setting row specifies which parameter type it configures; ParameterID=52 is the MID routing key |
| Billing.DepotValue | ParameterID | FK (implicit) | Per-depot configuration values keyed by parameter name |
| Billing.MerchantAccountValues | ParameterID | FK (implicit) | Per-merchant-account configuration values |
| Billing.GatewayEndpoint | ParameterID | FK (implicit) | Gateway endpoint configuration keyed by parameter |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies - this is a leaf lookup table.

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolMIDSettings | Table | FK on ParameterID; compound PK includes ParameterID |
| Billing.DepotValue | Table | FK on ParameterID |
| Billing.MerchantAccountValues | Table | FK on ParameterID |
| Billing.GatewayEndpoint | Table | FK on ParameterID |
| Billing.GetProtocolMIDSettings | Stored Procedure | Returns ProtocolMIDSettings rows filtered by ParameterID |
| Billing.GetMerchantValues | Stored Procedure | Retrieves merchant config values via ParameterID |
| Billing.GetMerchantValues_V2 | Stored Procedure | V2 variant of merchant config retrieval |
| Billing.GetDepotMIDSettings | Stored Procedure | Returns depot MID settings with parameter context |
| Billing.GetMerchantValuesByMerchantID | Stored Procedure | Merchant config lookup by merchant ID and parameter |
| Billing.WithdrawToFundingProcess | Stored Procedure | Resolves @MID string via ProtocolMIDSettings WHERE ParameterID=52 |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | Same MID resolution via ParameterID=52 |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BPRM | CLUSTERED PK | ParameterID ASC | - | - | Active; FILLFACTOR=90 |
| BPRM_NAME | UNIQUE NC | Name ASC | - | - | Active; FILLFACTOR=90; enforces name uniqueness |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BPRM | PRIMARY KEY CLUSTERED | One row per ParameterID |
| BPRM_NAME (index) | UNIQUE | Each parameter name appears exactly once |

---

## 8. Sample Queries

### 8.1 View all parameters

```sql
SELECT ParameterID, Name
FROM Billing.Parameter WITH (NOLOCK)
ORDER BY ParameterID
```

### 8.2 Find the MID parameter (used in WithdrawToFundingProcess routing)

```sql
SELECT ParameterID, Name
FROM Billing.Parameter WITH (NOLOCK)
WHERE ParameterID = 52
-- Returns: 52, 'merchantID'
```

### 8.3 Find which depots have MID settings configured

```sql
SELECT
    p.Name AS ParameterName,
    pms.DepotID,
    d.FundingTypeID,
    pms.RegulationID,
    pms.CurrencyID,
    pms.Value
FROM Billing.ProtocolMIDSettings pms WITH (NOLOCK)
JOIN Billing.Parameter p WITH (NOLOCK) ON p.ParameterID = pms.ParameterID
JOIN Billing.Depot d WITH (NOLOCK) ON d.DepotID = pms.DepotID
WHERE pms.ParameterID = 52  -- merchantID
ORDER BY pms.DepotID, pms.RegulationID
```

### 8.4 List all parameter usage counts in ProtocolMIDSettings

```sql
SELECT
    p.ParameterID,
    p.Name,
    COUNT(pms.ID) AS UsageCount
FROM Billing.Parameter p WITH (NOLOCK)
LEFT JOIN Billing.ProtocolMIDSettings pms WITH (NOLOCK) ON pms.ParameterID = p.ParameterID
GROUP BY p.ParameterID, p.Name
ORDER BY UsageCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Parameter | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Parameter.sql*
