# Review Notes: Dealing_CryptoVolume

## Auto-generated flags

| # | Flag | Detail |
|---|------|--------|
| 1 | Writer SP unknown | No active writer SP found in SSDT for INSERT INTO Dealing_CryptoVolume — should confirm with Dealing team whether this was intentionally decommissioned or if writer was renamed/moved |
| 2 | Stale since 2024-04-02 | Confirm whether Dealing_CryptoVolume_ByDirection (active, daily grain) is the intended replacement |
| 3 | CLUSTERED COLUMNSTORE | Unlike most Dealing_dbo tables — may indicate a different loading pattern was used; investigate original load mechanism |
| 4 | HS_Volume vs MM_Volume | Definition of Hedge Server vs Market Maker volumes needs clarification — was there a separate MM infrastructure for crypto? |
