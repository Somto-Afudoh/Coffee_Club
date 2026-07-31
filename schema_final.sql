--------------- TASK 1-------------
-- check for duplicates 
SELECT customer_id, COUNT(*) AS duplicate_count
FROM coffee.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
----------------------------------------------
SELECT Offer_id, COUNT(*) AS duplicate_count
FROM coffee.offers
GROUP BY offer_id
HAVING COUNT(*) > 1;
----------------------------------------------
SELECT event_id, COUNT(*) AS duplicate_count
FROM coffee.events
GROUP BY event_id
HAVING COUNT(*) > 1;

-- check for NULL values 
SELECT *
FROM coffee.customers
WHERE customer_id IS NULL;
-----------------------------------------------
SELECT *
FROM coffee.offers
WHERE offer_id IS NULL;
------------------------------------------------
SELECT *
FROM coffee.events
WHERE event_id IS NULL;


-- create primary key constraint for customers table

ALTER TABLE coffee.customers
ADD CONSTRAINT pk_customer
PRIMARY KEY (customer_id);

--------------------------------------------------------------

-- create primary key constraint for events table

ALTER TABLE coffee.events
ADD CONSTRAINT pk_events
PRIMARY KEY (event_id);

--------------------------------------------------------------

-- create primary key constraint for offers table

ALTER TABLE coffee.offers
ADD CONSTRAINT pk_offers
PRIMARY KEY (offer_id);

--------------------------------------------------------------

-- Check for Orphaned records
SELECT e.*
FROM coffee.events e
LEFT JOIN coffee.customers c
ON e.customer_id = c.customer_id
WHERE e.customer_id is NOT NULL
AND c.customer_id IS NULL;

---------------------------------

SELECT e.*
FROM coffee.events e
LEFT JOIN coffee.offers o
ON e.offer_id = o.offer_id
WHERE e.offer_id is NOT NULL
AND o.offer_id IS NULL;

---------------------------------

SELECT c.*
FROM coffee.offer_channels c
LEFT JOIN coffee.offers o
ON c.offer_id = o.offer_id
WHERE c.offer_id is NOT NULL
AND o.offer_id IS NULL;
--------------------------------------------------------------
-- create foreign key constraint on events table for customers

ALTER TABLE coffee.events
ADD CONSTRAINT fk_customers_events
FOREIGN KEY (customer_id) 
REFERENCES coffee.customers(customer_id)
ON DELETE RESTRICT;

--------------------------------------------------------------

-- create foreign key constraint on events table for offers

ALTER TABLE coffee.events
ADD CONSTRAINT fk_offers_events
FOREIGN KEY (offer_id) 
REFERENCES coffee.offers(offer_id)
ON DELETE RESTRICT;

--------------------------------------------------------------

-- create foreign key constraint on offers_channel table for offers

ALTER TABLE coffee.offer_channels
ADD CONSTRAINT fk_offers_offer_channels
FOREIGN KEY (offer_id) 
REFERENCES coffee.offers(offer_id)
ON DELETE CASCADE;

-- index all foreign keys on events table
CREATE INDEX idx_events_customer_id ON coffee.events (customer_id);
CREATE INDEX idx_events_offer_id ON coffee.events (offer_id);

-- index all foreign keys at offer channels table
CREATE INDEX idx_offer_channels_offer_id ON coffee.offer_channels (offer_id);


--------------- TASK 2-------------
SELECT *
FROM coffee.events;
-- ADD day column
ALTER TABLE coffee.events
ADD COLUMN day INTEGER;

UPDATE coffee.events
SET day = time / 24;

------------------------
--Add hour of day column
ALTER TABLE coffee.events
ADD COLUMN hour_of_day INTEGER;

UPDATE coffee.events
SET hour_of_day = time % 24;

--------------------------------
-- Add interval column
ALTER TABLE coffee.events
ADD COLUMN campaign_duration INTERVAL;

UPDATE coffee.events
SET campaign_duration = time * INTERVAL '1 hour';

-------------------------------------------------
--Check for invalid range

SELECT *
FROM coffee.events
WHERE time < 0
	OR time >= 720;

--------------------------------------
-- Handle the Age 118
-- Identify the suspicious age value

SELECT customer_id, age
FROM coffee.customers
WHERE age = 118;

-- count affected records
SELECT COUNT(*) AS age_118_count
FROM coffee.customers
WHERE age = 118;

-- Treat 118 as a placeholder and convert it to NULL
UPDATE coffee.customers
SET age = NULL
WHERE age = 118;

-- Verify the cleaning
SELECT customer_id, age
FROM coffee.customers
WHERE age IS NULL;


--------------- TASK 2-------------
CREATE VIEW coffee.offer_performance_summary AS
SELECT
	o.offer_id,
	o.offer_type,
	COUNT(*) FILTER (
		WHERE e.event = 'offer received'
	) AS total_received,
	COUNT(*) FILTER (
		WHERE e.event = 'offer completed'
	) AS total_completed,
	ROUND(
		100.0 * COUNT(*) FILTER (
			WHERE e.event = 'offer completed'
		)
		/ NULLIF(
			COUNT(*) FILTER (
				WHERE e.event = 'offer received'
			),
			0
		),
		2
	) AS completion_rate_percent
FROM coffee.offers o
LEFT JOIN coffee.events e
	ON o.offer_id = e.offer_id
GROUP BY
	o.offer_id,
	o.offer_type;

SELECT *
FROM coffee.offer_performance_summary
ORDER BY completion_rate_percent DESC;
--------------------------------------------------

-- Run query for  offer with the highest completion rate
SELECT *
FROM coffee.offer_performance_summary
WHERE total_received > 0
ORDER BY
	completion_rate_percent DESC,
	total_completed DESC
LIMIT 1;

----------------------Task 3-------------------------------

-- informational offers were followed by transactions
CREATE VIEW coffee.informational_offer_transactions AS
WITH influenced_transactions AS (
    SELECT DISTINCT
        o.offer_id,
        t.event_id AS transaction_event_id,
        t.customer_id,
        t.amount
    FROM coffee.offers o
    JOIN coffee.events v
        ON o.offer_id = v.offer_id
       AND v.event = 'offer viewed'
    JOIN coffee.events t
        ON t.customer_id = v.customer_id
       AND t.event = 'transaction'
       AND t.time > v.time
       AND t.time <= v.time + (o.duration * 24)
    WHERE o.offer_type = 'informational'
)
SELECT
    o.offer_id,
    o.offer_type,
    COUNT(it.transaction_event_id) AS influenced_transactions,
    COUNT(DISTINCT it.customer_id) AS influenced_customers,
    ROUND(
        COALESCE(SUM(it.amount), 0)::NUMERIC,
        2
    ) AS influenced_transaction_amount
FROM coffee.offers o
LEFT JOIN influenced_transactions it
    ON o.offer_id = it.offer_id
WHERE o.offer_type = 'informational'
GROUP BY
    o.offer_id,
    o.offer_type;

-- Run query for informational offers were followed by transactions
SELECT *
FROM coffee.informational_offer_transactions
ORDER BY influenced_transactions DESC;
-------------------------------------------------

-- A sinple tab;e for non-techical users
CREATE OR REPLACE VIEW coffee.offer_analytics_report AS
SELECT
    p.offer_id,
    p.offer_type,
    p.total_received,
    p.total_completed,
    p.completion_rate_percent,
    COALESCE(i.influenced_transactions, 0) AS influenced_transactions,
    COALESCE(i.influenced_customers, 0) AS influenced_customers,
    COALESCE(i.influenced_transaction_amount, 0) AS influenced_transaction_amount
FROM coffee.offer_performance_summary p
LEFT JOIN coffee.informational_offer_transactions i
    ON p.offer_id = i.offer_id;

-- Run Query for reporting view
SELECT *
FROM coffee.offer_analytics_report
ORDER BY
    completion_rate_percent DESC,
    influenced_transactions DESC;

------------- Task 4 ------------------

-- Add the new columns

ALTER TABLE coffee.customers
ADD COLUMN income_bucket VARCHAR(20),
ADD COLUMN age_group VARCHAR(20);

-- Create income buckets
UPDATE coffee.customers
SET income_bucket =
    CASE
        WHEN income IS NULL THEN 'Unknown'
        WHEN income < 40000 THEN 'Low Income'
        WHEN income BETWEEN 40000 AND 80000 THEN 'Middle Income'
        WHEN income > 80000 THEN 'High Income'
    END;

-- Create age groups
UPDATE coffee.customers
SET age_group =
    CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END;

-- Verify the results
SELECT
    customer_id,
    age,
    age_group,
    income,
    income_bucket
FROM coffee.customers
ORDER BY customer_id;