
---------------------------------------
-- SECTION 1: Database and table setup
-----------------------------------------


CREATE TABLE telco_customers (
    customer_id        VARCHAR(20)    PRIMARY KEY,
    gender             VARCHAR(10),
    senior_citizen     SMALLINT,          
    partner            VARCHAR(5),
    dependents         VARCHAR(5),
    tenure             INT,           
    phone_service      VARCHAR(5),
    multiple_lines     VARCHAR(25),
    internet_service   VARCHAR(25),
    online_security    VARCHAR(25),
    online_backup      VARCHAR(25),
    device_protection  VARCHAR(25),
    tech_support       VARCHAR(25),
    streaming_tv       VARCHAR(25),
    streaming_movies   VARCHAR(25),
    contract           VARCHAR(25),
    paperless_billing  VARCHAR(5),
    payment_method     VARCHAR(40),
    monthly_charges    NUMERIC(8,2),
    total_charges      VARCHAR(15),      -- imported as VARCHAR due to blanks
    churn              VARCHAR(5)
);


-----------------------------------
---SECTION 2: Data CLeaning
-----------------------------------

-----------------------------------
--2.1 Check total and row count
------------------------------------

SELECT COUNT(*) AS total_records
FROM telco_customers;

-- total rows expected: 7043

----------------------------------------
--2.2 check for duplicate customer IDs
----------------------------------------
SELECT
    customer_id,
    COUNT(*) AS occurrence_count
FROM telco_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--expected: 0 rows

------------------------------------------------
--2.3 check NULL / blank values in key columns
------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE gender IS NULL) AS null_gender,
    COUNT(*) FILTER (WHERE tenure IS NULL) AS null_tenure,
    COUNT(*) FILTER (WHERE monthly_charges IS NULL) AS null_monthly_charges,
    COUNT(*) FILTER (WHERE total_charges = '' OR total_charges IS NULL) AS blank_total_charges,
    COUNT(*) FILTER (WHERE churn IS NULL) AS null_churn
FROM telco_customers;

--------------------------------------------------------------
--2.4 Fix total_charges column
--Blank values exist for new customers with 0 tenure
--Convert to NUMERIC and replace blanks with 0
--------------------------------------------------------------
ALTER TABLE telco_customers
ADD COLUMN total_charges_clean NUMERIC(10,2);

UPDATE telco_customers
SET total_charges_clean =
    CASE
        WHEN TRIM(total_charges) = '' THEN 0
        ELSE CAST(TRIM(total_charges) AS NUMERIC(10,2)) END;

-- Verify fix
SELECT COUNT(*) AS rows_with_zero_total
FROM telco_customers
WHERE total_charges_clean = 0;


--------------------------------------------------------------
--2.5 Added a cleaned tenure_group column for easier segmentation
--This avoids repeating CASE WHEN logic in every query
--------------------------------------------------------------
ALTER TABLE telco_customers
ADD COLUMN tenure_group VARCHAR(20);

UPDATE telco_customers
SET tenure_group =
    CASE
        WHEN tenure BETWEEN 0  AND 12  THEN '0-12 Months'
        WHEN tenure BETWEEN 13 AND 24  THEN '13-24 Months'
        WHEN tenure BETWEEN 25 AND 48  THEN '25-48 Months'
        WHEN tenure BETWEEN 49 AND 72  THEN '49-72 Months'
        ELSE 'Unknown' END;


--------------------------------------------------------------
--2.6 Standardize churn column to consistent casing
--------------------------------------------------------------
UPDATE telco_customers
SET churn = INITCAP(churn);  -- 'yes' --> 'Yes',, 'no' --> 'No'

-- Verify distinct values
SELECT DISTINCT churn FROM telco_customers;


----------------------------------
--2.7 Final data quality summary
----------------------------------
SELECT
    COUNT(*)  AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes')  AS churned_customers,
    COUNT(*) FILTER (WHERE churn = 'No') AS active_customers,
    ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS overall_churn_rate_pct
FROM telco_customers;


----------------------------------------
-- SECTION 3: EXPLORATORY ANALYSIS
----------------------------------------

------------------------------------------
--Q1. What is the overall churn rate?
-----------------------------------------------

SELECT
    churn  AS churn_status,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM telco_customers
GROUP BY churn
ORDER BY churn;


-------------------------------------------------
--Q2. How does churn vary by customer gender?
------------------------------------------------
SELECT
    gender,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned,
    ROUND( COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2 ) AS churn_rate_pct
FROM telco_customers
GROUP BY gender
ORDER BY churn_rate_pct DESC;


-- --------------------------------------------------------------------------------------
-- Q3. Are senior citizens more likely to churn?
-- --------------------------------------------------------------------------------------

SELECT
    CASE
        WHEN senior_citizen = 1 THEN 'Senior Citizen'
        ELSE 'Non-Senior' END AS customer_segment,
    COUNT(*)  AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned,
    ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2)  AS churn_rate_pct
FROM telco_customers
GROUP BY senior_citizen
ORDER BY churn_rate_pct DESC;


--------------------------------------------------------------
--Q4. Does having a partner or dependents increase churn?
--------------------------------------------------------------

SELECT
    partner,
    dependents,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_customers
GROUP BY partner, dependents
ORDER BY churn_rate_pct DESC;

------------------------------------------
-- SECTION 4: CONTRACT & SERVICE ANALYSIS
-------------------------------------------

---------------------------------------------------------------------------------------------
--Q5. Which contract type has the highest churn?
---------------------------------------------------------------------------------------------

SELECT
    contract AS contract_type,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND( COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charge
FROM telco_customers
GROUP BY contract
ORDER BY churn_rate_pct DESC;


-----------------------------------------------------------------------------------------
--Q6. How does tenure affect churn risk?
-------------------------------------------------------------------------------------------

SELECT
    tenure_group,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_customers
GROUP BY tenure_group
ORDER BY
    CASE tenure_group
        WHEN '0-12 Months'   THEN 1
        WHEN '13-24 Months'  THEN 2
        WHEN '25-48 Months'  THEN 3
        WHEN '49-72 Months'  THEN 4 END;


--------------------------------------------------------------
--Q7. Which internet service type has the most churn?
----------------------------------------------------------------

SELECT
    internet_service,
    COUNT(*)  AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned,
    ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charge
FROM telco_customers
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;


-----------------------------------------------------------------------------------
--Q8. Do additional services (security, backup) reduce churn?
---------------------------------------------------------------------------------------

SELECT
    online_security,
    online_backup,
    tech_support,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_customers
WHERE internet_service != 'No'
GROUP BY online_security, online_backup, tech_support
ORDER BY churn_rate_pct ASC
LIMIT 10;


-----------------------------------------
--SECTION 5: Revenue analysis
-----------------------------------------

-- ------------------------------------------------------------
-- Q9. What is the total monthly revenue at risk from churn?
-- ------------------------------------------------------------

SELECT
    churn AS churn_status,
    COUNT(*) AS customer_count,
    ROUND(SUM(monthly_charges), 2) AS total_monthly_revenue,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charge_per_customer
FROM telco_customers
GROUP BY churn
ORDER BY churn;


-------------------------------------------------------------------------------------
--Q10. What is the average revenue per user (ARPU) by contract type and churn status?
-------------------------------------------------------------------------------------

SELECT
    contract,
    churn,
    COUNT(*) AS customer_count,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(total_charges_clean), 2) AS avg_lifetime_value
FROM telco_customers
GROUP BY contract, churn
ORDER BY contract, churn;


----------------------------------------------------------------
--Q11. Which payment method is most associated with churn?
---------------------------------------------------------------

SELECT
    payment_method,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned,
    ROUND( COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM telco_customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;


-----------------------------------
-- SECTION 6: Advanced analysis
------------------------------------

-- ------------------------------------------------------------
-- Q12. Rank payment methods by total revenue contribution
--      and churn impact using window functions
-- ------------------------------------------------------------

WITH payment_summary AS (
    SELECT
        payment_method,
        COUNT(*)  AS total_customers,
        SUM(monthly_charges) AS total_monthly_revenue,
        COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_count,
        ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct
    FROM telco_customers
    GROUP BY payment_method
)
SELECT
    payment_method,
    total_customers,
    ROUND(total_monthly_revenue, 2) AS  total_monthly_revenue,
    churn_rate_pct,
    RANK() OVER (ORDER BY total_monthly_revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY churn_rate_pct DESC) AS churn_risk_rank
FROM payment_summary
ORDER BY revenue_rank;


--------------------------------------------------------------
--Q13. Customer lifetime value (CLV) analysis by segment
-- Which customer profile generates the most long-term value?
-- ------------------------------------------------------------

WITH clv_segments AS (
    SELECT
        contract,
        internet_service,
        CASE
            WHEN senior_citizen = 1 THEN 'Senior'
            ELSE 'Non-Senior' END AS age_group,
        COUNT(*) AS customer_count,
        ROUND(AVG(total_charges_clean), 2) AS avg_lifetime_value,
        ROUND(AVG(monthly_charges), 2)  AS avg_monthly_charges,
        ROUND(COUNT(*) FILTER (WHERE churn = 'Yes') * 100.0 / COUNT(*), 2) AS churn_rate_pct
    FROM telco_customers
    GROUP BY contract, internet_service, age_group
)
SELECT
    contract,
    internet_service,
    age_group,
    customer_count,
    avg_lifetime_value,
    avg_monthly_charges,
    churn_rate_pct,
    RANK() OVER (ORDER BY avg_lifetime_value DESC) AS clv_rank
FROM clv_segments
WHERE customer_count >= 50   
ORDER BY clv_rank
LIMIT 10;


--------------------------------------------------------------
--Q14. Churn rate trend by tenure — running cumulative analysis
--How does churn accumulate as customers stay longer?
-------------------------------------------------------------

WITH tenure_churn AS (
    SELECT
        tenure,
        COUNT(*) AS total_at_tenure,
        COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_at_tenure
    FROM telco_customers
    GROUP BY tenure
)
SELECT
    tenure  AS months_with_company,
    total_at_tenure,
    churned_at_tenure,
    ROUND(churned_at_tenure * 100.0 / total_at_tenure, 2) AS churn_rate_pct,
    SUM(churned_at_tenure) OVER (ORDER BY tenure) AS cumulative_churned
FROM tenure_churn
ORDER BY tenure;


--------------------------------------------------------
--Q15. High-risk customer identification
--Find all customers who match top churn-risk criteria
-------------------------------------------------------

SELECT
    customer_id,
    contract,
    tenure,
    internet_service,
    payment_method,
    monthly_charges,
    CASE
        WHEN senior_citizen = 1 THEN 'Yes'
        ELSE 'No' END AS is_senior,
    partner,
    dependents,
    churn
FROM telco_customers
WHERE
    contract = 'Month-to-month'
    AND tenure <= 12
    AND payment_method = 'Electronic check'
    AND internet_service = 'Fiber optic'
    AND churn = 'No'           
ORDER BY monthly_charges DESC;


-----------------------------------------
--			End of Analysis
------------------------------------------