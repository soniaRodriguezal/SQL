USE employees;

-- 1. ¿Hay empleados con más de un cargo a la vez?

SELECT 
    emp_no
FROM (
    SELECT 
        t1.emp_no, 
        t1.from_date, 
        t1.to_date, 
        t2.from_date AS next_from_date, 
        t2.to_date AS next_to_date
    FROM 
        titles t1
    JOIN 
        titles t2 ON t1.emp_no = t2.emp_no 
                 AND t1.from_date < t2.to_date
                 AND t1.to_date > t2.from_date
                 AND t1.from_date <> t2.from_date
) AS Solapados
GROUP BY 
    emp_no
HAVING 
    COUNT(*) > 0;

-- 2. Calcula el promedio de años de servicio de los trabajadores actuales por cada departamento.
WITH EmpleadosActuales AS (
    SELECT 
        de.emp_no,
        de.dept_no,
        e.hire_date,
        YEAR(CURDATE()) - YEAR(e.hire_date) AS anios_servicio
    FROM 
        dept_emp de
    JOIN 
        employees e ON de.emp_no = e.emp_no
    WHERE 
        de.to_date = '9999-01-01' -- Indica que el empleado sigue en el departamento
)
SELECT 
    d.dept_name,
    AVG(ea.anios_servicio) AS promedio_anios_servicio
FROM 
    EmpleadosActuales ea
JOIN 
    departments d ON ea.dept_no = d.dept_no
GROUP BY 
    d.dept_name
ORDER BY 
    promedio_anios_servicio DESC;


-- 3. Mayor cambio de salario de cada empleado
WITH CambiosSalario AS (
    SELECT 
        s1.emp_no,
        ABS(s2.salary - s1.salary) AS cambio_salario
    FROM 
        salaries s1
    JOIN 
        salaries s2 
        ON s1.emp_no = s2.emp_no 
        AND s1.to_date = s2.from_date
)
SELECT 
    emp_no,
    MAX(cambio_salario) AS mayor_cambio_salario
FROM 
    CambiosSalario
GROUP BY 
    emp_no;

-- 4. Rotación de empleados por departamento (cantidad de empleados que dejan el departamento)
SELECT 
    d.dept_name,
    (SELECT COUNT(*)
     FROM dept_emp de
     WHERE de.dept_no = d.dept_no
       AND de.to_date <> '9999-01-01') AS rotacion_empleados
FROM 
    departments d
ORDER BY 
    rotacion_empleados DESC;

-- 5. Empleados con más de 20 años de servicio y sus actuales sueldos.
WITH EmpleadosMas20Anios AS (
    SELECT 
        e.emp_no,
        CONCAT(e.first_name, ' ', e.last_name) AS nombre,
        e.hire_date,
        (YEAR(CURDATE()) - YEAR(e.hire_date)) AS anios_servicio
    FROM 
        employees e
    WHERE 
        (YEAR(CURDATE()) - YEAR(e.hire_date)) > 20
)
SELECT 
    e.emp_no,
    e.nombre,
    s.salary AS sueldo_actual,
    e.anios_servicio
FROM 
    EmpleadosMas20Anios e
JOIN 
    salaries s ON e.emp_no = s.emp_no
JOIN 
    (SELECT emp_no, MAX(from_date) AS max_from_date
     FROM salaries
     GROUP BY emp_no) AS ultimos_sueldos 
    ON s.emp_no = ultimos_sueldos.emp_no AND s.from_date = ultimos_sueldos.max_from_date
ORDER BY 
    e.nombre;


-- 6. Cargo más común por cada departamento
WITH DeptTitulos AS (
    SELECT 
        de.dept_no,
        t.title,
        COUNT(*) AS conteo
    FROM 
        dept_emp de
    JOIN 
        titles t ON de.emp_no = t.emp_no
    GROUP BY 
        de.dept_no, t.title
),
MaxTitulosPorDept AS (
    SELECT 
        dt.dept_no,
        MAX(dt.conteo) AS max_conteo
    FROM 
        DeptTitulos dt
    GROUP BY 
        dt.dept_no
)
SELECT 
    d.dept_name,
    dt.title,
    dt.conteo
FROM 
    DeptTitulos dt
JOIN 
    MaxTitulosPorDept mtpd ON dt.dept_no = mtpd.dept_no AND dt.conteo = mtpd.max_conteo
JOIN 
    departments d ON dt.dept_no = d.dept_no
ORDER BY 
    d.dept_name;


-- 7. Empleados que han trabajado en todos los departamentos
SELECT 
    e.emp_no,
    COUNT(DISTINCT de.dept_no) AS departamentos_trabajados
FROM 
    employees e
JOIN 
    dept_emp de ON e.emp_no = de.emp_no
GROUP BY 
    e.emp_no
HAVING 
    COUNT(DISTINCT de.dept_no) = (SELECT COUNT(*) FROM departments);

-- 8. Incremento medio anual del sueldo por cada empleado


-- 9. Títulos distintos que han tenido los actuales managers
WITH ManagersActuales AS (
    SELECT 
        dm.emp_no,
        dm.dept_no,
        CONCAT(e.first_name, ' ', e.last_name) AS nombre
    FROM 
        dept_manager dm
	JOIN
		employees e
        ON dm.emp_no = e.emp_no
    WHERE 
        dm.to_date = '9999-01-01' 
)
SELECT 
    ma.emp_no,
    t.title,
    nombre
FROM 
    ManagersActuales ma
JOIN 
    titles t ON ma.emp_no = t.emp_no
GROUP BY 
    1, 2, 3
ORDER BY 
    1,2, 3;

-- 10. Sueldo medio de los trabajadores por género y departamento
SELECT 
    d.dept_name,
    e.gender,
    AVG(s.salary) AS sueldo_medio
FROM 
    employees e
JOIN 
    dept_emp de ON e.emp_no = de.emp_no
JOIN 
    departments d ON de.dept_no = d.dept_no
JOIN 
    salaries s ON e.emp_no = s.emp_no
WHERE 
    de.to_date = '9999-01-01'
    AND s.to_date = '9999-01-01'
GROUP BY 
    d.dept_name, e.gender
ORDER BY 
    d.dept_name, e.gender;

-- 11. Empleados con el mayor número de años en la empresa. Toda su información: nombre, sueldo, departamento (o departamentos), puesto...
-- top 10
WITH EmpleadosAnios AS (
    SELECT 
        e.emp_no,
        CONCAT(e.first_name, ' ', e.last_name) AS nombre,
        e.hire_date,
        (YEAR(CURDATE()) - YEAR(e.hire_date)) AS anios_servicio
    FROM 
        employees e
),
Top10Empleados AS (
    SELECT 
        ea.emp_no,
        ea.nombre,
        ea.anios_servicio
    FROM 
        EmpleadosAnios ea
    ORDER BY 
        3 DESC
    LIMIT 10
)
SELECT 
    te.emp_no,
    te.nombre,
    te.anios_servicio,
    d.dept_name AS departamento,
    t.title AS puesto,
    s.salary AS sueldo
FROM 
    Top10Empleados te
JOIN 
    dept_emp de ON te.emp_no = de.emp_no
JOIN 
    departments d ON de.dept_no = d.dept_no
JOIN 
    titles t ON te.emp_no = t.emp_no
JOIN 
    salaries s ON te.emp_no = s.emp_no
WHERE 
    de.to_date = '9999-01-01'
    AND s.to_date = '9999-01-01'
ORDER BY 
    1, 3 DESC, 4, 5;


-- 12. Empleados que han sido managers y también empleados en el mismo departamento
-- resolver en una sola query, sin subquery ni CTE.
SELECT 
    e.emp_no,
    CONCAT(e.first_name, ' ', e.last_name) AS nombre,
    d.dept_no,
    d.dept_name
FROM 
    employees e
JOIN 
    dept_emp de ON e.emp_no = de.emp_no
JOIN 
    dept_manager dm ON e.emp_no = dm.emp_no AND de.dept_no = dm.dept_no
JOIN 
    departments d ON de.dept_no = d.dept_no
WHERE 
    de.to_date = '9999-01-01'
    AND dm.to_date = '9999-01-01' 
ORDER BY 
    e.emp_no, d.dept_no;

-- 13. Sueldo medio de los empleados que han cambiado de departamento por lo menos dos veces
    
WITH EmpleadosCambio AS (
    SELECT 
        e.emp_no,
        COUNT(DISTINCT de.dept_no) AS cambios_depto
    FROM 
        employees e
    JOIN 
        dept_emp de ON e.emp_no = de.emp_no
    GROUP BY 
        e.emp_no
    HAVING 
        COUNT(DISTINCT de.dept_no) >= 2
)
SELECT 
    AVG(s.salary) AS sueldo_medio
FROM 
    EmpleadosCambio ecc
JOIN 
    salaries s ON ecc.emp_no = s.emp_no
WHERE 
    s.to_date = '9999-01-01';
    

-- 14. Empleados que nunca han tenido aumento de sueldo
WITH EmpleadosSinAumento AS (
    SELECT 
        s.emp_no
    FROM 
        salaries s
    GROUP BY 
        s.emp_no
    HAVING 
       MAX(s.salary) = MIN(s.salary)
)
SELECT 
    e.emp_no,
    CONCAT(e.first_name, ' ', e.last_name) AS nombre,
    s.salary AS sueldo_actual
FROM 
    EmpleadosSinAumento esa
JOIN 
    employees e ON esa.emp_no = e.emp_no
JOIN 
    salaries s ON e.emp_no = s.emp_no
ORDER BY 
    e.emp_no;

-- 15. Empleado con el mayor número de cargos diferentes a lo largo de su historia
WITH EmpleadosCargos AS (
    SELECT 
        t.emp_no,
        COUNT(DISTINCT t.title) AS num_cargos
    FROM 
        titles t
    GROUP BY 
        t.emp_no
),
MaxCargos AS (
    SELECT 
        MAX(num_cargos) AS max_cargos
    FROM 
        EmpleadosCargos
)
SELECT 
    ec.emp_no,
    CONCAT(e.first_name, ' ', e.last_name) AS nombre,
    ec.num_cargos
FROM 
    EmpleadosCargos ec
JOIN 
    MaxCargos mc ON ec.num_cargos = mc.max_cargos
JOIN 
    employees e ON ec.emp_no = e.emp_no
ORDER BY 
    ec.emp_no;
