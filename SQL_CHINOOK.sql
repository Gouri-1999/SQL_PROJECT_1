select * from employee;
select * from customer;
select * from invoice;
select * from invoice_line;
select * from track;
select * from genre;
select * from playlist;
select * from playlist_track;
select * from album;
select * from artist;
select * from media_type;
use chinook;

                                                         -- OBJECTIVE QUESTIONS

-- Q1. Does any table have missing values or duplicates? If yes how would you handle it ?
-- Null Values in employee table
SELECT * FROM employee
WHERE last_name IS NULL 
   OR first_name IS NULL 
   OR title IS NULL 
   OR reports_to IS NULL 
   OR birthdate IS NULL 
   OR hire_date IS NULL 
   OR address IS NULL 
   OR city IS NULL 
   OR state IS NULL 
   OR country IS NULL 
   OR postal_code IS NULL 
   OR phone IS NULL 
   OR fax IS NULL 
   OR email IS NULL;
   
SELECT 
employee_id, 
COALESCE(reports_to, 'N/A') AS reports_to 
FROM 
employee;
-- Null Values in customer table
SELECT * 
FROM customer 
WHERE first_name IS NULL 
   OR last_name IS NULL 
   OR company IS NULL 
   OR address IS NULL 
   OR city IS NULL 
   OR state IS NULL 
   OR country IS NULL 
   OR postal_code IS NULL 
   OR phone IS NULL 
   OR fax IS NULL 
   OR email IS NULL 
   OR support_rep_id IS NULL;
   
   SELECT customer_id, 
       COALESCE(company, 'N/A') AS company, 
       COALESCE(support_rep_id, 0) AS support_rep_id ,
       coalesce(state,'N/A') As state
FROM customer;
-- Null Values in track table
select * from track
where track_id is null
or name is null 
or album_id is null
or media_type_id is null
or genre_id is null
or composer is null ;
-- Handling Null Values 
select track_id ,
coalesce(composer,'N/A') AS composer
from track;

-- Checking duplicates in Album
SELECT album_id, title, count(*) FROM chinook.album Group by album_id, title having count(*)>1;

-- Checking duplicates in Artist
SELECT * FROM chinook.artist;
SELECT artist_id, name, count(*) FROM chinook.artist Group by artist_id, name having count(*)>1;

-- Checking duplicates in customer
SELECT * FROM chinook.customer;
SELECT customer_id, first_name,last_name, count(*) FROM chinook.customer Group by customer_id, first_name having count(*)>1;

-- Checking duplicates in employee
select * from chinook.employee;
select employee_id,last_name,first_name,count(*) from chinook.employee group by employee_id , first_name, last_name having count(*)>1;

-- Checking duplicates in genre
SELECT * FROM chinook.genre;
SELECT genre_id, name, count(*) FROM chinook.genre Group by genre_id, name having count(*)>1;

-- Checking duplicates in invoice
SELECT * FROM chinook.invoice;
SELECT invoice_id, customer_id, count(*) FROM chinook.invoice Group by customer_id, invoice_id having count(*)>1;

-- Check for duplicate invoice-line
SELECT * FROM chinook.invoice_line;
SELECT invoice_id, invoice_line_id, count(*) FROM chinook.invoice_line Group by invoice_id, invoice_line_id having count(*)>1;

-- Checking duplicates in media_type
SELECT * FROM chinook.media_type;
SELECT media_type_id, COUNT(*) AS count FROM chinook.media_type GROUP BY media_type_id HAVING COUNT(*) > 1;

-- Checking duplicates in playlist
SELECT * FROM chinook.playlist;
SELECT playlist_id,name, COUNT(*) from chinook.playlist group by playlist_id , name having  COUNT(*) > 1;

-- Checking duplicates in track
SELECT * FROM chinook.track;
select track_id , album_id , genre_id , count(*) from chinook.track group by track_id , album_id , genre_id having COUNT(*) > 1;

-- Q2. Find the top-selling tracks and top artist in the USA and identify their most famous genres?
SELECT
  t.name AS Track_Name,
  ar.name AS Artist_Name,
  g.name AS Genre,
  SUM(il.quantity) AS Quantity_Sold
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON i.customer_id = c.customer_id
WHERE c.country = 'USA'
GROUP BY t.name, ar.name, g.name
ORDER BY Quantity_Sold DESC
LIMIT 10;

-- Q3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?

SELECT c.customer_id,c.first_name,c.last_name,
  TIMESTAMPDIFF(YEAR, e.birthdate, CURDATE()) AS age,c.city,COALESCE(c.state,'N/A') as state,c.country
FROM customer c
JOIN employee e ON c.support_rep_id = e.employee_id
limit 20;

-- Q4. Calculate the total revenue and number of invoices for each country, state, and city
-- Total Revenue by Country, State, and City
SELECT billing_country, billing_state, billing_city, SUM(total) AS Total_Revenue
FROM invoice 
GROUP BY billing_country, billing_state, billing_city
ORDER BY Total_Revenue DESC 
limit 10;

-- Number of Invoices by Country, State, and City  
  SELECT billing_country, billing_state, billing_city, COUNT(invoice_id) AS num_invoices
FROM invoice 
GROUP BY billing_country, billing_state, billing_city
ORDER BY num_invoices DESC
 LIMIT 5;

-- Q5. Find the top 5 customers by total revenue in each country

WITH Customer_wise_revenue_cte1 as(
	SELECT
		c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customers,
        c.country,
        SUM(i.total) as Total_Revenue
	FROM 
		customer c 
	INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 
		c.customer_id, customers, c.country
	ORDER BY
		c.country, total_revenue),
ranked_customers_cte2 as (
	SELECT
		customer_id,
        customers,
        country,
        total_revenue,
        RANK() OVER (PARTITION BY country ORDER BY total_revenue desc) as customer_rank
	FROM 
		Customer_wise_revenue_cte1)	
SELECT 
	customer_id,
	customers,
	country,
	total_revenue,
    customer_rank
FROM
	ranked_customers_cte2
WHERE 
	customer_rank <= 5
ORDER BY
	country, customer_rank;

-- Q6. Identify the top-selling track for each customer

WITH Customer_track as (
	SELECT
		c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) as customers,
		SUM(il.quantity) as total_quantity
	FROM 
		customer c 
	 JOIN invoice i ON c.customer_id = i.customer_id
	JOIN invoice_line il ON i.invoice_id = il.invoice_id
	JOIN track t ON t.track_id = il.track_id
	GROUP BY
		c.customer_id, customers),
ranked as(
	SELECT
		Customer_track.customer_id,
        Customer_track.customers,
        Customer_track.total_quantity,
        t.track_id,
        t.name as track_name,
        ROW_NUMBER() OVER (PARTITION BY Customer_track.customer_id ORDER BY Customer_track.total_quantity DESC) as track_rank
	FROM 
		Customer_track
		 JOIN invoice i ON Customer_track.customer_id = i.customer_id
         JOIN invoice_line il ON i.invoice_id = il.invoice_id
		JOIN track t ON t.track_id = il.track_id)        
SELECT 
	customer_id,
    customers,
    track_id,
    track_name,
    total_quantity
FROM 
	ranked
WHERE
	track_rank = 1
ORDER BY
	customer_id;
    
    -- Q7. Are there any patterns or trends in customer purchasing behavior(e.g., frequency of purchases, preferred payment methods,average order value)?
-- 7.1 Frequency of Purchases
SELECT c.customer_id,c.first_name,c.last_name,
COUNT(i.invoice_id) AS Purchase_Frequency
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY Purchase_Frequency DESC
limit 15;

-- 7.2  Calculate the average order value for each customer
SELECT c.customer_id,c.first_name,c.last_name,
Round(AVG(i.total)) AS average_order_value
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY average_order_value DESC
limit 15;

-- 7.3  genre which was purchased on frequent basis

SELECT g.name AS genre,COUNT(il.invoice_line_id) AS purchase_frequency
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
GROUP BY g.name
ORDER BY purchase_frequency DESC
LIMIT 15;

-- Q8 What is the customer churn rate?

WITH RecentInvoice AS (
    SELECT MAX(invoice_date) AS most_recent_invoice_date
    FROM invoice
),
CutoffDate AS (
    SELECT DATE_SUB(most_recent_invoice_date, INTERVAL 1 YEAR) AS cutoff_date
    FROM RecentInvoice
),
ChurnedCustomers AS (
    SELECT 
        c.customer_id,
        COALESCE(c.first_name, ' ',c.last_name) as customers,
        MAX(i.invoice_date) AS last_purchase_date
    FROM 
        customer c
        LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 
        c.customer_id, customers
    HAVING 
        MAX(i.invoice_date) IS NULL OR MAX(i.invoice_date) < (SELECT cutoff_date FROM CutoffDate)
)
-- Calculate the churn rate 
SELECT 
    (SELECT COUNT(*) FROM ChurnedCustomers) / (SELECT COUNT(*) FROM customer) * 100 AS churn_rate;

-- Q9 Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists

WITH GenreSales AS (
    SELECT g.name AS genre,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM Invoice i
    JOIN Invoice_Line il ON i.invoice_id = il.invoice_id
    JOIN Track t ON il.track_id = t.track_id
    JOIN Genre g ON t.genre_id = g.genre_id
    JOIN Customer c ON i.customer_id = c.customer_id
    WHERE c.country = 'USA'
    GROUP BY g.name
),
TotalSales AS (
    SELECT SUM(total_sales) AS total_sales_amount
    FROM GenreSales)
SELECT gs.genre,gs.total_sales,
   (gs.total_sales / ts.total_sales_amount * 100) AS sales_percentage
FROM GenreSales gs
CROSS JOIN TotalSales ts
ORDER BY gs.total_sales DESC
LIMIT 15;

-- Q10 Find customers who have purchased tracks from at least 3 different genres

SELECT c.customer_id, c.first_name, c.last_name,
COUNT(DISTINCT g.genre_id) AS genre_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id, c.first_name,c.last_name
HAVING genre_count >= 3;

-- Q11 Rank genres based on their sales performance in the USA

SELECT g.name AS genre,
RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS sales_rank
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
GROUP BY g.name
ORDER BY sales_rank;

-- Q12 Identify customers who have not made a purchase in the last 3 months

WITH recent_purchase AS (
	SELECT
		c.customer_id
	FROM
		customer c 
		 JOIN invoice i ON c.customer_id = i.customer_id 
	WHERE
		i.invoice_date >= CURDATE() - INTERVAL 3 MONTH)        
SELECT
	c.customer_id,c.first_name, c.last_name
FROM  customer c
    LEFT JOIN recent_purchase rp ON c.customer_id = rp.customer_id
WHERE
	rp.customer_id IS NULL
ORDER BY
	c.customer_id;    


                                        -- SUBJECTIVE QUESTIONS
-- Q1 Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.
                                        
     SELECT 
    g.name,
    SUM(iv.unit_price * iv.quantity) AS TotalSales
FROM 
    invoice_line iv
    JOIN invoice i ON iv.invoice_id = i.invoice_id
    JOIN track t ON iv.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
WHERE 
    i.billing_country = 'USA'
GROUP BY 
    g.name 
ORDER BY 
    TotalSales DESC
LIMIT 3;  

-- Q2 Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.                                 
       --   top-selling genres in countries other than the USA                               
    SELECT
	g.genre_id,
    g.name AS genre_name,
    c.country,
    SUM(il.quantity) AS Quantity_sold
FROM
	genre g 
   JOIN track t ON g.genre_id = t.genre_id
     JOIN invoice_line il ON t.track_id = il.track_id
     JOIN invoice i ON il.invoice_id = i.invoice_id
	JOIN customer c ON i.customer_id = c.customer_id 
WHERE 
	country != 'USA'
GROUP BY
	g.genre_id, genre_name, c.country
ORDER BY 
	quantity_sold DESC;                                    
         
         --   top-selling genres in USA    
	SELECT
	g.genre_id,
    g.name AS Genre_name,
    c.country,
    SUM(il.quantity) AS quantity_sold
FROM
	genre g 
     JOIN track t ON g.genre_id = t.genre_id
	 JOIN invoice_line il ON t.track_id = il.track_id
     JOIN invoice i ON il.invoice_id = i.invoice_id
	 JOIN customer c ON i.customer_id = c.customer_id 
WHERE 
	country = 'USA'
GROUP BY
	g.genre_id, Genre_name, c.country
ORDER BY 
	quantity_sold DESC;
    
-- Q3 Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers? What insights cannthese patterns provide about customer loyalty and retention strategies?    
    
  WITH CustomerPurchaseStats AS (
    SELECT 
        c.customer_id,
        COUNT(i.invoice_id) AS Purchase_Frequency,
        SUM(il.quantity) AS Total_items_purchased,
        SUM(i.total) AS Total_spent,
        AVG(i.total) AS Avg_order_value,
        DATEDIFF(MAX(i.invoice_date), MIN(i.invoice_date)) AS Customer_tenure_days
    FROM 
        customer c
        JOIN invoice i ON c.customer_id = i.customer_id
        JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY 
        c.customer_id
),
CustomerSegments AS (
    SELECT 
        customer_id,
        Purchase_Frequency,
        Total_items_purchased,
        Total_spent,
        Avg_order_value,
        Customer_tenure_days,
        CASE 
            WHEN customer_tenure_days >= 365 THEN 'Long-Term'
            ELSE 'RECENT'
        END AS customer_segment
    FROM 
        CustomerPurchaseStats
)
SELECT 
    customer_segment,
    ROUND(AVG(purchase_frequency),3) AS avg_purchase_frequency,
    ROUND(AVG(total_items_purchased),3) AS avg_basket_size,
    ROUND(AVG(total_spent),3) AS avg_spending_amount,
    ROUND(AVG(avg_order_value),3) AS avg_order_value
FROM 
    CustomerSegments
GROUP BY 
    customer_segment;
    
 -- Q4  Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? How can this information guide product recommendations and cross-selling initiatives?
 
 -- Genre Pairs
SELECT g1.name AS genre1, g2.name AS genre2, COUNT(*) AS frequency
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN genre g1 ON t1.genre_id = g1.genre_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN genre g2 ON t2.genre_id = g2.genre_id
WHERE il1.invoice_line_id < il2.invoice_line_id AND g1.name <> g2.name
GROUP BY g1.name, g2.name
ORDER BY frequency DESC
LIMIT 50;

--- Artist Pairs
SELECT a1.name AS artist1, a2.name AS artist2, COUNT(*) AS frequency
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN artist a1 ON al1.artist_id = a1.artist_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
JOIN artist a2 ON al2.artist_id = a2.artist_id
WHERE il1.invoice_line_id < il2.invoice_line_id AND a1.name <> a2.name
GROUP BY a1.name, a2.name
ORDER BY frequency DESC
LIMIT 50;

--- Album pair
SELECT al1.title AS Album1, al2.title AS Album2, COUNT(*) AS Frequency
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
WHERE il1.invoice_line_id < il2.invoice_line_id
AND al1.title <> al2.title
GROUP BY al1.title, al2.title
ORDER BY frequency DESC
LIMIT 20;

-- Q5 Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations? How might these correlate with local demographic or economic factors?

-- Purchasing Behaviors
SELECT c.country, c.city, COUNT(DISTINCT i.invoice_id) AS total_purchases,
SUM(il.unit_price * il.quantity) AS total_spending,
(Round(AVG(il.unit_price * il.quantity))) AS avg_spending_per_purchase,
COUNT(DISTINCT c.customer_id) AS total_customers
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.country, c.city
ORDER BY total_spending DESC
LIMIT 10;

WITH customer_last_purchase AS (
    SELECT c.customer_id,MAX(i.invoice_date) AS last_purchase_date,c.country,c.city
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country, c.city
)
SELECT country,city,COUNT(*) AS total_customers,
SUM(CASE WHEN DATEDIFF(CURDATE(), last_purchase_date) > 365 THEN 1 ELSE 0 END) AS churned_customers,
round((SUM(CASE WHEN DATEDIFF(CURDATE(), last_purchase_date) > 365 THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS churn_rate
FROM customer_last_purchase
GROUP BY country, city
ORDER BY churn_rate DESC
limit 10;

-- Q6 Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?

WITH Customer_Profile AS (
    SELECT 
        c.customer_id,
        c.country,
        COALESCE(c.state,'N/A') as state,
        c.city,
        MAX(i.invoice_date) AS last_purchase_date,
        SUM(i.total) AS total_spending,
        COUNT(i.invoice_id) AS purchase_frequency,
        AVG(i.total) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        invoice i ON c.customer_id = i.customer_id
    GROUP BY 
        c.customer_id
),
churn_risk AS (
    SELECT 
        cp.customer_id,
        cp.country,
        cp.state,
        cp.city,
        cp.total_spending,
        cp.purchase_frequency,
        cp.avg_order_value,
        CASE 
            WHEN cp.last_purchase_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR) THEN 'High Risk'
            WHEN cp.total_spending < 100 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_profile
    FROM 
        Customer_Profile cp
),
risk_summary AS (
    SELECT 
        country,
        state,
        city,
        risk_profile,
      COUNT(customer_id) AS num_customers,
      AVG(total_spending) AS avg_total_spending,
        AVG(purchase_frequency) AS avg_purchase_frequency,
        AVG(avg_order_value) AS avg_order_value
    FROM 
        churn_risk
    GROUP BY 
        country, state, city, risk_profile
)
SELECT 
    Country,
    State,
    City,
    Risk_profile,
    num_customers,
    Avg_total_spending,
    Avg_purchase_frequency,
    Avg_order_value
FROM 
    risk_summary
ORDER BY 
    risk_profile DESC, avg_total_spending DESC;
    
-- Q7 Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?    
    
 -- Extract customer tenure 
SELECT c.customer_id, c.first_name, c.last_name, c.country, MIN(i.invoice_date) AS First_purchase_date, MAX(i.invoice_date) AS Last_purchase_date, COUNT(i.invoice_id) AS Purchase_count, SUM(i.total) AS Total_Spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id;

--- Extract purchase details
SELECT i.customer_id, il.invoice_line_id, il.track_id, il.unit_price, il.quantity, t.album_id, t.genre_id
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN track t ON il.track_id = t.track_id;
 
 -- Extract album and artist details
SELECT t.track_id, a.album_id, ar.artist_id, ar.name AS Artist_Name
FROM track t
JOIN album a ON t.album_id = a.album_id
JOIN artist ar ON a.artist_id = ar.artist_id; 

  
-- Q8 If data on promotional campaigns (discounts, events, email marketing) is available, how could you measure their impact on customer acquisition, retention, and overall sales?

--  Answer is in Word File

-- Q9 How would you approach this problem, if the objective and subjective questions weren't given?

--  Answer is in Word File

-- Q10 How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?

ALTER TABLE album
ADD COLUMN ReleaseYear INTEGER;
select * from album;

-- Q11Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. They want to know the average total amount spent by customers from each country, along with the number of customers and the average number of tracks purchased per customer

WITH tracks_per_customer AS 
(SELECT 
        i.customer_id,
        SUM(il.quantity) AS total_tracks
    FROM 
        invoice i
    JOIN 
        invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY 
        i.customer_id
),
customer_spending AS (
    SELECT 
        c.country,
        c.customer_id,
        SUM(i.total) AS total_spent,
        tpc.total_tracks
    FROM 
        customer c
    JOIN 
        invoice i ON c.customer_id = i.customer_id
    JOIN 
        tracks_per_customer tpc ON c.customer_id = tpc.customer_id
    GROUP BY 
        c.country, c.customer_id, tpc.total_tracks
)
SELECT 
    cs.country,
    COUNT(DISTINCT cs.customer_id) AS number_of_customers,
  AVG(cs.total_spent) AS average_amount_spent_per_customer,
   AVG(cs.total_tracks) AS average_tracks_purchased_per_customer
FROM 
    customer_spending cs
GROUP BY 
    cs.country
ORDER BY 
    average_amount_spent_per_customer DESC;












