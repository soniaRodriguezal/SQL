USE SAKILA;

-- 1. Según cuántos alquileres haya hecho el cliente clasifícalo en: Premium, Regular, Nuevo.
		-- Premium: más de 30 alquileres
        -- Regular: entre 10 y 30
SELECT
	c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS num_alquileres,
CASE
	WHEN COUNT(r.rental_id) > 30 THEN 'Premium'
    WHEN COUNT(r.rental_id) BETWEEN 10 AND 30 THEN 'Regular'
    ELSE 'Nuevo'
END AS 'customer_category'
FROM
	customer c
LEFT JOIN rental r
	ON c.customer_id = r.customer_id
GROUP BY 1,2,3
ORDER BY 4 DESC;
    

    
-- 2. Añade un prefijo al título según su clasificación.
		-- Ejemplo: para la clasificación G, 'Familiar - Titulo_de_la_película'
		-- PG(Parental Guidance Suggested), G(General Audiences), NC-17(No One 17 and Under Admitted), 
        -- PG-13(Parents Strongly Cautioned), R(restricted)
	SELECT
		title,
        rating,
	CASE
		WHEN rating = 'G' THEN 'General Audiences'
        WHEN rating = 'PG' THEN 'Parental Guidance Suggested'
        WHEN rating = 'PG-13' THEN 'Parents Strongly Cautioned'
        WHEN rating = 'NC-17' THEN 'No One 17 and Under Admitted'
        WHEN rating = 'R' THEN 'Restricted'
	END AS rating_classification
	FROM
		film
	ORDER BY 2;


-- 3. Para las películas de la categoría 1 y 2 aplica un descuento en su rental_rate de 10% y 15% respectivamente.
UPDATE 
	film f
JOIN film_category fc 
	ON f.film_id = fc.film_id
SET
	f.rental_rate = CASE
		WHEN fc.category_id = 1 THEN f.rental_rate * 0.90
        WHEN fc.category_id = 2 THEN f.rental_rate * 0.85
        ELSE f.rental_rate
END
WHERE fc.category_id IN (1,2);


-- 4. Películas con clasificación 'G', añade 5 años a su año de estreno.
SELECT
	film_id, 
    title,
    release_year,
    rating,
    CASE 
		WHEN rating = 'G' THEN release_year + 5
        ELSE release_year
	END AS modified_release_year
FROM
	film;


-- 5. Clasifica, según el tiempo que ha estado alquilada una película, si tiene que pagar o no multa.
		-- Multa para una diferencia superior a 3 días
SELECT 
    rental_id,
    rental_date,
    return_date,
    CASE 
        WHEN DATEDIFF(return_date, rental_date) > 3 THEN 'Multa'
        ELSE 'No Multa'
    END AS status
FROM 
    rental
WHERE 
    return_date IS NOT NULL;


-- 6. Clasifica los actores en función de la cantidad de películas en las que ha participado. 
		-- Veterano: más de 20
        -- Experimentado: entre 10 y 20
        -- Novato: menos de 10
SELECT
	a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(fa.film_id) AS num_pelis,
CASE 
	WHEN COUNT(fa.film_id) > 20 THEN 'Veterano'
    WHEN COUNT(fa.film_id) BETWEEN 10 AND 20 THEN 'Experimentado'
	ELSE 'Novato'
END AS clasificacion_actor
FROM
	actor a
JOIN film_Actor fa
	ON a.actor_id = fa.actor_id
GROUP BY 1
ORDER BY clasificacion_actor;
  
-- 7. Muestra una nueva columna con un incremento del 15% en el precio de alquiler de una película si dura más de 120 minutos
SELECT
	length,
CASE
	WHEN length > 120 THEN rental_rate * 1.15
    ELSE rental_rate
END AS modified_rental_rate
FROM
	film;


-- 8. Premia a los clientes con puntos en función de la cantidad de alquileres que haya hecho:
		-- 100 si ha alquilado más de 20 veces
        -- 50 si lo ha hecho entre 10 y 20 veces
        -- 10 si lo ha hecho menos de 10 veces
SELECT 
    customer_id,
    COUNT(*) AS rental_count,
    CASE 
        WHEN COUNT(*) > 20 THEN 100
        WHEN COUNT(*) BETWEEN 10 AND 20 THEN 50
        ELSE 10
    END AS puntos
FROM 
    rental
GROUP BY 
    customer_id;
	
    
-- 9. Clasifica los alquileres por prioridad 'Alta', 'Normal' y ordena la lista para que salgan los de alta prioridad en primer lugar.
		-- Clientes VIP son aquellos que pertenecen a la tienda 1
SELECT 
    r.rental_id,
    r.customer_id,
    CASE 
        WHEN c.store_id = 1 THEN 'Alta'
        ELSE 'Normal'
    END AS prioridad
FROM 
    rental r
JOIN 
    customer c ON r.customer_id = c.customer_id
ORDER BY 
    prioridad DESC,
    r.rental_date;
