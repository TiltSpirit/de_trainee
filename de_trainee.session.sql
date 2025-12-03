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
limit 10
--fixed

--Output the category of movies on which the most money was spent.
SELECT c.name, sum(p.amount) as expenses
FROM category as c
JOIN film_category as fc
on c.category_id = fc.category_id
JOIN film as f
on fc.film_id = f.film_id
JOIN inventory as i
on f.film_id = i.film_id
JOIN rental as r
on i.inventory_id = r.inventory_id
JOIN payment as p
on r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY expenses DESC
LIMIT 1
--fixed

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
    SELECT a.actor_id, first_name, last_name, c.name, count(c.name) as n_per_genre,
    dense_rank() over (ORDER BY count(c.name) DESC) as top_actors
    FROM actor as a
    JOIN film_actor as fa
    on a.actor_id = fa.actor_id
    JOIN film_category as fc
    on fa.film_id = fc.film_id
    JOIN category as c
    on fc.category_id = c.category_id and c.name like '%Children%'
    GROUP BY a.actor_id, first_name, last_name, c.name
)
SELECT first_name, last_name, n_per_genre    
from children_movie_stars
where top_actors <= 3
ORDER BY n_per_genre DESC
--fixed



--Output cities with the number of active and inactive customers (active - customer.active = 1).
--Sort by the number of inactive customers in descending order.
SELECT city.city_id, city,
sum(CASE 
    WHEN c.active = 1 then 1
    else 0
    end) as active_c,
sum(CASE 
    WHEN c.active = 0 then 1
    else 0
    end) as inactive_c
from city
JOIN address as ad 
on city.city_id = ad.city_id
JOIN customer as c
on ad.address_id = c.address_id
GROUP BY city.city_id, city.city
ORDER BY inactive_c DESC, city.city
--used case


--Output the category of movies that have the highest number of total
--rental hours in the city (customer.address_id in this city) and that start with the letter “a”.
--Do the same for cities that have a “-” in them. Write everything in one query.


--all categories for cities that start with "A" and for the ones that have "-" in them
SELECT name, city, rent_hours
FROM (SELECT name, c.city, sum(r.return_date - r.rental_date) as rent_sum, 
    cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60 / 60) as integer) as rent_hours, --rent_sum оставил временно для наглядности 
    rank() OVER (partition by c.city ORDER BY cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60) as integer) DESC)
    from category as ct
    JOIN film_category as fc
    on ct.category_id = fc.category_id
    JOIN film as f
    on fc.film_id = f.film_id
    JOIN inventory as i
    on f.film_id = i.film_id
    JOIN rental as r
    on i.inventory_id = r.inventory_id and (r.rental_date is not Null and r.return_date is not Null)
    JOIN customer as cs
    on r.customer_id = cs.customer_id
    JOIN address as a
    on cs.address_id = a.address_id
    JOIN city as c
    on a.city_id = c.city_id
    where (c.city like 'A%') or (c.city like '%-%')
    GROUP by ct.name, c.city)
where rank = 1


--categories that start with "A" for all cities
SELECT name, city, rent_hours
FROM (SELECT name, c.city, sum(r.return_date - r.rental_date) as rent_sum, 
    cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60 / 60) as integer) as rent_hours, --rent_sum оставил временно для наглядности 
    rank() OVER (partition by c.city ORDER BY cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60) as integer) DESC)
    from category as ct
    JOIN film_category as fc
    on ct.category_id = fc.category_id
    JOIN film as f
    on fc.film_id = f.film_id
    JOIN inventory as i
    on f.film_id = i.film_id
    JOIN rental as r
    on i.inventory_id = r.inventory_id and (r.rental_date is not Null and r.return_date is not Null)
    JOIN customer as cs
    on r.customer_id = cs.customer_id
    JOIN address as a
    on cs.address_id = a.address_id
    JOIN city as c
    on a.city_id = c.city_id
    where ct.name like 'A%'
    GROUP by ct.name, c.city)
where rank = 1


--categories on "a" for the cities that start with "a", and all categories for cities with dash
SELECT name, city, rent_hours
FROM (SELECT name, c.city, sum(r.return_date - r.rental_date) as rent_sum, 
    cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60 / 60) as integer) as rent_hours, --rent_sum оставил временно для наглядности 
    rank() OVER (partition by c.city ORDER BY cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60) as integer) DESC)
    from category as ct
    JOIN film_category as fc
    on ct.category_id = fc.category_id
    JOIN film as f
    on fc.film_id = f.film_id
    JOIN inventory as i
    on f.film_id = i.film_id
    JOIN rental as r
    on i.inventory_id = r.inventory_id and (r.rental_date is not Null and r.return_date is not Null)
    JOIN customer as cs
    on r.customer_id = cs.customer_id
    JOIN address as a
    on cs.address_id = a.address_id
    JOIN city as c
    on a.city_id = c.city_id
    where (c.city like 'A%') and (ct.name like 'A%')
    GROUP by ct.name, c.city)
where rank = 1
UNION
SELECT name, city, rent_hours
FROM (SELECT name, c.city, sum(r.return_date - r.rental_date) as rent_sum, 
    cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60 / 60) as integer) as rent_hours, --rent_sum оставил временно для наглядности 
    rank() OVER (partition by c.city ORDER BY cast(sum(extract(epoch from (r.return_date - r.rental_date)) / 60) as integer) DESC)
    from category as ct
    JOIN film_category as fc
    on ct.category_id = fc.category_id
    JOIN film as f
    on fc.film_id = f.film_id
    JOIN inventory as i
    on f.film_id = i.film_id
    JOIN rental as r
    on i.inventory_id = r.inventory_id and (r.rental_date is not Null and r.return_date is not Null)
    JOIN customer as cs
    on r.customer_id = cs.customer_id
    JOIN address as a
    on cs.address_id = a.address_id
    JOIN city as c
    on a.city_id = c.city_id
    where (c.city like '%-%')
    GROUP by ct.name, c.city)
where rank = 1