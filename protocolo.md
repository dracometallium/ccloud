<!-- vim: set syntax=txt spelllang=es spell: -->

TODO:

-   En caso de que el líder se caiga, el nuevo líder tiene que avisarle al
    resto.

-   Como se autentifican.

Enviar un inser_id por tabla.

# Formato:

-   Petición:

        {
            "version":  "0.0",
            "method":   <nombre_metodo>,
            "params":   <dict_parametros>,
            "id":       <uuid_para_respuesta_async>
            "token":    <token_id|null(para `hello`)>
        }

-   Respuesta:

        {
            "version":  "0.0",
            "status:"   <status_return>,
            "result":   <dict_respuesta>,
            "id":       <uuid_para_respuesta_async>
        }

**Nota:** El campo "http_status" no debe ser retornado como parte del _json_
sino que es el estatus que debe retornar la petición _HTTP_.

# hello

Identificación del usuario al líder (o la nube simulando ser un lider). El
handshake completo consta de dos pasos, `hello` y `connect`. El primero sirve
para identificar el usuario correctamente, y el segundo para seleccionar el
hospital, isla y sector.

Este método genera el token, por lo cual el enviado en la petición se ignora.

Parámetros:

-   usuario
-   password

Respuestas:

-   Si el cliente se identifico correctamente:

    -   status: "200 OK"
    -   result:
        -   token: <token>
        -   usuario: <datos del usuario>
        -   hospitales:
            -   [diccionario de <id_hospital>]:
                -   roles: [lista de roles]
                -   sectores:
                    -   <id_isla>: [lista de <id_sector>]
    -   https_status: 200

-   Si el login es incorrecto:

    -   status: "403 Forbidden"
    -   result: {}
    -   http_status: "403 Forbidden"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

# hello_cloud

Identificación del usuario a la nube (por parte del lider). El handshake
completo consta de dos pasos, `hello_cloud` y `connect`. El primero sirve para
identificar el usuario correctamente, y el segundo para seleccionar el
hospital, isla y sector.

Este método genera el token, por lo cual el enviado en la petición se ignora.

Parámetros:

-   usuario
-   password

Respuestas:

-   Si el cliente se identifico correctamente:

    -   status: "200 OK"
    -   result:
        -   token: <token>
        -   usuario: <datos del usuario>
        -   hospitales:
            -   [diccionario de <id_hospital>]:
                -   roles: [lista de roles]
                -   sectores:
                    -   <id_isla>: [lista de <id_sector>]
    -   https_status: 200

-   Si el login es incorrecto:

    -   status: "403 Forbidden"
    -   result: {}
    -   http_status: "403 Forbidden"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

# Connect

Segunda parte del handshake, selecciona el hospital, isla y sector.  Si se
quiere mantener la conexión con un líder, deben estar especificados todos los
parámetros. Si solo se desea acceder a los datos compartidos de un hospital,
solo se necesitara especificar el id de este. Este último modo de operación no
estará habilitado por el momento.

Si no se realiza este paso, cualquier otro método debería falla.

Parámetros:

-   Hospital
-   Isla
-   Sector
-   sync_id_isla: opcional. Si es distinto de nil, envía la actualización de la isla.
-   sync_id_hospital: opcional. Si es distinto de nil, envía la actualización
    del hospital.

Respuestas:

-   Si el cliente se identifico correctamente:

    -   status: "200 OK"
        -   sync_id_isla: <max_sync_id_isla>
        -   sync_id_hospital: <max_sync_id_hospital>
        -   update: %{<datos_update>}
    -   https_status: 200

-   Si el usuario no esta asignado al hospital, isla y sector:

    -   status: "403 Forbidden"
    -   result: {}
    -   http_status: "403 Forbidden"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

# Ping

(enviar cada <x> segundos)

Parámetros:

-   ping: <rand>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   pong: <mismo_rand>
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

# new_data

**Nota:** <data> puede ser cada una de las tablas: `control_enfermeria`,
`laboratorio`, `rx_torax`, `alerta`, `hcpaciente` o `episodio` en cuyo caso
retornan un triage, o `camas`, `isla`, `sector`, `usuario_hospital`,
`usuario_sector` u `hospital` en cuyo caso no retornan el triage.

Parámetros:

-   data: <dict_datos>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   sync_id: <sync_id>
        -   triage: <valor 1 a 4> #solo algunas tablas.
    -   https_status: 200

-   Si es un dato de líder pero no tiene conexión al este:

    -   status: "503 Service Unavailable"
    -   result: {}
    -   http_status: "503 Service Unavailable"

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"


# get_data

**Nota:** <data> puede ser cada una de las tablas: `control_enfermeria`,
`laboratorio`, `rx_torax`, `alerta`, `episodio`,`camas`, `hcpacientes`,
`islas`, `sectores`, `usuarios_hospital`, `usuarios_sector`.

Parámetros:

-   sync_id: <max_sync_id>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   data: [lista de datos]
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"

-   Si es un dato de líder pero no tiene conexión al este:

    -   status: "503 Service Unavailable"
    -   result: {}
    -   http_status: "503 Service Unavailable"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

-   Otros posibles casos:
    -   Que no reconozca el usuario.

# modify_data

**Nota:** <data> puede ser cada una de las tablas: `control_enfermeria`,
`laboratorio`, `rx_torax`, `alerta`, `hcpaciente` o `episodio` en cuyo caso
retornan un triage, o `cama`, `islas`, `sectores`, `usuarios_hospital`,
`usuarios_sector` u `hospital` en cuyo caso no retornan el triage.

Parámetros:

-   data: <dict_datos>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   sync_id: <sync_id>
        -   triage: <valor 1 a 4> #solo algunas tablas.
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"

-   Si es un dato de líder pero no tiene conexión al este:

    -   status: "503 Service Unavailable"
    -   result: {}
    -   http_status: "503 Service Unavailable"

# get_update

Parámetros:

-   sync_id_isla: <max_sync_id_isla>
-   sync_id_hospital: <max_sync_id_hospital>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   controles_enfermeria: [lista de `control_de_enfermeria`]
        -   laboratorios: [lista de `laboratorio`]
        -   rx_toraxs: [lista de `rx_torax`]
        -   alertas: [lista de `alerta`]
        -   episodios: [lista de `episodio`]
        -   camas: [lista de `cama`]
        -   hcpacientes: [lista de `hcpasiente`]
        -   islas: [lista de `isla`]
        -   sectores: [lista de `sector`]
        -   usuarios_hospital: [lista de `usuario_hospital`]
        -   usuarios_sector: [lista de `usuario_sector`]
        -   hospital: <hospital|null>
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

-   Otros posibles casos:
    -   Que no reconozca el usuario.

# copy_data

**Nota:** <tipo> puede ser cada una de las tablas: `control_enfermeria`,
`laboratorio`, `rx_torax`, `alerta`, `hcpaciente` o `episodio` en cuyo caso
retornan un triage, o `cama`, `isla`, `sector`, `usuario_hospital`,
`usuario_sector` u `hospital`.

Parámetros:

-   dato: <dict_datos>
-   tipo: <string>
-   triage: <int | nil>
-   nHC: <strign | nil>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   sync_id: <sync_id>
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"

