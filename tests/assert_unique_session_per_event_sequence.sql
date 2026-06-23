-- Singular test — fails if it returns any rows.
--
-- Within a single session_id, sequence_number should be unique — a
-- repeated sequence_number would indicate either a source data quality
-- issue or a bug in how events are being grouped, and would corrupt
-- int_events_sessionized's entry_uri/traffic_source/browser logic (which
-- relies on sequence_number = 1 being a single, unambiguous row).

select
    session_id,
    sequence_number,
    count(*) as row_count
from {{ ref('stg_thelook__events') }}
group by session_id, sequence_number
having count(*) > 1
