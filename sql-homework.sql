-- select DB "sakila"
USE sakila;

-- 1a - select the first name and last name of actors from the actor table
SELECT first_name, last_name
FROM actor

-- 1b - save the first and last name in uppercase letters into new column 'Actor Name'
SELECT first_name, last_name, CONCAT(first_name, ' ', last_name) as 'Actor Name'
FROM actor

-- 2a - find first and last name, id number from just a first name "Joe"
SELECT actor_id, first_name, last_name
FROM actor
WHERE first_name = 'Joe'

-- 2b - find all actors with the last name including 'gen'
SELECT CONCAT(first_name, ' ', last_name) as 'Actor Name'
FROM actor
WHERE last_name LIKE '%G%E%N%'

-- 2c - find all actors with the last name including 'li'
SELECT last_name, first_name
FROM actor
WHERE last_name LIKE '%L%I%'

-- 2c - find the country name and country_id using 'IN' for Afghanistan, Bangladesh, and China
SELECT country_id, country
FROM country
WHERE country IN ('Afghanistan', 'Bangladesh', 'China')

-- 3a - create column 'Description' as 'BLOB' data type,
ALTER TABLE actor
	ADD Description BLOB
    
-- 3b - delete 'Description' column from table
ALTER TABLE actor
	DROP COLUMN Description

-- 4a - list last names of actors, as well as the count of how many actors have that last name
SELECT last_name, COUNT(last_name) as Count
FROM actor
GROUP BY last_name

-- 4b - list last name of actors, as well as the count, but only if shared with two or less individuals
SELECT last_name, COUNT(last_name) as Count
FROM actor
GROUP BY last_name
HAVING  COUNT(last_name) < 3

-- 4c - actor 'Harpo Williams' was entered incorrectly as 'Groucho Williams' in actor table. fix this.
UPDATE actor 
SET first_name = 'Groucho'
WHERE first_name = 'Harpo' AND last_name = 'Williams'

-- 4d - change 'Groucho' back to 'Harpo'
UPDATE actor
set first_name = 'Harpo'
WHERE first_name = 'Groucho' and last_name = 'Williams'

-- 5a - what query would allow you to recreate the schema from the address table
SHOW CREATE TABLE address

-- 6a - join staff and address tables to display first_name, last_name, and address
SELECT first_name, last_name, address
FROM staff s
INNER JOIN address a ON s.address_id = a.address_id

-- 6b - join staff and payment tables to display the total amount rung up by each staff member in Aug 2005
SELECT CONCAT(s.first_name, ' ', s.last_name) AS full_name, SUM(amount) as total_sales
FROM staff s
CROSS JOIN payment p ON s.staff_id = p.staff_id
WHERE p.payment_date BETWEEN '2005-08-01 %' AND '2005-08-30 %'
GROUP BY CONCAT(s.first_name, ' ', s.last_name) 

-- 6c - use inner join to list each film and the number of actors listed for that film
SELECT f.title, ctr.num_actor-- , c.last_update-- , f.title
FROM film AS f
JOIN (
		SELECT film_id, count(*) as 'num_actor'
        FROM film_actor
        GROUP BY film_id
		) AS ctr
ON f.film_id = ctr.film_id


-- 6d - how many copies of 'Hunchback Impossible' exist in inventory
SELECT f.title, COUNT(i.film_id) as Count
FROM film f
CROSS JOIN inventory i ON f.film_id = i.film_id
WHERE f.title = 'Hunchback Impossible'

-- 6e - using payment and customer and join command, list total paid by each customer. list alphabetically
SELECT CONCAT(c.first_name, ' ', c.last_name) as customer, SUM(amount)
FROM  customer c
CROSS JOIN payment p ON c.customer_id = p.customer_id
GROUP BY CONCAT(c.first_name, ' ', c.last_name) 
ORDER BY CONCAT(c.first_name, ' ', c.last_name)

-- 7a - use subqueries to display titles with 'K' or 'Q' 
SELECT title
FROM film
WHERE language_id = (
		SELECT language_id
		FROM language
		WHERE name = 'english'
		)
and title LIKE 'K%' OR title LIKE 'Q%'

-- 7b - use subqueries to display all actors in 'Home Alone'
SELECT last_name, first_name
FROM actor
WHERE actor_id IN  (
		SELECT actor_id
		FROM film_actor
		WHERE film_id = (
				SELECT film_id
				FROM film
				WHERE title='Alone Trip'
                )
		)

-- 7c - Retrieve email, first and last name using subqueries
SELECT email, CONCAT(first_name, ' ',  last_name)
FROM customer
WHERE address_id IN (
		SELECT address_id
		FROM address
		WHERE city_id IN (
				SELECT city_id
				FROM city
				WHERE country_id= (
						SELECT country_id
						FROM country
						WHERE country= 'Canada'
						)
				)

		)

-- 7d - identify all family films
SELECT *
FROM film
WHERE film_id in (
		SELECT film_id
        FROM film_category
        WHERE category_id = (
				SELECT category_id
                FROM category
                WHERE name = 'family'
                )
		)

-- 7e - display move and number of rentals in descending order
SELECT f.title, total.rental_num
FROM film AS f
JOIN (  
		SELECT i.film_id, SUM(rg.rental_num) AS 'rental_num'
		FROM inventory as i
		JOIN (SELECT  inventory_id, COUNT(rental_id) AS 'rental_num'
				FROM rental
				GROUP BY inventory_id
              ) AS rg
		ON i.inventory_id=rg.inventory_id
		GROUP BY i.film_id
	  ) AS total
ON f.film_id = total.film_id
ORDER BY total.rental_num DESC

-- 7f - write query to disply how much business
SELECT c.city, asspt.total
FROM city AS c
JOIN (	
		SELECT a.city_id, sspt.total
		FROM address AS a
		JOIN (  
				SELECT s.address_id, spt.total
				FROM store AS s
				JOIN (  
						SELECT st.store_id, pt.total
						FROM staff AS st
						JOIN ( 	
								SELECT staff_id, SUM(amount) AS 'total'
								FROM payment
								GROUP BY staff_id
								) AS pt
						ON st.staff_id = pt.staff_id
						) AS spt
				ON s.store_id = spt.store_id
			  ) AS sspt
		ON a.address_id = sspt.address_id
	 ) AS asspt
ON c.city_id = asspt.city_id

-- 7g -  write a query to display for each store its store ID, city, and country.
SELECT com.store_id, com.city, co.country 
FROM country AS co
JOIN (	
		SELECT c.city, c.country_id, st.store_id
		FROM city as c
		JOIN (
				SELECT a.city_id, s.store_id
				FROM address AS a
				JOIN store AS s
				ON a.address_id = s.address_id
				) AS st
		ON c.city_id = st.city_id
		) AS com
ON co.country_id = com.country_id

-- 7h - list the top five genres in gross revenue in descending order
SELECT c.name, agg.total
FROM category AS c
JOIN (	
		SELECT fc.category_id, SUM(irpg.total) AS total
		FROM film_category AS fc
		JOIN (	
				SELECT i.film_id, SUM(rpg.total) AS total
				FROM inventory AS i
				JOIN (	
						SELECT r.inventory_id, SUM(pg.total) AS total
						FROM rental AS r
						JOIN (	
								SELECT rental_id, SUM(amount) AS total
								FROM payment
								GROUP BY rental_id
							  ) AS pg
						ON r.rental_id = pg.rental_id
						GROUP BY inventory_id
					 ) AS rpg
				ON i.inventory_id = rpg.inventory_id
				GROUP BY i.film_id
			 ) AS irpg
		ON fc.film_id = irpg.film_id
		GROUP BY fc.category_id 
	) AS agg
ON c.category_id = agg.category_id
ORDER BY agg.total DESC
LIMIT 5

-- 8a - create a view of query from 7h
CREATE VIEW top_5_genre
AS SELECT c.name, agg.total
FROM category AS c
JOIN (	
		SELECT fc.category_id, SUM(irpg.total) AS total
		FROM film_category AS fc
		JOIN (	
				SELECT i.film_id, SUM(rpg.total) AS total
				FROM inventory AS i
				JOIN (	
						SELECT r.inventory_id, SUM(pg.total) AS total
						FROM rental AS r
						JOIN (	
								SELECT rental_id, SUM(amount) AS total
								FROM payment
								GROUP BY rental_id
							  ) AS pg
						ON r.rental_id = pg.rental_id
						GROUP BY inventory_id
					 ) AS rpg
				ON i.inventory_id = rpg.inventory_id
				GROUP BY i.film_id
			 ) AS irpg
		ON fc.film_id = irpg.film_id
		GROUP BY fc.category_id 
	) AS agg
ON c.category_id = agg.category_id
ORDER BY agg.total DESC
LIMIT 5

-- 8b - diplay view
SELECT * FROM top_5_genre 

-- 8c - delete the view just created
DROP VIEW top_5_genre