# BackOffice.NewRiskAlertsPCIVersion

> Generates the Risk Alerts report for the BackOffice risk team, returning deposit records enriched with customer data, funding details, 3DS fraud signals, and acceptance status - with dynamic multi-filter SQL for all optional filter parameters.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from Billing.Deposit with multi-table JOIN; dynamic SQL via sp_executesql |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.NewRiskAlertsPCIVersion` powers the Risk Alerts screen in the BackOffice UI. It surfaces deposit activity for risk team review - showing each deposit alongside the customer's risk status, fraud indicators (3DS data), funding method, acceptance status, and biographical information. Risk analysts use this report to identify suspicious deposits, match funding details against customer identity, and make accept/reject decisions.

The "PCI Version" suffix indicates this procedure has been redacted of raw card data that would require PCI-DSS protection. Raw card numbers and CVVs are excluded; only non-sensitive identifiers (BIN code, card category) are exposed. This allows the report to run in environments with standard security without triggering PCI audit scope.

The procedure uses dynamic SQL (`sp_executesql`) to construct a WHERE clause from up to 8 optional filter parameters (regulation, white label, funding type, payment status, player status, etc.). Each filter, when provided as a comma-delimited string, is split into a temp table and joined as INNER JOIN to narrow results. Filters not provided are omitted entirely (not as optional WHERE clauses, but as absent JOINs), improving query plan efficiency.

Change history from code comments: added RiskStatusIDs parameter (Jul 2019, Adi), added 3DS info from Billing.Trace JSON (Aug 2019, Ran/Adi), extracted PaymentDetails to a view (Apr 2020, Adi), added iDEAL/Trustly details (Jun/Aug 2020).

---

## 2. Business Logic

### 2.1 Dynamic Filter Architecture

**What**: Optional multi-value filters are implemented as dynamically added INNER JOINs, not WHERE clauses, to minimize rows processed.

**Columns/Parameters Involved**: `@RegulationIDs`, `@WhiteLabels`, `@FundingTypeIDs`, `@PaymentStatusIDs`, `@PlayerStatusIDs`, `@DesignatedRegulationIDs`, `@AcceptanceStatusIDs`, `@RiskStatusIDs`

**Rules**:
- Each filter parameter is a comma-delimited NVARCHAR(250) string (e.g., "1,5,7").
- If provided: STRING_SPLIT into a temp table (#FundingTypeIDs, etc.) then INNER JOIN appended to dynamic SQL.
- If NULL: the JOIN is omitted (not as IS NULL filter - fully absent from query plan).
- @RiskStatusIDs uses a special CROSS APPLY against BackOffice.CustomerRisk with a check for active risk events (Dictionary.RiskEventStatus.IsActive=1).
- @IgnorePlayerLevelID filters out customers at a specific player level (e.g., exclude demo or test accounts).
- @IsOnlyFTD filters to First-Time Deposits only (IsFTD=1).

**Diagram**:
```
Base SQL (always present):
  Billing.Deposit BDEP
  JOIN Customer.Customer CCST
  JOIN BackOffice.Customer BCST
  JOIN Dictionary.Currency
  OUTER APPLY BackOffice.GetUserRisksByCID
  LEFT JOINs for country, last login, funding, card type, etc.

Dynamic additions (when parameter is non-NULL):
  + INNER JOIN #RegulationIDs R on R.ID = BCST.RegulationID
  + INNER JOIN #WhiteLabels WL on WL.ID = CCST.LabelID
  + INNER JOIN #FundingTypeIDs FT on FT.ID = BLFN.FundingTypeID
  + INNER JOIN #PaymentStatusIDs PSI on PSI.ID = BDEP.PaymentStatusID
  + INNER JOIN #PlayerStatusIDs PLSI on PLSI.ID = CCST.PlayerStatusID
  + INNER JOIN #DesignatedRegulationIDs DRI on DRI.ID = BCST.DesignatedRegulationID
  + CROSS APPLY (CustomerRisk filter with active risk status)
  + INNER JOIN #AcceptanceStatusIDs ASI on ASI.ID = BCST.AcceptanceStatusID

Fixed WHERE: ModificationDate BETWEEN @StartDate AND @EndDate
Optional WHERE additions: AND IsFTD=1 (if @IsOnlyFTD), AND PlayerLevelID <> @IgnorePlayerLevelID
```

### 2.2 3DS Fraud Signal Extraction

**What**: Extracts 3D Secure authentication parameters from Billing.Trace JSON blobs for fraud risk analysis.

**Columns/Parameters Involved**: `[3ds parameters]`, `[3DS External ID]`, `[3ds response]`

**Rules**:
- Billing.Trace is joined via OUTER APPLY (TOP 1) filtered to TransactionType=0 and EventType in (1,2).
- EventType 1 extracts CAVV, ECI, XID from JSON path $.Cavv/$.EciFlag/$.Xid.
- EventType 2 extracts from nested path $.Payload.Payment.ExtendedData.*.
- 3DS External ID: EventType=1 from $.TransactionId; EventType=2 from $.Payload.Payment.ProcessorTransactionId.
- Dictionary.ThreeDsResponseTypes provides human-readable 3DS response description via BDEP.PaymentData XML.

### 2.3 Payment Details Construction

**What**: Payment details column varies by funding type, extracting relevant identifiers from the PaymentData XML/JSON blob.

**Rules**:
- FundingTypeID 2 (Wire/IBAN): extracts IBANCodeAsString.
- FundingTypeID 33: concatenates CardID + FundingDetails + GCID from PaymentData XML.
- FundingTypeID 34 (Trustly): BicCode + Iban + BankName + AccountHolderName.
- FundingTypeID 35: BicCode + IBAN + AccountHolderName.
- Default: uses Billing.FundingPaymentDetailsForDeposit.FundingDetails (a view).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Start of the ModificationDate range for deposits to include. Required. Applied as `ModificationDate BETWEEN @StartDate AND @EndDate` on Billing.Deposit. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | End of the ModificationDate range. Required. |
| 3 | @IgnorePlayerLevelID | int | YES | 0 | CODE-BACKED | Player level to exclude from results. Default 0 (no exclusion, since 0 is typically not a valid PlayerLevelID). Used to filter out demo/test accounts. Applied as AND PlayerLevelID <> @IgnorePlayerLevelID. |
| 4 | @IsOnlyFTD | bit | YES | NULL | CODE-BACKED | If 1: return only First-Time Deposit records (IsFTD=1). NULL or 0: include all deposits. FTD flag is a key risk indicator - first deposits from new customers warrant higher scrutiny. |
| 5 | @WhiteLabels | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of LabelIDs to filter by. When provided, only deposits from customers with those white-label brand assignments are returned. INNER JOIN added to query. |
| 6 | @FundingTypeIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of FundingTypeIDs (e.g., "1,2,29" for CC, Wire, Plaid). Filters to specific payment methods. INNER JOIN on Billing.FundingPaymentDetailsForDeposit. |
| 7 | @PaymentStatusIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of Billing.Deposit PaymentStatusIDs to include. Filters to specific deposit states (e.g., pending, approved, chargeback). |
| 8 | @PlayerStatusIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of player statuses (Customer.Customer.PlayerStatusID). Allows filtering by customer trading status (active, blocked, closed, etc.). |
| 9 | @RegulationIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of regulation IDs (BackOffice.Customer.RegulationID). Filters by the regulatory regime under which the customer is registered (e.g., Cyprus, Australia, UK). |
| 10 | @DesignatedRegulationIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of designated regulation IDs (BackOffice.Customer.DesignatedRegulationID). The designated regulation may differ from the registration regulation for compliance routing purposes. |
| 11 | @AcceptanceStatusIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of AcceptanceStatusIDs (BackOffice.Customer.AcceptanceStatusID). Acceptance status reflects manual review decisions by the risk team (accepted, rejected, pending review). |
| 12 | @RiskStatusIDs | nvarchar(250) | YES | NULL | CODE-BACKED | Comma-delimited list of RiskStatusIDs from BackOffice.CustomerRisk. Filters to customers who have active risk events matching the specified risk status types. Uses CROSS APPLY with Dictionary.RiskEventStatus.IsActive=1 check. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Base query | Billing.Deposit | Reader | Primary data source - deposit records being reviewed |
| Base query | Customer.Customer | Reader | Customer identity data (name, email, IP, country, status) |
| Base query | BackOffice.Customer | Reader | BackOffice metadata (acceptance status, regulation, verification) |
| Outer apply | BackOffice.GetUserRisksByCID | Function callee | Risk status names aggregated per customer |
| Base query | Billing.Trace | Reader | 3DS fraud signal extraction via JSON parsing |
| Base query | History.LoginArch | Reader | Last login IP for geographic risk analysis |
| Base query | BackOffice.CustomerAllTimeAggregatedData | Reader | Total deposit amount per customer |
| Filter | BackOffice.CustomerRisk | Reader (CROSS APPLY) | Active risk event filter when @RiskStatusIDs provided |
| Filter | Dictionary.RiskEventStatus | Reader | Active flag check for customer risk events |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice UI Risk Alerts screen.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.NewRiskAlertsPCIVersion (procedure)
+-- Billing.Deposit (table)
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- BackOffice.GetUserRisksByCID (function) [OUTER APPLY]
+-- BackOffice.CustomerAllTimeAggregatedData (view)
+-- BackOffice.LastCustomerInfo (table)
+-- BackOffice.Manager (table) [acceptance manager name]
+-- BackOffice.CustomerRisk (table) [conditional filter]
+-- Billing.Trace (table) [3DS signals]
+-- Billing.FundingPaymentDetailsForDeposit (view)
+-- History.LoginArch (table) [last login IP]
+-- Dictionary.* (multiple lookup tables)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source - deposit records |
| Customer.Customer | Table | Customer identity and status |
| BackOffice.Customer | Table | Regulation, acceptance status, verification level |
| BackOffice.GetUserRisksByCID | Function | OUTER APPLY - aggregated risk status names |
| BackOffice.CustomerAllTimeAggregatedData | View | Total deposit amount |
| BackOffice.LastCustomerInfo | Table | Last login reference |
| BackOffice.Manager | Table | Acceptance manager name |
| BackOffice.CustomerRisk | Table | Active risk event filter |
| Billing.Trace | Table | 3DS fraud parameter extraction |
| Billing.FundingPaymentDetailsForDeposit | View | Funding details and payment method data |
| History.LoginArch | Table | Last login IP |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses dynamic SQL (sp_executesql) to build the final query. Executed WITH EXECUTE AS OWNER context is not set on this procedure (unlike P_GetConnectionStringsWithGroups).

---

## 8. Sample Queries

### 8.1 Get all risk alerts for a date range (no filters)

```sql
EXEC BackOffice.NewRiskAlertsPCIVersion
    @StartDate = '2026-03-17',
    @EndDate = '2026-03-18',
    @IgnorePlayerLevelID = 0,
    @IsOnlyFTD = NULL,
    @WhiteLabels = NULL,
    @FundingTypeIDs = NULL,
    @PaymentStatusIDs = NULL,
    @PlayerStatusIDs = NULL,
    @RegulationIDs = NULL,
    @DesignatedRegulationIDs = NULL,
    @AcceptanceStatusIDs = NULL,
    @RiskStatusIDs = NULL;
```

### 8.2 Get first-time deposit risk alerts for credit card only

```sql
EXEC BackOffice.NewRiskAlertsPCIVersion
    @StartDate = '2026-03-17',
    @EndDate = '2026-03-18',
    @IsOnlyFTD = 1,
    @FundingTypeIDs = '1';  -- 1 = Credit Card
```

### 8.3 Get risk alerts filtered by specific regulations and acceptance status

```sql
EXEC BackOffice.NewRiskAlertsPCIVersion
    @StartDate = '2026-03-17',
    @EndDate = '2026-03-18',
    @RegulationIDs = '1,3,5',
    @AcceptanceStatusIDs = '1,2';  -- Pending/Needs Review statuses
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Test plan - OPS0501 - Risk Alert screen optimization](https://etoro-jira.atlassian.net/pages/viewpageattachments.action?pageId=776568844) | Confluence attachment | Confirms this SP is the Risk Alert screen data source; mentions multiple customer risk status support and triggers from billing/RRE (MEDIUM confidence - test plan attachment from 2020) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.NewRiskAlertsPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.NewRiskAlertsPCIVersion.sql*
