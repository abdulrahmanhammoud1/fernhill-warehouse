# Data Dictionary

All files are UTF-8 CSV with a header row. The data covers activities from mid-December 2024 to mid-January 2026. Fernhill, Hopscotch and Apex are fictional, and so is all of the data.

## Hopscotch (`data/hopscotch/`)

Hopscotch is a multi-tenant online booking product. Each **operator** (a venue business) runs its own account. Timestamps are in **UTC** (ISO 8601, `Z` suffix). Money is in the operator's currency, in major units (for example `12.50`).

Operators set their own payment and cancellation policies. Some take a **non-refundable deposit** at booking and the balance on the day. Some keep a cancellation fee.

### operators.csv
| Column | Description |
|---|---|
| operator_key | Operator identifier |
| trading_name | Name the operator trades under |
| vertical | Broad activity category |
| iso_country | ISO country code |
| iso_currency | Currency that all of this operator's amounts are in |
| tz_name | IANA time zone of the operator's venue |
| is_sandbox | `true` for internal sandbox accounts |

### patrons.csv
A patron is a person's record at one operator. The same person booking with two operators has two patron records.

| Column | Description |
|---|---|
| patron_key | Patron identifier |
| operator_key | Operator the record belongs to |
| contact_email | As entered by the patron; optional |
| given_name, family_name | As entered |
| registered_ts | When the record was created (UTC) |

### reservation_versions.csv
Each time a reservation is created or changed (for example guests added, or cancelled), Hopscotch writes a new **version** containing the reservation's full state at that point.

| Column | Description |
|---|---|
| reservation_key | Reservation identifier |
| version_seq | Version number within the reservation, starting at 1 |
| operator_key | Operator |
| patron_key | Patron who made the reservation |
| offering | The experience reserved |
| session_start_ts | Activity start time (UTC) |
| booked_ts | When the reservation was first made (UTC) |
| valid_from_ts | When this version was written (UTC) |
| lifecycle | `LIVE` or `CANCELLED` |
| party_size | Number of guests |
| price_net | Price before tax |
| price_tax | Tax |
| iso_currency | Currency |

### money_movements.csv
Every movement of money against a reservation, in either direction.

| Column | Description |
|---|---|
| movement_key | Movement identifier |
| reservation_key | Reservation the money relates to |
| direction | `IN` = received from the guest, `OUT` = returned to the guest |
| value | Amount, including tax. Always positive; `direction` gives the sign |
| iso_currency | Currency |
| moved_ts | When the money moved (UTC) |
| rail | `card`, `cash` or `voucher` |
| memo | Free text, usually only on `OUT` rows |

## Apex (`data/apex/`)

Apex is venue management software for go-kart tracks. **Each site runs its own separate copy of Apex with its own database.** These files combine the extracts from every site into one file per table, with a `site_no` column added. Timestamps are in the **site's local time**, with no offset. Money is in the site's currency.

### sites.csv
| Column | Description |
|---|---|
| site_no | Site number (added during extraction) |
| site_title | Site name |
| iso_country | ISO country code |
| iso_currency | Currency |
| olson_tz | IANA time zone of the site |
| is_training | `1` for training and demo sites |

### profiles.csv
| Column | Description |
|---|---|
| site_no | Site |
| profile_no | Profile number |
| mail | Email, as entered at the kiosk or online; staff sometimes enter a placeholder |
| first, surname | As entered |
| joined_local | When the profile was created (local time) |

### tickets.csv
A ticket is one booked session at a site.

| Column | Description |
|---|---|
| site_no | Site |
| ticket_no | Ticket number |
| profile_no | Profile who booked |
| opened_local | When the ticket was created (local time) |
| session_local | Scheduled session start (local time) |
| product_label | Product booked |
| head_count | Number of participants |
| gross_minor | Ticket value including tax, in **minor units** (cents, pence) |
| outcome | `FULFILLED` or `WITHDRAWN` (cancelled) |
| withdrawn_local | When the ticket was withdrawn (local time), if it was |

### settlements.csv
Money taken and returned against a ticket.

| Column | Description |
|---|---|
| site_no | Site |
| settle_no | Settlement number |
| ticket_no | Ticket |
| settle_value | Amount, including tax. **Negative when money is returned** |
| settle_local | When it happened (local time) |
| instrument | `CARD`, `CASH` or `VOUCHER` |

## Exchange rates (`data/rates_daily.csv`)

Published once per business day.

| Column | Description |
|---|---|
| as_of | Date the rate applies to |
| base_ccy | `GBP`, `EUR` or `AUD` |
| quote_ccy | Always `USD` |
| usd_per_unit | US dollars per one unit of `base_ccy` |
