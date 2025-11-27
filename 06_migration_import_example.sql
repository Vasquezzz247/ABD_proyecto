/* ============================================================
   06_migration_import_example.sql
   Flujo:
   1) Crear tabla de staging
   2) Importar CSV a staging con BULK INSERT
   3) Pasar datos a gym.Socio
   4) Verificar resultados
   ============================================================ */

USE DB_Gimnasio;


/* ============================================================
   BLOQUE 1 — Crear tabla de staging para importación
   Ejecutar una sola vez (o cuando no exista)
   ============================================================ */

IF OBJECT_ID('gym.SocioImport', 'U') IS NULL
BEGIN
    CREATE TABLE gym.SocioImport (
        Nombre       NVARCHAR(120) NOT NULL,
        Email        NVARCHAR(120) NOT NULL,
        Telefono     NVARCHAR(30)  NULL,
        MembresiaID  INT           NULL
    );
END;
-- FIN BLOQUE 1



/* ============================================================
   BLOQUE 2 — Limpiar staging antes de cada importación
   Ejecutar antes de un nuevo BULK INSERT
   ============================================================ */

TRUNCATE TABLE gym.SocioImport;
-- FIN BLOQUE 2



/* ============================================================
   BLOQUE 3 — BULK INSERT DESDE EL CSV HACIA gym.SocioImport
   Archivo esperado:
   /var/opt/mssql/imports/socios_extra.csv
   Columnas en el CSV:
   Nombre,Email,Telefono,MembresiaID
   (primera fila = encabezados)
   ============================================================ */

BULK INSERT gym.SocioImport
FROM '/var/opt/mssql/imports/socios_extra.csv'
WITH (
    FIRSTROW       = 2,       -- saltar encabezado
    FIELDTERMINATOR = ',',    -- separador de columnas
    ROWTERMINATOR   = '0x0a', -- salto de línea Linux (\n)
    TABLOCK
);
-- FIN BLOQUE 3



/* ============================================================
   BLOQUE 4 — MOVER DATOS A LA TABLA FINAL gym.Socio
   Ejecutar después del BULK INSERT
   ============================================================ */

INSERT INTO gym.Socio (Nombre, Email, Telefono, Estado, FechaAlta, MembresiaID)
SELECT
    Nombre,
    Email,
    Telefono,
    1              AS Estado,
    SYSDATETIME()  AS FechaAlta,
    MembresiaID
FROM gym.SocioImport;
-- FIN BLOQUE 4



/* ============================================================
   BLOQUE 5 — Verificación de la importación
   Ejecutar cuando quieras ver qué se importó
   ============================================================ */

-- Total de socios
SELECT COUNT(*) AS TotalSocios
FROM gym.Socio;

-- Últimos 20 socios insertados (deberían incluir los del CSV)
SELECT TOP 20 *
FROM gym.Socio
ORDER BY SocioID DESC;

-- Lo que quedó en la tabla de staging
SELECT *
FROM gym.SocioImport;
-- FIN BLOQUE 5
