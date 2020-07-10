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
            "token":    <token_id|null(en caso de que no tenga)>
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

-   sector: <sector, isla, hospital>

Respuestas:

-   Si el cliente esta en la lista de conectados:
    
    -   status: "200 OK"
    -   result:
        -   token: <token_viejo>
    -   https_status: 200

-   Si el cliente no esta en la lista de conectados:

    -   status: "205 Reset Content"
    -   result:
        -   token: <nuevo_token(uuid)>
        -   db: <toda la base de datos, o como descargarla>
    -   http_status: "205 Reset Content"

-   Si el sector es incorrecto:

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

-   sector: <sector, isla, hospital>

Respuestas:

-   Si el cliente esta en la lista de conectados:
    
    -   status: "200 OK"
    -   result:
        -   token: <token_viejo>
    -   https_status: 200

-   Si el cliente no esta en la lista de conectados:

    -   status: "205 Reset Content"
    -   result:
        -   token: <nuevo_token(uuid)>
        -   
    -   http_status: "205 Reset Content"
    -   *El cliente debe reconectar enviando la DB*

-   Otros:

    -   status: "400 Bad Request"
    -   result: {}
    -   http_status: "400 Bad Request"

TODO: Como actualizar la DB de la nube.

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

# new_<data>

**Nota:** <data> puede ser cada una de las tablas: "control_enfermeria,
laboratorio, rx_torax, alerta, episodio, hcpasiente"

Parámetros:

-   data: <dict_datos>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
        -   sync_id: <sync_id>
        -   triage: <res_triage>
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result: {}
    -   http_status: "401 Unauthorized"


# get_<data>

**Nota:** <data> puede ser cada una de las tablas: "controles_enfermeria,
laboratorios, rx_toraxs, alertas, episodios, hcpasientes"

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

# get_update

Parámetros:

-   sync_id: <max_sync_id>

Respuestas:

-   Si el servidor reconoce el token y esta en la lista de conectados:

    -   status: "200 OK"
    -   result:
    -   https_status: 200

-   Si no reconoce el token o no esta en la lista de conectados:

    -   status: "401 Unauthorized"
    -   result:
        -   controles_enfermeria: [lista de `control_de_enfermeria`]
        -   laboratorios: [lista de `laboratorio`]
        -   rx_toraxs: [lista de `rx_torax`]
        -   alertas: [lista de `alerta`]
        -   episodios: [lista de `episodio`]
        -   hcpasientes: [lista de `hcpasiente`]
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

