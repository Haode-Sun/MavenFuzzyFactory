-- Data Preparation
-- Find the total number of website sessions
Use mavenfuzzyfactory;
Select Count(Distinct website_session_id) As number_of_sessions
From website_sessions;

 
-- Check missing values of the dataset

SELECT
    SUM(website_session_id IS NULL) AS sessionid_no,
    SUM(created_at IS NULL) AS createdat_no,
    SUM(user_id IS NULL) AS userid_no,
    SUM(is_repeat_session IS NULL) AS isrepeatsession_no,
    SUM(utm_source IS NULL) AS utmsource_no,
    SUM(utm_campaign IS NULL) AS utmcampaign_no,
    SUM(utm_content IS NULL) AS utmcontent_no,
    SUM(device_type IS NULL) AS devicetype_no,
    SUM(http_referer IS NULL) AS httpreferer_no
FROM
    website_sessions
	
	
-- Check the number of duplicates
SELECT 
website_session_id, 
created_at,
user_id,
is_repeat_session,
utm_source,
utm_campaign,
utm_content,
device_type,
http_referer,
COUNT(*) as duplicate_number
FROM website_sessions
GROUP BY website_session_id, 
created_at,
user_id,
is_repeat_session,
utm_source,
utm_campaign,
utm_content,
device_type,
http_referer
HAVING COUNT(*) > 1;

-- Check the time range of the dataset
Use mavenfuzzyfactory;
Select Min(created_at) as start_time,
Max(created_at) As end_time
From website_sessions


-- Show the unique values for the categorical columns
SELECT 
DISTINCT utm_source, 
utm_campaign,
utm_content,
http_referer
FROM mavenfuzzyfactory.website_sessions;


Exploratory Data Analysis

-- 1. What is the primary traffic source of website traffic?
Select utm_source,
utm_campaign,
http_referer,
Count(Distinct website_session_id) as session_count,
Concat(Round((Count(Distinct website_session_id)/472871) * 100, 2),'%') As percentage_of_total
From website_sessions
Group By utm_source,
utm_campaign,
http_referer
Order BY session_count Desc


-- 2. How do different traffic channels perform in terms of conversion rates
Use mavenfuzzyfactory;
Select 
ws.utm_source,
ws.utm_campaign,
ws.http_referer,
Count(Distinct ws.website_session_id) As sessions,
Count(Distinct o.order_id) As orders,
Concat(Round((Count(Distinct o.order_id)
/Count(Distinct ws.website_session_id)) *100, 2), '%') As session_to_order_conversion_rate
From website_sessions as ws
Left Join orders as o
On o.website_session_id=ws.website_session_id
Group by ws.utm_source,
ws.utm_campaign,
ws.http_referer
Order By session_to_order_conversion_rate Desc




-- 3.What are the top entry pages?

With entry_page AS
(SELECT 
website_session_id,
Min(website_pageview_id) as entry_point_id
FROM mavenfuzzyfactory.website_pageviews
Group By website_session_id)
Select 
wp.pageview_url,
Count(Distinct ep.website_session_id) As entrypoint_count,
Concat(Round((Count(Distinct ep.website_session_id)/472871) * 100, 2),'%') As percentage_of_total
From entry_page as ep
Left Join website_pageviews AS wp
On wp.website_pageview_id=ep.entry_point_id
Group By wp.pageview_url
Order By entrypoint_count Desc






-- 4. What are the bounce rates associated with different entry pages?
With bounced_table AS
(Select
website_session_id,
Count(Distinct website_pageview_id) As pageview_count
From website_pageviews
Group By website_session_id
Having Count(Distinct website_pageview_id)=1)
Select wp.pageview_url,
Count(Distinct wp.website_session_id) As sessions,
Count(Distinct bt.website_session_id) AS bounced_sessions,
Count(Distinct bt.website_session_id)
/Count(Distinct wp.website_session_id) As bounced_rate 
From website_pageviews as wp
Left Join bounced_table As bt
On wp.website_session_id=bt.website_session_id
Group By pageview_url 
Having pageview_url In ('/home','/lander-1','/lander-2','/lander-3','/lander-4','/lander-5')
Order By bounced_rate






-- 5. What are the overall paid traffic bounce rate trend monthly of different entry page?
Use mavenfuzzyfactory;
-- Select sessions of paid traffic with the first pageview id and number of pages visited
Create Temporary Table sessions_with_first_pageview_ids 
SELECT 
    ws.website_session_id,
    ws.created_at As session_create_time,
    MIN(wp.website_pageview_id) AS min_pageview_id,
    COUNT(DISTINCT wp.website_pageview_id) AS num_pages_visited
FROM website_sessions As ws
Left Join website_pageviews As wp
On ws.website_session_id=wp.website_session_id
Where utm_source IN ('gsearch','bsearch','socialbook')
And utm_campaign In ('nonbrand','brand','pilot','desktop_targeted')
Group by 1;
-- Select entry pages
Create Temporary Table sessions_with_entry_pages
Select 
sessions_with_first_pageview_ids.website_session_id,
sessions_with_first_pageview_ids.session_create_time,
sessions_with_first_pageview_ids.min_pageview_id As first_pageview_id,
sessions_with_first_pageview_ids.num_pages_visited,
website_pageviews.pageview_url As entry_page
From sessions_with_first_pageview_ids
Left Join website_pageviews
On sessions_with_first_pageview_ids.min_pageview_id=website_pageviews.website_pageview_id;
-- Calculate the bounce rate of the paid traffic
Select 
Year(sessions_with_entry_pages.session_create_time) As year,
Month(sessions_with_entry_pages.session_create_time) As month,
Count(Distinct website_session_id) As total_sessions,
Count(Distinct Case When num_pages_visited=1 Then website_session_id Else Null End) As bounced_sessions,
Count(Distinct Case When num_pages_visited=1 Then website_session_id Else Null End)
/Count(Distinct website_session_id) As total_bounce_rate,
Count(Distinct Case When entry_page='/home' And  num_pages_visited=1 Then website_session_id Else Null End)
/Count(Distinct Case When entry_page='/home' Then website_session_id Else Null End) As home_bounce_rate,
Count(Distinct Case When entry_page='/lander-1' And  num_pages_visited=1 Then website_session_id Else Null End)
/Count(Distinct Case When entry_page='/lander-1' Then website_session_id Else Null End) As lander1_bounce_rate,
Count(Distinct Case When entry_page='/lander-2' And  num_pages_visited=1 Then website_session_id Else Null End)
/Count(Distinct Case When entry_page='/lander-2' Then website_session_id Else Null End) As lander2_bounce_rate,
Count(Distinct Case When entry_page='/lander-3' And num_pages_visited=1  Then website_session_id Else Null End)
/Count(Distinct Case When entry_page='/lander-3' Then website_session_id Else Null End) As lander3_bounce_rate,
Count(Distinct Case When entry_page='/lander-4'And num_pages_visited=1 Then website_session_id Else Null End)
/Count(Distinct Case When entry_page='/lander-4' Then website_session_id Else Null End) As lander4_bounce_rate,
Count(Distinct Case When entry_page='/lander-5'And num_pages_visited=1 Then website_session_id Else Null End)
/Count(Distinct Case When entry_page='/lander-5' Then website_session_id Else Null End) As lander5_bounce_rate
From sessions_with_entry_pages
Group By 1,2

-- 6. What are the most viewed and least viewed pages on the website? List the ranking of them.

With pageview_number As
(Select pageview_url,
Count(Distinct website_pageview_id) As pageview_count
From website_pageviews
Group By pageview_url
Having pageview_url Not In ('/home','/lander-1','/lander-2','/lander-3','/lander-4','/lander-5')
Order By pageview_count Desc)

Select pageview_url,
pageview_count,
Dense_rank()Over(Order By pageview_count Desc) pageview_rank
From pageview_number

--- Find the pageview_count of different URLs on a monthly basis
SELECT 
Year(created_at) As year_of_time,
Month(created_at) As month_of_time,
Count(Distinct Case when pageview_url='/billing' Then website_session_id Else Null ENd) AS billing_count,
Count(Distinct Case when pageview_url='/billing-2' Then website_session_id Else Null ENd) AS billing2_count,
Count(Distinct Case when pageview_url='/the-original-mr-fuzzy' Then website_session_id Else Null ENd) AS mrfuzzy_count,
Count(Distinct Case when pageview_url='/the-forever-love-bear' Then website_session_id Else Null ENd) AS lovebear_count,
Count(Distinct Case when pageview_url='/the-birthday-sugar-panda' Then website_session_id Else Null ENd) AS sugarpanda_count,
Count(Distinct Case when pageview_url='/the-hudson-river-mini-bear' Then website_session_id Else Null ENd) AS minibear_count,
Count(Distinct Case when pageview_url='/cart' Then website_session_id Else Null ENd) AS cart_count,
Count(Distinct Case when pageview_url='/shipping' Then website_session_id Else Null ENd) AS shipping_count,
Count(Distinct Case when pageview_url='/thank-you-for-your-order' Then website_session_id Else Null ENd) AS order_count
FROM mavenfuzzyfactory.website_pageviews
Group By 1,2

-- Find out the click rate of specific product page on a monthly basis
SELECT 
Year(created_at) As year_of_time,
Month(created_at) As month_of_time,
Count(Distinct Case when pageview_url='/the-original-mr-fuzzy' Then website_session_id Else Null ENd)
/Count(Distinct Case When pageview_url In ('/the-original-mr-fuzzy','/the-forever-love-bear','/the-birthday-sugar-panda' ,'/the-hudson-river-mini-bear') 
Then website_session_id Else Null ENd) As mrfuzzy_percent,
Count(Distinct Case when pageview_url='/the-forever-love-bear' Then website_session_id Else Null ENd)
/Count(Distinct Case When pageview_url In ('/the-original-mr-fuzzy','/the-forever-love-bear','/the-birthday-sugar-panda' ,'/the-hudson-river-mini-bear') 
Then website_session_id Else Null ENd) As lovebear_percent,
Count(Distinct Case when pageview_url='/the-birthday-sugar-panda' Then website_session_id Else Null ENd)
/Count(Distinct Case When pageview_url In ('/the-original-mr-fuzzy','/the-forever-love-bear','/the-birthday-sugar-panda' ,'/the-hudson-river-mini-bear') 
Then website_session_id Else Null ENd) As sugarpanda_percent,
Count(Distinct Case when pageview_url='/the-hudson-river-mini-bear' Then website_session_id Else Null ENd)
/Count(Distinct Case When pageview_url In ('/the-original-mr-fuzzy','/the-forever-love-bear','/the-birthday-sugar-panda' ,'/the-hudson-river-mini-bear') 
Then website_session_id Else Null ENd) As minibear_percent
FROM mavenfuzzyfactory.website_pageviews
Group By 1,2


-- 7. Can the paid traffic conversion funnels be established to evaluate the conversion rates of the top 2 entry pages? (‘/home’,’/lander-2’)

-- Step 1: Select all pageviews for relevant sessions
Use mavenfuzzyfactory;
-- Select sessions with specific entry pages
Create Temporary Table top2_entry_page_sessions
Select 
website_pageviews.website_session_id,
Min(website_pageview_id) As entry_page_id
From website_pageviews
Left Join website_sessions
On website_pageviews.website_session_id=website_sessions.website_session_id
Where pageview_url In ('/home','/lander-2')
And utm_content In ('b_ad_1','b_ad_2','g_ad_1','g_ad_2','social_ad_1','social_ad_2')
Group By website_pageviews.website_session_id;


-- Step 2: Identify the sequence of placing an order.
With max_pageview_count AS
(
SELECT website_session_id,
Count(Distinct website_pageview_id) As pageview_count
FROM mavenfuzzyfactory.website_pageviews
Group By website_session_id
Order by pageview_count Desc
-- Having Count(Distinct website_pageview_id) =7
)
Select mpc.website_session_id,
wp.website_pageview_id,
wp.pageview_url
From max_pageview_count As mpc
Left Join website_pageviews As wp
On mpc.website_session_id=wp.website_session_id
Group By website_session_id,wp.website_pageview_id
Order By pageview_count Desc;

-- By pulling out the “pageview_url” of a complete session, we know that the sequence of placing an order is:
-- Page 1: entry pages (which are '/home','/lander-1','/lander-2','/lander-3','/lander-4','/lander-5')
-- Page 2: product index page (which is '/products)',
-- Page 3: specific product pages'(which are ‘/the-original-mr-fuzzy','/the-hudson-river-mini-bear','/the-birthday-sugar-panda','/the-forever-love-bear'),
-- Page 4: cart page (which is '/cart'),
-- Page 5: shipping page (which is '/shipping'),
-- Page 6: billing pages (which are '/billing-2','/billing')
-- Page 7: placing an order page (which is '/thank-you-for-your-order')


-- Step 3: Build the conversion funnel.
Create Temporary Table top2_entry_page_conversion_funnel
Select teps.*,wp.pageview_url,
Case When pageview_url='/products' Then 1 Else 0 End As to_product_index_page,
Case When pageview_url IN ('/the-original-mr-fuzzy',
'/the-hudson-river-mini-bear',
'/the-birthday-sugar-panda',
'/the-forever-love-bear') Then 1 Else 0 End As to_product_page,
Case When pageview_url='/cart' Then 1 Else 0 End As to_cart_page,
Case When pageview_url='/shipping' Then 1 Else 0 End As to_shipping_page,
Case When pageview_url In('/billing-2','/billing') Then 1 Else 0 End As to_billing_page,
Case When pageview_url='/thank-you-for-your-order' Then 1 Else 0 End As to_order_page
From top2_entry_page_sessions As teps
Left Join website_sessions As ws
On teps.website_session_id=ws.website_session_id
Left Join website_pageviews As wp
On teps.website_session_id=wp.website_session_id;

--  Calculte conversion rate of each step
Select 
Sum(to_product_index_page)/Count(Distinct website_session_id) As product_index_conv_rate,
Sum(to_product_page)/Sum(to_product_index_page) As product_conv_rate,
Sum(to_cart_page)/Sum(to_product_page) As cart_conv_rate,
Sum(to_shipping_page)/Sum(to_cart_page) As shipping_conv_rate,
Sum(to_billing_page)/Sum(to_shipping_page) As billing_conv_rate,
Sum(to_order_page)/Sum(to_billing_page) As order_conv_rate
From top2_entry_page_conversion_funnel

-- 8.	What is the distribution of traffic across various device types for each traffic source?
-- Step 1 Calculate the total sessions for desktop and mobile respectively.
SELECT
Count(Distinct website_session_id) AS total_sessions,
Count(Distinct Case When device_type='mobile' then website_session_id Else Null End) AS mobile_sessions,
Count(Distinct Case WHen device_type='desktop' Then website_session_id Else Null End ) As desktop_sessons
From Mavenfuzzyfactory.website_sessions



-- Step 2 Calculate the percentage for desktop and mobile of different utm_source.
Select 
utm_source,
Count(Distinct Case When device_type='mobile' then website_session_id Else Null End)
/145844 As mobile_percentage,
Count(Distinct Case When device_type='desktop' then website_session_id Else Null End)
/327027 As desktop_percentage
From website_sessions
Group By 1
Order By 2 Desc 

-- 9.	What percentage of sessions originate from organic search, direct type-ins, and paid searches?
SELECT 
Year(created_at),
Count(Distinct Case When utm_source Is Null And utm_campaign Is Null And http_referer In ('https://www.gsearch.com','https://www.bsearch.com') Then website_session_id Else Null End)
/Count(Distinct website_session_id) As organic_search_rate,
Count(Distinct Case When utm_source Is Null And utm_campaign Is Null And http_referer Is Null Then website_session_id Else Null End)
/Count(Distinct website_session_id) As direct_type_in_rate,
Count(Distinct Case When utm_campaign='brand' Then website_session_id Else Null End)
/Count(Distinct website_session_id) As paid_brand_search_rate,
Count(Distinct Case When utm_campaign='nonbrand' Then website_session_id Else Null End)
/Count(Distinct website_session_id) As paid_nonbrand_search_rate
FROM mavenfuzzyfactory.website_sessions
Group By 1
