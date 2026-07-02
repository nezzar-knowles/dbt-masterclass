{#
    generate_schema_name(custom_schema_name, node)

    This is a dbt built-in macro override — dbt calls a macro with exactly
    this name to decide what schema each model lands in, so naming it
    generate_schema_name (not a custom name) is what makes it take effect
    project-wide, no ref() or explicit call needed anywhere.

    WHY THIS EXISTS:
    Our dbt_project.yml sets +schema: staging / +schema: intermediate /
    +schema: marts on the three model layers. Without this override, dbt's
    DEFAULT behavior is to concatenate that custom schema onto your target
    schema, e.g. target schema "dbt_ebenezer" + custom schema "marts"
    becomes "dbt_ebenezer_marts". That's usually fine in dev, but in a
    shared/prod environment with multiple custom schemas, the default
    concatenation can produce schema name collisions or just confusing
    sprawl, especially once you add a 4th or 5th layer down the road.

    WHAT THIS VERSION DOES INSTEAD:
    Same concatenation behavior as dbt's default (target_schema + "_" +
    custom_schema_name) — included here NOT because we need different
    behavior right now, but so the mechanism is visible and editable
    in one place instead of being invisible "magic" students never see.
    If you ever want every model to land in ONE shared schema regardless
    of layer (a common ask in smaller teams), delete the custom_schema_name
    branch below and always return target.schema.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}