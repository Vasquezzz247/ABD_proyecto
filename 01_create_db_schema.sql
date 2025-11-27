/* ============================================================
   01_create_db_schema.sql
   Crea la BD DB_Gimnasio, ajusta dimensionamiento básico,
   esquema gym, tablas, relaciones e índices.
   ============================================================ */

-- recrear la db
/*
IF DB_ID('DB_Gimnasio') IS NOT NULL
BEGIN
    ALTER DATABASE DB_Gimnasio SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DB_Gimnasio;
END;
*/

-- Crear BD si no existe
IF DB_ID('DB_Gimnasio') IS NULL
BEGIN
    CREATE DATABASE DB_Gimnasio;
END;

USE DB_Gimnasio;

--Dimensionamiento básico:

ALTER DATABASE DB_Gimnasio
MODIFY FILE (NAME = DB_Gimnasio, SIZE = 100MB, FILEGROWTH = 50MB);
ALTER DATABASE DB_Gimnasio
MODIFY FILE (NAME = DB_Gimnasio_log, SIZE = 50MB, FILEGROWTH = 25MB);

-- Crear esquema lógico para separar objetos de negocio
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gym')
    EXEC('CREATE SCHEMA gym');

/* ==========================
   TABLAS MAESTRAS / CATÁLOGOS
   ========================== */

-- Planes de membresía
IF OBJECT_ID('gym.Membresia', 'U') IS NULL
BEGIN
    CREATE TABLE gym.Membresia(
        MembresiaID   INT IDENTITY PRIMARY KEY,
        NombrePlan    NVARCHAR(100) NOT NULL,
        PrecioMensual DECIMAL(10,2) NOT NULL,
        DuracionMeses INT NOT NULL,              -- 1, 3, 6, 12, etc.
        Descripcion   NVARCHAR(250) NULL
    );
END;

-- Métodos de pago (catálogo)
IF OBJECT_ID('gym.MetodoPago', 'U') IS NULL
BEGIN
    CREATE TABLE gym.MetodoPago(
        MetodoPagoID INT IDENTITY PRIMARY KEY,
        Nombre       NVARCHAR(50) NOT NULL,
        Activo       BIT NOT NULL DEFAULT 1
    );
END;

/* ===============================
   TABLAS PRINCIPALES DE NEGOCIO
   =============================== */

-- Socios del gimnasio
IF OBJECT_ID('gym.Socio', 'U') IS NULL
BEGIN
    CREATE TABLE gym.Socio(
      SocioID      INT IDENTITY PRIMARY KEY,
      Nombre       NVARCHAR(120) NOT NULL,
      Email        NVARCHAR(120) UNIQUE NOT NULL,
      Telefono     NVARCHAR(30)  NULL,
      Estado       TINYINT NOT NULL DEFAULT 1,     -- 1=Activo,0=Inactivo
      FechaAlta    DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
      MembresiaID  INT NULL
    );
END;

-- Entrenadores
IF OBJECT_ID('gym.Entrenador', 'U') IS NULL
BEGIN
    CREATE TABLE gym.Entrenador(
      EntrenadorID INT IDENTITY PRIMARY KEY,
      Nombre       NVARCHAR(120) NOT NULL,
      Especialidad NVARCHAR(120) NULL
    );
END;

-- Clases (tipo de clase)
IF OBJECT_ID('gym.Clase', 'U') IS NULL
BEGIN
    CREATE TABLE gym.Clase(
      ClaseID    INT IDENTITY PRIMARY KEY,
      Nombre     NVARCHAR(120) NOT NULL,
      Nivel      NVARCHAR(50)  NULL,
      CupoMaximo INT NOT NULL CHECK (CupoMaximo > 0)
    );
END;

-- Programación de clases
IF OBJECT_ID('gym.HorarioClase', 'U') IS NULL
BEGIN
    CREATE TABLE gym.HorarioClase(
      HorarioID       INT IDENTITY PRIMARY KEY,
      ClaseID         INT NOT NULL,
      EntrenadorID    INT NOT NULL,
      FechaHoraInicio DATETIME2 NOT NULL,
      DuracionMin     INT NOT NULL CHECK (DuracionMin BETWEEN 15 AND 240),
      Cupo            INT NOT NULL CHECK (Cupo > 0)
    );
END;

-- Reservas de socios
IF OBJECT_ID('gym.Reserva', 'U') IS NULL
BEGIN
    CREATE TABLE gym.Reserva(
      ReservaID    INT IDENTITY PRIMARY KEY,
      SocioID      INT NOT NULL,
      HorarioID    INT NOT NULL,
      Estado       NVARCHAR(20) NOT NULL DEFAULT 'Confirmada', -- Confirmada/Cancelada/NoShow
      FechaReserva DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;

-- Pagos de socios
IF OBJECT_ID('gym.Pago', 'U') IS NULL
BEGIN
    CREATE TABLE gym.Pago(
      PagoID       INT IDENTITY PRIMARY KEY,
      SocioID      INT NOT NULL,
      Monto        DECIMAL(12,2) NOT NULL CHECK (Monto > 0),
      FechaPago    DATE NOT NULL,
      Metodo       NVARCHAR(30) NOT NULL,
      Concepto     NVARCHAR(120) NULL,
      MetodoPagoID INT NULL
    );
END;

/* ==========================
   CLAVES FORÁNEAS
   ========================== */

-- Socio -> Membresia
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Socio_Membresia')
BEGIN
    ALTER TABLE gym.Socio
        ADD CONSTRAINT FK_Socio_Membresia
        FOREIGN KEY (MembresiaID) REFERENCES gym.Membresia(MembresiaID);
END;

-- HorarioClase -> Clase
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HC_Clase')
BEGIN
    ALTER TABLE gym.HorarioClase
        ADD CONSTRAINT FK_HC_Clase
        FOREIGN KEY (ClaseID) REFERENCES gym.Clase(ClaseID);
END;

-- HorarioClase -> Entrenador
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HC_Entrenador')
BEGIN
    ALTER TABLE gym.HorarioClase
        ADD CONSTRAINT FK_HC_Entrenador
        FOREIGN KEY (EntrenadorID) REFERENCES gym.Entrenador(EntrenadorID);
END;

-- Reserva -> Socio
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_R_Socio')
BEGIN
    ALTER TABLE gym.Reserva
        ADD CONSTRAINT FK_R_Socio
        FOREIGN KEY (SocioID) REFERENCES gym.Socio(SocioID);
END;

-- Reserva -> HorarioClase
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_R_Horario')
BEGIN
    ALTER TABLE gym.Reserva
        ADD CONSTRAINT FK_R_Horario
        FOREIGN KEY (HorarioID) REFERENCES gym.HorarioClase(HorarioID);
END;

-- Pago -> Socio
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_P_Socio')
BEGIN
    ALTER TABLE gym.Pago
        ADD CONSTRAINT FK_P_Socio
        FOREIGN KEY (SocioID) REFERENCES gym.Socio(SocioID);
END;

-- Pago -> MetodoPago
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Pago_MetodoPago')
BEGIN
    ALTER TABLE gym.Pago
        ADD CONSTRAINT FK_Pago_MetodoPago
        FOREIGN KEY (MetodoPagoID) REFERENCES gym.MetodoPago(MetodoPagoID);
END;

-- Restricción única para evitar doble reserva del mismo socio en mismo horario
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Reserva_Socio_Horario')
BEGIN
    ALTER TABLE gym.Reserva
        ADD CONSTRAINT UQ_Reserva_Socio_Horario UNIQUE (SocioID, HorarioID);
END;

/* ==========================
   ÍNDICES PARA OPTIMIZACIÓN
   ========================== */

CREATE INDEX IX_Reserva_Socio_Horario
ON gym.Reserva (SocioID, HorarioID);

CREATE INDEX IX_Pago_Socio_Fecha
ON gym.Pago (SocioID, FechaPago);

CREATE INDEX IX_HorarioClase_Clase
ON gym.HorarioClase (ClaseID, FechaHoraInicio);
