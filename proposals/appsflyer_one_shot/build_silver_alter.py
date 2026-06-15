"""Build the silver-table ALTER SQL from a structured (col_name, comment) list.

The PDF -> ALTER mapping is data, not code. Keeping it in a list rather
than as raw SQL lets us re-render with different escaping rules (single
quotes for SQL strings) without hand-editing 86 ALTER statements.
"""
from pathlib import Path

TABLE = "main.de_output.de_output_appsflyer_silver_reports"
OUT = Path(__file__).resolve().parents[2] / "knowledge" / "UC_generated" / "de_output" / "Tables" / "de_output_appsflyer_silver_reports.alter.sql"

# (column_name, comment) pairs in physical order.
COLUMNS: list[tuple[str, str]] = [
    # ---- Already written by direct Write/StrReplace ----
    # AttributedTouchType .. UserAgent (44 cols already in the file).
    # The remaining 42 columns:

    # Multi-Touch Contributors (15)
    ("Contributor1Partner",     "Agency or PMD (Preferred Marketing Developer) of the 1st contributing touchpoint - always lowercase. (Tier 1 - AppsFlyer field `contributor1_af_prt`)"),
    ("Contributor1MediaSource", "Media source of the 1st (most recent) touchpoint that contributed to the conversion. (Tier 1 - AppsFlyer field `contributor1_media_source`)"),
    ("Contributor1Campaign",    "Campaign name of the 1st (most recent) contributing touchpoint. (Tier 1 - AppsFlyer field `contributor1_campaign`)"),
    ("Contributor1TouchType",   "How the user interacted at the 1st (most recent) contributing touchpoint: `click` or `impression`. (Tier 1 - AppsFlyer field `contributor1_touch_type`)"),
    ("Contributor1TouchTime",   "Date and time of the 1st (most recent) contributing touchpoint. Stored as STRING - SP_AppFlyer_Reports normalises placeholder strings ('None', 'USD', 'usd') to NULL upstream of this layer; cast with try_to_timestamp before chronological ordering. (Tier 1 - AppsFlyer field `contributor1_touch_time`)"),
    ("Contributor2Partner",     "Agency or PMD of the 2nd contributing touchpoint - always lowercase. (Tier 1 - AppsFlyer field `contributor2_af_prt`)"),
    ("Contributor2MediaSource", "Media source of the 2nd touchpoint that contributed to the conversion. (Tier 1 - AppsFlyer field `contributor2_media_source`)"),
    ("Contributor2Campaign",    "Campaign name of the 2nd contributing touchpoint. (Tier 1 - AppsFlyer field `contributor2_campaign`)"),
    ("Contributor2TouchType",   "How the user interacted at the 2nd contributing touchpoint: `click` or `impression`. (Tier 1 - AppsFlyer field `contributor2_touch_type`)"),
    ("Contributor2TouchTime",   "Date and time of the 2nd contributing touchpoint. Stored as STRING with the same NULL-normalisation as Contributor1TouchTime. (Tier 1 - AppsFlyer field `contributor2_touch_time`)"),
    ("Contributor3Partner",     "Agency or PMD of the 3rd (oldest) contributing touchpoint - always lowercase. (Tier 1 - AppsFlyer field `contributor3_af_prt`)"),
    ("Contributor3MediaSource", "Media source of the 3rd (oldest) touchpoint that contributed to the conversion. (Tier 1 - AppsFlyer field `contributor3_media_source`)"),
    ("Contributor3Campaign",    "Campaign name of the 3rd (oldest) contributing touchpoint. (Tier 1 - AppsFlyer field `contributor3_campaign`)"),
    ("Contributor3TouchType",   "How the user interacted at the 3rd contributing touchpoint: `click` or `impression`. (Tier 1 - AppsFlyer field `contributor3_touch_type`)"),
    ("Contributor3TouchTime",   "Date and time of the 3rd (oldest) contributing touchpoint. Stored as STRING on silver (the bi_db gold mirror stores it as TIMESTAMP - the type-asymmetry is a known anomaly). (Tier 1 - AppsFlyer field `contributor3_touch_time`)"),

    # Location (8 incl IP)
    ("Region",      "Region derived from device IP as reported by SDK. For SKAN: derived from country_code. eToro values are AppsFlyer macro-region codes (`EU`, `AS`, `AU`, `SA`, `AF`, `NA`) - NOT eToro's marketing-region SCD. (Tier 1 - AppsFlyer field `region`)"),
    ("CountryCode", "Country code using ISO 3166 alpha-2. AppsFlyer per-vendor convention: `UK` is used, NOT `GB`. The bi_db SP normalises UK->GB but the silver layer preserves the raw value. (Tier 1 - AppsFlyer field `country_code`)"),
    ("State",       "State or province of the device location. (Tier 1 - AppsFlyer field `state`)"),
    ("City",        "City of the device location. Can be districts or boroughs. **DDM-masked** with `default()` on the bi_db gold mirror; verify masking on this silver path before exposing in user-facing dashboards. (Tier 1 - AppsFlyer field `city`)"),
    ("PostalCode",  "Postal or ZIP code of the device location. (Tier 1 - AppsFlyer field `postal_code`)"),
    ("DMA",         "Designated Market Area as defined by Nielsen (US-focused). 'None' for non-US. (Tier 1 - AppsFlyer field `dma`)"),
    ("IP",          "IP address (IPv4 or IPv6). Used to determine user location. **PRESENT on silver - DROPPED on the bi_db gold mirror by SP_AppFlyer_Reports.** Treat as PII. (Tier 1 - AppsFlyer field `ip`)"),
    ("WIFI",        "Whether the device was connected via Wi-Fi at the time of the event: `TRUE` or `FALSE`. eToro stores it as 'true' / 'false' string. (Tier 1 - AppsFlyer field `wifi`)"),

    # Device & Network (9)
    ("Operator",   "Name of the mobile operator derived from SIM MCCMNC code (e.g. 'Vodafone'). Empty when on Wi-Fi or unknown. (Tier 1 - AppsFlyer field `operator`)"),
    ("Carrier",    "The carrier name provided by Android's `getSimCarrierIdName()`. May differ from Operator under roaming. (Tier 1 - AppsFlyer field `carrier`)"),
    ("Language",   "Language (locale) reported by the device per IETF BCP 47 standard (e.g. 'Deutsch', 'English'). (Tier 1 - AppsFlyer field `language`)"),
    ("Platform",   "The operating system or ecosystem on which the application runs: `'android'` or `'ios'`. ~75% android / ~23% ios on the bi_db mirror; ~2% 'None' / GUID-shaped dirty values - filter `Platform IN ('android','ios','None')` for clean grouping. (Tier 1 - AppsFlyer field `platform`)"),
    ("DeviceType", "Commercial model name of the device. **DEPRECATED Feb 2022** - replaced by `device_model` in the AppsFlyer schema. Often empty in observed data. (Tier 1 - AppsFlyer field `device_type` - deprecated)"),
    ("OSVersion",  "Version of the operating system on the device (e.g. '13', '16.1.1'). (Tier 1 - AppsFlyer field `os_version`)"),
    ("AppVersion", "Version of the customer's app as reported by the SDK or S2S APIs (e.g. '651.114.0', '618.0.0'). (Tier 1 - AppsFlyer field `app_version`)"),
    ("SDKVersion", "AppsFlyer SDK version installed in the app (e.g. 'v6.12.2'). (Tier 1 - AppsFlyer field `sdk_version`)"),

    # Device Identifiers (7)
    ("AppsFlyerID",    "A unique ID generated by the SDK when the app is first installed. AppsFlyer's privacy-safe device+install identifier - the primary device key for iOS post-ATT (use this, NOT IDFA). Joins to `bronze_marketperformance_tracking_customer.AppsflyerID` for CID resolution. (Tier 1 - AppsFlyer field `appsflyer_id`)"),
    ("AdvertisingID",  "User-resettable device ID, also known as GAID (Google Advertising ID, Android). For CTV: CTV ID such as RIDA. Empty for iOS devices. ~62% coverage across the bi_db mirror. (Tier 1 - AppsFlyer field `advertising_id`)"),
    ("IDFA",           "User-resettable advertising ID found on iOS devices (Identifier for Advertisers). **Empty for the majority of iOS rows post-iOS14.5 ATT framework** - Apple's App Tracking Transparency requires per-app opt-in. ~8% total coverage / ~36% of iOS rows on the bi_db mirror. For iOS attribution use `AppsFlyerID` as the primary device key. (Tier 1 - AppsFlyer field `idfa`)"),
    ("AndroidID",      "Permanent hardware-level device ID (Android). Empty for iOS. (Tier 1 - AppsFlyer field `android_id`)"),
    ("CustomerUserID", "The Customer User ID (CUID) - unique app user identifier set by the advertiser. eToro passes a hashed CID at registration / login, so this column links AppsFlyer events back to eToro user accounts. **NULL on Installs and OrganicInstalls** (no CID exists pre-registration); ~26% of total bi_db rows carry a populated value. For per-CID rollups, prefer the `bronze_marketperformance_tracking_customer.AppsflyerID` bridge. (Tier 1 - AppsFlyer field `customer_user_id`)"),
    ("IMEI",           "Permanent hardware device ID. Collection is restricted in many markets - typically empty on modern devices. (Tier 1 - AppsFlyer field `imei`)"),
    ("IDFV",           "Vendor ID provided by iOS - unique per app vendor on a device. Empty for Android. (Tier 1 - AppsFlyer field `idfv`)"),

    # App (3)
    ("AppID",    "Unique app identifier in AppsFlyer. eToro values: `'com.etoro.openbook'` (Android, dot notation - Google Play package) or `'id674984916'` (iOS, App Store ID). Differs from `EtoroAppID` which uses underscore notation. (Tier 1 - AppsFlyer field `app_id`)"),
    ("AppName",  "Official name of the application as it appears in the app stores. Not a constant - changed over time (e.g. `'eToro: Investing made social'` -> `'eToro: Trade. Invest. Connect.'`). (Tier 1 - AppsFlyer field `app_name`)"),
    ("BundleID", "iOS: Bundle ID to match the app. Android: equivalent to App ID. Same value as `AppID` in observed data. (Tier 1 - AppsFlyer field `bundle_id`)"),

    # Custom eToro pipeline-added fields (5)
    ("DateID",       "Event date as YYYYMMDD integer (e.g. 20260610). ETL partition key. Equals `Date` formatted as YYYYMMDD. (Tier 2 - eToro pipeline)"),
    ("Date",         "Event date - the date the install or in-app event occurred. **Not the install date** for InAppEvents - may differ significantly from `InstallTime`. For event-period analysis filter on `Date` / `DateID`; for install-cohort analysis filter on `InstallTime`. (Tier 2 - eToro pipeline)"),
    ("EtoroAppID",   "AppsFlyer-export-config app key: `'com_etoro_openbook'` (Android, underscore separator) or `'id674984916'` (iOS). Differs from `AppID` (dot notation). (Tier 2 - eToro pipeline)"),
    ("EtoroAppName", "Human-readable platform label set by the AppsFlyer export config: `'OneApp Android'` or `'OneApp iOS'`. (Tier 2 - eToro pipeline)"),
    ("EtoroReport",  "AppsFlyer report-type partition - the most important filter on this table. Values: `'OrganicInstalls'` (~86.5M, no paid touch / SKAdNetwork-restricted), `'InAppEvents'` (~37.8M, post-install business events), `'Installs'` (~7.0M, paid attributed installs). **ALWAYS filter EtoroReport** - the three classes never sum cleanly: `Installs + OrganicInstalls = total installs` but `InAppEvents` are events on already-installed devices, not installs. (Tier 2 - eToro pipeline)"),
]


def render_alter_statement(col: str, comment: str) -> str:
    # Single quote escape per SQL: ' -> ''.
    safe = comment.replace("'", "''")
    return f"ALTER TABLE {TABLE} ALTER COLUMN {col} COMMENT '{safe}';"


def main() -> None:
    if not OUT.exists():
        raise SystemExit(f"Expected header to exist at {OUT}")
    existing = OUT.read_text(encoding="utf-8")
    sections = [
        "\n-- Multi-Touch Contributors (1, 2, 3) ---------------------------------------\n",
    ]
    for i, (col, comment) in enumerate(COLUMNS):
        if col == "Region":
            sections.append("\n-- Location (8 incl IP) -------------------------------------------------\n")
        elif col == "Operator":
            sections.append("\n-- Device & Network (9) -------------------------------------------------\n")
        elif col == "AppsFlyerID":
            sections.append("\n-- Device Identifiers (7) -----------------------------------------------\n")
        elif col == "AppID":
            sections.append("\n-- App (3) ---------------------------------------------------------------\n")
        elif col == "DateID":
            sections.append("\n-- Custom eToro Fields (5, pipeline-added) -------------------------------\n")
        sections.append(render_alter_statement(col, comment))
        sections.append("\n")

    out_text = existing.rstrip() + "\n" + "".join(sections)
    out_text = out_text.rstrip() + "\n"
    OUT.write_text(out_text, encoding="utf-8")
    print(f"Wrote {len(COLUMNS)} additional column comments to {OUT}")


if __name__ == "__main__":
    main()
