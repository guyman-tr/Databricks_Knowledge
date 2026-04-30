# Dictionary.DepotMode

> Lookup table defining the account modes for payment processing depot configuration — General, Live, and Demo — used to route merchant/protocol settings to the correct environment.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DepotModeID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

In eToro's payment processing architecture, a "depot" represents a configuration context for merchant account routing. Depots operate in different modes: General (0) for configuration that applies regardless of environment, Live (1) for production payment processing, and Demo (2) for sandbox/test environments. This table provides the dictionary of those modes.

Without this table, the billing system would have no way to separate payment processing configurations between production and test environments. The depot mode determines which merchant IDs (MIDs), protocol settings, and routing rules are applied when processing a deposit or cashout.

The table is extensively referenced by billing infrastructure: `Billing.MerchantAccountRouting`, `Billing.DepotValue`, `Billing.ProtocolValue`, `Billing.ProtocolMIDSettings`, and multiple procedures that retrieve merchant and protocol configurations (`Billing.GetMerchantValues`, `Billing.GetDepotMIDSettings`, `Billing.GetProtocolMIDSettings`, `Billing.GetProtocolDetails`).

---

## 2. Business Logic

### 2.1 Environment-Based Payment Routing

**What**: Payment processing configurations are separated by depot mode to prevent test transactions from using production merchant accounts.

**Columns/Parameters Involved**: `DepotModeID`, `DepotModeName`

**Rules**:
- General (0) — configuration that applies in all environments (shared settings, default values)
- Live (1) — production payment processing configuration with real merchant IDs and live PSP endpoints
- Demo (2) — sandbox configuration with test merchant IDs for QA, staging, and development environments
- Procedures like `Billing.GetMerchantValues` filter by DepotModeID to return only the appropriate configuration for the current environment

---

## 3. Data Overview

| DepotModeID | DepotModeName | Meaning |
|---|---|---|
| 0 | General | Environment-agnostic configuration — settings that apply to all depot modes as defaults or shared values. Inherited when no Live- or Demo-specific override exists |
| 1 | Live | Production payment processing mode — uses real merchant IDs, live PSP API endpoints, and actual bank connections. All real customer deposits and cashouts route through this mode |
| 2 | Demo | Sandbox/test payment processing mode — uses test merchant IDs and sandbox PSP endpoints. Used by QA, staging environments, and internal testing to simulate payment flows without real money |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepotModeID | tinyint | NO | - | VERIFIED | Primary key identifying the depot mode. 0=General, 1=Live, 2=Demo. Referenced by Billing.MerchantAccountRouting, Billing.DepotValue, Billing.ProtocolValue, Billing.ProtocolMIDSettings as a routing dimension. |
| 2 | DepotModeName | varchar(20) | YES | - | VERIFIED | Human-readable mode name. Nullable in DDL but all 3 rows have values. Used in BackOffice configuration UIs and billing setup procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.MerchantAccountRouting | DepotModeID | Implicit | Routes payment method selections to appropriate merchant accounts by environment |
| Billing.DepotValue | DepotModeID | Implicit | Stores depot-level configuration values per mode |
| Billing.ProtocolValue | DepotModeID | Implicit | Stores protocol-level settings per depot mode |
| Billing.ProtocolMIDSettings | DepotModeID | Implicit | Merchant ID settings per protocol and depot mode |
| Billing.GetMerchantValues | DepotModeID | JOIN | Retrieves merchant configuration for the specified environment |
| Billing.GetMerchantValues_V2 | DepotModeID | JOIN | V2 of merchant configuration retrieval |
| Billing.GetDepotMIDSettings | DepotModeID | JOIN | Returns MID settings for a specific depot mode |
| Billing.GetProtocolMIDSettings | DepotModeID | JOIN | Returns protocol-level MID settings per mode |
| Billing.GetProtocolDetails | DepotModeID | JOIN | Returns full protocol details including depot mode |
| Billing.GetMIDDescription | DepotModeID | JOIN | Resolves MID to description with depot mode context |
| Billing.GetMIDDescriptionV2 | DepotModeID | JOIN | V2 of MID description resolution |
| Billing.GetMerchantDetailsForOneAccountByDepotOnly | DepotModeID | JOIN | Returns merchant details filtered by depot mode only |
| Billing.GetNFTRedeemDetailsByOperationID | DepotModeID | JOIN | NFT redeem details including depot mode |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepotMode (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantAccountRouting | Table | References — routing configuration |
| Billing.DepotValue | Table | References — depot configuration values |
| Billing.ProtocolValue | Table | References — protocol settings |
| Billing.ProtocolMIDSettings | Table | References — MID settings |
| Billing.GetMerchantValues | Procedure | Reader — merchant config lookup |
| Billing.GetDepotMIDSettings | Procedure | Reader — MID settings lookup |
| Billing.GetProtocolDetails | Procedure | Reader — protocol details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DepotMode | CLUSTERED | DepotModeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all depot modes
```sql
SELECT  DepotModeID,
        DepotModeName
FROM    Dictionary.DepotMode WITH (NOLOCK)
ORDER BY DepotModeID
```

### 8.2 Show merchant routing by depot mode
```sql
SELECT  dm.DepotModeName,
        mar.MerchantAccountID,
        mar.FundingTypeID
FROM    Billing.MerchantAccountRouting mar WITH (NOLOCK)
        JOIN Dictionary.DepotMode dm WITH (NOLOCK) ON mar.DepotModeID = dm.DepotModeID
ORDER BY dm.DepotModeID
```

### 8.3 Compare Live vs Demo MID settings
```sql
SELECT  dm.DepotModeName,
        pms.ProtocolID,
        pms.MerchantID
FROM    Billing.ProtocolMIDSettings pms WITH (NOLOCK)
        JOIN Dictionary.DepotMode dm WITH (NOLOCK) ON pms.DepotModeID = dm.DepotModeID
WHERE   dm.DepotModeID IN (1, 2)  -- Live, Demo
ORDER BY pms.ProtocolID, dm.DepotModeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 13 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepotMode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepotMode.sql*
