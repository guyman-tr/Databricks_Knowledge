# BI_DB_dbo.BI_DB_TicketsForOPS_NEW

> 105-row operational ticket tracking table combining wire deposit pool tickets and rejected-approved cashout tickets for OPS teams, enriched with Customer Support case details and agent assignments. Sourced from Fivetran Google Sheets (wires) + BI_DB_HourlyReport_Withdraws (cashouts) + BI_OUTPUT Customer Support system via SP_TicketsForOPSNEW. Daily TRUNCATE+INSERT refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Fivetran Google Sheets (wires) + BI_DB_HourlyReport_Withdraws (cashouts) + BI_OUTPUT Customer Support via SP_TicketsForOPSNEW |
| **Refresh** | Daily (TRUNCATE+INSERT, no @Date parameter, full replace) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not in Generic Pipeline mapping — may not be exported to UC_ |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_TicketsForOPS_NEW` is a small operational table (105 rows) that consolidates active ticket work for Operations teams into a single view. It combines two ticket sources:

1. **Wires team** (82 rows): Wire deposit transactions from a Fivetran-synced Google Sheet (`wire_deposits_ops`) where the status contains 'Pool' — indicating unidentified or pending wire deposits that need manual OPS intervention.
2. **Cashouts team** (23 rows): Rejected but previously approved withdrawal requests from `BI_DB_HourlyReport_Withdraws`, enriched with case numbers from `Billing.WithdrawRejects`.

Both sources are matched to Customer Support tickets via CaseNumber/ticket_number, then enriched with ticket metadata (status, type, priority, product) from the BI_OUTPUT Customer Support Case system, and agent details (name, department, team) from the Agent User table. A ROW_NUMBER deduplication ensures only the latest version of each case is kept.

The table covers tickets from March 2021 to April 2024. The small row count reflects that this is an active-work queue (current items), not a historical archive. TRUNCATE+INSERT means the full table is replaced daily.

---

## 2. Business Logic

### 2.1 Wire Ticket Selection

**What**: Wire deposits in 'Pool' status from Google Sheets.
**Columns Involved**: `Status`, `Team`
**Rules**:
- Source: `External_Fivetran_google_sheets_wire_deposits_ops`
- Filter: `status LIKE '%Pool%'` AND `ISNUMERIC(ticket_number) = 1`
- CID cleanup: 'NA' and 'N/A' converted to NULL, then CAST to INT
- Excludes specific CID patterns (e.g., '%15716479574216%', '%?%')
- Team = 'Wires'

### 2.2 Cashout Ticket Selection

**What**: Rejected withdrawals that were previously approved.
**Columns Involved**: `Status`, `Team`
**Rules**:
- Source: `BI_DB_HourlyReport_Withdraws` WHERE `CashoutStatus = 'Rejected' AND Approved = 1`
- Ticket number from `Billing.WithdrawRejects.CaseNumber`
- Team = 'Cashouts'

### 2.3 Ticket Deduplication

**What**: Only the most recent version of each ticket is kept.
**Columns Involved**: All
**Rules**:
- `ROW_NUMBER() OVER(PARTITION BY CaseNumber ORDER BY CreatedDate DESC)` → RN=1

### 2.4 Assigned Agent Name

**What**: Agent full name assembled from first and last name.
**Columns Involved**: `AssignedTo`
**Rules**:
- `us.FirstName + ' ' + us.LastName` from Customer_Support_Agent_User
- NULL if no agent assigned (LEFT JOIN)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. Very small table (105 rows) — all queries are instant.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Open wire tickets | `WHERE Team = 'Wires'` |
| Rejected cashout tickets | `WHERE Team = 'Cashouts'` |
| Tickets by department | `GROUP BY Department` |
| Unassigned tickets | `WHERE AssignedTo IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer details for ticket holders |

### 3.4 Gotchas

- **CID can be NULL**: Wire deposits with 'NA'/'N/A' CID are converted to NULL
- **Type column is unpopulated**: The SP's INSERT statement skips the Type column — it will always be NULL in current data
- **Status vs TicketStatus**: Two different status columns — Status is the wire/cashout operational status ('Pool / Client', 'Rejected'), TicketStatus is the CS ticket status ('On-hold', 'Closed', 'New')
- **Small and volatile**: 105 rows today, fully replaced daily — historical analysis is not possible from this table alone

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | ETL metadata | Standard ETL infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Wire: CAST from string with NA/N/A→NULL; Cashout: passthrough from BI_DB_HourlyReport_Withdraws. (Tier 1 — Customer.CustomerStatic) |
| 2 | Ticket Number | bigint | YES | Customer Support case number. Wire: from google_sheets_wire_deposits_ops.ticket_number (filtered ISNUMERIC=1); Cashout: from Billing.WithdrawRejects.CaseNumber. Used as join key to CS case system. (Tier 2 — SP_TicketsForOPSNEW) |
| 3 | CreatedDate | datetime | YES | Ticket creation timestamp from the Customer Support Case system (BI_OUTPUT). (Tier 2 — SP_TicketsForOPSNEW) |
| 4 | TicketStatus | nvarchar(max) | YES | Customer Support ticket status from the Case system. Values include: 'On-hold', 'Closed', 'In Routing', 'New', 'Solved'. Distinct from operational Status column. (Tier 2 — SP_TicketsForOPSNEW) |
| 5 | Type | nvarchar(max) | YES | Ticket type from Customer Support Case system. Currently unpopulated — the SP INSERT statement does not include this column. (Tier 2 — SP_TicketsForOPSNEW) |
| 6 | Priority | nvarchar(max) | YES | Ticket priority from Customer Support Case system. Observed values: 'High', 'Normal'. (Tier 2 — SP_TicketsForOPSNEW) |
| 7 | Product | nvarchar(max) | YES | Product associated with the ticket. Predominantly 'eToro Trading Platform'. From Customer Support Case system. (Tier 2 — SP_TicketsForOPSNEW) |
| 8 | AssignedTo | nvarchar(max) | YES | Full name of the assigned CS agent. ETL-computed as FirstName + ' ' + LastName from Customer_Support_Agent_User. NULL if unassigned. (Tier 2 — SP_TicketsForOPSNEW) |
| 9 | Department | nvarchar(max) | YES | Department of the assigned CS agent. From Customer_Support_Agent_User. Values include: 'Operations', 'OPS CS', 'CF', 'CS'. NULL if unassigned. (Tier 2 — SP_TicketsForOPSNEW) |
| 10 | UserTeam | nvarchar(max) | YES | Team of the assigned CS agent within their department. From Customer_Support_Agent_User.Team (renamed to avoid collision with output Team column). Values include: 'Communications - RO', 'Asia'. NULL if unassigned. (Tier 2 — SP_TicketsForOPSNEW) |
| 11 | Status | nvarchar(max) | YES | Operational status from the source system. Wire: status from Google Sheets (e.g., 'Pool / Unidentified', 'Pool / Client', 'Pool / Below $10 - missing data'). Cashout: CashoutStatus from HourlyReport_Withdraws (always 'Rejected'). (Tier 2 — SP_TicketsForOPSNEW) |
| 12 | DepositID/WithdrawID | bigint | YES | Financial transaction identifier. Wire: deposit_id from Google Sheets (0 if unknown); Cashout: WithdrawID from HourlyReport_Withdraws. Polymorphic — interpretation depends on Team column. (Tier 2 — SP_TicketsForOPSNEW) |
| 13 | Team | nvarchar(max) | YES | Source team classification. ETL-computed: 'Wires' (from Google Sheets wire_deposits_ops) or 'Cashouts' (from HourlyReport_Withdraws rejected cashouts). 2 distinct values. (Tier 2 — SP_TicketsForOPSNEW) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | Fivetran Google Sheets / BI_DB_HourlyReport_Withdraws | cid / CID | Wire: NULL for NA/N/A + CAST INT; Cashout: passthrough |
| Ticket Number | Google Sheets / Billing.WithdrawRejects | ticket_number / CaseNumber | Wire: ISNUMERIC filter; Cashout: passthrough |
| CreatedDate | BI_OUTPUT.Customer_Support_Case | CreatedDate | Passthrough |
| TicketStatus | BI_OUTPUT.Customer_Support_Case | Status | Passthrough |
| Type | BI_OUTPUT.Customer_Support_Case | Type | Passthrough (unpopulated) |
| Priority | BI_OUTPUT.Customer_Support_Case | Priority | Passthrough |
| Product | BI_OUTPUT.Customer_Support_Case | Product | Passthrough |
| AssignedTo | BI_OUTPUT.Customer_Support_Agent_User | FirstName + LastName | Concatenation |
| Department | BI_OUTPUT.Customer_Support_Agent_User | Department | Passthrough |
| UserTeam | BI_OUTPUT.Customer_Support_Agent_User | Team | Rename |
| Status | Google Sheets / HourlyReport_Withdraws | status / CashoutStatus | Passthrough |
| DepositID/WithdrawID | Google Sheets / HourlyReport_Withdraws | deposit_id / WithdrawID | Passthrough |
| Team | (computed) | — | 'Wires' or 'Cashouts' literal |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
Fivetran Google Sheets (wire_deposits_ops, status LIKE '%Pool%') ──┐
                                                                     ├── UNION → #union
BI_DB_dbo.BI_DB_HourlyReport_Withdraws (Rejected + Approved=1) ──┘
  + etoro.Billing.WithdrawRejects (CaseNumber for cashouts)
  |
  + BI_OUTPUT.Customer_Support_Case (ticket metadata)
  + BI_OUTPUT.Customer_Support_Agent_User (agent info)
  |-- ROW_NUMBER() PARTITION BY CaseNumber → RN=1 dedup --|
  |-- SP_TicketsForOPSNEW (TRUNCATE+INSERT) --|
  v
BI_DB_dbo.BI_DB_TicketsForOPS_NEW (105 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer master dimension |
| Ticket Number | BI_OUTPUT.Customer_Support_Case (CaseNumber) | CS ticket system |

### 6.2 Referenced By (other objects point to this)

No consumer SPs found referencing this table.

---

## 7. Sample Queries

### 7.1 Open wire tickets by status

```sql
SELECT Status, COUNT(*) AS ticket_count
FROM BI_DB_dbo.BI_DB_TicketsForOPS_NEW
WHERE Team = 'Wires'
GROUP BY Status
ORDER BY ticket_count DESC
```

### 7.2 Tickets by assigned agent

```sql
SELECT AssignedTo, Department, UserTeam, COUNT(*) AS tickets
FROM BI_DB_dbo.BI_DB_TicketsForOPS_NEW
WHERE AssignedTo IS NOT NULL
GROUP BY AssignedTo, Department, UserTeam
ORDER BY tickets DESC
```

### 7.3 Unassigned high-priority tickets

```sql
SELECT [Ticket Number], CID, Team, Status, CreatedDate
FROM BI_DB_dbo.BI_DB_TicketsForOPS_NEW
WHERE AssignedTo IS NULL AND Priority = 'High'
ORDER BY CreatedDate
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 1 T1, 12 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 7/10, Sources: 6/10*
*Object: BI_DB_dbo.BI_DB_TicketsForOPS_NEW | Type: Table | Production Source: Fivetran Google Sheets + HourlyReport_Withdraws + BI_OUTPUT CS via SP_TicketsForOPSNEW*
