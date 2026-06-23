# Module 5: Orchestration & CI/CD — Instructor Guide
# thelook_ecommerce project practicalization

## What's in this module

Everything in Module 5 is about *process*, not data shape, so all the
teaching demonstrations run against the existing project you've already
built. Nothing new to model. The new files added for this module are:

| File | Purpose |
|---|---|
| `models/marts/core/fct_order_items_incremental.sql` | Live demo of incremental materialization on a growing dataset |
| `models/marts/core/_thelook__exposures.yml` | Documents who consumes the marts — surfaces in dbt docs and affects Slim CI's impact graph |
| `ci/deploy_job_reference.yml` | Exact settings checklist for configuring the two dbt Cloud jobs live in class |
| `ci/ci_demo_broken_branch_instructions.sql` | Step-by-step instructions for staging the deliberate CI failure demo |
| `analyses/module5_pipeline_monitoring.sql` | Post-run monitoring queries to run against the warehouse |

---

## Recommended teaching order

### 1. Environment setup (15 min)

Open Deploy → Environments in dbt Cloud and walk through creating a
Production environment alongside the existing Development one. Key
points:

- Point the prod environment at a different BigQuery dataset
  (e.g. `dbt_masterclass_prod` vs `dbt_ebenezer`).
- Show that `generate_schema_name` (already in `macros/`) controls
  how custom schemas like `staging` / `marts` combine with the target
  schema — this is the moment that macro stops being abstract and
  becomes something students can see in BigQuery's left panel.
- Prod should use a SHARED service account credential, not anyone's
  personal one. Ask students why. Correct answer: personal credentials
  expire or get rotated; a shared service account is stable.

### 2. Daily deploy job (20 min)

Use `ci/deploy_job_reference.yml` as your checklist and configure
the daily job live. Walk through each step in order and explain why
the order matters:

- `dbt deps` must come first (packages must be installed before models
  that use them can compile).
- `dbt seed` before `dbt run` (models ref seeds; seeds must exist first).
- `dbt snapshot` before `dbt run` for the same reason.
- `dbt source freshness` LAST — it checks freshness as of the moment
  the run completes, not before. Running it first would check
  yesterday's data.
- `dbt docs generate` as the final step auto-publishes updated docs
  on every run. Ask students: "what happens if you skip this?"
  Answer: docs go stale the moment the project changes.

Show the cron schedule and ask students to calculate what 5:00 AM UTC
is in their timezone — this trips people up constantly in real jobs.

### 3. Incremental materialization demo (25 min)

Open `fct_order_items_incremental.sql` in the IDE. Walk through:

- Why this model specifically: it's the largest mart model and the
  one BI tools will query most. Full rebuild on every run is wasteful.
- The `is_incremental()` block: explain that dbt wraps the whole model
  in a conditional — on first run, the `{% if is_incremental() %}` block
  is false and the full table builds; on subsequent runs it's true and
  only the filtered rows process.
- The 3-day lookback buffer: this is the key teaching point.
  Ask students: "why not just filter to today?" Because order_status
  changes AFTER the order is placed — a row created 2 days ago can
  still flip from `shipped` to `returned` today. Without a buffer,
  those updated rows would be missed.
- `unique_key='order_item_id'`: this triggers a MERGE instead of an
  INSERT. Without it, reprocessed rows would duplicate.
- The partition_by config: BigQuery scans the partition matching the
  WHERE clause, not the full table. Show the estimated bytes in the
  BigQuery console before and after partition pruning.

Run `dbt run --select fct_order_items_incremental` live. Check row
count before and after. Come back tomorrow (or later that day if new
data arrives) and run it again — students seeing the row count grow
is more convincing than any slide.

Run `analyses/module5_pipeline_monitoring.sql` Query 2 to verify
the incremental buffer is working correctly.

### 4. The CI demo (30 min — the centrepiece of this module)

This is the most impactful demonstration. Do it in this exact order:

**Setup (before class if possible):**
- Confirm the GitHub repo is connected in dbt Cloud (should be from
  Module 1 setup).
- Go to Deploy → Jobs → Create Job → enable "Run on Pull Requests."
- Point the "Defer to" setting at the Daily Production Run job.
- The command must be:
  ```
  dbt deps
  dbt build --select state:modified+ --defer --state ./prod-artifacts
  ```

**The demo:**

Step 1 — show the full project in the IDE (30+ models, 17 metrics,
all tests). Ask: "if someone changes one model, does CI have to
rebuild all of this?" Let students guess.

Step 2 — follow `ci/ci_demo_broken_branch_instructions.sql`. Create
a new branch `ci-demo-broken-margin`, edit `int_inventory_resolved.sql`
to multiply cost by -1, commit, and open a Pull Request on GitHub.

Step 3 — switch to dbt Cloud's Jobs screen and watch the CI job
trigger automatically (it usually takes 30–60 seconds to appear).

Step 4 — open the running job. Show students the model count in the
run: it should be 3 models (int_inventory_resolved, int_inventory_aging,
fct_inventory), NOT 30+. This is the Slim CI payoff.

Step 5 — the job fails on `assert_no_negative_margins`. Show the
failure in the job logs. Switch to GitHub and show the PR with the
blocked merge button.

Step 6 — fix the bug (remove the -1 multiplier), push a new commit
to the same branch. Watch the CI job re-trigger, go green, and
unblock the merge.

Key questions to ask students during Step 4:
- "Why only 3 models?" → state:modified+ selected only the changed
  model and its downstream dependents.
- "What about fct_order_items — it also refs int_order_items_joined,
  not inventory. Why didn't it rebuild?" → because it's NOT downstream
  of int_inventory_resolved. The + means downstream of THIS change,
  not the whole project.
- "Where did ref('fct_orders') come from without rebuilding it?"
  → --defer used the production version.

### 5. Exposures in dbt docs (10 min)

Run `dbt docs generate` and open the docs site. Navigate to any mart
model (e.g. fct_order_items) and show the lineage graph. Point out
that the Revenue & Margin Dashboard exposure now appears as a
downstream node — students can see a model's BI consumers in the same
graph as its source dependencies.

Show the `maturity: low` exposure (marketing_channel_dashboard). Ask:
"what does maturity mean here?" It's metadata — dbt doesn't enforce it
— but it's a signal to consumers that this dashboard rests on a
heuristic join and shouldn't be used for major budget decisions.

### 6. Notifications and monitoring (10 min)

- Show the notification settings on the daily job (Slack webhook or
  email). Describe the scenario: "the daily job fails at 5 AM and
  sends a Slack message — who should receive it and what do they do?"
- Open `analyses/module5_pipeline_monitoring.sql` and run Query 4
  (the test result proxy). This shows students what the singular tests
  are checking in plain SQL form — good for demystifying what "dbt test
  passed" actually verified.

---

## Common questions to prep for

**"What if the incremental model misses a row?"**
Answer: `dbt run --full-refresh --select fct_order_items_incremental`
rebuilds the full table from scratch. This is the escape hatch — use
it when you suspect the incremental logic is wrong or the source data
was backfilled. Note the `--full-refresh` flag is blocked in production
by default in some dbt Cloud setups, which is a feature, not a bug.

**"Does Slim CI build models that changed upstream of my change?"**
Answer: No — `state:modified+` only selects downstream dependents, not
upstream ones. If your change breaks something upstream, that's caught
by the fact that upstream models ran in the last full production run
and their state is what --defer uses.

**"How does --defer know what the production models look like?"**
Answer: the `manifest.json` produced by the last successful production
run is stored as an artifact in dbt Cloud. The "Defer to" job setting
tells the CI job to pull that artifact. No manifest = no defer = CI
builds the full project. Point this out as a reason why the daily
production job must be kept running and healthy.

**"Can we use Airflow/Prefect/Cloud Composer instead of dbt Cloud's
scheduler?"**
Answer: yes — dbt Cloud's scheduler is a thin wrapper around the same
dbt CLI commands you've been running all along. Any orchestrator can
call `dbt run`, `dbt test`, etc. via the CLI or the dbt Cloud API.
The principles in this module apply regardless of the orchestration
tool.
