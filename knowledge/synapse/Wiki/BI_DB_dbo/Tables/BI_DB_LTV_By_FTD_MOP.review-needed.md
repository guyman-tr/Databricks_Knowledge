# BI_DB_dbo.BI_DB_LTV_By_FTD_MOP — Review Needed

## Tier 4 Items

None.

## Reviewer Questions

1. **Current_Club naming**: Column is called "Club" but contains PlayerLevel values (Standard, Silver, Gold, etc.). Should this be renamed to Current_PlayerLevel for clarity?
2. **2-year FTD window**: Only the last 2 years of FTDs are included. Is this sufficient for LTV analysis, or should the window be extended?
3. **Revenue windows source**: Revenue30/60/90/180/360days come from BI_DB_First5Actions. What exactly does "revenue" measure here (commissions, spread, total)?
4. **LTV_NoExtreme**: What is the extreme outlier removal methodology in BI_DB_LTV_BI_Actual?
