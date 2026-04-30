# Billing.GetPayoutProcessData

> Returns a fully enriched, single-row view of a specific WithdrawToFunding record by its ID, joining all relevant dictionary tables (FundingType, CashoutType, CashoutStatus, Depot, Regulation, CashoutMode, Currency, MatchStatus, Country) plus Customer and BackOffice schemas - used by the analytics service for payout processing context.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single enriched row for a given Billing.WithdrawToFunding.ID (@WTF_ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPayoutProcessData` retrieves the complete business context for a single payout processing record - a `Billing.WithdrawToFunding` row - by joining it to every relevant entity: the customer's CID and GCID (from Customer.Customer), the customer's regulation (from BackOffice.Customer -> Dictionary.Regulation), the funding instrument's type name, the cashout type and status names, the depot name, the payout mode name, the processing currency abbreviation, the match status name, and the customer's country name.

The procedure exists to give the analytics service (AnalyticsServiceUser) a single call that returns all the information needed to process, audit, or report on a payout operation without requiring multiple joins in the consumer. It is the canonical "give me everything about this cashout payment order" endpoint.

Data flows: the analytics service calls this procedure with the WithdrawToFunding ID (@WTF_ID), typically after detecting a payout that needs analytics processing. The procedure joins outward from `Billing.WithdrawToFunding` through `Billing.Withdraw` (to get CID/IPAddress), then to `Customer.Customer` (for GCID and CountryID), `BackOffice.Customer` (for designated regulation), and all relevant Dictionary tables. The result is a single enriched row.

---

## 2. Business Logic

### 2.1 Multi-Schema Join Chain for Full Context

**What**: The procedure traverses four schemas (Billing, Customer, BackOffice, Dictionary) in a single query to resolve all ID columns to human-readable names and add the customer's regulatory context.

**Columns/Parameters Involved**: `WTF.WithdrawID`, `BW.CID`, `CC.GCID`, `BOC.DesignatedRegulationID`, `DCNTY.CountryID`

**Join chain**:
```
Billing.WithdrawToFunding (WTF)
  -> Billing.Withdraw (BW)          -- via WithdrawID -> gets CID, IPAddress
  -> Customer.Customer (CC)          -- via CID -> gets GCID, CountryID
  -> Billing.Funding (BF)            -- via FundingID -> gets FundingTypeID
  -> BackOffice.Customer (BOC)       -- via CID -> gets DesignatedRegulationID
  -> Dictionary.FundingType (FD)     -- via FundingTypeID -> Name
  -> Dictionary.CashoutType (DCOT)   -- via CashoutTypeID -> CashoutTypeName
  -> Dictionary.CashoutStatus (DCOS) -- via CashoutStatusID -> Name
  -> Billing.Depot (BD)              -- LEFT JOIN via DepotID -> Name (optional)
  -> Dictionary.Regulation (DR)      -- via DesignatedRegulationID -> Name
  -> Dictionary.CashoutMode (DCOM)   -- via CashoutModeID -> CashoutModeName
  -> Dictionary.Currency (DC)        -- via ProcessCurrencyID -> Abbreviation
  -> Dictionary.MatchStatus (DMS)    -- via MatchStatusID -> Name
  -> Dictionary.Country (DCNTY)      -- via CC.CountryID -> Name
```

### 2.2 Depot as Optional Join

**What**: Depot may not always be assigned to a payment order.

**Rules**:
- `LEFT JOIN Billing.Depot AS BD ON WTF.DepotID = BD.DepotID AND WTF.DepotID > 0`
- If DepotID is 0 or NULL, `ISNULL(BD.Name, 'NA')` returns 'NA' as the depot display value
- All other joins are INNER JOINs - missing related records would cause the row to not be returned

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WTF_ID | INT | NO | - | CODE-BACKED | The `Billing.WithdrawToFunding.ID` of the payment order to retrieve. All joins and output data are anchored to this single record. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | WithdrawID | Billing.WithdrawToFunding.WithdrawID | CODE-BACKED | Parent withdrawal request ID. FK to Billing.Withdraw. |
| 3 | CID | Billing.Withdraw.CID | CODE-BACKED | Customer identifier. Retrieved via Billing.Withdraw. |
| 4 | IPAddress | Billing.Withdraw.IPAddress | CODE-BACKED | Customer IP address at time of withdrawal submission. |
| 5 | GCID | Customer.Customer.GCID | CODE-BACKED | Global Customer ID (GCID) - the cross-system customer identifier. From Customer.Customer. |
| 6 | FundingID | Billing.WithdrawToFunding.FundingID | CODE-BACKED | Payment instrument ID. FK to Billing.Funding. |
| 7 | FundingTypeID | Billing.Funding.FundingTypeID | CODE-BACKED | Payment method type code (1=CreditCard, 2=Wire, etc.). From Billing.Funding. |
| 8 | CashoutStatusID | Billing.WithdrawToFunding.CashoutStatusID | CODE-BACKED | Current cashout status code. FK to Dictionary.CashoutStatus. |
| 9 | ProcessCurrencyID | Billing.WithdrawToFunding.ProcessCurrencyID | CODE-BACKED | Processing currency code. FK to Dictionary.Currency. |
| 10 | ManagerID | Billing.WithdrawToFunding.ManagerID | CODE-BACKED | BackOffice manager assigned to this payment order. FK to BackOffice.Manager. |
| 11 | WithdrawToFundingID | Billing.WithdrawToFunding.ID | CODE-BACKED | PK of the WithdrawToFunding record (echoed as WithdrawToFundingID for clarity). Same as @WTF_ID. |
| 12 | CashoutTypeID | Billing.WithdrawToFunding.CashoutTypeID | CODE-BACKED | Cashout type code. FK to Dictionary.CashoutType. |
| 13 | MatchStatusID | Billing.WithdrawToFunding.MatchStatusID | CODE-BACKED | Match status code for this payment order. FK to Dictionary.MatchStatus. |
| 14 | DepotID | Billing.WithdrawToFunding.DepotID | CODE-BACKED | Depot/bank assigned to process this cashout. FK to Billing.Depot. 0 = unassigned. |
| 15 | ProtocolMIDSettingsID | Billing.WithdrawToFunding.ProtocolMIDSettingsID | CODE-BACKED | Protocol MID settings ID governing routing for this cashout. FK to Billing.ProtocolMIDSettings. |
| 16 | CashoutModeID | Billing.WithdrawToFunding.CashoutModeID | CODE-BACKED | Cashout mode (manual vs automated entry). FK to Dictionary.CashoutMode. |
| 17 | FundingName | Dictionary.FundingType.Name | CODE-BACKED | Human-readable payment method name (e.g., "Credit Card", "Wire Transfer"). |
| 18 | CachoutType | Dictionary.CashoutType.CashoutTypeName | CODE-BACKED | Human-readable cashout type name (note: column alias has typo "Cachout"). |
| 19 | CachoutStatus | Dictionary.CashoutStatus.Name | CODE-BACKED | Human-readable cashout status name (note: column alias has typo "Cachout"). |
| 20 | Depot | ISNULL(Billing.Depot.Name, 'NA') | CODE-BACKED | Depot name, or 'NA' if no depot is assigned (DepotID=0). |
| 21 | Regulation | Dictionary.Regulation.Name | CODE-BACKED | Customer's designated regulatory framework name (e.g., "ASIC", "FCA"). From BackOffice.Customer.DesignatedRegulationID. |
| 22 | CashoutModeName | Dictionary.CashoutMode.CashoutModeName | CODE-BACKED | Human-readable cashout mode name (e.g., "Manual", "Automatic"). |
| 23 | Currency | Dictionary.Currency.Abbreviation | CODE-BACKED | ISO currency abbreviation for the processing currency (e.g., "USD", "EUR"). |
| 24 | MatchStatus | Dictionary.MatchStatus.Name | CODE-BACKED | Human-readable match status name for this payment order (fund matching state). |
| 25 | Country | Dictionary.Country.Name | CODE-BACKED | Customer's registered country name. From Customer.Customer.CountryID via Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WTF_ID | Billing.WithdrawToFunding.ID | Filter | Primary anchor for all joins |
| WTF.WithdrawID | Billing.Withdraw | INNER JOIN | Retrieves CID and IPAddress |
| BW.CID | Customer.Customer | INNER JOIN | Retrieves GCID and CountryID |
| BW.CID | BackOffice.Customer | INNER JOIN | Retrieves DesignatedRegulationID for regulation name |
| WTF.FundingID | Billing.Funding | INNER JOIN | Retrieves FundingTypeID |
| BF.FundingTypeID | Dictionary.FundingType | INNER JOIN | Resolves FundingTypeID to name |
| WTF.CashoutTypeID | Dictionary.CashoutType | INNER JOIN | Resolves CashoutTypeID to name |
| WTF.CashoutStatusID | Dictionary.CashoutStatus | INNER JOIN | Resolves CashoutStatusID to name |
| WTF.DepotID | Billing.Depot | LEFT JOIN | Resolves DepotID to name (optional - 0 returns 'NA') |
| BOC.DesignatedRegulationID | Dictionary.Regulation | INNER JOIN | Resolves regulation ID to name |
| WTF.CashoutModeID | Dictionary.CashoutMode | INNER JOIN | Resolves mode ID to name |
| WTF.ProcessCurrencyID | Dictionary.Currency | INNER JOIN | Resolves currency ID to abbreviation |
| WTF.MatchStatusID | Dictionary.MatchStatus | INNER JOIN | Resolves match status ID to name |
| CC.CountryID | Dictionary.Country | INNER JOIN | Resolves country ID to name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AnalyticsServiceUser | GRANT EXECUTE | Permission | Analytics service calls this for payout processing context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPayoutProcessData (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Customer.Customer (table - cross-schema)
├── Billing.Funding (table)
├── BackOffice.Customer (table - cross-schema)
├── Dictionary.FundingType (table - cross-schema)
├── Dictionary.CashoutType (table - cross-schema)
├── Dictionary.CashoutStatus (table - cross-schema)
├── Billing.Depot (table - optional LEFT JOIN)
├── Dictionary.Regulation (table - cross-schema)
├── Dictionary.CashoutMode (table - cross-schema)
├── Dictionary.Currency (table - cross-schema)
├── Dictionary.MatchStatus (table - cross-schema)
└── Dictionary.Country (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary source - anchored by @WTF_ID |
| Billing.Withdraw | Table | INNER JOINed for CID and IPAddress |
| Customer.Customer | Table | INNER JOINed for GCID and CountryID |
| Billing.Funding | Table | INNER JOINed for FundingTypeID |
| BackOffice.Customer | Table | INNER JOINed for DesignatedRegulationID |
| Dictionary.FundingType | Table | INNER JOINed for method name |
| Dictionary.CashoutType | Table | INNER JOINed for cashout type name |
| Dictionary.CashoutStatus | Table | INNER JOINed for status name |
| Billing.Depot | Table | LEFT JOINed for depot name |
| Dictionary.Regulation | Table | INNER JOINed for regulation name |
| Dictionary.CashoutMode | Table | INNER JOINed for mode name |
| Dictionary.Currency | Table | INNER JOINed for currency abbreviation |
| Dictionary.MatchStatus | Table | INNER JOINed for match status name |
| Dictionary.Country | Table | INNER JOINed for country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AnalyticsServiceUser | DB Security Principal | EXECUTE permission - analytics processing of payout data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: All joins except Billing.Depot are INNER JOINs - if any dictionary value is missing (e.g., an unmapped CashoutStatusID), the procedure returns 0 rows silently rather than raising an error. The AnalyticsServiceUser caller would need to handle this case. Column aliases "CachoutType" and "CachoutStatus" have a typo ("Cachout" instead of "Cashout") - preserved here as documented in the DDL.

---

## 8. Sample Queries

### 8.1 Get full context for a specific payment order
```sql
EXEC [Billing].[GetPayoutProcessData] @WTF_ID = 12345678
```

### 8.2 Find WTF IDs to investigate
```sql
-- Find recent payment orders in a specific status for testing
SELECT TOP 10 ID, WithdrawID, CashoutStatusID, DepotID, CreationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE CashoutStatusID = 1  -- pending
ORDER BY CreationDate DESC
```

### 8.3 Equivalent manual query showing the join pattern
```sql
SELECT
    WTF.WithdrawID, BW.CID, CC.GCID,
    FD.Name AS FundingName,
    DCOT.CashoutTypeName AS CachoutType,
    DCOS.Name AS CachoutStatus,
    ISNULL(BD.Name, 'NA') AS Depot,
    DR.Name AS Regulation,
    DCOM.CashoutModeName,
    DC.Abbreviation AS Currency,
    DMS.Name AS MatchStatus,
    DCNTY.Name AS Country
FROM Billing.WithdrawToFunding WTF WITH (NOLOCK)
INNER JOIN Billing.Withdraw BW WITH (NOLOCK) ON WTF.WithdrawID = BW.WithdrawID
INNER JOIN Customer.Customer CC WITH (NOLOCK) ON BW.CID = CC.CID
INNER JOIN Billing.Funding BF WITH (NOLOCK) ON WTF.FundingID = BF.FundingID
INNER JOIN BackOffice.Customer BOC WITH (NOLOCK) ON BW.CID = BOC.CID
INNER JOIN Dictionary.FundingType FD WITH (NOLOCK) ON BF.FundingTypeID = FD.FundingTypeID
INNER JOIN Dictionary.CashoutType DCOT WITH (NOLOCK) ON WTF.CashoutTypeID = DCOT.CashoutTypeID
INNER JOIN Dictionary.CashoutStatus DCOS WITH (NOLOCK) ON WTF.CashoutStatusID = DCOS.CashoutStatusID
LEFT JOIN Billing.Depot BD WITH (NOLOCK) ON WTF.DepotID = BD.DepotID AND WTF.DepotID > 0
INNER JOIN Dictionary.Regulation DR WITH (NOLOCK) ON DR.ID = BOC.DesignatedRegulationID
INNER JOIN Dictionary.CashoutMode DCOM WITH (NOLOCK) ON WTF.CashoutModeID = DCOM.CashoutModeID
INNER JOIN Dictionary.Currency DC WITH (NOLOCK) ON WTF.ProcessCurrencyID = DC.CurrencyID
INNER JOIN Dictionary.MatchStatus DMS WITH (NOLOCK) ON WTF.MatchStatusID = DMS.MatchStatusID
INNER JOIN Dictionary.Country DCNTY WITH (NOLOCK) ON CC.CountryID = DCNTY.CountryID
WHERE WTF.ID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPayoutProcessData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPayoutProcessData.sql*
