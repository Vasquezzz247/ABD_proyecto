/* ============================================================
   05_backup_restore.sql
   Ejemplos de respaldo, verificación y restauración.
   Compatible con DBeaver
   ============================================================ */


/* ============================================================
   BLOQUE 1 — BACKUP COMPLETO DE LA BD PRINCIPAL
   ============================================================ */

USE master;

BACKUP DATABASE DB_Gimnasio
TO DISK = N'/var/opt/mssql/backups/DB_Gimnasio_full.bak'
WITH INIT, COMPRESSION, STATS = 5;
-- FIN BLOQUE 1



/* ============================================================
   BLOQUE 2 — VERIFICAR QUE EL ARCHIVO .BAK ES VÁLIDO
   ============================================================ */

USE master;

RESTORE VERIFYONLY
FROM DISK = N'/var/opt/mssql/backups/DB_Gimnasio_full.bak';
-- FIN BLOQUE 2



/* ============================================================
   BLOQUE 3 — RESTAURAR EL BACKUP A DB_Gimnasio_Test
   (Crea una copia exacta para pruebas)
   ============================================================ */

USE master;

RESTORE DATABASE DB_Gimnasio_Test
FROM DISK = N'/var/opt/mssql/backups/DB_Gimnasio_full.bak'
WITH MOVE 'DB_Gimnasio'     TO '/var/opt/mssql/data/DB_Gimnasio_Test.mdf',
     MOVE 'DB_Gimnasio_log' TO '/var/opt/mssql/data/DB_Gimnasio_Test_log.ldf',
     REPLACE,
     STATS = 5;
-- FIN BLOQUE 3



/* ============================================================
   BLOQUE 4 — VERIFICAR QUE LA BD RESTAURADA EXISTE
   ============================================================ */

SELECT name AS BaseDeDatos, database_id, create_date
FROM sys.databases
WHERE name LIKE 'DB_Gimnasio%';
-- Debe mostrar:
-- DB_Gimnasio
-- DB_Gimnasio_Test
-- FIN BLOQUE 4



/* ============================================================
   BLOQUE 5 — VALIDAR QUE LA COPIA (DB_Gimnasio_Test) TIENE DATOS
   ============================================================ */

USE DB_Gimnasio_Test;

SELECT COUNT(*) AS Socios        FROM gym.Socio;
SELECT COUNT(*) AS Entrenadores  FROM gym.Entrenador;
SELECT COUNT(*) AS Horarios      FROM gym.HorarioClase;
SELECT COUNT(*) AS Reservas      FROM gym.Reserva;
SELECT COUNT(*) AS Pagos         FROM gym.Pago;
-- Todos los valores deberían ser similares a la BD original
-- FIN BLOQUE 5