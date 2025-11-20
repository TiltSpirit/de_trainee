--Output the number of movies in each category, sorted descending.
SELECT category.name, count(film.film_id) as number_per_category
FROM category
LEFT JOIN film_category
ON category.category_id = film_category.category_id
LEFT JOIN film
on film_category.film_id = film.film_id
GROUP BY category.category_id
ORDER BY number_per_category DESC

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
