# Review Notes: Dealing_CryptoVolume_ByDirection

## Auto-generated flags

| # | Flag | Detail |
|---|------|--------|
| 1 | IsBuy inversion | Close trades have IsBuy inverted — confirm this is intentional and documented in SP comments; could confuse downstream consumers expecting raw position direction |
| 2 | Volume vs Units | Volume is int (click count) while Units is decimal — confirm whether Volume from VolumeOnClose counts correctly for aggregated directional analysis |
