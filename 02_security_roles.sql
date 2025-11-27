/* ============================================================
   02_security_roles.sql
   Crea logins, usuarios, roles y permisos básicos.
   ============================================================ */

USE master;

-- Logins a nivel de servidor (ajusta las contraseñas a tu gusto)
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'gym_admin')
BEGIN
    CREATE LOGIN gym_admin WITH PASSWORD = 'Aa0101!!GymAdmin',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'gym_app_rw')
BEGIN
    CREATE LOGIN gym_app_rw WITH PASSWORD = 'Aa0101!!AppRW',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'gym_app_ro')
BEGIN
    CREATE LOGIN gym_app_ro WITH PASSWORD = 'Aa0101!!AppRO',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
END;

USE DB_Gimnasio;

/* Usuarios de base de datos mapeados a esos logins */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'gym_admin')
BEGIN
    CREATE USER gym_admin FOR LOGIN gym_admin;
END;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'gym_app_rw')
BEGIN
    CREATE USER gym_app_rw FOR LOGIN gym_app_rw;
END;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'gym_app_ro')
BEGIN
    CREATE USER gym_app_ro FOR LOGIN gym_app_ro;
END;

/* Roles a nivel de BD */
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_admin')
BEGIN
    CREATE ROLE rol_admin;
END;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_operativo')
BEGIN
    CREATE ROLE rol_operativo;
END;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_lectura')
BEGIN
    CREATE ROLE rol_lectura;
END;

/* Asignar usuarios a roles */
EXEC sp_addrolemember 'rol_admin',     'gym_admin';
EXEC sp_addrolemember 'rol_operativo', 'gym_app_rw';
EXEC sp_addrolemember 'rol_lectura',   'gym_app_ro';

/* Permisos:
   - rol_lectura: solo SELECT en el esquema gym
   - rol_operativo: SELECT/INSERT/UPDATE/DELETE en el esquema gym
   - rol_admin: control total sobre gym + creación de objetos
*/

GRANT SELECT ON SCHEMA::gym TO rol_lectura;

GRANT SELECT, INSERT, UPDATE, DELETE
ON SCHEMA::gym TO rol_operativo;

GRANT CONTROL ON SCHEMA::gym TO rol_admin;
GRANT ALTER   ON SCHEMA::gym TO rol_admin;
