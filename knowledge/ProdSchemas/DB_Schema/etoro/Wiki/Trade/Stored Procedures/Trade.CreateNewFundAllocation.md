# Trade.CreateNewFundAllocation

> Creates a new investment fund with its interval and allocation configuration, supporting both instrument-based (direct asset) and copy-based (CopyTrader) allocation types in a single transactional operation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FundIntervalAllocationID via result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CreateNewFundAllocation creates a new managed investment fund (or "Smart Portfolio" / "CopyPortfolio") including its definition, time interval, and allocation rules. eToro's fund product allows users to create portfolios that allocate capital across instruments (stocks, ETFs, crypto) or across other traders (via CopyTrader), with defined investment percentages, stop-loss, take-profit, and leverage settings.

This procedure is the entry point for fund creation. Without it, no new funds could be created in the system. It supports the SSRS reporting workflow (indicated by the @DoSelectAtEnd parameter added for dbo.SSRS_Trade_CreateNewFundAllocation) and the programmatic fund creation API.

The procedure creates three linked records in a single transaction: (1) a Trade.Fund record defining the fund name, owner, and properties, (2) a Trade.FundInterval record defining the time period (start/end dates), and (3) a Trade.FundIntervalAllocation record defining what the fund invests in (instrument or copied trader). All three use NOT EXISTS guards to prevent duplicates.

---

## 2. Business Logic

### 2.1 Dual Allocation Types

**What**: Fund allocations can target either a specific financial instrument or another trader (for copy-trading).

**Columns/Parameters Involved**: `@AllocationType`, `@InstrumentSymbol`, `@ParentUserName`

**Rules**:
- AllocationType determines the allocation mode (1 = default)
- If @InstrumentSymbol is provided: resolves InstrumentID from Trade.InstrumentMetaData by SymbolFull; requires @InvestmentPct, @StopLossPct, @TakeProfitPct, @IsBuy, @Leverage
- If @ParentUserName is provided: resolves ParentCID from Customer.Customer by UserName; requires @InvestmentPct, @OpenOpen, @StopLossPct
- Both @InstrumentID and @ParentCID cannot be NULL simultaneously (validated with RAISERROR)

### 2.2 Idempotent Insert Guards

**What**: All three INSERT statements use NOT EXISTS checks to prevent duplicate records.

**Columns/Parameters Involved**: Fund.FundName+FundAccountID, FundInterval.FundID+dates, FundIntervalAllocation composite key

**Rules**:
- Fund: unique by FundName (case-insensitive) + FundAccountID (CID)
- FundInterval: unique by FundID + PlannedStart + PlannedEnd
- FundIntervalAllocation: unique by FundIntervalID + InstrumentID/ParentCID combination
- If the fund already exists, subsequent inserts use the existing FundID

**Diagram**:
```
Trade.Fund (1)
    |
    +-- Trade.FundInterval (1:N)
          |
          +-- Trade.FundIntervalAllocation (1:N)
                +-- InstrumentID (direct asset) OR
                +-- ParentCID (copy-trade)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundName | NVARCHAR(255) | NO | - | CODE-BACKED | Display name for the fund/portfolio. Must be unique per CID (case-insensitive check). |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID who owns the fund account. Validated against Customer.Customer. Also used as FundAccountID. |
| 3 | @FundOwnerID | INT | YES | NULL | CODE-BACKED | Fund owner/manager CID. Defaults to @CID if NULL. Allows a different user to manage the fund on behalf of the account holder. |
| 4 | @RefreshIntervalMonths | INT | NO | - | CODE-BACKED | How often the fund rebalances its allocations, in months. |
| 5 | @IsPublic | BIT | YES | 0 | CODE-BACKED | Whether the fund is visible to other users for copying. 0 = private, 1 = public/discoverable. |
| 6 | @HasCrypto | BIT | YES | 1 | CODE-BACKED | Whether the fund includes cryptocurrency allocations. Default 1 (includes crypto). May affect regulatory treatment. |
| 7 | @MinCopyAmount | MONEY | YES | NULL | CODE-BACKED | Minimum amount another user must invest to copy this fund. NULL means no minimum. |
| 8 | @FundIntervalType | TINYINT | YES | 1 | CODE-BACKED | Type of interval period. Default 1. Determines rebalancing behavior. |
| 9 | @StartDateStr | NVARCHAR(20) | NO | - | CODE-BACKED | Interval start date as string in DD/MM/YYYY format (converted via style 103). |
| 10 | @EndDateStr | NVARCHAR(20) | NO | - | CODE-BACKED | Interval end date as string in DD/MM/YYYY format. |
| 11 | @AllocationType | TINYINT | YES | 1 | CODE-BACKED | Allocation mode: determines whether this allocation targets an instrument or a copied trader. Default 1. |
| 12 | @InstrumentSymbol | NVARCHAR(20) | YES | NULL | CODE-BACKED | Full instrument symbol (e.g., "AAPL", "BTC"). Resolved to InstrumentID via Trade.InstrumentMetaData.SymbolFull. NULL if this is a copy allocation. |
| 13 | @ParentUserName | VARCHAR(20) | YES | NULL | CODE-BACKED | Username of the trader to copy. Resolved to ParentCID via Customer.Customer.UserName. NULL if this is an instrument allocation. |
| 14 | @InvestmentPct | DECIMAL(16,8) | NO | - | CODE-BACKED | Percentage of fund capital allocated to this instrument/trader. |
| 15 | @StopLossPct | DECIMAL(16,8) | NO | - | CODE-BACKED | Stop-loss percentage threshold. When losses reach this percentage, the allocation is closed. |
| 16 | @TakeProfitPct | DECIMAL(16,8) | NO | - | CODE-BACKED | Take-profit percentage threshold. When gains reach this percentage, the allocation is closed. |
| 17 | @OpenOpen | BIT | YES | NULL | CODE-BACKED | For copy allocations: whether to copy positions that are already open when the copy starts. 1 = copy existing open positions, 0 = only copy new positions. |
| 18 | @IsBuy | BIT | YES | NULL | CODE-BACKED | For instrument allocations: trade direction. 1 = buy/long, 0 = sell/short. Required for instrument allocations. |
| 19 | @Leverage | INT | YES | NULL | CODE-BACKED | For instrument allocations: leverage multiplier. Required for instrument allocations. |
| 20 | @DoSelectAtEnd | BIT | YES | 1 | CODE-BACKED | Controls whether to return the created records as a result set. 1 = return (used by SSRS reports), 0 = silent. Added 2017-02-07 for dbo.SSRS_Trade_CreateNewFundAllocation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Fund INSERT | Trade.Fund | Writer | Creates the fund definition record |
| Interval INSERT | Trade.FundInterval | Writer | Creates the fund time interval record |
| Allocation INSERT | Trade.FundIntervalAllocation | Writer | Creates the allocation (instrument or copy) record |
| CID validation | Customer.Customer | Lookup | Validates @CID exists and resolves @ParentUserName to CID |
| Symbol resolution | Trade.InstrumentMetaData | Lookup | Resolves @InstrumentSymbol to InstrumentID via SymbolFull |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SSRS_Trade_CreateNewFundAllocation | Caller | Consumer | SSRS reporting wrapper that calls this procedure with @DoSelectAtEnd=1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CreateNewFundAllocation (procedure)
+-- Trade.Fund (table)
+-- Trade.FundInterval (table)
+-- Trade.FundIntervalAllocation (table)
+-- Customer.Customer (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Fund | Table | INSERT target for fund definition |
| Trade.FundInterval | Table | INSERT target for fund interval |
| Trade.FundIntervalAllocation | Table | INSERT target + final SELECT for result set |
| Customer.Customer | Table | CID validation and ParentCID resolution |
| Trade.InstrumentMetaData | Table | InstrumentSymbol to InstrumentID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SSRS_Trade_CreateNewFundAllocation | Stored Procedure | SSRS report wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check existing funds for a customer
```sql
SELECT FundID, FundName, FundAccountID, FundOwnerID, IsPublic, RefreshIntervalMonths
FROM   Trade.Fund WITH (NOLOCK)
WHERE  FundAccountID = 12345
```

### 8.2 View fund intervals and allocations
```sql
SELECT f.FundName, fi.PlannedStart, fi.PlannedEnd,
       fia.AllocationType, fia.InstrumentID, fia.ParentCID, fia.InvestmentPct
FROM   Trade.FundIntervalAllocation fia WITH (NOLOCK)
       JOIN Trade.FundInterval fi WITH (NOLOCK) ON fia.FundIntervalID = fi.FundIntervalID
       JOIN Trade.Fund f WITH (NOLOCK) ON fi.FundID = f.FundID
WHERE  f.FundAccountID = 12345
```

### 8.3 Resolve instrument symbol to ID
```sql
SELECT InstrumentID, SymbolFull, InstrumentTypeID
FROM   Trade.InstrumentMetaData WITH (NOLOCK)
WHERE  UPPER(SymbolFull) = 'AAPL'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CreateNewFundAllocation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CreateNewFundAllocation.sql*
