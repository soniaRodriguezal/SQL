USE classicmodels;

-- EJERCICIOS OBLIGATORIOS
-- 1. Encontrar los clientes que han gastado por encima de la media (media de gasto de los clientes se entiende)
WITH gasto_cliente AS (
    SELECT 
        c.customerName,
        SUM(od.quantityOrdered * od.priceEach) AS total_gastado
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY 1
),
gasto_medio AS (
    SELECT 
        AVG(total_gastado) AS media_gasto
    FROM gasto_cliente
)
SELECT 
    gc.customerName, 
    gc.total_gastado 
FROM gasto_cliente gc
JOIN gasto_medio gm ON gc.total_gastado > gm.media_gasto
ORDER BY 2 DESC;

-- 2. 
/*Dame el ranking por año de los empleados que menos han tenido que trabajar cada año,
puede haber más de un criterio para esto*/
SELECT
    YEAR(o.orderDate) anio,
    e.employeeNumber,
    CONCAT(e.firstName,' ', e.lastName) nombre,
    COUNT(o.orderNumber) AS totalOrders,
    RANK() OVER (PARTITION BY YEAR(o.orderDate) ORDER BY COUNT(o.orderNumber)) rankin
FROM employees e
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY 1,2,3
ORDER BY 1,5;

-- 3. Dame el porcentaje de contribución de cada categoría al total de las ventas, porcentaje OJO
WITH ventas_categoria AS (
    SELECT 
        p.productLine,
        SUM(od.quantityOrdered * od.priceEach) AS total_ventas
    FROM products p
    JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productLine
)
SELECT 
    vc.productLine,
    vc.total_ventas,
   ROUND((vc.total_ventas / (SELECT SUM(total_ventas) FROM ventas_categoria)),2)* 100 AS porcentaje_contribucion
FROM ventas_categoria vc
ORDER BY porcentaje_contribucion DESC;

-- 4. WoW del total acumulado en cuanto a facturas emitidas de los pedidos para el año 2003 y 2004
-- Selecciona los datos de las facturas emitidas por semana para los años 2003 y 2004 y calcula el WoW en una sola consulta
SELECT
    anio,
    semana,
    total_acumulado,
    LAG(total_acumulado) OVER (PARTITION BY anio ORDER BY semana) AS total_acumulado_anterior,
    ((total_acumulado - LAG(total_acumulado) OVER (PARTITION BY anio ORDER BY semana)) / 
    LAG(total_acumulado) OVER (PARTITION BY anio ORDER BY semana)) * 100 AS WOW
FROM (
    SELECT
        YEAR(o.orderDate) AS anio,
        WEEK(o.orderDate, 3) AS semana,
        SUM(p.amount) AS total_facturas,
        SUM(SUM(p.amount)) OVER (PARTITION BY YEAR(o.orderDate) ORDER BY WEEK(o.orderDate, 3)) AS total_acumulado
    FROM payments p
    JOIN orders o ON p.customerNumber = o.customerNumber
    WHERE YEAR(o.orderDate) IN (2003, 2004)
    GROUP BY YEAR(o.orderDate), WEEK(o.orderDate, 3)
) AS facturas_acumuladas
ORDER BY 1,2;


-- 5. MoM de lo mismo
-- Selecciona los datos de las facturas emitidas por mes para los años 2003 y 2004 y calcula el MoM en una sola consulta
SELECT
    anio,
    mes,
    total_acumulado,
    LAG(total_acumulado) OVER (PARTITION BY anio ORDER BY mes) AS total_acumulado_anterior,
    ((total_acumulado - LAG(total_acumulado) OVER (PARTITION BY anio ORDER BY mes)) / 
    LAG(total_acumulado) OVER (PARTITION BY anio ORDER BY mes)) * 100 AS MOM
FROM (
    SELECT
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        SUM(p.amount) AS total_facturas,
        SUM(SUM(p.amount)) OVER (PARTITION BY YEAR(o.orderDate) ORDER BY MONTH(o.orderDate)) AS total_acumulado
    FROM payments p
    JOIN orders o ON p.customerNumber = o.customerNumber
    WHERE YEAR(o.orderDate) IN (2003, 2004)
    GROUP BY 1,2
) AS facturas_acumuladas
ORDER BY 1,2;


-- 6. YoY de lo mismo
-- Selecciona los datos de las facturas emitidas por mes para los años 2003 y 2004 y calcula el YoY en una sola consulta
SELECT
    anio,
    mes,
    total_acumulado,
    LAG(total_acumulado) OVER (PARTITION BY mes ORDER BY anio) AS total_acumulado_anterior,
    ((total_acumulado - LAG(total_acumulado) OVER (PARTITION BY mes ORDER BY anio)) / 
    LAG(total_acumulado) OVER (PARTITION BY mes ORDER BY anio)) * 100 AS YOY
FROM (
    SELECT
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        SUM(p.amount) AS total_facturas,
        SUM(SUM(p.amount)) OVER (PARTITION BY YEAR(o.orderDate) ORDER BY MONTH(o.orderDate)) AS total_acumulado
    FROM payments p
    JOIN orders o ON p.customerNumber = o.customerNumber
    WHERE YEAR(o.orderDate) IN (2003, 2004)
    GROUP BY 1,2
) AS facturas_acumuladas
ORDER BY 1,2;


-- 7. Saca las mismas métricas separadas por cada tienda
-- WOW
SELECT
    codigo_tienda,
    tienda,
    anio,
    semana,
    total_acumulado,
    LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, anio ORDER BY semana) AS total_acumulado_anterior,
    ((total_acumulado - LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, anio ORDER BY semana)) / 
    LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, anio ORDER BY semana)) * 100 AS WOW
FROM (
    SELECT
        ofc.officeCode AS codigo_tienda,
        ofc.city AS tienda,
        YEAR(o.orderDate) AS anio,
        WEEK(o.orderDate, 3) AS semana,
        SUM(p.amount) AS total_facturas,
        SUM(SUM(p.amount)) OVER (PARTITION BY ofc.officeCode, YEAR(o.orderDate) ORDER BY WEEK(o.orderDate, 3)) AS total_acumulado
    FROM payments p
    JOIN orders o ON p.customerNumber = o.customerNumber
    JOIN customers c ON o.customerNumber = c.customerNumber
    JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices ofc ON e.officeCode = ofc.officeCode
    WHERE YEAR(o.orderDate) IN (2003, 2004)
    GROUP BY 1,3,4
) AS facturas_acumuladas
ORDER BY 1,3,4;

-- MOM
SELECT
    codigo_tienda,
    tienda,
    anio,
    mes,
    total_acumulado,
    LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, anio ORDER BY mes) AS total_acumulado_anterior,
    ((total_acumulado - LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, anio ORDER BY mes)) / 
    LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, anio ORDER BY mes)) * 100 AS MOM
FROM (
    SELECT
        ofc.officeCode AS codigo_tienda,
        ofc.city AS tienda,
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        SUM(p.amount) AS total_facturas,
        SUM(SUM(p.amount)) OVER (PARTITION BY ofc.officeCode, YEAR(o.orderDate) ORDER BY MONTH(o.orderDate)) AS total_acumulado
    FROM payments p
    JOIN orders o ON p.customerNumber = o.customerNumber
    JOIN customers c ON o.customerNumber = c.customerNumber
    JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices ofc ON e.officeCode = ofc.officeCode
    WHERE YEAR(o.orderDate) IN (2003, 2004)
    GROUP BY 1,3,4
) AS facturas_acumuladas
ORDER BY 1,3,4;

-- YOY
SELECT
    codigo_tienda,
    tienda,
    anio,
    mes,
    total_acumulado,
    LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, mes ORDER BY anio) AS total_acumulado_anterior,
    ((total_acumulado - LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, mes ORDER BY anio)) / 
    LAG(total_acumulado) OVER (PARTITION BY codigo_tienda, mes ORDER BY anio)) * 100 AS YOY
FROM (
    SELECT
        ofc.officeCode AS codigo_tienda,
        ofc.city AS tienda,
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        SUM(p.amount) AS total_facturas,
        SUM(SUM(p.amount)) OVER (PARTITION BY ofc.officeCode, YEAR(o.orderDate) ORDER BY MONTH(o.orderDate)) AS total_acumulado
    FROM payments p
    JOIN orders o ON p.customerNumber = o.customerNumber
    JOIN customers c ON o.customerNumber = c.customerNumber
    JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices ofc ON e.officeCode = ofc.officeCode
    WHERE YEAR(o.orderDate) IN (2003, 2004)
    GROUP BY 1,3,4
) AS facturas_acumuladas
ORDER BY 1,3,4;


-- 8.
/* ¿Qué porcentaje respecto a la facturación global representa cada una de las tiendas?
Saca esta métrica por cada mes y por cada año*/
WITH facturacion_tiendas AS (
    SELECT 
        ofc.officeCode AS codigo_tienda,
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        SUM(od.quantityOrdered * od.priceEach) AS facturacion_mensual
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    JOIN customers c ON o.customerNumber = c.customerNumber
    JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
    JOIN offices ofc ON e.officeCode = ofc.officeCode
    GROUP BY 1, 2, 3
),
facturacion_global AS (
    SELECT
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        SUM(od.quantityOrdered * od.priceEach) AS facturacion_mensual_global
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY 1,2
)
SELECT 
    ft.codigo_tienda,
    ft.anio,
    ft.mes,
    ft.facturacion_mensual,
    fg.facturacion_mensual_global,
    (ft.facturacion_mensual / fg.facturacion_mensual_global) * 100 AS porcentaje_contribucion
FROM facturacion_tiendas ft
JOIN facturacion_global fg ON ft.anio = fg.anio AND ft.mes = fg.mes
ORDER BY 1,2,3;


-- 9.
/* Para cada mes, obtén el número de clientes nuevos (aquellos que han realizado su primer pedido ese mes), 
el número de clientes recurrentes (aquellos que han realizado más de un pedido ese mes) 
y el porcentaje de clientes recurrentes sobre el total. */
-- Haz 2 ctes y con eso lo sacas

WITH pedidos_cliente AS (
    SELECT 
        c.customerNumber AS num_cliente,
        YEAR(o.orderDate) AS anio,
        MONTH(o.orderDate) AS mes,
        COUNT(o.orderNumber) AS numero_pedidos,
        SUM(COUNT(O.ORDERnUMBER)) OVER (PARTITION BY c.customerNumber ORDER BY YEAR(o.orderDate), MONTH(o.orderDate)) AS total_pedidos
    FROM customers c
    LEFT JOIN orders o ON c.customerNumber = o.customerNumber
    GROUP BY 1,2,3
),
clientes_mes AS (
    SELECT
        anio,
        mes,
		COUNT(DISTINCT num_cliente) AS clientes_total,
        SUM(CASE WHEN total_pedidos = numero_pedidos THEN 1 ELSE 0 END) AS clientes_nuevos,
        SUM(CASE WHEN total_pedidos > 1 THEN 1 ELSE 0 END) AS clientes_recurrentes -- Esto lo encontré tras horas de buscar por internet la manera de hacerlo...
       
    FROM pedidos_cliente
    GROUP BY 1,2
)
SELECT 
    anio,
    mes,
    clientes_nuevos,
    clientes_recurrentes,
    clientes_total,
    ROUND((clientes_recurrentes / clientes_total) *100,2) AS porcentaje_clientes_recurrentes
FROM clientes_mes
ORDER BY 1,2;



-- 10.
/* Para cada vendedor, obtén el número de pedidos realizados y la facturación acumulada,
 y ordena los vendedores por el número de pedidos totales que ha hecho.*/
WITH pedidos_vendedor AS (
    SELECT
        e.employeeNumber AS numero_vendedor,
        CONCAT(e.firstName, ' ', e.lastName) AS nombre,
        COUNT(DISTINCT o.orderNumber) AS numero_pedidos,
        SUM(od.quantityOrdered * od.priceEach) AS facturacion_acumulada
    FROM employees e
    JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY e.employeeNumber, e.firstName, e.lastName
)
SELECT
    numero_vendedor,
    nombre,
    numero_pedidos,
    facturacion_acumulada
FROM pedidos_vendedor
ORDER BY numero_pedidos DESC;
-- *TENGO HECHOS ALGUNOS DEL MODO HARDCORE MÁS ABAJO*




-- MODO HARDCORE ON, recomendado hacerlas, aunque no obligatorio.
-- (se valorará el esfuerzo, el intento, aunque no lleguéis al resultado -creo que podéis hacerlo perfectamente-
-- dejad la query como se quede con comentarios de vuestro camino para construirla, gracias :)


-- 1.
/* Obtén los 5 clientes que han gastado más dinero en cada país y en cada año, 
junto con el importe total gastado y los días transcurridos entre cada pedido y su correspondiente pago,
puede que el pago sean varios pedidos de golpe, se tendrá que calcular para comprobar...*/
-- versión más amable: si no consigues encontrar los días transcurridos entre pedido y pago
-- sustituye esa columna por la cantidad de pedidos que ha hecho ese cliente


-- 2.
/* Para cada producto, obtén su clasificación (low, medium o high) según el ratio de beneficio (precio de venta - coste),
 y ordena los productos por clasificación y por precio de venta. (high, medium, low y mayor precio de venta primero) */
-- los cortes de la clasificación son a tu criterio, siempre que tengan un sentido. Razona tu criterio en algún comentario.
 

-- 3.
/* Obtén una tabla con los nombres de los clientes, 
el número de sus pedidos, el importe total de sus pedidos, 
la fecha del primer pedido, la fecha del último pedido. */
-- 3.1 añade una columna para ver el tiempo que ha transcurrido 
-- y muestra el clientes más antiguo de cada tienda
WITH pedidos_cliente AS (
    SELECT 
        c.customerName AS nombre_cliente,
        COUNT(o.orderNumber) AS numero_pedidos,
        SUM(od.quantityOrdered * od.priceEach) AS importe_total_pedidos,
        MIN(o.orderDate) AS fecha_primer_pedido,
        MAX(o.orderDate) AS fecha_ultimo_pedido,
        e.officeCode AS codigo_tienda
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
    GROUP BY c.customerName, e.officeCode
),
clientes_mas_antiguos AS (
    SELECT 
        codigo_tienda,
        nombre_cliente,
        fecha_primer_pedido,
        ROW_NUMBER() OVER (PARTITION BY codigo_tienda ORDER BY fecha_primer_pedido) AS row_num
    FROM pedidos_cliente
)
SELECT 
    pc.nombre_cliente,
    pc.numero_pedidos,
    pc.importe_total_pedidos,
    pc.fecha_primer_pedido,
    pc.fecha_ultimo_pedido,
    TIMESTAMPDIFF(MONTH, pc.fecha_primer_pedido, pc.fecha_ultimo_pedido) AS meses_transcurridos,
    pc.codigo_tienda,
    ca.row_num
FROM pedidos_cliente pc
JOIN clientes_mas_antiguos ca ON pc.codigo_tienda = ca.codigo_tienda AND pc.nombre_cliente = ca.nombre_cliente
ORDER BY pc.codigo_tienda, pc.fecha_primer_pedido;



-- 4.
/* Para cada mes, obtén el número de productos nuevos (aquellos que se han añadido al stock ese mes) 
4.1. además, para cada mes, qué productos son (id, nombre...) y cuántas unidades se ha pedido (según el stock que hay en products),
con su precio y el coste que supone.*/


-- 5.
/* Para cada país y cada año, obtén el número de clientes que han realizado un pedido en el primer trimestre del año 
y no han realizado ningún otro pedido en el resto del año. */
WITH pedidos_primer_trimestre AS (
    SELECT
        c.customerNumber AS numero_cliente,
        c.country AS pais,
        YEAR(o.orderDate) AS anio,
        COUNT(o.orderNumber) AS pedidos_primer_trimestre
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    WHERE MONTH(o.orderDate) BETWEEN 1 AND 3
    GROUP BY 1,2,3
),
pedidos_resto_anio AS (
    SELECT
        c.customerNumber AS numero_cliente,
        YEAR(o.orderDate) AS anio,
        COUNT(o.orderNumber) AS pedidos_resto_anio
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    WHERE MONTH(o.orderDate) BETWEEN 4 AND 12
    GROUP BY 1,2
),
clientes_filtrados AS (
    SELECT
        p1.pais,
        p1.anio,
        p1.numero_cliente
    FROM pedidos_primer_trimestre p1
    LEFT JOIN pedidos_resto_anio p2 ON p1.numero_cliente = p2.numero_cliente AND p1.anio = p2.anio
    WHERE p2.pedidos_resto_anio IS NULL
)
SELECT
    pais,
    anio,
    COUNT(DISTINCT numero_cliente) AS numero_clientes
FROM clientes_filtrados
GROUP BY 1,2
ORDER BY 1,2;

-- 6.
/* Para cada cliente, obtén su número de cliente, nombre, 
el importe total gastado en sus pedidos, el número de pedidos realizados, 
el número de productos diferentes comprados y la fecha del último pedido.*/


-- 7.
/* Obtén una tabla con los nombres de los clientes, el número de sus pedidos, 
el importe total de sus pedidos, la fecha del primer pedido, la fecha del último pedido 
y la media de días transcurridos entre cada pedido, 
pero únicamente para aquellos clientes que han realizado más de 3 pedidos 
y cuyos pedidos no han sido cancelados.*/