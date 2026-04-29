# BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation — Review Needed

## Questions for Reviewer

1. **Regulation IDs 6,7,8,12**: Confirm these are all the US regulation IDs. Are there newer US regulation entries that should be excluded?
2. **NYDFS+FINRA in recent data**: Some rows show CurrentRegulation='NYDFS+FINRA'. These customers may have been re-regulated AFTER initial detection. Should these be cleaned up from the watchlist?
3. **Accumulation without cleanup**: The table only grows — no mechanism removes customers who have since been moved to US regulation. Is there a periodic cleanup process?
4. **Designated_Regulation_DB vs DesignatedRegulation**: Confirm that Designated_Regulation_DB is the country-level regulation (from Dim_Country.RegulationID) while DesignatedRegulation is the customer's personal designated regulation.
