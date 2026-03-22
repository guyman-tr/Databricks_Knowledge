# Review Notes: Dealing_Employees_Report

## Auto-generated flags

| # | Flag | Detail |
|---|------|--------|
| 1 | CopyTarde typo | Column is named `CopyTarde` (should be `CopyTrade`) — confirm this is an original typo in the DDL that must not be renamed to avoid breaking downstream consumers |
| 2 | previos_Position_PnL typo | Column `previos_Position_PnL` (should be `previous`) — same DDL typo concern |
| 3 | AccountTypeID 7 and 13 | Confirm AccountTypeID=7=employee and 13=employee_special — verify from Dim_AccountType |
| 4 | DailyPnL composite logic | Three-way logic (open / same-day close / prior-day close) is complex — verify from SP_Employees_Report the exact conditions and that NULL handling is correct for each path |
| 5 | 231M row size | Very large table — confirm Date+CID combined filters are used in production queries |
