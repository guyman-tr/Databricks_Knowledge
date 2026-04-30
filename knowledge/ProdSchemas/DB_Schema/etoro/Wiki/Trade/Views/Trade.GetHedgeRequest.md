# Trade.GetHedgeRequest

> Direct passthrough view of Trade.HedgeRequest exposing all pending hedge open and close requests for exposure queries and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | HedgeID, RequestType (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetHedgeRequest is a direct SELECT from Trade.HedgeRequest with NOLOCK - no filtering, no JOINs. It exposes all pending hedge requests (open and close) exactly as stored in the base table. The view answers: "What hedge requests are currently pending at the hedge servers?"

The view exists as a named abstraction so procedures can reference GetHedgeRequest instead of HedgeRequest directly - enabling consistent use of NOLOCK and a single point of change if filtering or enrichment is added later. Trade.HedgeExposureAndRequestQuery and Trade.HedgeExposureWithNoRequests JOIN to this view to combine live hedge exposure with pending requests for reporting and validation.

Data flows: HedgeRequest rows are created by Trade.HedgeOpenRequestAdd (RequestType=1) and Trade.HedgeCloseRequestAdd (RequestType=2). Trade.HedgeOpen and Trade.HedgeClose DELETE rows after execution. The view reads the current state; no write path.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. All column logic is inherited from Trade.HedgeRequest. See Section 4 for element descriptions and Trade.HedgeRequest documentation for RequestType lifecycle (1=Open, 2=Close).

---

## 3. Data Overview

| HedgeID | RequestType | InstrumentID | HedgeServerID | Amount | IsBuy | Occurred | Meaning |
|---------|-------------|--------------|---------------|--------|-------|----------|---------|
| 16401124 | 1 | 2 | 24 | 25 | 0 | 2012-08-21 | Open request for GBP (Instrument 2), short, 25 units, hedge server 24. Pending execution. |
| 16401125 | 1 | 6 | 24 | 25 | 0 | 2012-08-21 | Open request for CHF (Instrument 6), short, same server and amount. |
| 16163232 | 2 | NULL | NULL | NULL | NULL | 2012-06-25 | Close request. Legacy row with minimal data - close requests often have NULL until filled by execution. |
| 16266568 | 2 | NULL | NULL | NULL | NULL | 2012-06-27 | Close request with RequestedEndForexRate=1567.52 (limit price for close). |
| 16266588 | 2 | NULL | NULL | NULL | NULL | 2012-06-27 | Another close request, RequestedEndForexRate=1570.65. |

**Selection criteria**: Mix of RequestType=1 (open) and RequestType=2 (close). Open requests show full instrument/server/amount; close requests show legacy/minimal patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeID | int | NO | - | CODE-BACKED | Primary key (part 1). Allocated by Internal.GetHedgeID. Identifies the hedge request; after execution becomes HedgeID in Trade.Hedge. Same for open and close. (From Trade.HedgeRequest) |
| 2 | RequestType | int | NO | - | CODE-BACKED | Primary key (part 2). 1=Open request, 2=Close request. CHECK enforces (1, 2). (From Trade.HedgeRequest) |
| 3 | CurrencyID | int | YES | - | CODE-BACKED | FK to Dictionary.Currency. Denomination currency. NULL for some legacy rows. (From Trade.HedgeRequest) |
| 4 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. Part of Trade.ProviderToInstrument. (From Trade.HedgeRequest) |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Tradeable instrument (e.g., 1=EUR/USD, 2=GBP). (From Trade.HedgeRequest) |
| 6 | HedgeServerID | int | YES | - | CODE-BACKED | FK to Trade.HedgeServer. Which hedge server processes this request. (From Trade.HedgeRequest) |
| 7 | Leverage | int | YES | - | CODE-BACKED | Leverage multiple (e.g., 400). (From Trade.HedgeRequest) |
| 8 | Amount | money | YES | - | CODE-BACKED | Position size in currency. (From Trade.HedgeRequest) |
| 9 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units. (From Trade.HedgeRequest) |
| 10 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count for broker execution. (From Trade.HedgeRequest) |
| 11 | NetProfit | money | YES | - | CODE-BACKED | P&L. NULL for open; populated on close when known. (From Trade.HedgeRequest) |
| 12 | InitForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Rate at open. NULL until hedge executed. (From Trade.HedgeRequest) |
| 13 | InitDateTime | datetime | YES | - | CODE-BACKED | When hedge was/will be opened. (From Trade.HedgeRequest) |
| 14 | LimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate. (From Trade.HedgeRequest) |
| 15 | StopRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate. (From Trade.HedgeRequest) |
| 16 | IsBuy | bit | YES | - | CODE-BACKED | 1=long, 0=short. Opposite of client position direction. (From Trade.HedgeRequest) |
| 17 | OrderID | varchar(50) | YES | - | CODE-BACKED | Broker order ID. Set after order sent. (From Trade.HedgeRequest) |
| 18 | EndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Actual close rate. (From Trade.HedgeRequest) |
| 19 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Requested close rate for limit/stop closes. (From Trade.HedgeRequest) |
| 20 | EndDateTime | datetime | YES | - | CODE-BACKED | When hedge was closed. (From Trade.HedgeRequest) |
| 21 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When the request was submitted. (From Trade.HedgeRequest) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK | Denomination currency. |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK (implicit) | Instrument-provider config. |
| HedgeServerID | Trade.HedgeServer | FK | Hedge server routing. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeExposureAndRequestQuery | reqView | LEFT JOIN / RIGHT JOIN | Combines exposure with pending requests. |
| Trade.HedgeExposureWithNoRequests | GHR | LEFT JOIN, EXISTS | Validates exposure when no requests exist. |
| Trade.HedgeExposureWithNoRequestsWithActiveParent | GHR | LEFT JOIN, EXISTS | Same validation with active parent. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeRequest (view)
└── Trade.HedgeRequest (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | FROM - direct passthrough SELECT * |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeExposureAndRequestQuery | Procedure | LEFT JOIN, RIGHT JOIN for exposure + requests |
| Trade.HedgeExposureWithNoRequests | Procedure | LEFT JOIN, EXISTS check |
| Trade.HedgeExposureWithNoRequestsWithActiveParent | Procedure | LEFT JOIN, EXISTS check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List pending open requests by hedge server
```sql
SELECT HedgeID, InstrumentID, HedgeServerID, Amount, IsBuy, Occurred
  FROM Trade.GetHedgeRequest WITH (NOLOCK)
 WHERE RequestType = 1
 ORDER BY HedgeServerID, Occurred;
```

### 8.2 Resolve request to instrument and provider
```sql
SELECT GHR.HedgeID, GHR.RequestType, PTI.PresentationCode, GHR.Amount, GHR.IsBuy,
       THS.HedgeServerName, GHR.Occurred
  FROM Trade.GetHedgeRequest GHR WITH (NOLOCK)
  JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON GHR.ProviderID = PTI.ProviderID AND GHR.InstrumentID = PTI.InstrumentID
  LEFT JOIN Trade.HedgeServer THS WITH (NOLOCK)
    ON GHR.HedgeServerID = THS.HedgeServerID
 WHERE GHR.RequestType = 1
 ORDER BY GHR.Occurred DESC;
```

### 8.3 Count requests by type and hedge server
```sql
SELECT RequestType, HedgeServerID, COUNT(*) AS RequestCount
  FROM Trade.GetHedgeRequest WITH (NOLOCK)
 GROUP BY RequestType, HedgeServerID
 ORDER BY RequestType, HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeRequest | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetHedgeRequest.sql*
