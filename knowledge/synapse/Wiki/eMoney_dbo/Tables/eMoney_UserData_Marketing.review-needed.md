# Review Needed — eMoney_dbo.eMoney_UserData_Marketing

## Flags / Reviewer Questions

1. **SP Suspension**: `SP_eMoney_UserData_Marketing` is commented out as SP 11 in `SP_eMoney_Execute_Group_One`. Table was last updated 2026-04-12. Is this table being deprecated or temporarily suspended?

2. **`Date_Inserted` naming**: This column holds `AccountCreateDate` (eTM account creation date), not the row insertion date. This is misleading naming. Should this be renamed to `AccountCreateDate` or `eTM_Account_Creation_Date` in a future version?

3. **`IBANUsed` = `IBANUsage`**: These two columns are always identical. `IBANUsed` appears to be a redundant legacy column. Should it be removed to reduce confusion?

4. **TxTypeID groupings**: CardUsage is TxTypeID IN (1,2,3,4,9) and IBANUsage is IN (5,6,7,8,13). Reviewer should confirm these TxTypeID groupings are still correct and complete. Is TxTypeID=0 (Unknown) excluded intentionally?

5. **'NotOrdered' sentinel**: `LastCardStatus='NotOrdered'` is an SP-injected string not present in `eMoney_Dictionary_CardStatus`. This means JOINs to the dictionary table on this column will fail for ~1.9M rows. Intended design?

## Data Quality Observations

- 95.4% of records have `LastCardStatus='NotOrdered'` (no card customers in IBAN program)
- `IBANUsed` and `IBANUsage` are 100% identical across all 2M+ rows — confirmed by GROUP BY query
- SP idempotency guard prevents double-runs on same day but requires UpdateDate to be accurate — if SP crashes mid-way, next day's run may find UpdateDate from partial insert
