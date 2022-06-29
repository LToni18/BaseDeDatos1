CREATE DATABASE Banco_Kingdom;
USE Banco_Kingdom;

CREATE TABLE operaciones
(
Codigo_operacion INTEGER (11) AUTO_INCREMENT PRIMARY KEY NOT NULL,
Descripcion VARCHAR(50)
);

INSERT INTO operaciones (Codigo_operacion, descripcion) VALUES (6010,'RETIRO');
INSERT INTO operaciones (Codigo_operacion, descripcion) VALUES (7011,'PRESTAMO');
INSERT INTO operaciones (Codigo_operacion, descripcion) VALUES (8012,'PRESTAMO');
INSERT INTO operaciones (Codigo_operacion, descripcion) VALUES (9013,'RETIRO');

select op.*
from operaciones as op;

CREATE TABLE Tipo_cuenta
(
Codigo_cuenta INTEGER  AUTO_INCREMENT PRIMARY KEY,
descripcion VARCHAR(50),
estado varchar(30)
);

INSERT INTO Tipo_cuenta (Codigo_cuenta, descripcion) VALUES (4012,'ESTANDAR');
INSERT INTO Tipo_cuenta (Codigo_cuenta, descripcion) VALUES (4013,'PREMIUM');
INSERT INTO Tipo_cuenta (Codigo_cuenta, descripcion) VALUES (4014,'ESTANDAR');
INSERT INTO Tipo_cuenta (Codigo_cuenta, descripcion) VALUES (4015,'PREMIUM');

select tc.*
from tipo_cuenta as tc;

CREATE TABLE cliente
(
codigo_cliente INTEGER AUTO_INCREMENT PRIMARY KEY NOT NULL,
nombre VARCHAR(50),
apellido VARCHAR(50)
);

INSERT INTO cliente (codigo_cliente, nombre, apellido) VALUES (3025,'Juan Vargas','choque collque');
INSERT INTO cliente (codigo_cliente, nombre, apellido) VALUES (3026,'Richard Bautista','Sabedra castaño');
INSERT INTO cliente (codigo_cliente, nombre, apellido) VALUES (3027,'Vaneza Prado','Cuquimia Igor');
INSERT INTO cliente (codigo_cliente, nombre, apellido) VALUES (3028,'Palmer amidala','Cori Welsmayer');

select cli.*
from cliente as cli;

CREATE TABLE Tarjeta
(
Numero_tarjeta INTEGER AUTO_INCREMENT PRIMARY KEY NOT NULL,
Codigo_cliente INT(11),
Codigo_cuenta INT(11),
fecha_afiliacion Date,
fecha_caducidad Date,
Saldo INTEGER,
FOREIGN KEY (Codigo_cliente) REFERENCES cliente (codigo_cliente),
FOREIGN KEY (Codigo_cuenta) REFERENCES Tipo_cuenta (Codigo_cuenta)
);

INSERT INTO tarjeta (numero_tarjeta, Codigo_cliente, Codigo_cuenta, fecha_afiliacion, fecha_caducidad, saldo)
VALUES (1001, 3025, 4012, '2021-10-03', '2024-10-03', 1000),
       (1002, 3026, 4013, '2021-01-04', '2024-01-04', 2000),
       (1003, 3027, 4014, '2021-09-12', '2024-09-12', 5002),
       (1004, 3028, 4015, '2021-01-01', '2024-01-01', 3008);

select tar.*
from tarjeta as tar;

CREATE TABLE transacciones
(
Codigo_transacciones INTEGER AUTO_INCREMENT PRIMARY KEY NOT NULL,
Numero_tarjeta INT (11),
Codigo_operacion INT (11),
fecha_de_transaccion Date,
cuenta_destino VARCHAR(50),
monto INTEGER,
FOREIGN KEY (Codigo_operacion) REFERENCES operaciones (Codigo_operacion),
FOREIGN KEY (Numero_tarjeta) REFERENCES Tarjeta (Numero_tarjeta)
);

INSERT INTO transacciones (Codigo_transacciones, Numero_tarjeta, Codigo_operacion, fecha_de_transaccion, cuenta_destino, monto)
VALUES      (9110,          1001, 6010,      '2021-05-04',     'Juanavarguera@gmail.com', 40),
            (9111,        1002,7011,        '2021-04-01',     'Richardomalcolque@gmail.com', 100),
            (9212,         1003,8012,       '2021-10-04',     'Thequinprado.com', 1000),
            (9313,        1004,9013,        '2021-10-01',     'Palmerfiolder.com', 980);

select tra.*
from transacciones as tra;

-- FUNCIONES
#SALDO MINIMO (OPCIONAL)
CREATE or replace FUNCTION min_saldo() RETURNS int
BEGIN
return
(
    SELECT min(tar.saldo)
    FROM tarjeta AS tar
);
END;

SELECT min_saldo();
drop function min_saldo;

-- resta entre saldo y monto
create or replace function operaciones(num_tarjeta int, cod_transaccion int)
returns integer
begin
return
    (
        select (sum(tar.Saldo) - sum(tra.monto)) as diferencia
        from tarjeta as tar,
             transacciones as tra
        where tar.Numero_tarjeta = num_tarjeta
          and tra.Codigo_transacciones = cod_transaccion
    );
end;
select operaciones(1003,9212);

#2.funcion que verifica si existe un cliente o no.

CREATE or replace FUNCTION verificar(nombres varchar(50),apellidos varchar(50),
nombres_comparar varchar(50),apellidos_comparar varchar(50))

returns bool
begin
    declare respuesta bool default false;
    set respuesta = (nombres =nombres_comparar and apellidos = apellidos_comparar);

    return respuesta;
end;

select cli.codigo_cliente,cli.nombre,cli.apellido,tar.fecha_afiliacion,tar.fecha_caducidad,tar.Saldo,tp.descripcion
from cliente as cli
INNER JOIN tarjeta AS tar ON cli.codigo_cliente = tar.Codigo_cliente
INNER JOIN tipo_cuenta AS tp ON tar.Codigo_cuenta = tp.Codigo_cuenta
where verificar(cli.nombre, cli.apellido, 'Juan Vargas', 'choque collque');

-- Ver quienes son PREMIUM y sus saldos del cliente
DROP FUNCTION IF EXISTS verquienessonPREMIUM;

CREATE or replace FUNCTION verquienessonPREMIUM(Codigo_cuenta VARCHAR(50) , descripcion VARCHAR(50))
RETURNS BOOL
   BEGIN
       RETURN Codigo_cuenta=descripcion ;
   end;
select cli.nombre,cli.apellido,tp.descripcion,tj.Saldo
from tarjeta AS tj
join cliente AS cli on tj.Codigo_cliente = cli.codigo_cliente
join Tipo_cuenta AS tp on tj.Codigo_cuenta = tp.Codigo_cuenta
where verquienessonPREMIUM(tp.descripcion,'PREMIUM');

-- Buscar cliente con el codigo_cliente
DROP FUNCTION IF EXISTS buscarcliente;

CREATE FUNCTION buscarcliente(Codigocuenta Integer , nombre VARCHAR(50))
RETURNS BOOL
   BEGIN
       RETURN Codigocuenta=nombre ;
   end;
select tj.Codigo_cliente,cli.nombre,cli.apellido,tj.Numero_tarjeta,tj.Saldo
from tarjeta AS tj
join cliente AS cli on tj.Codigo_cliente = cli.codigo_cliente
where buscarcliente(cli.codigo_cliente,3025);



-- TRIGGERS
#1.CUENTAS ACTIVAS SEGUN EL ADMINISTRADOR

create or replace trigger tip_cuenta
    before update
    on tipo_cuenta
    for each row
begin
    if new.descripcion =
       'ESTANDAR' or new.descripcion =
                        'PREMIUM'  then
        set new.estado = 'activo';
    else
        set new.estado = 'inactivo';
    end if;
end;
update tipo_cuenta
set descripcion =
        'PREMIUM'
where Codigo_cuenta = 4013;

SELECT * from Tipo_cuenta ;

-- añadir clientes
create or replace trigger before_agregar_cliente_update
    before update
    on cliente
    for each row
    begin
        insert into cliente(codigo_cliente, nombre, apellido)
        values (OLD.codigo_cliente,OLD.nombre,OLD.apellido);
    end;

insert into cliente( nombre, apellido)
values  ('Yeami Yanitsa','Sanchez Pisfil');
update cliente set nombre='Ludwing' where apellido ='Ibarra';
select *from cliente;

insert into cliente( nombre, apellido)
values  ('Saul Elias','Canaza Herrera');
update cliente set nombre='Ludwing' where apellido ='Ibarra';
select *from cliente;

-- VISTAS
-- unir dos tablas
CREATE or replace VIEW Registro
AS
SELECT cli.nombre, cli.apellido, Tar.Numero_tarjeta
FROM Cliente as cli
 inner join tarjeta as tar on tar.Codigo_cliente = cli.codigo_cliente;

SELECT * FROM Registro;
--

#3. vista de todas las tablas juntas
create or replace view las_tablas as
select cli.nombre,
       cli.apellido,
       tarje.Saldo,
       tarje.fecha_afiliacion,
       tarje.fecha_caducidad,
       oper.Descripcion,
       trans.fecha_de_transaccion,
       trans.cuenta_destino,
       trans.monto
from tarjeta as tarje
         inner join transacciones as trans on tarje.Numero_tarjeta = trans.Numero_tarjeta
         inner join cliente as cli on tarje.Codigo_cliente = cli.codigo_cliente
         inner join tipo_cuenta as tc on tarje.Codigo_cuenta = tc.codigo_cuenta
         inner join operaciones as oper on trans.Codigo_operacion = oper.Codigo_operacion;

select * from las_tablas;
