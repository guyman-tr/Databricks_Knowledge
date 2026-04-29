# BI_DB_dbo.BI_DB_TicketsForOPS_NEW — Column Lineage

## Source Objects

| Source | Schema | Role | Join Condition |
|--------|--------|------|----------------|
| External_Fivetran_google_sheets_wire_deposits_ops | BI_DB_dbo (External) | Wire deposit tickets (status LIKE '%Pool%') | Main driver (Wires team) |
| BI_DB_dbo.BI_DB_HourlyReport_Withdraws | BI_DB_dbo | Rejected approved cashouts | CashoutStatus='Rejected' AND Approved=1 (Cashouts team) |
| External_etoro_Billing_WithdrawRejects | BI_DB_dbo (External) | Case numbers for rejected withdrawals | BWR.WithdrawID = W.WithdrawID |
| External_BI_OUTPUT_Customer_Customer_Support_Case | BI_DB_dbo (External) | Ticket details (status, type, priority, product) | ncs.CaseNumber = B.[Ticket number] |
| External_BI_OUTPUT_Customer_Customer_Support_Agent_User | BI_DB_dbo (External) | Agent details (name, department, team) | ncs.OwnerId = us.ID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | Wire: google_sheets_wire_deposits_ops / Cashout: BI_DB_HourlyReport_Withdraws | cid / CID | Wire: CASE NULL for 'NA'/'N/A' + CAST to INT; Cashout: passthrough |
| Ticket Number | Wire: google_sheets_wire_deposits_ops / Cashout: Billing_WithdrawRejects | ticket_number / CaseNumber | Wire: filtered ISNUMERIC=1; Cashout: CaseNumber |
| CreatedDate | Customer_Support_Case | CreatedDate | Passthrough |
| TicketStatus | Customer_Support_Case | Status | Passthrough |
| Type | Customer_Support_Case | Type | Passthrough (currently unpopulated) |
| Priority | Customer_Support_Case | Priority | Passthrough |
| Product | Customer_Support_Case | Product | Passthrough |
| AssignedTo | Customer_Support_Agent_User | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| Department | Customer_Support_Agent_User | Department | Passthrough |
| UserTeam | Customer_Support_Agent_User | Team | Passthrough (renamed to avoid collision with output Team column) |
| Status | Wire: google_sheets_wire_deposits_ops / Cashout: BI_DB_HourlyReport_Withdraws | status / CashoutStatus | Passthrough from each source |
| DepositID/WithdrawID | Wire: google_sheets_wire_deposits_ops / Cashout: BI_DB_HourlyReport_Withdraws | deposit_id / WithdrawID | Passthrough from each source |
| Team | (computed) | — | 'Wires' or 'Cashouts' based on source branch |
| UpdateDate | (ETL) | GETDATE() | ETL metadata timestamp |

## Production Source Chain

```
Fivetran Google Sheets (wire_deposits_ops) ──┐
                                              ├── UNION → #union
BI_DB_HourlyReport_Withdraws (Rejected+Approved) ──┘
  + etoro.Billing.WithdrawRejects (CaseNumber for cashouts)
  |
  + BI_OUTPUT.Customer_Support_Case (ticket details)
  + BI_OUTPUT.Customer_Support_Agent_User (agent info)
  |-- SP_TicketsForOPSNEW (TRUNCATE+INSERT) --|
  v
BI_DB_dbo.BI_DB_TicketsForOPS_NEW (105 rows)
```
