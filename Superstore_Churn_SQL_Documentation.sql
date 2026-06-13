-- =====================================================
-- PROJECT 3 : ECOMMERCE CUSTOMER RETENTION & CHURN
-- Dataset  : Custom Ecommerce Dataset
-- Author   : Amit Kumar
-- Tool     : MySQL
-- =====================================================

USE olist_analytics;

-- =====================================================
-- SECTION 1 : BUSINESS OVERVIEW
-- =====================================================

-- -------------------------------------------------------
-- Query 1 : Total Customers
-- -------------------------------------------------------
-- PURPOSE  : Find how many unique customers exist in our database
-- WHY      : This is the base metric every business tracks
--            It tells us the size of our customer base
-- INSIGHT  : If total customers are low, business needs more
--            marketing and customer acquisition strategies
-- -------------------------------------------------------
SELECT
COUNT(DISTINCT customer_id) AS total_customers
FROM ecommerce_customers;


-- -------------------------------------------------------
-- Query 2 : Total Orders
-- -------------------------------------------------------
-- PURPOSE  : Count total number of orders placed
-- WHY      : Orders = business activity level
--            More orders means business is growing
-- INSIGHT  : Compare total orders vs total customers
--            If orders >> customers, customers are repeating (good!)
--            If orders = customers, nobody is coming back (bad!)
-- -------------------------------------------------------
SELECT
COUNT(DISTINCT order_id) AS total_orders
FROM ecommerce_orders;


-- -------------------------------------------------------
-- Query 3 : Total Revenue
-- -------------------------------------------------------
-- PURPOSE  : Calculate total money earned from delivered orders
-- WHY      : Revenue is the most important business metric
--            We filter only Delivered orders because
--            Cancelled/Returned orders don't earn money
-- INSIGHT  : If revenue is low despite high orders,
--            customers are buying cheap products
--            Focus on upselling premium categories
-- -------------------------------------------------------
SELECT
ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce_orders
WHERE order_status = 'Delivered';


-- -------------------------------------------------------
-- Query 4 : Average Order Value (AOV)
-- -------------------------------------------------------
-- PURPOSE  : Find average money spent per order
-- WHY      : AOV is a key ecommerce health metric
--            Higher AOV = customers buying more per visit
-- INSIGHT  : If AOV is low, introduce bundle offers or
--            minimum order discounts to increase basket size
--            AOV target should always increase year over year
-- -------------------------------------------------------
SELECT
ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM ecommerce_orders
WHERE order_status = 'Delivered';


-- -------------------------------------------------------
-- Query 5 : Order Status Breakdown
-- -------------------------------------------------------
-- PURPOSE  : See distribution of Delivered, Cancelled,
--            Shipped, Returned orders
-- WHY      : High cancellation or return rate is a red flag
--            It means customers are unhappy with the product
--            or delivery experience
-- INSIGHT  : Cancellation rate above 10% needs investigation
--            Return rate above 5% means product quality issues
--            Use window function OVER() to calculate % in same query
-- -------------------------------------------------------
SELECT
order_status,
COUNT(*) AS total_orders,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM ecommerce_orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- -------------------------------------------------------
-- Query 6 : Revenue by Month
-- -------------------------------------------------------
-- PURPOSE  : See how revenue changes every month
-- WHY      : Monthly trend shows seasonality and growth
--            Which months are peak and which are slow
-- INSIGHT  : If revenue spikes in Oct-Dec = festive season effect
--            If revenue drops in June-July = off season
--            Use this to plan marketing campaigns in advance
-- -------------------------------------------------------
SELECT
DATE_FORMAT(order_date, '%Y-%m') AS order_month,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS monthly_revenue
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY 1
ORDER BY 1;


-- -------------------------------------------------------
-- Query 7 : Revenue by Year
-- -------------------------------------------------------
-- PURPOSE  : Compare yearly revenue to see growth
-- WHY      : Year over Year (YoY) growth is how investors
--            and management measure business performance
-- INSIGHT  : If 2023 revenue > 2022 revenue = business growing
--            If 2024 revenue < 2023 revenue = something went wrong
--            Investigate what changed in that year
-- -------------------------------------------------------
SELECT
YEAR(order_date) AS order_year,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS yearly_revenue
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY 1
ORDER BY 1;


-- =====================================================
-- SECTION 2 : PRODUCT INSIGHTS
-- =====================================================

-- -------------------------------------------------------
-- Query 8 : Revenue by Category
-- -------------------------------------------------------
-- PURPOSE  : Find which product categories make most money
-- WHY      : Business should invest more in top categories
--            and either improve or remove low performing ones
-- INSIGHT  : Top category = hero product of the business
--            Bottom category = consider removing or discounting
--            AVG order value per category shows premium vs budget
-- -------------------------------------------------------
SELECT
category,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue,
ROUND(AVG(revenue), 2) AS avg_order_value
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY category
ORDER BY total_revenue DESC;


-- -------------------------------------------------------
-- Query 9 : Revenue by Sub Category
-- -------------------------------------------------------
-- PURPOSE  : Drill down into categories to find best products
-- WHY      : Category level is not enough for product decisions
--            Sub category shows exactly which product type sells best
-- INSIGHT  : Within Electronics if Mobile > Laptop
--            Stock more mobiles and run mobile specific campaigns
--            This is called drill down analysis in product analytics
-- -------------------------------------------------------
SELECT
category,
sub_category,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY category, sub_category
ORDER BY total_revenue DESC;


-- -------------------------------------------------------
-- Query 10 : Top 10 Best Selling Products
-- -------------------------------------------------------
-- PURPOSE  : Find the 10 most ordered products
-- WHY      : Best sellers should always be in stock
--            They drive majority of revenue
-- INSIGHT  : If same product appears multiple times from
--            different customers = organic demand is high
--            These products need priority in inventory planning
-- -------------------------------------------------------
SELECT
product_name,
category,
COUNT(DISTINCT order_id) AS times_ordered,
ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY product_name, category
ORDER BY times_ordered DESC
LIMIT 10;


-- -------------------------------------------------------
-- Query 11 : Payment Method Analysis
-- -------------------------------------------------------
-- PURPOSE  : See which payment methods customers prefer
-- WHY      : If UPI is most used, make UPI experience smoother
--            If Credit Card is low, offer credit card cashback
-- INSIGHT  : COD (Cash on Delivery) orders have higher
--            cancellation rates in real world ecommerce
--            Business should incentivize prepaid payments
--            with extra discounts to reduce COD dependency
-- -------------------------------------------------------
SELECT
payment_method,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS usage_percentage
FROM ecommerce_orders
GROUP BY payment_method
ORDER BY total_orders DESC;


-- -------------------------------------------------------
-- Query 12 : Discount Impact on Revenue
-- -------------------------------------------------------
-- PURPOSE  : Understand if discounts are helping or hurting revenue
-- WHY      : Too many discounts reduce profit margins
--            But right discounts increase conversion
-- INSIGHT  : If High Discount bucket has most orders but low revenue
--            = we are giving too much discount for small orders
--            Sweet spot is Medium discount with high revenue
--            CASE WHEN is used to create discount buckets/groups
-- -------------------------------------------------------
SELECT
CASE
    WHEN discount = 0 THEN 'No Discount'
    WHEN discount <= 0.10 THEN 'Low (0-10%)'
    WHEN discount <= 0.20 THEN 'Medium (10-20%)'
    ELSE 'High (20-30%)'
END AS discount_bucket,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue,
ROUND(AVG(revenue), 2) AS avg_revenue
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY 1
ORDER BY total_revenue DESC;


-- =====================================================
-- SECTION 3 : CUSTOMER ANALYTICS
-- =====================================================

-- -------------------------------------------------------
-- Query 13 : Customer Segment Distribution
-- -------------------------------------------------------
-- PURPOSE  : Count how many customers are in each segment
--            New / Regular / Premium / VIP
-- WHY      : Understanding segment distribution helps plan
--            personalized marketing for each group
-- INSIGHT  : If VIP customers are only 5% but contribute 40% revenue
--            = protect VIP customers at all cost
--            Give them priority support and exclusive offers
-- -------------------------------------------------------
SELECT
customer_segment,
COUNT(DISTINCT customer_id) AS total_customers,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM ecommerce_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;


-- -------------------------------------------------------
-- Query 14 : Revenue by Customer Segment
-- -------------------------------------------------------
-- PURPOSE  : Find which customer segment brings most revenue
-- WHY      : Not all customers are equal
--            20% customers usually bring 80% revenue (Pareto Rule)
-- CONCEPT  : JOIN is used here to combine customer info
--            from customers table with revenue from orders table
-- INSIGHT  : If Premium segment has high revenue per customer
--            = invest in upgrading Regular customers to Premium
--            through loyalty programs and rewards
-- -------------------------------------------------------
SELECT
c.customer_segment,
COUNT(DISTINCT c.customer_id) AS total_customers,
COUNT(DISTINCT o.order_id) AS total_orders,
ROUND(SUM(o.revenue), 2) AS total_revenue,
ROUND(SUM(o.revenue) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer
FROM ecommerce_customers c
JOIN ecommerce_orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;


-- -------------------------------------------------------
-- Query 15 : Age Group Analysis
-- -------------------------------------------------------
-- PURPOSE  : Understand which age group buys most
-- WHY      : Age group helps in targeted marketing
--            26-35 age group usually has highest spending power
-- INSIGHT  : If 18-25 group orders most but spends less
--            = they buy budget products
--            Target them with student offers and EMI options
--            If 36-45 spends most = target them with premium products
-- -------------------------------------------------------
SELECT
c.age_group,
COUNT(DISTINCT c.customer_id) AS total_customers,
COUNT(DISTINCT o.order_id) AS total_orders,
ROUND(SUM(o.revenue), 2) AS total_revenue
FROM ecommerce_customers c
JOIN ecommerce_orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.age_group
ORDER BY total_revenue DESC;


-- -------------------------------------------------------
-- Query 16 : New vs Returning Customers
-- -------------------------------------------------------
-- PURPOSE  : Split customers into first time buyers
--            and repeat buyers
-- WHY      : Returning customers cost less to acquire
--            and spend more than new customers
-- CONCEPT  : Subquery is used to first count orders per customer
--            then classify them as New or Returning
-- INSIGHT  : If 70% customers are New and only 30% returning
--            = retention problem! Business is losing customers
--            after first purchase. Fix onboarding and post
--            purchase experience immediately
-- -------------------------------------------------------
SELECT
customer_type,
COUNT(*) AS total_customers
FROM (
    SELECT
    customer_id,
    CASE
        WHEN COUNT(DISTINCT order_id) = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type
    FROM ecommerce_orders
    GROUP BY customer_id
) AS customer_classification
GROUP BY customer_type;


-- =====================================================
-- SECTION 4 : GEOGRAPHIC ANALYSIS
-- =====================================================

-- -------------------------------------------------------
-- Query 17 : Revenue by Region
-- -------------------------------------------------------
-- PURPOSE  : Compare performance across North, South,
--            East, West, Central regions
-- WHY      : Helps decide where to open warehouses,
--            increase delivery staff or run region ads
-- INSIGHT  : If South region has highest revenue
--            = open more delivery hubs in South
--            If Central region is low = run regional
--            campaigns to increase awareness
-- -------------------------------------------------------
SELECT
region,
COUNT(DISTINCT o.customer_id) AS total_customers,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce_orders o
WHERE order_status = 'Delivered'
GROUP BY region
ORDER BY total_revenue DESC;


-- -------------------------------------------------------
-- Query 18 : Revenue by State
-- -------------------------------------------------------
-- PURPOSE  : Drill down from region to state level
-- WHY      : State level data helps in state specific
--            tax, logistics and marketing decisions
-- INSIGHT  : Maharashtra and Karnataka usually top in
--            Indian ecommerce due to Mumbai and Bangalore
--            If a state is underperforming = check if
--            delivery is available there or logistics is slow
-- -------------------------------------------------------
SELECT
state,
COUNT(DISTINCT o.customer_id) AS total_customers,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce_orders o
WHERE order_status = 'Delivered'
GROUP BY state
ORDER BY total_revenue DESC;


-- -------------------------------------------------------
-- Query 19 : Top 10 Cities by Revenue
-- -------------------------------------------------------
-- PURPOSE  : Find top 10 revenue generating cities
-- WHY      : Tier 1 cities usually dominate ecommerce
--            but Tier 2 cities like Indore, Jaipur are growing
-- INSIGHT  : If Indore or Jaipur appear in top 10
--            = Tier 2 city growth is happening
--            Invest in same day delivery in these cities
--            to capture the growing market
-- -------------------------------------------------------
SELECT
city,
COUNT(DISTINCT o.customer_id) AS total_customers,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce_orders o
WHERE order_status = 'Delivered'
GROUP BY city
ORDER BY total_revenue DESC
LIMIT 10;


-- =====================================================
-- SECTION 5 : RETENTION ANALYSIS
-- =====================================================

-- -------------------------------------------------------
-- Query 20 : Monthly Active Customers
-- -------------------------------------------------------
-- PURPOSE  : Count unique customers who ordered each month
-- WHY      : Monthly Active Users (MAU) is a core product metric
--            Falling MAU = customers are leaving the platform
-- INSIGHT  : MAU should grow month over month
--            If MAU drops after a certain month = investigate
--            was there a bad product update, delivery issue
--            or competitor launched something better?
-- -------------------------------------------------------
SELECT
DATE_FORMAT(order_date, '%Y-%m') AS order_month,
COUNT(DISTINCT customer_id) AS active_customers
FROM ecommerce_orders
GROUP BY 1
ORDER BY 1;


-- -------------------------------------------------------
-- Query 21 : Repeat Purchase Rate
-- -------------------------------------------------------
-- PURPOSE  : What % of customers placed more than 1 order
-- WHY      : This is THE most important retention metric
--            Industry benchmark is 25-40% for ecommerce
-- INSIGHT  : If repeat rate is below 20% = serious retention problem
--            If repeat rate is above 40% = excellent customer loyalty
--            Repeat customers have 5x higher lifetime value
--            than one time buyers
-- -------------------------------------------------------
SELECT
ROUND(
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END) * 100.0
    / COUNT(DISTINCT customer_id), 2
) AS repeat_purchase_rate
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM ecommerce_orders
    GROUP BY customer_id
) AS order_summary;


-- -------------------------------------------------------
-- Query 22 : Customer Order Frequency
-- -------------------------------------------------------
-- PURPOSE  : See distribution of how many orders
--            each customer has placed
-- WHY      : Frequency distribution reveals customer behavior
--            Most customers will have 1-2 orders
-- INSIGHT  : If many customers have 5+ orders = strong loyalty
--            If 80% customers have exactly 1 order = one and done problem
--            Fix with welcome emails, loyalty points, and
--            personalized product recommendations
-- -------------------------------------------------------
SELECT
order_count,
COUNT(*) AS total_customers
FROM (
    SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS order_count
    FROM ecommerce_orders
    GROUP BY customer_id
) AS freq
GROUP BY order_count
ORDER BY order_count;


-- -------------------------------------------------------
-- Query 23 : Retention by Customer Segment (CTE)
-- -------------------------------------------------------
-- PURPOSE  : Find average orders and active days per segment
-- WHY      : Different segments need different retention strategies
-- CONCEPT  : CTE (Common Table Expression) is used here
--            WITH keyword creates a temporary table
--            Makes complex queries easier to read and write
-- INSIGHT  : VIP customers should have highest avg orders
--            If New customers have very low avg days active
--            = they are signing up but not coming back
--            Fix with onboarding flow and first purchase offers
-- -------------------------------------------------------
WITH customer_orders AS (
    SELECT
    c.customer_id,
    c.customer_segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    MIN(o.order_date) AS first_order,
    MAX(o.order_date) AS last_order
    FROM ecommerce_customers c
    JOIN ecommerce_orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_segment
)
SELECT
customer_segment,
COUNT(*) AS total_customers,
ROUND(AVG(total_orders), 2) AS avg_orders_per_customer,
ROUND(AVG(DATEDIFF(last_order, first_order)), 0) AS avg_days_active
FROM customer_orders
GROUP BY customer_segment
ORDER BY avg_orders_per_customer DESC;


-- =====================================================
-- SECTION 6 : CHURN ANALYSIS
-- =====================================================

-- -------------------------------------------------------
-- Query 24 : Overall Churn Rate
-- -------------------------------------------------------
-- PURPOSE  : Find what % of customers stopped buying
--            (no order in last 90 days)
-- WHY      : Churn Rate is the most critical metric for
--            any subscription or ecommerce business
--            High churn = business is dying slowly
-- CONCEPT  : CTE used to find last order date per customer
--            DATEDIFF calculates days since last purchase
--            90 days is standard churn threshold for ecommerce
-- INSIGHT  : Churn rate above 30% = serious problem
--            Industry average churn is 20-25%
--            Every 1% reduction in churn = significant revenue gain
-- -------------------------------------------------------
WITH last_order AS (
    SELECT
    customer_id,
    MAX(order_date) AS last_order_date
    FROM ecommerce_orders
    GROUP BY customer_id
)
SELECT
COUNT(DISTINCT CASE WHEN DATEDIFF('2024-12-31', last_order_date) > 90
      THEN customer_id END) AS churned_customers,
COUNT(DISTINCT customer_id) AS total_customers,
ROUND(
    COUNT(DISTINCT CASE WHEN DATEDIFF('2024-12-31', last_order_date) > 90
    THEN customer_id END) * 100.0
    / COUNT(DISTINCT customer_id), 2
) AS churn_rate
FROM last_order;


-- -------------------------------------------------------
-- Query 25 : Churn by Customer Segment
-- -------------------------------------------------------
-- PURPOSE  : Find churn rate separately for each segment
-- WHY      : Not all segments churn equally
--            New customers churn more than VIP customers
-- CONCEPT  : Two CTEs chained together
--            First CTE = last order per customer
--            Second CTE = add churn flag and segment info
-- INSIGHT  : If New segment churn is 60% = acquisition is wasted
--            If VIP segment churn is 10% = good, protect them
--            Focus retention budget on Regular segment
--            because they have potential to become Premium
-- -------------------------------------------------------
WITH last_order AS (
    SELECT
    customer_id,
    MAX(order_date) AS last_order_date
    FROM ecommerce_orders
    GROUP BY customer_id
),
churn_flag AS (
    SELECT
    l.customer_id,
    c.customer_segment,
    CASE WHEN DATEDIFF('2024-12-31', l.last_order_date) > 90
         THEN 'Churned' ELSE 'Active' END AS churn_status
    FROM last_order l
    JOIN ecommerce_customers c ON l.customer_id = c.customer_id
)
SELECT
customer_segment,
COUNT(*) AS total_customers,
SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned,
SUM(CASE WHEN churn_status = 'Active' THEN 1 ELSE 0 END) AS active,
ROUND(SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2) AS churn_rate
FROM churn_flag
GROUP BY customer_segment
ORDER BY churn_rate DESC;


-- -------------------------------------------------------
-- Query 26 : Churn by Region
-- -------------------------------------------------------
-- PURPOSE  : Find which region has highest customer churn
-- WHY      : Regional churn could mean delivery problems
--            or competitor is stronger in that region
-- INSIGHT  : If East region has 40% churn = check if
--            delivery is slow there or competitor Meesho/Flipkart
--            is running aggressive campaigns in that region
--            Regional churn analysis helps operations team
--            fix logistics issues before they get worse
-- -------------------------------------------------------
WITH last_order AS (
    SELECT
    customer_id,
    MAX(order_date) AS last_order_date
    FROM ecommerce_orders
    GROUP BY customer_id
),
churn_flag AS (
    SELECT
    l.customer_id,
    o.region,
    CASE WHEN DATEDIFF('2024-12-31', l.last_order_date) > 90
         THEN 'Churned' ELSE 'Active' END AS churn_status
    FROM last_order l
    JOIN ecommerce_orders o ON l.customer_id = o.customer_id
    GROUP BY l.customer_id, o.region, churn_status
)
SELECT
region,
COUNT(DISTINCT customer_id) AS total_customers,
SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) * 100.0
      / COUNT(DISTINCT customer_id), 2) AS churn_rate
FROM churn_flag
GROUP BY region
ORDER BY churn_rate DESC;


-- -------------------------------------------------------
-- Query 27 : High Risk Customers
-- -------------------------------------------------------
-- PURPOSE  : Find customers who haven't ordered in 60-90 days
--            They have not churned yet but are about to
-- WHY      : These customers can still be saved with
--            a win-back campaign before they fully churn
-- INSIGHT  : Send these customers a personalised email
--            with a special discount like
--            "We miss you! Here is 20% off your next order"
--            This is called Win-Back Campaign in product analytics
--            Saving 1 high risk customer costs 5x less than
--            acquiring a new customer
-- -------------------------------------------------------
WITH last_order AS (
    SELECT
    customer_id,
    MAX(order_date) AS last_order_date
    FROM ecommerce_orders
    GROUP BY customer_id
)
SELECT
l.customer_id,
c.customer_segment,
c.city,
l.last_order_date,
DATEDIFF('2024-12-31', l.last_order_date) AS days_since_last_order
FROM last_order l
JOIN ecommerce_customers c ON l.customer_id = c.customer_id
WHERE DATEDIFF('2024-12-31', l.last_order_date) BETWEEN 60 AND 90
ORDER BY days_since_last_order DESC;


-- =====================================================
-- SECTION 7 : COHORT ANALYSIS
-- =====================================================

-- -------------------------------------------------------
-- Query 28 : Monthly Cohort Table
-- -------------------------------------------------------
-- PURPOSE  : Group customers by the month they first purchased
--            Then track how many returned in month 1, 2, 3...
-- WHY      : Cohort analysis is the gold standard for
--            measuring true customer retention over time
-- CONCEPT  : CTE 1 = find first order month for each customer
--            CTE 2 = calculate month number for every order
--            PERIOD_DIFF = difference between two year-month values
--            CASE WHEN = pivot data into columns
-- INSIGHT  : January 2022 cohort had 100 customers
--            If only 20 returned in month 1 = 20% retention
--            If retention drops below 10% by month 3 = bad
--            Good ecommerce has 30%+ month 1 retention
--            This table is what product managers present
--            in board meetings to show platform health
-- -------------------------------------------------------
WITH first_order AS (
    SELECT
    customer_id,
    DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM ecommerce_orders
    GROUP BY customer_id
),
cohort_orders AS (
    SELECT
    f.customer_id,
    f.cohort_month,
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    PERIOD_DIFF(
        DATE_FORMAT(o.order_date, '%Y%m'),
        DATE_FORMAT(f.cohort_month, '%Y%m')
    ) AS month_number
    FROM first_order f
    JOIN ecommerce_orders o ON f.customer_id = o.customer_id
)
SELECT
cohort_month,
COUNT(DISTINCT CASE WHEN month_number = 0 THEN customer_id END) AS month_0,
COUNT(DISTINCT CASE WHEN month_number = 1 THEN customer_id END) AS month_1,
COUNT(DISTINCT CASE WHEN month_number = 2 THEN customer_id END) AS month_2,
COUNT(DISTINCT CASE WHEN month_number = 3 THEN customer_id END) AS month_3,
COUNT(DISTINCT CASE WHEN month_number = 6 THEN customer_id END) AS month_6,
COUNT(DISTINCT CASE WHEN month_number = 12 THEN customer_id END) AS month_12
FROM cohort_orders
GROUP BY cohort_month
ORDER BY cohort_month;


-- -------------------------------------------------------
-- Query 29 : Cohort Retention Rate %
-- -------------------------------------------------------
-- PURPOSE  : Convert cohort numbers into retention percentages
-- WHY      : Raw numbers are hard to compare across cohorts
--            Percentages make comparison easy
-- CONCEPT  : Three CTEs chained together
--            CTE 1 = first order month
--            CTE 2 = cohort size
--            CTE 3 = month numbers
--            Final = calculate retention %
-- INSIGHT  : If Jan cohort has 40% month 1 retention
--            but Feb cohort has only 20% = something went
--            wrong in February (bad campaign, delivery issue)
--            Cohort comparison catches problems early
--            before they affect all customers
-- -------------------------------------------------------
WITH first_order AS (
    SELECT
    customer_id,
    DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM ecommerce_orders
    GROUP BY customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
    FROM first_order
    GROUP BY cohort_month
),
cohort_orders AS (
    SELECT
    f.customer_id,
    f.cohort_month,
    PERIOD_DIFF(
        DATE_FORMAT(o.order_date, '%Y%m'),
        DATE_FORMAT(f.cohort_month, '%Y%m')
    ) AS month_number
    FROM first_order f
    JOIN ecommerce_orders o ON f.customer_id = o.customer_id
)
SELECT
co.cohort_month,
cs.cohort_customers AS total_customers,
ROUND(COUNT(DISTINCT CASE WHEN month_number = 1 THEN co.customer_id END)
      * 100.0 / cs.cohort_customers, 2) AS month_1_retention,
ROUND(COUNT(DISTINCT CASE WHEN month_number = 3 THEN co.customer_id END)
      * 100.0 / cs.cohort_customers, 2) AS month_3_retention,
ROUND(COUNT(DISTINCT CASE WHEN month_number = 6 THEN co.customer_id END)
      * 100.0 / cs.cohort_customers, 2) AS month_6_retention
FROM cohort_orders co
JOIN cohort_size cs ON co.cohort_month = cs.cohort_month
GROUP BY co.cohort_month, cs.cohort_customers
ORDER BY co.cohort_month;


-- =====================================================
-- SECTION 8 : WINDOW FUNCTIONS
-- =====================================================

-- -------------------------------------------------------
-- Query 30 : Customer Revenue Ranking
-- -------------------------------------------------------
-- PURPOSE  : Rank all customers by their total spending
-- WHY      : Identify top spenders for VIP treatment
-- CONCEPT  : RANK()       = gives same rank to ties, skips next rank
--            DENSE_RANK() = gives same rank to ties, no skipping
--            ROW_NUMBER() = always unique number, no ties
--            Example : scores 100, 100, 90
--            RANK        = 1, 1, 3
--            DENSE_RANK  = 1, 1, 2
--            ROW_NUMBER  = 1, 2, 3
-- INSIGHT  : Top 10% customers by revenue = your VIP segment
--            These customers should get dedicated account managers
--            exclusive early access to new products
--            and special festival offers
-- -------------------------------------------------------
SELECT
customer_id,
total_revenue,
RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,
DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS dense_rank,
ROW_NUMBER() OVER(ORDER BY total_revenue DESC) AS row_num
FROM (
    SELECT
    customer_id,
    ROUND(SUM(revenue), 2) AS total_revenue
    FROM ecommerce_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) AS revenue_summary
LIMIT 20;


-- -------------------------------------------------------
-- Query 31 : Top 3 Customers Per Region
-- -------------------------------------------------------
-- PURPOSE  : Find top 3 revenue customers in each region
-- WHY      : Regional top customers get region specific offers
-- CONCEPT  : PARTITION BY = restart ranking for each region
--            This is the most important window function concept
--            Without PARTITION BY = rank across entire dataset
--            With PARTITION BY = rank within each group
-- INSIGHT  : Top customers in each region are brand ambassadors
--            Give them referral programs to bring more customers
--            from their city or state
-- -------------------------------------------------------
WITH regional_revenue AS (
    SELECT
    c.customer_id,
    c.customer_segment,
    o.region,
    ROUND(SUM(o.revenue), 2) AS total_revenue,
    RANK() OVER(PARTITION BY o.region ORDER BY SUM(o.revenue) DESC) AS region_rank
    FROM ecommerce_customers c
    JOIN ecommerce_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_segment, o.region
)
SELECT * FROM regional_revenue
WHERE region_rank <= 3;


-- -------------------------------------------------------
-- Query 32 : Month over Month Revenue Growth (LAG)
-- -------------------------------------------------------
-- PURPOSE  : Compare each month revenue with previous month
--            and calculate growth percentage
-- WHY      : MoM growth is reported in every business review meeting
--            Positive growth = good, Negative = investigate
-- CONCEPT  : LAG() = access previous row value
--            LAG(revenue) = previous month revenue
--            Without LAG you would need a self join which is complex
--            LAG makes it simple in one query
-- INSIGHT  : If MoM growth is consistently above 10% = healthy growth
--            If growth suddenly drops to -20% = something happened
--            Check if there was a competitor sale, delivery issues
--            or product stock out in that month
-- -------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    ROUND(SUM(revenue), 2) AS revenue
    FROM ecommerce_orders
    WHERE order_status = 'Delivered'
    GROUP BY 1
)
SELECT
order_month,
revenue,
LAG(revenue) OVER(ORDER BY order_month) AS prev_month_revenue,
ROUND(
    (revenue - LAG(revenue) OVER(ORDER BY order_month))
    * 100.0 / LAG(revenue) OVER(ORDER BY order_month), 2
) AS mom_growth_percent
FROM monthly_revenue
ORDER BY order_month;


-- -------------------------------------------------------
-- Query 33 : Running Total Revenue
-- -------------------------------------------------------
-- PURPOSE  : Show cumulative revenue growing month by month
-- WHY      : Running total shows if business is on track
--            to hit annual revenue target
-- CONCEPT  : SUM() OVER(ORDER BY) = running total
--            Each row adds current month to all previous months
--            This is called cumulative sum or running sum
-- INSIGHT  : If you set annual target of 1 Crore
--            Running total by June should be around 50 Lakhs
--            If it is only 30 Lakhs by June = you are behind target
--            Take action in Q3 to recover the gap
-- -------------------------------------------------------
SELECT
DATE_FORMAT(order_date, '%Y-%m') AS order_month,
ROUND(SUM(revenue), 2) AS monthly_revenue,
ROUND(SUM(SUM(revenue)) OVER(ORDER BY DATE_FORMAT(order_date, '%Y-%m')), 2) AS running_total
FROM ecommerce_orders
WHERE order_status = 'Delivered'
GROUP BY 1
ORDER BY 1;


-- =====================================================
-- SECTION 9 : RFM ANALYSIS
-- =====================================================

-- -------------------------------------------------------
-- Query 34 : Calculate Raw RFM Values
-- -------------------------------------------------------
-- PURPOSE  : Calculate Recency, Frequency, Monetary for
--            every customer
-- WHY      : RFM is the foundation of customer segmentation
--            Used by every major ecommerce company
-- CONCEPT  : R = Recency   = days since last purchase (lower is better)
--            F = Frequency = number of orders placed (higher is better)
--            M = Monetary  = total money spent (higher is better)
--            DATEDIFF = calculate days between two dates
-- INSIGHT  : Customer with R=5, F=50, M=100000 = Champion
--            Customer with R=300, F=1, M=500 = Lost Customer
--            RFM tells you everything about a customer
--            in just 3 numbers
-- -------------------------------------------------------
WITH rfm_base AS (
    SELECT
    customer_id,
    DATEDIFF('2024-12-31', MAX(order_date)) AS recency,
    COUNT(DISTINCT order_id) AS frequency,
    ROUND(SUM(revenue), 2) AS monetary
    FROM ecommerce_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),

-- -------------------------------------------------------
-- Query 35 : RFM Scoring with NTILE
-- -------------------------------------------------------
-- PURPOSE  : Convert raw RFM values into scores of 1 to 5
-- WHY      : Raw values are hard to compare
--            Scores 1-5 make it easy to segment customers
-- CONCEPT  : NTILE(5) = divides customers into 5 equal buckets
--            For Recency  : lower days = higher score (DESC)
--            For Frequency: higher orders = higher score (ASC)
--            For Monetary : higher spend = higher score (ASC)
--            Score 5 = best, Score 1 = worst
-- INSIGHT  : A customer with R=5, F=5, M=5 = perfect customer
--            A customer with R=1, F=1, M=1 = completely lost
--            NTILE makes scoring fair and data driven
--            not based on manual thresholds
-- -------------------------------------------------------
rfm_scores AS (
    SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER(ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER(ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),

-- -------------------------------------------------------
-- Query 36 : RFM Segmentation with CASE WHEN
-- -------------------------------------------------------
-- PURPOSE  : Assign segment name to each customer
--            based on their RFM scores
-- WHY      : Segment names make it easy for marketing team
--            to create targeted campaigns
-- CONCEPT  : CASE WHEN checks score combinations
--            and assigns meaningful segment labels
--            CONCAT combines R, F, M scores into one code
--            Example : score 543 = R5, F4, M3
-- SEGMENT DEFINITIONS :
--   Champions      = High R + High F + High M (best customers)
--   Loyal          = Medium-High R + Medium-High F
--   New Customers  = High R + Low F (just joined)
--   Potential      = Medium R + Medium M (can grow)
--   At Risk        = Low R + High F (used to be good, now fading)
--   Cant Lose      = Low R + Very High F (must save these)
--   Lost           = Low R + Low F (gone)
-- -------------------------------------------------------
rfm_segments AS (
    SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 3 THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'Cant Lose Them'
        WHEN r_score <= 1 AND f_score <= 2 THEN 'Lost Customers'
        ELSE 'Needs Attention'
    END AS rfm_segment
    FROM rfm_scores
)

-- -------------------------------------------------------
-- Query 37 : RFM Segment Summary (MOST IMPORTANT QUERY)
-- -------------------------------------------------------
-- PURPOSE  : Final summary showing all segments with
--            customer count, avg metrics and total revenue
-- WHY      : This is the deliverable that goes to management
--            One table that tells the entire customer story
-- INSIGHT  : Champions = reward them, ask for reviews, referrals
--            Loyal = upsell to premium products
--            New Customers = onboard well, give second purchase offer
--            Potential Loyalist = give loyalty points to push them up
--            At Risk = send win back campaign immediately
--            Cant Lose Them = call personally, give big discount
--            Lost Customers = one last email campaign, then accept loss
--            Needs Attention = analyse individually
--
-- THIS QUERY SHOWS YOU ARE A PRODUCT ANALYST
-- NOT JUST A SQL DEVELOPER
-- TAKE SCREENSHOT OF THIS FOR SURE ⭐⭐⭐
-- -------------------------------------------------------
SELECT
rfm_segment,
COUNT(DISTINCT customer_id) AS total_customers,
ROUND(AVG(recency), 0) AS avg_recency_days,
ROUND(AVG(frequency), 1) AS avg_frequency,
ROUND(AVG(monetary), 2) AS avg_monetary,
ROUND(SUM(monetary), 2) AS total_revenue
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_revenue DESC;
