<!-- vim: set syntax=txt spelllang=es spell: -->

TODO:

-   En caso de que el líder se caiga, tiene el nuevo líder tiene que avisarle
    al resto.

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

Parámetros:

-   usuario
-   password
-   hospital
-   isla
-   sector

Respuestas:

-   Si el cliente esta en la lista de conectados:
    
    -   status: "200 OK"
    -   result:
        -   token: <token>
    -   https_status: 200

-   Si el login es incorrecto:

    -   status: "403 Forbidden"
    -   result: {}
    -   http_status: "403 Forbidden"

-   Si es la nube y no tiene conexión al líder:
    
    -   status: "503 Service Unavailable"
    -   result: {}
    -   http_status: "503 Service Unavailable"

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

# hello_cloud

Parámetros:

-   usuario
-   password
-   hospital
-   isla
-   sector

Respuestas:

-   Si el cliente esta en la lista de conectados:
    
    -   status: "200 OK"
    -   result:
        -   token: <token>
    -   https_status: 200

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
`laboratorio`, `rx_torax`, `alerta` o `episodio` en cuyo caso retornan un
triage, o `camas`, `hcpasientes`, `islas`, `sectores`, `usuarios_hospital`,
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


# get_data

**Nota:** <data> puede ser cada una de las tablas: `control_enfermeria`,
`laboratorio`, `rx_torax`, `alerta`, `episodio`,`camas`, `hcpasientes`,
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

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

-   Otros posibles casos:
    -   Que no reconozca el usuario.

# get_hospital

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   data: <hospital>
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

# get_datos_usuario

Parámetros:

-   hospital
-   cuil

Respuestas:

-   Si no se produce un error:

    -   status: "200 OK"
    -   result:
        -   sectores: [lista de sectores]
        -   roles: [lista de roles]
    -   https_status: 200

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

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
        -   hcpasientes: [lista de `hcpasiente`]
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

(se puede hacer esto??)

Parámetros:

-   data: <dict_datos>

Respuestas:

-   Siempre que se reconozca el mensaje:

    -   status: "200 OK"
    -   result: {}
    -   https_status: 200

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

