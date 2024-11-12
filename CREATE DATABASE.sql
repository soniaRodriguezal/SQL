-- EJERCICIO DE TODO LO VISTO HASTA HOY 100223
/* Vamos a hacer un ejercicio completo de crear una BD creando tablas con su información.
Productos bancarios y transacciones.
Tenemos 2 empresas:

Materiales Deportivos SL (MD) y Bebidas Energeticas SL (BE). 

La empresa MD tiene 3 productos bancarios, 2 en N26 y 1 en CaixaBank. BE tiene solo 1 en N26.

Producto 1- 3 transacciones

Producto 2- 5 transacciones

Objetivo: informar al equipo de negocio de:

Cuánto disponible tenemos en caja en cada empresa

Esquema:
Bancos: bank_id, bank_name, user, password
Productos: product_id, IBAN, creation_date
Empresas: company_id, company_name, nif
Transacciones: tx_id, concept, date, amount, balance

Pasos
1. crear BD
2. crear tablas
*/



create database BC;
USE BC;-- OTRA OPCION SI NO PONEMOS ESTE PASO ES CREATE TABLE IF NOT EXISTS BC.BANCOS (
-- Tabla para INFORMACIÓN BANCOS
CREATE TABLE IF NOT EXISTS Bancos (
bank_id INT AUTO_INCREMENT PRIMARY KEY,
bank_name VARCHAR(20),
user VARCHAR(20),
password varchar(20)
); 
-- TABLA INFORMACIÓN EMPRESAS
CREATE TABLE IF NOT EXISTS Empresas (
company_id INT AUTO_INCREMENT PRIMARY KEY,
company_name VARCHAR(60),
nif VARCHAR(20)
);
-- TABLA INFORMACIÓN PRODUCTOS
CREATE TABLE IF NOT EXISTS Productos (
product_id INT AUTO_INCREMENT PRIMARY KEY,
IBAN VARCHAR(40),
creation_date DATE
);
-- TABLA TRANSACCIONES
CREATE TABLE IF NOT EXISTS Transacciones (
tx_id INT AUTO_INCREMENT PRIMARY KEY,
concept VARCHAR(100),
date DATETIME,
amount DECIMAL,
balance DECIMAL
);
ALTER TABLE Bancos 
MODIFY COLUMN user VARCHAR(60);