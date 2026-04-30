# Customer.CorrectDynamicsGaps

> Fills missing or stale financial aggregate data in Microsoft Dynamics CRM for a single customer by sending a combined customer profile and trading metrics XML message via SQL Server Service Broker.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to resync) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CorrectDynamicsGaps is a CRM data-repair procedure. It is called when Dynamics CRM is found to be missing or out-of-date for a specific customer - typically deposits, cashouts, positions, or profit figures that the standard DynamicsInsert omitted. The name "Gaps" refers to data gaps in Dynamics: fields that were never sent or were lost.

The procedure serves as a supplementary CRM sync: it first calls Customer.DynamicsInsert (which sends the full identity and compliance profile) and then sends a second, independent Service Broker message containing the financial trading aggregates (balance, PnL, deposits, cashouts, positions, lots, profit, commission, login count). The dual-send ensures Dynamics receives both the profile and the financials even if the original sync was partial.

It is typically triggered manually or by a maintenance job when a discrepancy between the eToro database and Dynamics CRM is detected. The hardcoded action 'INSERT' in the XML signals to the Dynamics consumer to create or overwrite the record, rather than partially update it.

---

## 2. Business Logic

### 2.1 Dual-Send CRM Correction Pattern

**What**: Two separate Dynamics payloads are sent for the same customer to cover both profile and financial data.

**Columns/Parameters Involved**: `@CID`, `Customer.DynamicsInsert`, `Service Broker`

**Rules**:
- Step 1: Calls Customer.DynamicsInsert @CID, 'INSERT' - sends the full identity/compliance XML (see Customer.DynamicsInsert for its payload structure)
- Step 2: Builds a second XML (FOR XML RAW('Trade')) containing only the financial trading aggregates and sends it separately to 'svcDynamics'
- Both messages use the same Service Broker infrastructure (BEGIN DIALOG ... FROM svcInitiator TO svcDynamics ON CONTRACT ctrAnyXMLData)
- Hardcoded action 'INSERT' tells Dynamics to create or replace, not delta-update
- If @CID IS NULL: returns immediately with no action

**Diagram**:
```
CorrectDynamicsGaps(@CID)
  |
  +--> EXEC Customer.DynamicsInsert(@CID, 'INSERT')
  |      Sends: full profile (identity, compliance, affiliate, KYC)
  |
  +--> BUILD XML (FOR XML RAW('Trade'))
  |      Source: Customer.Customer + BackOffice.CustomerAllTimeAggregatedData
  |      + BackOffice.GetUnrealizedPnL + BackOffice.GetUsedMargin
  |
  +--> SEND via Service Broker -> svcDynamics
         Delivers: financial aggregates (balance, PnL, positions, lots, etc.)
```

### 2.2 OriginalProviderID Normalization (Legacy Pattern)

**What**: Resolves OriginalProviderID before sending, handling legacy registration edge cases.

**Columns/Parameters Involved**: `OriginalProviderID`, `OriginalCID`, `IsReal`, `Registered`

**Rules**:
- If OriginalProviderID > 1: use as-is (valid affiliate provider)
- Else if OriginalCID = CID (self-referral): use IsReal as sentinel (1 or 0)
- Else if Registered < 2007-10-02 (pre-affiliate-program): use IsReal as sentinel
- Else: use OriginalProviderID (0 or 1 pass-through)
- Note: using IsReal as a fallback for OriginalProviderID is a legacy pattern from before the affiliate system was established

### 2.3 Equity Calculation

**What**: Calculates real-time equity as part of the XML payload.

**Columns/Parameters Involved**: `Credit`, `UnrealizedPnL`, `UsedMargin`

**Rules**:
- Equity = (Credit * 100 + BackOffice.GetUnrealizedPnL(CID) + BackOffice.GetUsedMargin(CID)) / 100.0
- All three BackOffice functions return values in cents; division by 100 converts to dollars for Dynamics
- UnrealizedPnL and UsedMargin are computed at call time (live snapshot), not from stored aggregates

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES (guard) | - | CODE-BACKED | Customer ID to resync to Dynamics. If NULL, the procedure returns immediately without action. Used to query Customer.Customer and BackOffice.CustomerAllTimeAggregatedData for XML construction. |

**XML payload sent to Dynamics (FOR XML RAW('Trade') output fields):**

| XML Field | Source | Business Meaning |
|-----------|--------|-----------------|
| Action | Hardcoded 'INSERT' | Signals Dynamics consumer to create or overwrite the record |
| CustomerName | Customer.Customer.UserName | Customer login name |
| CID | @CID | Customer identifier |
| TradingAccountID | @CID | Same as CID - single account per customer in this flow |
| OriginalCID | Customer.Customer.OriginalCID | Original referring customer CID |
| OriginalProviderID | CASE-normalized (see 2.2) | Affiliate provider who acquired the customer |
| ProviderID | Customer.Customer.ProviderID | Current provider assignment |
| Balance | Customer.Customer.Credit | Customer account balance |
| UnrealizedPnL | BackOffice.GetUnrealizedPnL / 100.0 | Open position floating PnL in dollars |
| UsedMargin | BackOffice.GetUsedMargin / 100.0 | Margin locked by open positions in dollars |
| Equity | (Credit*100 + UnrealizedPnL_cents + UsedMargin_cents) / 100.0 | Total account value: balance + unrealized PnL + margin |
| Deposits | BackOffice.CustomerAllTimeAggregatedData.TotalDeposit | Lifetime total deposits |
| Cashouts | BackOffice.CustomerAllTimeAggregatedData.TotalCashout | Lifetime total cashouts |
| Bonuses | BackOffice.CustomerAllTimeAggregatedData.TotalBonus | Lifetime total bonuses received |
| Compensations | BackOffice.CustomerAllTimeAggregatedData.TotalCompensation | Lifetime total compensations received |
| PositionsCount | BackOffice.CustomerAllTimeAggregatedData.TotalPositionCount | Lifetime total positions opened |
| Lots | BackOffice.CustomerAllTimeAggregatedData.TotalLot | Lifetime total trading volume in lots |
| Profit | BackOffice.CustomerAllTimeAggregatedData.TotalProfit | Lifetime realized profit/loss |
| Commission | BackOffice.CustomerAllTimeAggregatedData.TotalCommission | Lifetime total commissions paid |
| NumOfLogins | BackOffice.CustomerAllTimeAggregatedData.TotalLoginCount | Lifetime login count |
| RegistartionDate | Customer.Customer.Registered | Customer registration date (note: typo in XML field name) |
| RealDB | Customer.Customer.IsReal | 1 = real environment, 0 = demo |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.DynamicsInsert | EXEC | Calls DynamicsInsert as first step to send profile payload |
| @CID | Customer.Customer | Read (JOIN) | Reads customer profile: UserName, Credit, ProviderID, OriginalCID, OriginalProviderID, IsReal, Registered |
| @CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN (read) | Reads lifetime financial aggregates: deposits, cashouts, positions, lots, profit |
| CID | BackOffice.GetUnrealizedPnL | Function call | Live unrealized PnL in cents |
| CID | BackOffice.GetUsedMargin | Function call | Live used margin in cents |
| svcDynamics | SQL Server Service Broker | Message target | CRM sync message destination (async) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CRM_TS (SQL login/role) | EXECUTE | Permission | CRM maintenance role has execute permission |
| PROD_BIadmins (SQL role) | EXECUTE | Permission | BI admin role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CorrectDynamicsGaps (procedure)
├── Customer.DynamicsInsert (procedure)
│     ├── Maintenance.Feature (table - cross-schema)
│     ├── Customer.Customer (view)
│     ├── BackOffice.Customer (table - cross-schema)
│     ├── BackOffice.Affiliate (table - cross-schema)
│     ├── dbo.DemoCustomers (synonym - linked server)
│     ├── dbo.RealCustomers (synonym - linked server)
│     └── Internal.GetCountryIDByIP (function - cross-schema)
├── Customer.Customer (view)
├── BackOffice.CustomerAllTimeAggregatedData (table - cross-schema)
├── BackOffice.GetUnrealizedPnL (function - cross-schema)
├── BackOffice.GetUsedMargin (function - cross-schema)
└── svcDynamics (Service Broker service)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.DynamicsInsert | Procedure | Called as first step; sends full identity/compliance profile to Dynamics |
| Customer.Customer | View | Customer profile data for XML (UserName, Credit, OriginalCID, etc.) |
| BackOffice.CustomerAllTimeAggregatedData | Table | Lifetime financial aggregates (deposits, positions, profit, etc.) |
| BackOffice.GetUnrealizedPnL | Function | Real-time unrealized PnL for equity calculation |
| BackOffice.GetUsedMargin | Function | Real-time used margin for equity calculation |

### 6.2 Objects That Depend On This

No dependents found (called externally via maintenance jobs or direct execution by CRM/BI roles).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL guard | Input validation | IF @CID IS NULL RETURN - prevents accidental full-scan execution |
| FOR XML RAW('Trade'), BINARY BASE64, ELEMENTS, TYPE | XML generation | Element-centric XML with base64 binary encoding, element name = 'Trade' |
| Service Broker async | Delivery pattern | Fire-and-forget: returns after enqueue; Dynamics processing is asynchronous |

---

## 8. Sample Queries

### 8.1 Resync a specific customer's Dynamics record

```sql
EXEC Customer.CorrectDynamicsGaps @CID = 12345678
-- Sends both DynamicsInsert profile + financial aggregate XML to svcDynamics
```

### 8.2 Check if a customer has financial aggregate data available

```sql
SELECT CID, TotalDeposit, TotalCashout, TotalPositionCount, TotalProfit
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE CID = 12345678
-- Verify aggregates exist before triggering CorrectDynamicsGaps
```

### 8.3 Check Service Broker queue for pending messages sent by this procedure

```sql
SELECT TOP 10
    queuing_order,
    message_type_name,
    CAST(message_body AS VARCHAR(MAX)) AS MessageBody
FROM svcDynamics WITH (NOLOCK)
ORDER BY queuing_order DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CorrectDynamicsGaps | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.CorrectDynamicsGaps.sql*
