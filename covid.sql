-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 15-09-2020 a las 01:16:08
-- Versión del servidor: 10.4.13-MariaDB
-- Versión de PHP: 7.2.32

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `covid`
--

-- --------------------------------------------------------

--
-- Tablas para guardar el máximo sync ID, solo de la nube
--
CREATE TABLE `SyncIDHosp` (
  `sync_id` int(11),
  `idHosp` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `SyncIDIsla` (
  `sync_id` int(11),
  `idHosp` varchar(15),
  `idIsla` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Estructura de tabla para la tabla `Alerta`
--
CREATE TABLE `Alerta` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `numeroHC` varchar(15),
  `fechaAlerta` bigint(11),
  `gravedadAlerta` int(11),
  `gravedadAnterior` int(11),
  `anotacionMedico` varchar(150),
  `auditoriaMedico` varchar(15),
  `ocultarAlerta` int(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Cama`
--

CREATE TABLE `Cama` (
  `sync_id` int(11),
  `idHospitalCama` varchar(15),
  `idSector` varchar(15),
  `idCama` varchar(150),
  `numeroHCPac` varchar(15),
  `ubicacionX` int(11),
  `ubicacionY` int(11),
  `orientacion` varchar(30),
  `estado` int(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Episodio`
--

CREATE TABLE `Episodio` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `numeroHC` varchar(15),
  `fechaIngreso` bigint(11),
  `fechaEgreso` bigint(11),
  `razon` varchar(30),
  `cuil` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Hospital`
--

CREATE TABLE `Hospital` (
  `sync_id` int(11),
  `idHosp` varchar(15),
  `nombre` varchar(150),
  `calle` varchar(150),
  `numero` varchar(15),
  `CP` varchar(15),
  `planoCamas` varchar(300)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Isla`
--

CREATE TABLE `Isla` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `idIsla` varchar(15),
  `idLider` int(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Laboratorio`
--

CREATE TABLE `Laboratorio` (
  `sync_id` int(11),
  `idHospitalLab` varchar(15),
  `numeroHCLab` varchar(15),
  `fecha` bigint(11),
  `cuil` varchar(15),
  `dimeroD` int(11),
  `linfopenia` int(11),
  `plaquetas` int(11),
  `ldh` int(11),
  `ferritina` int(11),
  `proteinaC` float
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `HCpaciente`
--

CREATE TABLE `HCpaciente` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `idIsla` varchar(15),
  `numeroHC` varchar(15),
  `tipoDocumento` varchar(15),
  `paisExp` varchar(15),
  `dni` varchar(15),
  `nombre` varchar(150),
  `apellido` varchar(150),
  `nacionalidad` varchar(15),
  `genero` varchar(15),
  `calle` varchar(150),
  `numero` varchar(15),
  `piso` varchar(15),
  `id_provincia` int(11),
  `id_loc` int(11),
  `CP` varchar(15),
  `telefono` varchar(15),
  `telefonoFamiliar` varchar(15),
  `telefonoFamiliar2` varchar(15),
  `fechaNac` bigint(11),
  `gravedad` int(11),
  `nivelConfianza` int(11),
  `auditoriaComorbilidades` varchar(15),
  `iccGrado2` int(11),
  `epoc` int(11),
  `diabetesDanioOrgano` int(11),
  `hipertension` int(11),
  `obesidad` int(11),
  `enfermedadRenalCronica` int(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `RxTorax`
--

CREATE TABLE `RxTorax` (
  `sync_id` int(11),
  `idHospitalRad` varchar(15),
  `numeroHCRad` varchar(15),
  `fechaRad` bigint(11),
  `cuil` varchar(15),
  `resultadoRad` varchar(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Sector`
--

CREATE TABLE `Sector` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `idIsla` varchar(15),
  `idSector` varchar(15),
  `descripcion` varchar(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `SignosVitales`
--

CREATE TABLE `SignosVitales` (
  `sync_id` int(11),
  `id_hospital` varchar(15),
  `numeroHCSignosVitales` varchar(15),
  `fechaSignosVitales` bigint(11),
  `auditoria` varchar(15),
  `frec_resp` int(11),
  `sat_oxi` int(11),
  `disnea` varchar(30),
  `oxigenoSuplementario` varchar(30),
  `fraccionInsOxigeno` int(11),
  `presSist` int(11),
  `frec_card` int(11),
  `temp` double,
  `nivelConciencia` varchar(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Usuario`
--

CREATE TABLE `Usuario` (
  `cuil` varchar(15),
  `clave` varchar(150),
  `sal` varchar(37),
  `nombre` varchar(150),
  `apellido` varchar(150),
  `email` varchar(150),
  `telefono` varchar(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `UsuarioHospital`
--

CREATE TABLE `UsuarioHospital` (
  `sync_id` int(11),
  `sync_id_usuario` int(11),
  `idHospital` varchar(15),
  `cuil` varchar(15),
  `idRol` int(11),
  `estadoLaboral` int(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `UsuarioSector`
--

CREATE TABLE `UsuarioSector` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `idSector` varchar(15),
  `cuil` varchar(15),
  `estado` int(11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indices de la tabla `Alerta`
--
ALTER TABLE `Alerta`
  ADD PRIMARY KEY (`idHospital`,`numeroHC`,`fechaAlerta`);

--
-- Indices de la tabla `Cama`
--
ALTER TABLE `Cama`
  ADD PRIMARY KEY (`idHospitalCama`,`idSector`,`idCama`);

--
-- Indices de la tabla `Episodio`
--
ALTER TABLE `Episodio`
  ADD PRIMARY KEY (`idHospital`,`numeroHC`,`fechaIngreso`);

--
-- Indices de la tabla `Hospital`
--
ALTER TABLE `Hospital`
  ADD PRIMARY KEY (`idHosp`);

--
-- Indices de la tabla `Isla`
--
ALTER TABLE `Isla`
  ADD PRIMARY KEY (`idHospital`,`idIsla`);

--
-- Indices de la tabla `Laboratorio`
--
ALTER TABLE `Laboratorio`
  ADD PRIMARY KEY (`idHospitalLab`,`numeroHCLab`,`fecha`);

--
-- Indices de la tabla `HCpaciente`
--
ALTER TABLE `HCpaciente`
  ADD PRIMARY KEY (`idHospital`,`idIsla`,`numeroHC`);

--
-- Indices de la tabla `RxTorax`
--
ALTER TABLE `RxTorax`
  ADD PRIMARY KEY (`idHospitalRad`,`numeroHCRad`,`fechaRad`);

--
-- Indices de la tabla `Sector`
--
ALTER TABLE `Sector`
  ADD PRIMARY KEY (`idHospital`,`idSector`);

--
-- Indices de la tabla `SignosVitales`
--
ALTER TABLE `SignosVitales`
  ADD PRIMARY KEY (`id_hospital`,`numeroHCSignosVitales`,`fechaSignosVitales`);

--
-- Indices de la tabla `Usuario`
--
ALTER TABLE `Usuario`
  ADD PRIMARY KEY (`cuil`);

--
-- Indices de la tabla `UsuarioHospital`
--
ALTER TABLE `UsuarioHospital`
  ADD PRIMARY KEY (`idHospital`,`cuil`,`idRol`);

--
-- Indices de la tabla `UsuarioSector`
--
ALTER TABLE `UsuarioSector`
  ADD PRIMARY KEY (`idHospital`,`idSector`,`cuil`);

ALTER TABLE `SyncIDHosp`
  ADD PRIMARY KEY (`idHosp`);

ALTER TABLE `SyncIDIsla`
  ADD PRIMARY KEY (`idHosp`, `idIsla`);

INSERT INTO Usuario VALUES ("20-0000-0", "c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec", "", "admin", "admin_ln" , "admin@hospital", "1212");

INSERT INTO Hospital VALUES (1, "H0", "hospital 01", "siempre viva 1234", "(299)0000", "8300", "url_plano");

INSERT INTO UsuarioHospital VALUES (3, 2, "H0", "20-0000-0", 0, 1);

INSERT INTO Isla VALUES (3, "H0", "I0", 0);

INSERT INTO Sector VALUES (4, "H0", "I0", "S0", "Sector Test!");

INSERT INTO UsuarioSector VALUES (5, "H0", "S0", "20-0000-0", 1);

INSERT INTO SyncIDHosp VALUES (5, "H0");

INSERT INTO SyncIDIsla VALUES (0, "H0", "I0");

COMMIT;


/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
