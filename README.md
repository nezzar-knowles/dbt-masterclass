# dbt Masterclass — thelook_ecommerce Capstone Project

Practical companion project for the dbt Masterclass (Modules 1-6), built against
Google's public `thelook_ecommerce` dataset on BigQuery. This repo grows one
module at a time — each module's slide deck has a corresponding chunk of this
project, so by Module 6 it's a complete, working capstone pipeline.

## What's built so far

**Module 1 — Project Structure & Best Practices**
- Folder structure and naming conventions (below)
- `dbt_project.yml` with layered model config (staging/intermediate/marts)
- A minimal source stub for the 7 `thelook_ecommerce` tables
- A pre-flight verification script in `analyses/`

**Module 2 — Writing Models, Tests, Macros & Documentation**
- All 7 staging models (`stg_thelook__*`), one per source table, with light
  renaming/casting and no joins
- `macros/standardize_text.sql` — fixes the status/category casing
  inconsistency found during the pre-flight check
- `macros/valid_order_statuses.sql` — single source of truth for the order
  status enum, shared by two different tests (read the comment inside, the
  exact values still need confirming against the live table)
- `tests/generic/test_not_in_future.sql` — custom generic test, meaningful
  specifically because we confirmed this dataset is live, not frozen
- `packages.yml` — adds dbt_utils (run `dbt deps` after pulling this down)
- `_thelook__docs.md` and `_thelook__staging_models.yml` — doc blocks and
  data tests on every staging model, using the current `data_tests:` /
  `arguments:` syntax (dbt v1.10.5+ / Fusion). If your project runs an
  older dbt Core version, see the comment at the top of the yml file for
  how to flatten the syntax.

Two tests are intentionally left as TODOs (`users.traffic_source` and
`events.event_type` accepted_values) because I haven't verified the exact
enum values against the live table — fill those in once you have them.

**Module 3 — Sources, Seeds & Snapshots**
- `_thelook__sources.yml` now has full descriptions plus freshness checks
  on `orders` and `events` (read the comment at the bottom of that file —
  freshness here measures "is this dataset still growing," not real
  pipeline lag, since we don't control how Google loads it)
- `seeds/holiday_calendar.csv` — US holiday/shopping-event calendar,
  2024-2027, generated programmatically rather than typed from memory, so
  every date is verifiably correct rather than recalled. This is the
  canonical "what belongs in seeds/" example: static, instructor-curated,
  unrelated to the source system itself
- `seeds/traffic_source_channel_mapping.csv` — maps raw traffic_source
  values to broader Paid/Organic channel groups. **CAVEAT: the traffic_source
  values listed are my best assessment, not verified against the live
  table** — an unmatched value silently produces a null channel_group
  rather than an error, so reconcile this before trusting it's complete.
- `seeds/country_region_mapping.csv` — maps users.country to a macro region
  (~45 commonly-occurring countries). **CAVEAT: not guaranteed exhaustive
  of every country actually present in the live data** — same silent-null
  failure mode as above if a country doesn't match.
- `seeds/product_category_target_margin.csv` — instructor-defined target
  margin % per department/category, for a target-vs-actual variance
  exercise. These are illustrative numbers I invented for the course, not
  real category economics — say that explicitly to students. **CAVEAT:
  department/category names are based on a typical clothing-retailer
  taxonomy and have NOT been verified against the live products table.**
- `snapshots/users_snapshot.yml` — SCD2 tracking on `users`, using the
  current YAML-based snapshot config (dbt v1.9+) and the `check` strategy
  (there's no updated_at column on this table, so `timestamp` isn't an
  option). Read the comment in that file — whether you'll actually observe
  a row change depends on whether the source ever mutates existing rows in
  place, which I haven't verified either way

**Marts layer (7 models)** — final, business-facing tables, each mapped to
specific business questions:

| Model | Grain | Answers |
|---|---|---|
| `dim_customers` | 1 row / user | Who are our customers? Lifetime revenue? Repeat vs one-time? Acquisition channel? Nearest DC? |
| `dim_products` | 1 row / product | What do we sell? Markup by category/brand/department? |
| `dim_distribution_centers` | 1 row / DC | Where do we fulfill from? |
| `fct_orders` | 1 row / order | Revenue per order? Ship/deliver speed? Return rate? Holiday correlation? |
| `fct_order_items` | 1 row / line item | **Start here for revenue/margin** — order-level revenue undercounts multi-item orders |
| `fct_inventory` | 1 row / inventory unit | How much stock is unsold, and for how long? Tied-up inventory cost? |
| `fct_sessions` | 1 row / session | Traffic by channel? Session-to-purchase conversion? |

`fct_orders.attributed_session_id` and `attributed_traffic_source` link to
`fct_sessions`, but inherit the heuristic caveat from
`int_events_to_orders_attribution` — present with that caveat attached, not
as verified fact.

All seven have `unique` + `not_null` tests on their grain column, plus
`relationships` tests linking facts back to dimensions, in
`_thelook__marts_models.yml`.

**Intermediate layer (10 models)** — built ahead of the semantic layer module
so there's reusable, tested logic underneath it:
- `int_order_items_joined` / `int_order_items_with_distribution_center` —
  order economics: margin (sale_price - cost), distribution center chained
  through products
- `int_orders_pivoted_status_dates` — order lifecycle durations
  (days_to_ship/deliver/fulfill) and a was_returned flag
- `int_users_order_history_rollup` / `int_users_first_order_attribution` —
  customer-level rollups: lifetime revenue, order count, first-order timing
- `int_inventory_resolved` — **resolves the inventory_items/products
  duplication flagged in Module 2.** Decision made and documented in-file:
  products is the source of truth for product attributes going forward.
- `int_inventory_aging` — days-in-inventory for unsold stock
- `int_events_sessionized` — events collapsed to one row per session
- `int_events_to_orders_attribution` — **read the comment in this file
  before using it.** Best-effort heuristic linking orders to a prior
  session; there's no real foreign key between the two tables, so this is
  explicitly a teaching example of an ambiguous join, not ground truth.
- `int_orders_with_holiday_flag` — finally puts the Module 3
  `holiday_calendar` seed to use
- `int_users_nearest_distribution_center` — great-circle distance via
  BigQuery's native `ST_DISTANCE`/`ST_GEOGPOINT` (no manual haversine
  formula needed)

All ten have `unique` + `not_null` tests on their grain column in
`_thelook__intermediate_models.yml`.

## Before you touch anything: run the pre-flight check

Open `analyses/peek_at_source_data.sql` in the dbt Cloud IDE and run each
query block against your own connection. This confirms, with your own eyes,
on the actual live dataset:
- real row counts per table (don't quote a number from a blog post)
- the real min/max date range in `orders` (this dataset has reportedly kept
  growing over time, so old write-ups may understate it)
- the exact current values for `orders.status`, `order_items.status`,
  `events.event_type`, and `users.traffic_source`
- the exact current column list on `order_items` — some public documentation
  of this dataset omits `sale_price`, which most revenue queries depend on
- whether the source tables are partitioned/clustered (affects how we teach
  incremental models in Module 4)

This is a five-minute step. Do it before the first time you teach this, and
do it again before each cohort — Google can update this dataset without
warning.

## Folder structure

```
models/
  staging/
    thelook/                 <- one folder per source system
      _thelook__sources.yml  <- source() declarations live here, not in models
  intermediate/               <- reusable joins/logic, not exposed to BI tools
  marts/
    core/                     <- final, business-facing models
analyses/                      <- one-off exploratory SQL, version-controlled
                                  but never materialized into the warehouse
seeds/                         <- small static CSVs we maintain ourselves
                                  (added in Module 3)
snapshots/                     <- SCD tracking (added in Module 3)
macros/                        <- reusable Jinja (added in Module 2)
tests/                         <- singular/custom tests (added in Module 2)
```

## Naming conventions

| Layer        | Pattern                          | Example                  |
|--------------|-----------------------------------|---------------------------|
| Staging      | `stg_<source>__<entity>`          | `stg_thelook__orders`     |
| Intermediate | `int_<entity>__<verb_phrase>`     | `int_orders__joined_items`|
| Marts (fact) | `fct_<entity>`                    | `fct_orders`              |
| Marts (dim)  | `dim_<entity>`                    | `dim_customers`           |

The double underscore (`__`) separates the source/system prefix from the
entity name — this is a deliberate dbt community convention, not a typo.

## Why the source lives in a different project than your models

`thelook_ecommerce` lives in Google's `bigquery-public-data` project and is
read-only — you can query it, but nothing in this project ever writes to it.
Every model, seed, and snapshot we build lands in **your own** GCP project
instead. That's why `_thelook__sources.yml` sets `database: bigquery-public-data`
explicitly — without that, dbt would look for the tables inside your own
project and fail to find them.

## Business-question analyses (`analyses/`)

Eight ready-to-run queries against the marts layer, each opening with the
business question it answers — meant as both a teaching example of what
belongs in `analyses/` (compiled with ref()/source(), version-controlled,
never materialized) and as a starting demo set for whatever BI tool you
connect.

| File | Question |
|---|---|
| `revenue_trend_by_month.sql` | Is revenue growing from more orders, or bigger orders? |
| `product_category_performance.sql` | Which categories drive revenue vs. margin? |
| `customer_segmentation_ltv.sql` | How much more are repeat customers worth? |
| `fulfillment_speed_by_distribution_center.sql` | Are some DCs slower to ship/deliver? |
| `returns_analysis_by_category.sql` | What's actually driving our return rate? |
| `slow_moving_inventory.sql` | What's tying up capital unsold the longest? |
| `marketing_channel_performance.sql` | Which channel converts and drives revenue, not just traffic? (Compares two legitimate but different cuts — read the in-file comment.) |
| `holiday_order_lift.sql` | Do major shopping holidays actually lift order volume in this dataset? |

`peek_at_source_data.sql` (from Module 1) is still there too — that one's
the pre-flight check, these eight are the payoff.

## Macros (`macros/`)

| Macro | Purpose |
|---|---|
| `standardize_text(column_name)` | Trims/lowercases free-text categorical columns (Module 2) |
| `valid_order_statuses()` | Single source of truth for the order status enum, shared by two tests (Module 2) |
| `safe_divide_pct(numerator, denominator)` | safe_divide() × 100, so every margin/conversion-rate calc handles zero/null the same way |
| `days_between(start_date, end_date)` | Wraps date_diff(..., day) with intuitive start-then-end argument order (BigQuery's native date_diff is end-then-start, which trips people up) |
| `limit_in_dev(row_limit=1000)` | Adds a LIMIT only when `target.name == 'dev'`, for fast iteration on large tables like `events`. **Check your dbt Cloud environment's actual name under Deploy > Environments** — it may be `default` rather than `dev`, in which case edit the string in this macro to match. |
| `generate_schema_name(custom_schema_name, node)` | Override of dbt's built-in schema-naming macro. Currently reproduces dbt's default concatenation behavior (`target_schema_customschema`) on purpose — included so the mechanism is visible/editable rather than invisible "magic," not because we need different behavior yet. Read the in-file comment for how to change it to a single shared schema. |

`tests/generic/test_not_in_future.sql` is technically a macro too (custom
generic tests are macros under the hood) — see the Module 2 section above.

### Refactored to use these macros

`days_between()` now backs the date-diff logic in
`int_orders_pivoted_status_dates`, `int_users_first_order_attribution`,
`int_inventory_aging`, and `fulfillment_speed_by_distribution_center.sql`.

`safe_divide_pct()` now backs the percentage calculations in
`dim_products.expected_margin_pct`, `product_category_performance.sql`
(`margin_pct`), `returns_analysis_by_category.sql` and
`fulfillment_speed_by_distribution_center.sql` (`return_rate_pct`), and
`marketing_channel_performance.sql` (`session_conversion_rate_pct`).

**Scale change worth knowing:** these columns now return 0-100 (true
percentages), not 0-1 (raw ratios) like the original `safe_divide(...)`
versions did. Columns were renamed with an explicit `_pct` suffix
(`return_rate` → `return_rate_pct`, etc.) specifically so the scale change
is visible in the column name, not silent. If you'd built any dashboard or
downstream logic against the old 0-1 versions, it needs updating.

Two dollar-value averages (`avg_order_value`, `avg_lifetime_revenue`) were
deliberately left on plain `safe_divide()` — they're averages, not
percentages, so `safe_divide_pct()` doesn't apply. `int_events_sessionized`
also keeps its raw `date_diff(..., second)` for session duration, since
`days_between()` is day-granularity only and forcing it would silently
produce wrong units.

## Tests (`tests/`) — singular tests

Each fails if it returns any rows, run against real warehouse data on every `dbt test`.

| File | Catches |
|---|---|
| `assert_order_revenue_matches_line_items.sql` | `fct_orders.order_revenue` drifting from the actual line-item sum |
| `assert_no_negative_margins.sql` | Items sold below cost — flagged for review, not necessarily an error |
| `assert_inventory_item_not_sold_before_created.sql` | sold_at earlier than created_at — genuine data corruption |
| `assert_order_item_dates_in_order.sql` | Impossible lifecycle sequences (e.g. delivered before shipped) |
| `assert_no_orphaned_order_items.sql` | Teaching example only — hand-written version of the existing `relationships` test, intentionally redundant with it |
| `assert_seed_join_coverage.sql` | Turns the "unmatched seed value → silent null" risk into an automated >5% threshold check |
| `assert_unique_session_per_event_sequence.sql` | Repeated sequence_number within a session, which would corrupt `int_events_sessionized`'s entry_uri logic |

## Unit tests (`unit_tests:` in yml, alongside the model — NOT in `tests/`)

Test model *logic* against fabricated mock rows, not real data. Fast, no warehouse query.

| File | Tests |
|---|---|
| `models/intermediate/_thelook__unit_tests_orders.yml` | `int_orders_pivoted_status_dates` day-diff math, including the null-when-unshipped edge case |
| `models/intermediate/_thelook__unit_tests_inventory.yml` | `int_inventory_resolved`'s is_currently_in_stock flag for sold/unsold cases |
| `models/marts/core/_thelook__unit_tests_customers.yml` | `dim_customers.customer_segment` — the highest-value unit test in the project, pure conditional logic |
| `models/intermediate/_thelook__unit_tests_attribution.yml` | `int_events_to_orders_attribution`'s 24-hour window edge case — exactly the kind of scenario that's hard to find naturally in real data |

Run `dbt test --select test_type:unit` to run only the unit tests, or
`dbt test --select test_type:singular` for just the singular ones.

## Semantic Layer (`models/semantic/`)

MetricFlow semantic models and metrics, built directly on the marts layer.
**Search was unavailable while building this section, so the YAML syntax
below is from well-established MetricFlow patterns, not freshly verified
against current docs — run `dbt parse` (or open Studio IDE, which parses
automatically) before teaching with it, and treat any parse error as a
syntax-drift issue to fix, not a project design problem.**

### Semantic models (5)

| File | Grain | Use for |
|---|---|---|
| `sem_order_items.yml` | line item | Revenue/margin by product, category, brand — **default to this** over sem_orders for anything product-specific |
| `sem_orders.yml` | order | Fulfillment timing, return rate, holiday lift |
| `sem_customers.yml` | customer | LTV, segmentation, acquisition channel. Note: `customer_lifetime_revenue` here won't always exactly reconcile with a sliced sum of sem_order_items' revenue — different aggregation paths, worth explaining to students directly |
| `sem_inventory.yml` | inventory unit | Stock health, capital tied up |
| `sem_sessions.yml` | session | Traffic, conversion — independent of revenue by design |

### Metrics, one file per type (17 total)

- **`metrics_simple.yml`** (10) — direct 1:1 wraps of a measure: `revenue`, `margin`, `orders`, `customers`, `inventory_capital`, `sessions`, plus four building-block metrics (`returned_items`, `total_items`, `converted_sessions`) used only as ratio inputs, not meant to be surfaced to end users directly.
- **`metrics_ratio.yml`** (4) — `margin_rate`, `average_order_value` (deliberately cross-semantic-model — numerator from sem_order_items, denominator from sem_orders, to show students metrics aren't limited to one semantic model), `return_rate`, `session_conversion_rate`. **Syntax note:** ratio numerator/denominator reference other *metrics*, not raw measures directly — that's why the building-block metrics above exist.
- **`metrics_cumulative.yml`** (3) — `revenue_running_total` (unbounded), `revenue_trailing_30_day` (windowed), `orders_running_total`.
- **`metrics_derived.yml`** (3) — `revenue_per_customer`, `margin_minus_inventory_capital` (intentionally illustrative — read the in-file caveat, it's not a true profitability number since unsold inventory capital isn't a realized cost), `revenue_growth_vs_trailing_30_day` (combines two cumulative metrics).

Query any of these via `dbt sl query --metrics revenue --group-by metric_time__month` once the semantic layer is connected.

## Module 5 — Orchestration & CI/CD

All demonstrations run against the existing project — no new models to
understand from scratch, just existing ones wired into a pipeline.

| File | Purpose |
|---|---|
| `models/marts/core/fct_order_items_incremental.sql` | Incremental version of fct_order_items with a 3-day lookback buffer and BigQuery partition config. Read the in-file comments before teaching the buffer — it's the most common point of confusion. |
| `models/marts/core/_thelook__exposures.yml` | 4 exposures documenting who consumes the marts. Appears in `dbt docs` lineage graph and affects Slim CI's impact scope. |
| `ci/deploy_job_reference.yml` | Exact dbt Cloud job settings for the daily production run and the Slim CI PR check. Use as a live config checklist. |
| `ci/ci_demo_broken_branch_instructions.sql` | Instructions for the deliberate CI failure demo — introduces a -1 multiplier on cost in int_inventory_resolved, breaks assert_no_negative_margins, and blocks the PR merge. |
| `analyses/module5_pipeline_monitoring.sql` | 4 post-run monitoring queries: row count trend, incremental health check, snapshot health, and a test-result proxy. |
| `docs/module5_instructor_guide.md` | Full recommended teaching order, what to say at each step, timing, and answers to common student questions. **Read this before teaching Module 5.** |

Key teaching point specific to this dataset: the incremental model demo
only works convincingly because thelook_ecommerce is **live and growing**
— row counts actually change between runs, something most thelook-based
courses can't show because they treat the dataset as a frozen snapshot.

## Setup checklist (dbt Cloud)

1. GCP service account with `BigQuery Job User` + `BigQuery Data Editor` roles
   on **your own** project, JSON key downloaded.
2. dbt Cloud → New Project → BigQuery → upload that JSON key → Test Connection.
3. Connect a real GitHub/GitLab/Azure DevOps repo (not a dbt-managed repo) —
   Module 4 needs this for Slim CI on pull requests.
4. Set your personal Development dataset under Profile → Credentials.
5. Initialize the project in Studio IDE, then replace the generated
   `dbt_project.yml` with the one in this repo.

