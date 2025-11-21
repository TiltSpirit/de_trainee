--Output the number of movies in each category, sorted descending.
SELECT category.name, count(film.film_id) as number_per_category
FROM category
LEFT JOIN film_category
ON category.category_id = film_category.category_id
LEFT JOIN film
on film_category.film_id = film.film_id
GROUP BY category.category_id
ORDER BY number_per_category DESC
--completed

--Output the 10 actors whose movies rented the most, sorted in descending order.
SELECT actor.actor_id, first_name, last_name, count(rental_id) as n_rented
FROM actor
JOIN film_actor as fa
ON actor.actor_id = fa.actor_id
JOIN film as f
on fa.film_id = f.film_id
JOIN inventory as i
on f.film_id = i.film_id
JOIN rental as r
on i.inventory_id = r.inventory_id
GROUP BY actor.actor_id
ORDER BY n_rented DESC
--completed

--Output the category of movies on which the most money was spent.
SELECT c.name, sum(p.amount) as expenses
FROM category as c
JOIN film_category as fc
on c.category_id = fc.category_id
LEFT JOIN film as f
on fc.film_id = f.film_id
JOIN inventory as i
on f.film_id = i.film_id
JOIN rental as r
on i.inventory_id = r.inventory_id
JOIN payment as p
on r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY expenses DESC
--not sure

--Print the names of movies that are not in the inventory. Write a query without using the IN operator.
SELECT film.title
FROM film
LEFT JOIN inventory as i
on film.film_id = i.film_id
where i.inventory_id is Null
--completed

--Output the top 3 actors who have appeared the most in movies in the “Children” category.
-- If several actors have the same number of movies, output all of them.
with children_movie_stars As (
    SELECT a.actor_id, first_name, last_name, c.name, count(c.name) as n_per_genre
    FROM actor as a
    JOIN film_actor as fa
    on a.actor_id = fa.actor_id
    JOIN film_category as fc
    on fa.film_id = fc.film_id
    JOIN category as c
    on fc.category_id = c.category_id and c.name like '%Children%'
    GROUP BY a.actor_id, first_name, last_name, c.name
    ORDER BY n_per_genre DESC
)
SELECT first_name, last_name, n_per_genre,
    dense_rank() over (ORDER BY n_per_genre DESC) as top_actors
from children_movie_stars
--ну это кринж что нельзя фильтровать результаты оконной функции, потом перепишу



--Output cities with the number of active and inactive customers (active - customer.active = 1).
--Sort by the number of inactive customers in descending order.
SELECT city, sum(c.active) as active, count(*) as n_customers, (count(*) - sum(c.active)) as inactive
from city
JOIN address as ad 
on city.city_id = ad.city_id
JOIN store as st
on ad.address_id = st.address_id
JOIN customer as c
on st.store_id = c.store_id
GROUP BY city.city
ORDER BY inactive DESC
--completed


--Output the category of movies that have the highest number of total
--rental hours in the city (customer.address_id in this city) and that start with the letter “a”.
--Do the same for cities that have a “-” in them. Write everything in one query.
SELECT *
from category as c
JOIN film_category as fc
on c.category_id = fc.category_id
JOIN film as f
on fc.film_id = f.film_id
--in progress