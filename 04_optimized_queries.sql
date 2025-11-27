/* ============================================================
   04_optimized_queries.sql
   Consultas optimizadas y funciones ventana
   para usar en el informe y en Power BI.
   ============================================================ */

USE DB_Gimnasio;

-- 1) Top 10 clases por número de reservas (usa IX_Reserva_Socio_Horario, IX_HorarioClase_Clase)
SELECT TOP 10
    c.Nombre AS Clase,
    COUNT(*) AS TotalReservas,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS RankingPopularidad
FROM gym.Reserva r
JOIN gym.HorarioClase h ON h.HorarioID = r.HorarioID
JOIN gym.Clase c        ON c.ClaseID = h.ClaseID
GROUP BY c.Nombre
ORDER BY TotalReservas DESC;

-- 2) Ingresos mensuales por socio con acumulado (función ventana)
WITH PagosMes AS (
    SELECT
        s.SocioID,
        s.Nombre,
        DATEFROMPARTS(YEAR(p.FechaPago), MONTH(p.FechaPago), 1) AS Mes,
        SUM(p.Monto) AS TotalMes
    FROM gym.Pago p
    JOIN gym.Socio s ON s.SocioID = p.SocioID
    GROUP BY s.SocioID, s.Nombre,
             DATEFROMPARTS(YEAR(p.FechaPago), MONTH(p.FechaPago), 1)
)
SELECT
    SocioID,
    Nombre,
    Mes,
    TotalMes,
    SUM(TotalMes) OVER (PARTITION BY SocioID ORDER BY Mes
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS AcumuladoPorSocio
FROM PagosMes
ORDER BY SocioID, Mes;

-- 3) Ocupación promedio de cada horario (reservas / cupo)
SELECT
    h.HorarioID,
    c.Nombre AS Clase,
    h.FechaHoraInicio,
    h.Cupo,
    COUNT(r.ReservaID) AS Reservas,
    CAST(COUNT(r.ReservaID) * 100.0 / h.Cupo AS DECIMAL(5,2)) AS PorcentajeOcupacion
FROM gym.HorarioClase h
LEFT JOIN gym.Reserva r ON r.HorarioID = h.HorarioID AND r.Estado = 'Confirmada'
JOIN gym.Clase c ON c.ClaseID = h.ClaseID
GROUP BY h.HorarioID, c.Nombre, h.FechaHoraInicio, h.Cupo
ORDER BY PorcentajeOcupacion DESC;
