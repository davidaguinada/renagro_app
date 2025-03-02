from fastapi import FastAPI, HTTPException, Path, Body
import yaml
from apiFunciones import *

app = FastAPI(
    title="RENAGRO API",
    description="Esta es una RESTapi desarrollada para el control de calidad de entrevistas del RENAGRO",
    version="1.0.0",
    contact={
        "name": "Vladimir Aguiñada", 
        "email": "contacto@renagro.com"},
    swagger_ui_parameters={"defaultModelsExpandDepth": -1}
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow specific origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)
# -----------------  ENDPOINTS 

@app.get("/monitores", description="**Obtén** la lista general de monitores", tags=["Consultas"])
async def obtener_monitores_endpoint():
    try:
        results = obtener_monitores(redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/monitores", description="**Agrega** un nuevo monitor", tags=["Mantenimiento"])
async def guardar_monitor_endpoint(params: Monitor):
    try:
        results = guardar_monitor(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.delete("/monitores/{monitor_id}", description="**Elimina** un monitor existente", tags=["Mantenimiento"])
async def eliminar_monitor_endpoint(monitor_id: str = Path(..., description="ID del monitor a eliminar")):
    try:
        results = elimina_monitor(monitor_id, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/actividad", description= "**Obtén** detalles de la actividad de los registradores", tags=["Consultas"] )
async def actividad_endpoint(params: Params_monitoreo):
    try:
        results = actividad(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/actividad_agrupada", description= "**Obtén** detalles de la actividad de los registradores", tags=["Consultas"] )
async def actividad_endpoint(params: Params_monitoreo):
    try:
        results = actividad(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/regionalizacion" , description="**Obtén** acceso al catalogo de _regionalización del MA_" , tags=["Consultas"])
async def regionalizacion_endpoint(params: Params_regionalizacion):
    try:
        results = regionalizacion(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/division_territorial" , description="**Obtén** acceso al catalogo de _division territorial_" , tags=["Consultas"])
async def division_territorial_endpoint(params: Params_diviterr):
    try:
        results = division_territorial(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/usuario" , description="**Busca** al usuario indicado en Survey Solutions" , tags=["Consultas"])
async def usuario_endpoint(params: Params_usuario):
    try:
        results = usuario(params, suso_server, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/registradores_subalternos", description="**Obtén** los registradores que se encuentran debajo de un Headqarter, Monitor o Supervisor", tags=["Consultas"])
async def registradores_subalternos__endpoint(params: Params_subalternos):
    try:
        results = registradores_subalternos(params, suso_server, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/supervisores_subalternos", description="**Obtén** los registradores que se encuentran debajo de un Headqarter, Monitor o Supervisor", tags=["Consultas"])
async def rsupervisores_subalternos__endpoint(params: Params_subalternos):
    try:
        results = supervisores_subalternos(params, suso_server, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/entrevistas", description= "**Obtén** la lista de entrevistas recolectadas", tags=["Consultas"] )
async def entrevistas_endpoint(params: Params):
    try:
        results = entrevistas(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#     
@app.post("/parcelas", description= "**Obtén** la lista de parcelas recolectadas", tags=["Consultas"] )
async def parcelas_endpoint(params: Params_parcelas):
    try:
        results = parcelas(params, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.post("/cambiar_estado_entrevista" , description="**Cambia** el estado de una entrevista a Aprobado o Rechazada",tags=["Procesos"])
async def cambiar_estado_entrevista_endpoint(params: Params_estado):
    try:
        results = cambio_estado_entrevista(params, suso_server, redis_server['host'], redis_server['port'])
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.get("/registradores", description="**Obtén** la lista general de registradores", tags=["Consultas"])
async def registradores_endpoint():
    campos = ['registrador']
    try:
        results = obtener_valores_unicos(redis_server['host'], redis_server['port'], campos)
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# -----------------
#
@app.get("/supervisores", description = "**Obtén** la lista general de supervisores", tags=["Consultas"])
async def supervisores_endpoint():
    campos = ['supervisor']
    try:
        results = obtener_valores_unicos(redis_server['host'], redis_server['port'], campos)
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/estados_entrevista", description = "**Obtén** la lista de estados de entrevista", tags=["Consultas"])
async def estados_entrevista_endpoint():
    campos = ['estado_entrevista']
    try:
        results = obtener_valores_unicos(redis_server['host'], redis_server['port'], campos)
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
 
# -----------------  MAIN 
#
if __name__ == "__main__":
    import uvicorn

    with open('api/apiConfig.yaml', 'r') as file:
        config = yaml.safe_load(file)

    redis_server = config['redis_server']
    suso_server = config['suso_server']
    uvicorn_server = config['uvicorn_server']

    swagger_site = "http://" + uvicorn_server['host'] + ":" + str(uvicorn_server['port']) + "/docs"
    print(swagger_site)

    uvicorn.run(app, host=uvicorn_server['host'], port=uvicorn_server['port'])
