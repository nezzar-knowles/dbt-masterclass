{% docs sale_price_vs_retail_price %}
`products.retail_price` is the catalog/list price. `order_items.sale_price`
is what the customer was actually charged at the moment of purchase, and
can legitimately differ from retail_price (discounts, promotions, price
changes over time). Always use `sale_price` for revenue calculations —
using `retail_price` instead will overstate revenue whenever a discount
applied.
{% enddocs %}

{% docs inventory_items_product_duplication %}
The source `inventory_items` table carries its own copies of several
product attributes (category, name, brand, retail_price, department, sku,
distribution_center_id) in addition to `product_id`. These are kept as-is
in staging (prefixed `inv_`) rather than dropped, so nothing is silently
lost — but they duplicate `stg_thelook__products` and the two could in
principle disagree (e.g. if a product's retail price changed after an
inventory item was created). Pick one source of truth in the intermediate
layer rather than carrying both forward into marts.
{% enddocs %}

{% docs dataset_is_live %}
Confirmed directly against the live table (not from secondary
documentation): this source data is actively maintained, with most tables
showing a last-modified date matching the current date rather than a
frozen historical snapshot. Treat any cited date range or row count from
external blog posts as a lower bound, not a current fact — re-verify with
analyses/peek_at_source_data.sql.
{% enddocs %}

{% docs order_status_grain %}
Order status is tracked independently at the order level
(`stg_thelook__orders.order_status`) and the line-item level
(`stg_thelook__order_items.order_status`), and the two are not guaranteed
to match at any given moment — an order can show as in-progress overall
while an individual item has already shipped. Don't assume one can be
derived from the other without checking.
{% enddocs %}
