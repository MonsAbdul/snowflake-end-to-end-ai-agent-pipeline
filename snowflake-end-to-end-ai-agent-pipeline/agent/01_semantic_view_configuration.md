# Semantic View Configuration

- Name: SEMANTIC_VIEW
- Location: DASH_DB_SI.RETAIL
- Warehouse: DASH_WH_SI
- Role: SNOWFLAKE_INTELLIGENCE_ADMIN
- Source objects: All five RETAIL tables plus ENRICHED_MARKETING_INTELLIGENCE
- MARKETING_CAMPAIGN_METRICS primary key: CATEGORY

## Relationship

- From table: ENRICHED_MARKETING_INTELLIGENCE
- To table: MARKETING_CAMPAIGN_METRICS
- Relationship type: Many to One
- From column: PRODUCT_NAME
- To column: CATEGORY