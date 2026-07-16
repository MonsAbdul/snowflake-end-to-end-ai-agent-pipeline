-- ============================================================
-- SECTION 1: CREATE THE SECURE VIEW
-- ============================================================

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

CREATE OR REPLACE SECURE VIEW marketing_intelligence_view AS
SELECT
    campaign_name AS "Ad Campaign",
    category AS "Product Category",
    clicks AS "Engagement Clicks",
    0 AS "Customer Sentiment Score"
FROM marketing_campaign_metrics;

-- Check which roles have access to the database and schema.
SHOW GRANTS ON DATABASE DASH_DB_SI;
SHOW GRANTS ON SCHEMA DASH_DB_SI.RETAIL;

-- Check access to the secure view.
SHOW GRANTS ON VIEW marketing_intelligence_view;

-- Verify that the administrator can query the secure view.
SELECT *
FROM marketing_intelligence_view
LIMIT 5;


-- ============================================================
-- SECTION 2: CREATE THE RESTRICTED MARKETING ROLE
-- ============================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE ROLE marketing_intelligence_role;

GRANT USAGE
ON WAREHOUSE DASH_WH_SI
TO ROLE marketing_intelligence_role;

GRANT USAGE
ON DATABASE DASH_DB_SI
TO ROLE marketing_intelligence_role;

GRANT USAGE
ON SCHEMA DASH_DB_SI.RETAIL
TO ROLE marketing_intelligence_role;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER
TO ROLE marketing_intelligence_role;

GRANT SELECT
ON VIEW DASH_DB_SI.RETAIL.marketing_intelligence_view
TO ROLE marketing_intelligence_role;

-- Assign the restricted role to your current Snowflake user.
SET current_user = CURRENT_USER();

GRANT ROLE marketing_intelligence_role
TO USER IDENTIFIER($current_user);


-- ============================================================
-- SECTION 3: CREATE AND APPLY THE MASKING POLICY
-- ============================================================

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

CREATE OR REPLACE MASKING POLICY mask_engagement_clicks
AS (val NUMBER)
RETURNS NUMBER ->
    CASE
        WHEN CURRENT_ROLE() IN (
            'SNOWFLAKE_INTELLIGENCE_ADMIN',
            'ACCOUNTADMIN'
        )
        THEN val
        ELSE 0
    END;

ALTER TABLE marketing_campaign_metrics
MODIFY COLUMN clicks
SET MASKING POLICY mask_engagement_clicks;

-- Verify that the masking policy is attached to the column.
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.POLICY_REFERENCES(
        POLICY_NAME => 'mask_engagement_clicks'
    )
);


-- ============================================================
-- SECTION 4: VERIFY ADMIN AND RESTRICTED RESULTS
-- ============================================================

-- Recreate the secure view so it uses the masked base-table column.
USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

CREATE OR REPLACE SECURE VIEW marketing_intelligence_view AS
SELECT
    campaign_name AS "Ad Campaign",
    category AS "Product Category",
    clicks AS "Engagement Clicks",
    0 AS "Customer Sentiment Score"
FROM marketing_campaign_metrics;

-- ------------------------------------------------------------
-- ADMIN TEST
-- The administrator should see the real click values.
-- ------------------------------------------------------------

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

SELECT
    "Ad Campaign",
    "Engagement Clicks"
FROM marketing_intelligence_view;


-- ------------------------------------------------------------
-- RESTRICTED MARKETING ROLE TEST
-- The restricted role should see 0 for all click values.
-- ------------------------------------------------------------

USE ROLE marketing_intelligence_role;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

SELECT
    "Ad Campaign",
    "Engagement Clicks"
FROM marketing_intelligence_view;