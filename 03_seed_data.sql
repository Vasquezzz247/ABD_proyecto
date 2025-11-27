/* ============================================================
   03_seed_data.sql
   Inserta datos iniciales:
   - Membresías y métodos de pago
   - Clases base
   - 1000 socios y 100 entrenadores
   - Horarios, reservas y pagos de ejemplo
   ============================================================ */

/* =============== BLOQUE 1: catálogos base =============== */

USE DB_Gimnasio;

-- Membresías base
IF NOT EXISTS (SELECT 1 FROM gym.Membresia)
BEGIN
    INSERT INTO gym.Membresia (NombrePlan, PrecioMensual, DuracionMeses, Descripcion)
    VALUES
      (N'Básico',     20.00, 1,  N'Acceso a máquinas en horario normal'),
      (N'Plus',       35.00, 1,  N'Máquinas + clases grupales'),
      (N'Premium',    50.00, 1,  N'Todo incluido + entrenador personalizado'),
      (N'Anual Plus', 350.00,12, N'Membresía anual con descuento');
END;

-- Métodos de pago
IF NOT EXISTS (SELECT 1 FROM gym.MetodoPago)
BEGIN
    INSERT INTO gym.MetodoPago (Nombre)
    VALUES (N'Efectivo'),
           (N'Tarjeta'),
           (N'Transferencia');
END;

-- Clases base
IF NOT EXISTS (SELECT 1 FROM gym.Clase)
BEGIN
    INSERT INTO gym.Clase (Nombre, Nivel, CupoMaximo)
    VALUES
      (N'Spinning', N'Intermedio', 20),
      (N'Crossfit', N'Avanzado',   15),
      (N'Yoga',     N'Principiante',25),
      (N'Funcional',N'Intermedio', 18);
END;
-- ===== FIN BLOQUE 1 =====


/* =============== BLOQUE 2: Entrenadores  =============== */

DECLARE @nextEntrenador INT;

WHILE (SELECT COUNT(*) FROM gym.Entrenador) < 100
BEGIN
    SELECT @nextEntrenador = COUNT(*) + 1 FROM gym.Entrenador;

    INSERT INTO gym.Entrenador (Nombre, Especialidad)
    VALUES (
        CONCAT(N'Entrenador ', FORMAT(@nextEntrenador, '000')),
        CASE (@nextEntrenador % 4)
            WHEN 0 THEN N'Crossfit'
            WHEN 1 THEN N'Spinning'
            WHEN 2 THEN N'Funcional'
            WHEN 3 THEN N'Yoga'
        END
    );
END;
-- ===== FIN BLOQUE 2 =====


/* =============== BLOQUE 3: Socios =============== */

DECLARE @nextSocio INT;

WHILE (SELECT COUNT(*) FROM gym.Socio) < 1000
BEGIN
    SELECT @nextSocio = COUNT(*) + 1 FROM gym.Socio;

    INSERT INTO gym.Socio (Nombre, Email, Telefono, Estado, FechaAlta, MembresiaID)
    VALUES (
        CONCAT(N'Socio ', FORMAT(@nextSocio, '0000')),
        CONCAT(N'socio', @nextSocio, N'@gym.sv'),
        CONCAT(N'7', RIGHT('0000000' + CAST(@nextSocio AS VARCHAR(7)), 7)),
        1,
        DATEADD(DAY, -(@nextSocio % 365), SYSDATETIME()),
        ((ABS(CHECKSUM(NEWID())) % 4) + 1)   -- membresía 1..4 aleatoria
    );
END;
-- ===== FIN BLOQUE 3 =====


/* =============== BLOQUE 4: Horarios =============== */

IF NOT EXISTS (SELECT 1 FROM gym.HorarioClase)
BEGIN
    DECLARE @i INT = 1;

    WHILE @i <= 60
    BEGIN
        INSERT INTO gym.HorarioClase (ClaseID, EntrenadorID, FechaHoraInicio, DuracionMin, Cupo)
        SELECT
          ((@i - 1) % 4) + 1 AS ClaseID,               -- rota entre 4 clases
          ((@i - 1) % 100) + 1 AS EntrenadorID,        -- rota entre 100 entrenadores
          DATEADD(HOUR, @i, SYSDATETIME()) AS FechaHoraInicio,
          CASE (@i % 3) WHEN 0 THEN 45 WHEN 1 THEN 60 ELSE 90 END AS DuracionMin,
          CASE (@i % 3) WHEN 0 THEN 15 WHEN 1 THEN 20 ELSE 25 END AS Cupo;

        SET @i = @i + 1;
    END;
END;
-- ===== FIN BLOQUE 4 =====


/* =============== BLOQUE 5: Reservas =============== */

IF NOT EXISTS (SELECT 1 FROM gym.Reserva)
BEGIN
    INSERT INTO gym.Reserva (SocioID, HorarioID, Estado, FechaReserva)
    SELECT TOP (800)
        s.SocioID,
        h.HorarioID,
        CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN N'Cancelada'
            WHEN 1 THEN N'NoShow'
            ELSE N'Confirmada'
        END AS Estado,
        DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % 30), SYSDATETIME())
    FROM gym.Socio s
    CROSS JOIN gym.HorarioClase h
    WHERE s.SocioID <= 300
    ORDER BY NEWID();
END;
-- ===== FIN BLOQUE 5 =====


/* =============== BLOQUE 6: Pagos =============== */

IF NOT EXISTS (SELECT 1 FROM gym.Pago)
BEGIN
    INSERT INTO gym.Pago (SocioID, Monto, FechaPago, Metodo, Concepto, MetodoPagoID)
    SELECT TOP (500)
        s.SocioID,
        CASE (ABS(CHECKSUM(NEWID())) % 3)
            WHEN 0 THEN 20.00
            WHEN 1 THEN 35.00
            ELSE 50.00
        END AS Monto,
        DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % 60), CAST(GETDATE() AS DATE)) AS FechaPago,
        mp.Nombre,
        N'Mensualidad',
        mp.MetodoPagoID
    FROM gym.Socio s
    CROSS JOIN gym.MetodoPago mp
    ORDER BY NEWID();
END;
-- ===== FIN BLOQUE 6 =====

--consultas solo para probar:
USE DB_Gimnasio;

SELECT COUNT(*) AS Socios        FROM gym.Socio;
SELECT COUNT(*) AS Entrenadores  FROM gym.Entrenador;
SELECT COUNT(*) AS Horarios      FROM gym.HorarioClase;
SELECT COUNT(*) AS Reservas      FROM gym.Reserva;
SELECT COUNT(*) AS Pagos         FROM gym.Pago;

