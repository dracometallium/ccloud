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
-- Estructura de tabla para la tabla `Alerta`
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

CREATE TABLE `Alerta` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `numeroHC` varchar(15),
  `fechaAlerta` int(11),
  `gravedadAlerta` int(11),
  `gravedadAnterior` int(11),
  `get_laboratorios` varchar(15),
  `anotacionEnfermero` varchar(150),
  `auditoriaEnfermero` varchar(15),
  `calificacionMedico` varchar(15),
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
  `idIsla` varchar(150),
  `idSector` varchar(15),
  `idCama` varchar(150),
  `numeroHCPac` varchar(15),
  `ubicacionX` int(11),
  `ubicacionY` int(11),
  `orientacion` varchar(150),
  `estado` varchar(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Episodio`
--

CREATE TABLE `Episodio` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `numeroHC` varchar(15),
  `fechaIngreso` int(11),
  `fechaEgreso` int(11),
  `razon` varchar(15),
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
  `planoCamas` varchar(150)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `Hospital`
--

-- INSERT INTO `Hospital` (`sync_id`, `idHosp`, `nombre`, `calle`, `numero`, `CP`, `planoCamas`) VALUES
-- (1, 0, 'Francisco López Lima', 'E. Gelonch', '721', 'R8332', ''),
-- (2, 1, 'Provincial Neuquen Dr. Castro Rendon', 'Buenos Aires', '450', 'Q8300', '');

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

--
-- Volcado de datos para la tabla `Isla`
--

-- INSERT INTO `Isla` (`sync_id`, `idHospital`, `idIsla`, `idLider`) VALUES
-- (3, 0, 'I0', 1),
-- (4, 0, 'I1', 1),
-- (5, 1, 'I3', 1),
-- (6, 1, 'I4', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Laboratorio`
--

CREATE TABLE `Laboratorio` (
  `sync_id` int(11),
  `idHospitalLab` varchar(15),
  `numeroHCLab` varchar(15),
  `fecha` int(11),
  `cuil` varchar(15),
  `dimeroD` int(11),
  `Linfopenia` int(11),
  `plaquetas` int(11),
  `ldh` int(11),
  `ferritina` int(11),
  `proteinaC` double
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `HCpaciente`
--

CREATE TABLE `HCpaciente` (
  `sync_id` int(11),
  `idHospital` varchar(15),
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
  `CP` varchar(15),
  `telefono` varchar(15),
  `telefonoFamiliar` varchar(15),
  `telefonoFamiliar2` varchar(15),
  `fechaNac` int(11),
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
  `fechaRad` int(11),
  `cuil` varchar(15),
  `resultadoRad` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Sector`
--

CREATE TABLE `Sector` (
  `sync_id` int(11),
  `idHospital` varchar(15),
  `idIsla` varchar(150),
  `idSector` varchar(15),
  `descripcion` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `SignosVitales`
--

CREATE TABLE `SignosVitales` (
  `sync_id` int(11),
  `id_hospital` varchar(15),
  `numeroHCSignosVitales` varchar(15),
  `fechaSignosVitales` int(11),
  `auditoria` varchar(15),
  `frec_resp` int(11),
  `sat_oxi` int(11),
  `disnea` varchar(15),
  `oxigenoSuplementario` varchar(15),
  `fraccionInsOxigeno` int(11),
  `presSist` int(11),
  `frec_card` int(11),
  `temp` double,
  `nivelConciencia` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Usuario`
--

CREATE TABLE `Usuario` (
  `cuil` varchar(15),
  `clave` varchar(150),
  `nombre` varchar(150),
  `apellido` varchar(150),
  `email` varchar(150),
  `telefono` varchar(15)
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
  `idIsla` varchar(150),
  `idSector` varchar(15),
  `cuil` varchar(15),
  `estado` varchar(15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `Alerta`
--
ALTER TABLE `Alerta`
  ADD PRIMARY KEY (`idHospital`,`numeroHC`,`fechaAlerta`);

--
-- Indices de la tabla `Cama`
--
ALTER TABLE `Cama`
  ADD PRIMARY KEY (`idHospitalCama`,`idIsla`,`idSector`,`idCama`);

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
  ADD PRIMARY KEY (`idHospital`,`numeroHC`);

--
-- Indices de la tabla `RxTorax`
--
ALTER TABLE `RxTorax`
  ADD PRIMARY KEY (`idHospitalRad`,`numeroHCRad`,`fechaRad`);

--
-- Indices de la tabla `Sector`
--
ALTER TABLE `Sector`
  ADD PRIMARY KEY (`idHospital`,`idIsla`,`idSector`);

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
  ADD PRIMARY KEY (`idHospital`,`idIsla`,`idSector`,`cuil`);

ALTER TABLE `SyncIDHosp`
  ADD PRIMARY KEY (`idHosp`);

ALTER TABLE `SyncIDIsla`
  ADD PRIMARY KEY (`idHosp`, `idIsla`);
COMMIT;


/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
