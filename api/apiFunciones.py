from requests.auth import HTTPBasicAuth
from fastapi import FastAPI, Response
from fastapi.responses import StreamingResponse 
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from typing import List, Dict
from redis import Redis
from redisearch import Client, Query, AggregateRequest, reducers
import requests
import time
import json
import re
import redis
from datetime import datetime, date
from pydantic import BaseModel, validator
from typing import Optional
import pandas as pd
import io
import csv 

class Filters(BaseModel):
    llave_entrevista_corta: List[str] = []
    fecha_entrevista: List[str] = []
    registrador: List[str] = []
    supervisor: List[str] = []
    estado_entrevista: List[str] = []

class Filters_parcela(BaseModel):
    llave_entrevista_corta: List[str] = []
    fecha_entrevista: List[str] = []
    nombre_productor: List[str] = []
    nombre_parcela: List[str] = []
    codigo_parcela_corto: List[str] = []
    registrador: List[str] = []
    supervisor: List[str] = []
    parcela_geolocalizada: List[str] = []
    regionalizacion_region: List[str] = []
    regionalizacion_zona: List[str] = []
    regionalizacion_subzona: List[str] = []
    regionalizacion_area: List[str] = []
    territorio_region: List[str] = []
    territorio_provincia: List[str] = []
    territorio_municipio: List[str] = []
    territorio_distrito: List[str] = []
    territorio_seccion: List[str] = []
    territorio_paraje: List[str] = []

class Filter_monitoreo(BaseModel):
    fecha_entrevista: List[str] = []
    registrador: List[str] = []
    registrador_cedula_corta: List[str] = []
    supervisor: List[str] = []
    get_file: str = 'No'

class Params_monitoreo(BaseModel):
    Filters: Filter_monitoreo
    itemsPerPage: int = 10
    page: int = 1

class Params(BaseModel):
    filters: Filters
    itemsPerPage: int = 10
    page: int = 1

    @validator('itemsPerPage')
    def check_codigo_itemsPerPage(cls, v):
        if v<=0:
            raise ValueError("El parámetro 'itemsPerPage' debe ser mayor a 0")
        return v
    @validator('page')
    def check_codigo_page(cls, v):
        if v<=0:
            raise ValueError("El parámetro 'page' debe ser mayor a 0")
        return v

class Params_parcelas(BaseModel):
    filters: Filters_parcela
    itemsPerPage: int = 10
    page: int = 1

    @validator('itemsPerPage')
    def check_codigo_itemsPerPage(cls, v):
        if v<=0:
            raise ValueError("El parámetro 'itemsPerPage' debe ser mayor a 0")
        return v
    @validator('page')
    def check_codigo_page(cls, v):
        if v<=0:
            raise ValueError("El parámetro 'page' debe ser mayor a 0")
        return v

class Params_estado(BaseModel):
    id_entrevista: str = ""
    llave_entrevista : str = ""
    nuevo_estado: str = ""

class Params_subalternos(BaseModel):
    usuario_consulta: str = ""

class Params_usuario(BaseModel):
    usuario: str = ""
    password: str = ""

class Params_fechas(BaseModel):
    fecha_inicial: str = ""
    fecha_final: str = ""

class Params_diviterr(BaseModel):
    region :  str = ""
    provincia :  str = ""
    municipio :  str = ""
    distrito : str = ""
    seccion :  str = ""
    paraje:  str = ""

class Params_regionalizacion(BaseModel):
    region :  str = ""
    zona :  str = ""
    subzona :  str = ""
    area : str = ""

class Monitor(BaseModel):
    UserName: str = ""
    FullName: str = ""
    Supervisors: List[str] = []

# -----------------   
#
def obtener_monitores(host: str, port: int):
        
        client = Client('idx_usuarios', host, port )
        
        offset = 0
        page_size = 1500
        query = Query('*').paging(offset, page_size)
        valores_unicos= set([])

        while True:
            resultados = client.search(query)
            
            if not resultados.docs:
                break
            
            for doc in resultados.docs:
                # Acceder a la parte JSON del documento
                json_data = json.loads(doc.__dict__.get('json', '{}'))
                user_role = json_data.get('Role', None)
                if user_role =="Monitor":
                    valores_unicos.add( json_data.get('UserName', None) )
            
            offset += page_size
            query.paging(offset, page_size)
        
        vu = list(valores_unicos)

        return vu 

# -----------------   
#
def guardar_monitor(params: Monitor, host, port):
    
    monitor= params.UserName
    json_user={}
    json_user['UserName']=params.UserName
    json_user['FullName']=params.FullName
    json_user['Role']="Monitor"
    json_user['Supervisors']=params.Supervisors
    
    try:
        redis_client = redis.Redis(host, port, decode_responses=True)
        key = "usuario:" + monitor
        redis_client.execute_command('JSON.SET', key, '.', json.dumps(json_user) )
    except redis.RedisError as e:
            print(f"Error al conectar con Redis: {e}")

    return { "STORED" }
# -----------------   
#
def elimina_monitor(monitor_id, host, port):

    try:
        redis_client = redis.Redis(host, port, decode_responses=True)
        key = "usuario:" + monitor_id
        redis_client.delete(key)
    except redis.RedisError as e:
            print(f"Error al conectar con Redis: {e}")

    return { "DELETED" }

# ----------------- 
#
def actividad(params: Params_monitoreo, host: str, port: int):
    
    def construir_resumen(documento):
        documento = json.loads(documento)
        # Llaves que queremos conservar en el nuevo documento
        llaves_interes = [
            "llave_entrevista",
            "registrador_cedula",
            "registrador", 
            "registrador_nombre",
            "registrador_cedula",
            "supervisor",
            "supervisor_nombre",
            "total_parcelas",
            "total_area",
            "creado"
        ]
        try:
            documento_corto = {llave: documento[llave] for llave in llaves_interes if llave in documento}
        except Exception as e:
            print(e)
        
        return documento_corto
    
    def convertir_a_epoch(fecha_str):
        fecha_dt = datetime.strptime(fecha_str, "%d-%m-%Y")
        fecha_date = fecha_dt.date()
        epoch = date(1970, 1, 1)
        timestamp = int((fecha_date - epoch).total_seconds())
  
        return timestamp
    
    def construye_query(params:Params_monitoreo):

        p= { 
            "registrador" : params.Filters.registrador, 
            "supervisor" : params.Filters.supervisor,
            "registrador_cedula_corta" : params.Filters.registrador_cedula_corta,
            "fecha_entrevista": params.Filters.fecha_entrevista
        }
    
        filtro_fechas=""
        filtro_entrevista=""
        query_parts = []
        for key, values in p.items():
            
            if key in ["fecha_entrevista"] :
                cadena = ""
                if len(values)>=1:  
                    values = [convertir_a_epoch(fecha) for fecha in values]
                    if len(values)==2:
                        cadena = "[" + str(values[0]) + " " + str(values[1]) + "]"
                    elif len(values)==1:
                        cadena = "[" + str(values[0]) + " " + str(values[0]) + "]"

                    if cadena!="":    
                        filtro_fechas = f'@fecha_timestamp:{cadena}'
                    else:
                        filtro_fechas = ""
        
            if key in ["registrador", "supervisor"] :
                if values:  
                    valores_sin_comillas = [f'{item}' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
            
            if key in ["registrador_cedula_corta"]:
                if values:  
                    valores_sin_comillas = [f'{item}*' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
 
        redis_query_string =""    
        if filtro_fechas!="":
            redis_query_string += filtro_fechas 

        if len(query_parts)>0:
            redis_query_string +=  " & ".join(query_parts) + " " 
            
        return redis_query_string

    print("\n")
    print(params)
    redis_query_string = construye_query(params)
    print(redis_query_string)
    print("\n")

    json_results = []

    redis_client = Redis(host, port, decode_responses=True)
    rs = Client('idx_parcela', conn=redis_client)

    # Obtiene el total de documentos que cumplen la condicion del query
    try:
        result_count = rs.search(redis_query_string)
    except Exception as e:
        print(e)

    total_documentos = result_count.total

    json_results = []
    json_results.append({"total_documentos" : total_documentos})

    redis_client.close()
    try:
        redis_client = Redis(host, port, decode_responses=True)
        rs = Client('idx_entrevista', conn=redis_client)
    except Exception as e:
        print(e)

    # Prepara la obtención del offset de datos
    items_per_page = params.itemsPerPage
    page_number = params.page

    total_paginas = (total_documentos//items_per_page)+1
    if total_paginas==1 | page_number<1:
        offset = 0 
    elif page_number>total_paginas:
        offset = (total_paginas - 1) * items_per_page
    else:
        offset = (page_number - 1) * items_per_page

    # query = Query(redis_query_string).paging(0, 1300)  
    # result = rs.search(query)
    # print(result)

    query = Query(redis_query_string).paging(offset, items_per_page)
    result = rs.search(query)

    for doc in result.docs:
        json_entrevista=doc.__dict__["json"]
        resumen = construir_resumen(json_entrevista)
        json_results.append(resumen)

    redis_client.close()

    return json_results
# ----------------- 
#
def actividad_agrupada(params: Params_monitoreo, host: str, port: int):
    
    def construir_resumen(documento):
        documento = json.loads(documento)
        # Llaves que queremos conservar en el nuevo documento
        llaves_interes = [
            "llave_entrevista",
            "registrador_cedula",
            "registrador", 
            "registrador_nombre",
            "registrador_cedula",
            "supervisor",
            "supervisor_nombre",
            "total_parcelas",
            "total_area",
            "creado"
        ]
        try:
            documento_corto = {llave: documento[llave] for llave in llaves_interes if llave in documento}
        except Exception as e:
            print(e)
        
        return documento_corto
    
    def convertir_a_epoch(fecha_str):
        fecha_dt = datetime.strptime(fecha_str, "%d-%m-%Y")
        fecha_date = fecha_dt.date()
        epoch = date(1970, 1, 1)
        timestamp = int((fecha_date - epoch).total_seconds())
  
        return timestamp
    
    def construye_query(params:Params_monitoreo):

        p= { 
            "registrador" : params.Filters.registrador, 
            "supervisor" : params.Filters.supervisor,
            "registrador_cedula_corta" : params.Filters.registrador_cedula_corta,
            "fecha_entrevista": params.Filters.fecha_entrevista
        }
    
        filtro_fechas=""
        filtro_entrevista=""
        query_parts = []
        for key, values in p.items():
            
            if key in ["fecha_entrevista"] :
                cadena = ""
                if len(values)>=1:  
                    values = [convertir_a_epoch(fecha) for fecha in values]
                    if len(values)==2:
                        cadena = "[" + str(values[0]) + " " + str(values[1]) + "]"
                    elif len(values)==1:
                        cadena = "[" + str(values[0]) + " " + str(values[0]) + "]"

                    if cadena!="":    
                        filtro_fechas = f'@fecha_timestamp:{cadena}'
                    else:
                        filtro_fechas = ""
        
            if key in ["registrador", "supervisor"] :
                if values:  
                    valores_sin_comillas = [f'{item}' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
            
            if key in ["registrador_cedula_corta"]:
                if values:  
                    valores_sin_comillas = [f'{item}*' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
 
        redis_query_string =""    
        if filtro_fechas!="":
            redis_query_string += filtro_fechas 

        if len(query_parts)>0:
            redis_query_string +=  " & ".join(query_parts) 
            
        return redis_query_string
    
    def convertir_lista_a_dict(lista):
        # Verifica que la lista tenga una longitud par
        if len(lista) % 2 != 0:
            raise ValueError("La lista debe tener una longitud par")

        # Crea un diccionario a partir de la lista
        diccionario = {}
        for i in range(0, len(lista), 2):
            clave = lista[i]
            valor = lista[i + 1]
            diccionario[clave] = valor

        return diccionario

    print("\n")
    print(params)
    redis_query_string = construye_query(params)
    print(redis_query_string)
    print("\n")

    json_results = []

    try:
        redis_client = Redis(host, port, decode_responses=True)
        result = redis_client.execute_command('FT.AGGREGATE', 'idx_parcela', "'"+ redis_query_string + "'", 
                           'GROUPBY', '5', '@registrador_cedula_corta', '@registrador', '@registrador_nombre', 
                           '@supervisor', '@supervisor_nombre', 
                           'REDUCE', 'COUNT', '0', 'AS', 'total_parcelas', 
                           'REDUCE', 'SUM', '1', '@area_parcela', 'AS', 'suma_areas')
 
        total_documentos = len(result)-1
        
        if total_documentos>=1:
            for item in result[1:]:
                obj = convertir_lista_a_dict(item)
                #print(obj)
                json_results.append(obj)
    except Exception as e:
        print(e)

    return json_results

    # # if params.Filters.get_file.upper()=="YES":
    # #     try:
    # #         # Crear un archivo CSV en memoria
    # #         output = io.StringIO()
    # #         fieldnames = ["registrador_cedula_corta", "registrador", "registrador_nombre", "supervisor", "supervisor_nombre", "total_parcelas", "suma_areas"]
    # #         csv_writer = csv.DictWriter(output, fieldnames=fieldnames)
    # #         csv_writer.writeheader()
            
    # #         # Recolectar los resultados del generador asíncrono
    # #         results = []
    # #         async for result in json_results:
    # #             results.append(result)
    # #         csv_writer.writerows(results)
    # #         # Regresar al inicio del archivo para que se lea desde el principio
    # #         output.seek(0)
    # #         # Crear una respuesta de streaming para la descarga del archivo
    # #         response = StreamingResponse(output, media_type="text/csv")
    # #         response.headers["Content-Disposition"] = "attachment; filename=datos.csv"
    # #         return response
    # #         # Crear un archivo CSV en memoria
    # #         # output = io.StringIO()
    # #         # fieldnames = ["registrador_cedula_corta", "registrador", "registrador_nombre", "supervisor", "supervisor_nombre", "total_parcelas", "suma_areas"]
    # #         # csv_writer = csv.DictWriter(output, fieldnames=fieldnames)
    # #         # csv_writer.writeheader()
    # #         # csv_writer.writerows(json_results)

    # #         # # Regresar al inicio del archivo para que se lea desde el principio
    # #         # output.seek(0)
        
    # #         # # Crear una respuesta de streaming para la descarga del archivo
    # #         # response = StreamingResponse(output, media_type="text/csv")
    # #         # response.headers["Content-Disposition"] = "attachment; filename=datos.csv"
    # #         # return response
    
    # #         #  # Configurar la respuesta HTTP
    # #         # response = Response(content=output.getvalue())
    # #         # response.headers["Content-Disposition"] = "attachment; filename=datos.csv"
    # #         # response.headers["Content-Type"] = "text/csv"
    # #         # return response
    #     except Exception as e:
    #         print(e)
    #else:

    
# -----------------   
#
def regionalizacion(params: Params_regionalizacion, host: str, port: int):

    busqueda = { "region" : params.region , 
            "zona" : params.zona, 
            "subzona": params.subzona,
            "area": params.area,
    }
    
    def encontrar_elemento_por_nombre(lista, nombre):
        for elemento in lista:
            if elemento['nombre'] == nombre:
                return elemento
        return None

    documento ={}

    try:
        redis_client = redis.Redis(host, port, decode_responses=True)
        catalogo = "catalogo:regionalizacion"
        json_data = redis_client.execute_command('JSON.GET', catalogo)
        if json_data:
            documento = json.loads(json_data)
    except redis.RedisError as e:
        print(f"Error al conectar con Redis: {e}")

    if documento=={}:
        return { 'ERROR' : 'Catalogo de regonalización del MA no existe' } 
    
    elementos = []

    try: 
        if busqueda["region"] == "":
            # Devuelve lista de regiones
            elementos = [region['nombre'] for region in documento]
        else:
            region = encontrar_elemento_por_nombre(documento, busqueda["region"])
            if region:
                if busqueda["zona"] == "":
                    # Devuelve lista de provincias de la región indicada
                    elementos = [zona['nombre'] for zona in region['zonas']]
                else:
                    zona = encontrar_elemento_por_nombre(region['zonas'], busqueda["zona"])
                    if zona:
                        if busqueda["subzona"] == "":
                            # Devuelve lista de municipios según la provincia indicada
                            elementos = [subzona['nombre'] for subzona in zona['subzonas']]
                        else:
                            subzona = encontrar_elemento_por_nombre(zona['subzonas'], busqueda["subzona"])
                            if subzona:
                                if busqueda["area"] == "":
                                    # Devuelve lista de distritos del municipio indicado
                                    elementos = [area['nombre'] for area in subzona['areas']]
    except Exception as e:
        print(e)


    return elementos

# -----------------  
#
def division_territorial(params: Params_diviterr, host: str, port: int):

    def encontrar_elemento_por_nombre(lista, nombre):
        for elemento in lista:
            if elemento['nombre'] == nombre:
                return elemento
        return None
    
    busqueda = { "region" : params.region , 
            "provincia" : params.provincia, 
            "municipio": params.municipio,
            "distrito": params.distrito,
            "seccion": params.seccion,
            "paraje" : params.paraje}
    
    documento ={}

    try:
        redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
        catalogo = "catalogo:territorio"
        json_data = redis_client.execute_command('JSON.GET', catalogo)
        if json_data:
            documento = json.loads(json_data)
    except redis.RedisError as e:
        print(f"Error al conectar con Redis: {e}")

    if documento=={}:
        return { 'ERROR' : 'Catalogo de division territorial no existe' } 
    
    elementos = []

    try:
        if busqueda["region"] == "":
            # Devuelve lista de regiones
            elementos = [region['nombre'] for region in documento]
        else:
            region = encontrar_elemento_por_nombre(documento, busqueda["region"])
            if region:
                if busqueda["provincia"] == "":
                    # Devuelve lista de provincias de la región indicada
                    elementos = [provincia['nombre'] for provincia in region['provincias']]
                else:
                    provincia = encontrar_elemento_por_nombre(region['provincias'], busqueda["provincia"])
                    if provincia:
                        if busqueda["municipio"] == "":
                            # Devuelve lista de municipios según la provincia indicada
                            elementos = [municipio['nombre'] for municipio in provincia['municipios']]
                        else:
                            municipio = encontrar_elemento_por_nombre(provincia['municipios'], busqueda["municipio"])
                            if municipio:
                                if busqueda["distrito"] == "":
                                    # Devuelve lista de distritos del municipio indicado
                                    elementos = [distrito['nombre'] for distrito in municipio['distritos']]
                                else:
                                    distrito = encontrar_elemento_por_nombre(municipio['distritos'], busqueda["distrito"])
                                    if distrito:
                                        if busqueda["seccion"] == "":
                                            # Devuelve lista de secciones del distrito indicado
                                            elementos = [seccion['nombre'] for seccion in distrito['secciones']]
                                        else:
                                            seccion = encontrar_elemento_por_nombre(distrito['secciones'], busqueda["seccion"])
                                            if seccion:
                                                if busqueda["paraje"] == "":
                                                    # Devuelve lista de parajes de la sección indicada
                                                    elementos = [paraje['nombre'] for paraje in seccion['parajes']]
    except Exception as e:
        print(e)

    return elementos

# -----------------   
#
def entrevistas(params: Params, host: str, port: int):
    
    def construir_resumen(documento):
        documento = json.loads(documento)
        # Llaves que queremos conservar en el nuevo documento
        llaves_interes = [
            "id_entrevista",
            "llave_entrevista",
            "fecha_entrevista",
            "registrador", 
            "registrador_nombre",
            "supervisor",
            "supervisor_nombre",
            "problemas",
            "estado_entrevista",
            "url_entrevista",
            "cuestionario",
            "creado"
        ]
        try:
            documento_corto = {llave: documento[llave] for llave in llaves_interes if llave in documento}
        except Exception as e:
            print(e)
        
        return documento_corto
    
    def convertir_a_epoch(fecha_str):
        fecha_dt = datetime.strptime(fecha_str, "%d-%m-%Y")
        fecha_date = fecha_dt.date()
        epoch = date(1970, 1, 1)
        timestamp = int((fecha_date - epoch).total_seconds())

        return timestamp
    
    def construye_query(params):
        filters = params.filters
        filtro_fechas=""
        filtro_entrevista=""
        query_parts = []
        for key, values in filters.dict().items():
            
            if key in ["fecha_entrevista"] :
                cadena=""
                if len(values)>=1:  
                    values = [convertir_a_epoch(fecha) for fecha in values]
                    if len(values)==2:
                        cadena = "[" + str(values[0]) + " " + str(values[1]) + "]"
                    elif len(values)==1:
                        cadena = "[" + str(values[0]) + " " + str(values[0]) + "]"

                    if cadena!="":    
                        filtro_fechas = f' @fecha_timestamp:{cadena} '
                    else:
                        filtro_fechas = ""

            # if key in ["llave_entrevista"] :
            #     if len(values)>=1:  
            #         llave = values[0]
            #         llave_escape = re.sub(r"-", r"\\-", llave)
            #         filtro_entrevista = f'@{key}:' + "{" + llave_escape + "*}"

            if key in ["registrador", "supervisor", "estado_entrevista"] :
                if values:  
                    valores_sin_comillas = [f'{item}' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
            
            if key in ["llave_entrevista_corta"]:
                if values:  
                    valores_sin_comillas = [f'{item}*' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
 
        redis_query_string =""    
        if filtro_fechas!="":
            redis_query_string += filtro_fechas 

        if len(query_parts)>0:
            redis_query_string +=  " & ".join(query_parts) + " "      
        
        return redis_query_string

    print("\n")
    print(params,"\n")
    redis_query_string = construye_query(params)
    print(redis_query_string)
    print("\n")

    redis_client = Redis(host, port, decode_responses=True)
    rs = Client('idx_entrevista', conn=redis_client)
    
    # Obtiene el total de documentos que cumplen la condicion del query
    try:
        result_count = rs.search(redis_query_string)
    except Exception as e:
        print(e)

    total_documentos = result_count.total

    json_results = []
    json_results.append({"total_documentos" : total_documentos})

    redis_client.close()
    try:
        redis_client = Redis(host, port, decode_responses=True)
        rs = Client('idx_entrevista', conn=redis_client)
    except Exception as e:
        print(e)

    # Prepara la obtención del offset de datos
    items_per_page = params.itemsPerPage
    page_number = params.page

    total_paginas = (total_documentos//items_per_page)+1
    if total_paginas==1 | page_number<1:
        offset = 0 
    elif page_number>total_paginas:
        offset = (total_paginas - 1) * items_per_page
    else:
        offset = (page_number - 1) * items_per_page

    query = Query(redis_query_string).paging(offset, items_per_page)
    result = rs.search(query)

    for doc in result.docs:
        json_entrevista=doc.__dict__["json"]
        resumen = construir_resumen(json_entrevista)
        json_results.append(resumen)

    redis_client.close()

    return json_results
# -----------------   
#
def parcelas(params: Params_parcelas, host: str, port: int):
    
    def construir_resumen(documento):
        documento = json.loads(documento)
        # Llaves que queremos conservar en el nuevo documento
        llaves_interes = [
            "llave_entrevista",
            "fecha_entrevista",
            "nombre_productor",
            "coordenadas_entrevista",
            "nombre_parcela",
            "codigo_parcela",
            "regionalizacion",
            "territorio",
            "supervisor",
            "supervisor_nombre",
            "registrador", 
            "registrador_nombre",
            "estado_parcela",
            "area_parcela",
            "cuestionario",
            "coordenadas_parcela",
            "parcela_geolocalizda",
            "tipo_captura_coordenadas",
            "creado"
        ]

        try:
            documento_corto = {llave: documento[llave] for llave in llaves_interes if llave in documento}
        except Exception as e:
            print(e)
        
        return documento_corto
    
    def convertir_a_epoch(fecha_str):
        fecha_dt = datetime.strptime(fecha_str, "%d-%m-%Y")
        fecha_date = fecha_dt.date()
        epoch = date(1970, 1, 1)
        timestamp = int((fecha_date - epoch).total_seconds())

        return timestamp
    
    def construye_query(params):
        filters = params.filters
        filtro_fechas=""
        filtro_entrevista=""
        query_parts = []
        for key, values in filters.dict().items():

            if key in ["fecha_entrevista"] :
                cadena=""
                if len(values)>=1:  
                    values = [convertir_a_epoch(fecha) for fecha in values]
                    if len(values)==2:
                        cadena = "[" + str(values[0]) + " " + str(values[1]) + "]"
                    elif len(values)==1:
                        cadena = "[" + str(values[0]) + " " + str(values[0]) + "]"

                    if cadena!="":    
                        filtro_fechas = f' @fecha_timestamp:{cadena} '
                    else:
                        filtro_fechas = ""

            if key in ["registrador", "supervisor", "parcela_geolocalizada"] :
                if values:  
                    valores_sin_comillas = [f'{item}' for item in values]
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")

            if key in ["llave_entrevista_corta", "codigo_parcela_corto", 
                       "nombre_parcela", "nombre_productor"] :
                if values:  
                    valores_sin_comillas = [f'{item}*' for item in values] 
                    filtro_otros = "|".join(valores_sin_comillas)
                    query_parts.append(f"@{key}:({filtro_otros})")
            
            reg = [ "regionalizacion_region", "regionalizacion_zona", "regionalizacion_subzona", "regionalizacion_area", ] 
            if key in reg:
                for i in range(3, -1, -1):
                    if key==reg[i]:
                        if values: 
                            query_parts.append(f"@{key}:({values[0]})")
                            break
                        
                # if values:  
                #     valores_sin_comillas = [f'{item}' for item in values] 
                #     print(valores_sin_comillas)
                #     filtro_otros = "|".join(valores_sin_comillas)
                #     query_parts.append(f"@{key}:({filtro_otros})")

            ter = [ "territorio_region", "territorio_provincia", "territorio_municipio", "territorio_distrito" , "territorio_seccion", "territorio_paraje"  ] 
            if key in ter:
                for i in range(5, -1, -1):
                    if key==ter[i]:
                        if values: 
                            query_parts.append(f"@{key}:({values[0]})")
                            break
                # if values:  
                #     valores_sin_comillas = [f'{item}' for item in values] 
                #     print(valores_sin_comillas)
                #     filtro_otros = "|".join(valores_sin_comillas)
                #     query_parts.append(f"@{key}:({filtro_otros})")
 
        redis_query_string =""    
        if filtro_fechas!="":
            redis_query_string += filtro_fechas 

        if len(query_parts)>0 :
            redis_query_string += " & ".join(query_parts) + " "      
    
        return redis_query_string

    print("\n")
    print(params,"\n")
    redis_query_string = construye_query(params)
    print(redis_query_string)
    print("\n")

    redis_client = Redis(host, port, decode_responses=True)
    rs = Client('idx_parcela', conn=redis_client)
    
    # Obtiene el total de documentos que cumplen la condicion del query
    result_count = rs.search(redis_query_string)
    total_documentos = result_count.total

    json_results = []
    json_results.append({"total_documentos" : total_documentos})

    redis_client.close()

    redis_client = Redis(host, port, decode_responses=True)
    rs = Client('idx_parcela', conn=redis_client)

    # Prepara la obtención del offset de datos
    items_per_page = params.itemsPerPage
    page_number = params.page

    total_paginas = (total_documentos//items_per_page)+1
    if total_paginas==1 | page_number<1:
        offset = 0 
    elif page_number>total_paginas:
        offset = (total_paginas - 1) * items_per_page
    else:
        offset = (page_number - 1) * items_per_page

    query = Query(redis_query_string).paging(offset, items_per_page)
    result = rs.search(query)

    for doc in result.docs:
        json_entrevista=doc.__dict__["json"]
        resumen = construir_resumen(json_entrevista)
        json_results.append(resumen)

    redis_client.close()

    return json_results


# -----------------   
#
def usuario (params: Params_usuario, suso_server, host: str, port: int ):
    usuario_buscado = params.usuario

    user_auth = HTTPBasicAuth(suso_server['api-user'],suso_server['api-password'])
    api_endpoint = suso_server["server-url"] +"users/" + usuario_buscado
    response = requests.get(api_endpoint, auth=user_auth )

    if response.status_code==200:
        json_user = response.json()
        fecha_actual = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
        json_user["LastLogin"] = fecha_actual
        
        try:
            redis_client = redis.Redis(host, port, decode_responses=True)
            key = "usuario:" + usuario_buscado
            redis_client.execute_command('JSON.SET', key, '.', json.dumps(json_user) )
        except redis.RedisError as e:
            print(f"Error al conectar con Redis: {e}")
    
        return json_user
    else:
        return { "ERROR": "Usuario no encontrado" }   
# -----------------   
#
def registradores_subalternos(params: Params_subalternos, suso_server, host, port ):
    usuario_consulta = params.usuario_consulta

    def registradores_supervisor(usuario_consulta):

        redis_client = Redis(host, port, decode_responses=True)
        rs = Client('idx_entrevista', conn=redis_client)
        redis_query_string = Query(f"@supervisor:{usuario_consulta}").return_field("registrador").paging(0, 1000)
        resultados = rs.search(redis_query_string)
        registradores = {doc.registrador for doc in resultados.docs}
        redis_client.close
    
        return registradores
   
    usuario_data = {}
    registradores = {}
    # Buscar Role de usuario_contulta
    usuario_data = buscar_usuario_REDIS( host, port, usuario_consulta)
    if usuario_data=={}:
        usuario_data = buscar_usuario_SUSO(suso_server,usuario_consulta)
    if usuario_data=={}:
        return { "registradores" : {} }
    usuario_role = usuario_data["Role"]

    # Si el usuario es de tipo Interviewer
    
    if usuario_role=="Interviewer":
        return { "registrador" : {usuario_consulta} }

    # Busqueda de registradores por Headquarter
    if usuario_role=="Headquarter":  
        res = obtener_valores_unicos(host, port, ["registrador"])
        return res
    
    # Busqueda de registradores por Monitor
    if usuario_role=="Monitor":  
        supervidores =  usuario_data["Supervisors"]
        
        registradores_totales = set([])
        for sup in supervidores:
            registradores=registradores_supervisor(sup)
            registradores_totales.update(registradores)
        
        rt=list(registradores_totales)
        return rt 

    # Busqueda de registradores por Supervisor
    if usuario_role=="Supervisor":  
        registradores=registradores_supervisor(usuario_consulta)
        return { "registrador" : registradores }

# -----------------  
# 
def supervisores_subalternos( params: Params_subalternos, suso_server, host: str, port: int):  
    usuario_consulta = params.usuario_consulta

    usuario_data = {}
    # Buscar Role de usuario_contulta
    usuario_data = buscar_usuario_REDIS( host, port, usuario_consulta)
    if usuario_data=={}:
        usuario_data = buscar_usuario_SUSO(suso_server,usuario_consulta)
    if usuario_data=={}:
        return { }
    usuario_role = usuario_data["Role"]

    # Busqueda de registradores por Headquarter
    if usuario_role=="Headquarter":  
        res = obtener_valores_unicos(host, port, ["supervisor"])
        return res
    
    # Busqueda de registradores por Monitor
    if usuario_role=="Monitor":  
        
        return usuario_data["Supervisors"]

# -----------------   
#
def buscar_usuario_SUSO(suso_server,usuario_buscado):

    user_auth = HTTPBasicAuth(suso_server['api-user'],suso_server['api-password'])
    api_endpoint = suso_server["server-url"] +"users/" + usuario_buscado
    response = requests.get(api_endpoint, auth=user_auth )

    if response.status_code==200:
        json_user = response.json()
 
        return json_user
    else:
        return {  }
# -----------------   
#    
def buscar_usuario_REDIS( host: str, port: int, usuario_buscado):

    redis_client = redis.Redis(host, port, decode_responses=True)
    contenido = redis_client.execute_command('JSON.GET', 'usuario:'+usuario_buscado)
    if contenido is not None:
        data = json.loads(contenido)
    else:
        data={}

    return data
    
# -----------------   
#
def obtener_valores_unicos(host: str, port: int, campos):
        valores_unicos = {campo: set() for campo in campos}
        
        client = Client('idx_entrevista', host, port )
        
        offset = 0
        page_size = 1500
        query = Query('*').paging(offset, page_size)
        
        while True:
            resultados = client.search(query)
            
            if not resultados.docs:
                break
            
            for doc in resultados.docs:
                # Acceder a la parte JSON del documento
                json_data = json.loads(doc.__dict__.get('json', '{}'))
                for campo in campos:
                    # Acceder al valor del campo en el JSON anidado
                    valor = json_data.get(campo, None)
                    if valor is not None:
                        valores_unicos[campo].add(valor)
                    else:
                        print(f'Campo {campo} no encontrado en el documento')
            
            offset += page_size
            query.paging(offset, page_size)
        
        return {campo: list(valores) for campo, valores in valores_unicos.items()}

# -----------------  
# 
def cambio_estado_entrevista(params : Params_estado, suso_server, host: str, port: int, ):
    id_entrevista = params.id_entrevista
    llave_entrevista = params.llave_entrevista
    nuevo_estado = params.nuevo_estado

    if nuevo_estado == "ApprovedBySupervisor":
        api_endpoint = suso_server["server-url"] + id_entrevista +"/approve"
    elif nuevo_estado == "RejectedBySupervisor":
        api_endpoint = suso_server["server-url"] + id_entrevista +"/reject"
    user_auth = HTTPBasicAuth(suso_server['api-user'],suso_server['api-password'])
    response = requests.get(api_endpoint, auth=user_auth )

    if response.status_code!=200:
        return { "ERROR": "ERROR CODE "+ str(response.status_code) }
    elif response.status_code==200:
        redis_client = Redis(host, port, decode_responses=True)
        contenido = redis_client.execute_command('JSON.GET', 'entrevista:'+llave_entrevista)
        data = json.loads(contenido)
        if data is not None:
            if data["llave-entrevista"] == llave_entrevista: 
                data["estado-entrevista"] = nuevo_estado
            res= json.dumps(data) 
            redis_client.execute_command('JSON.SET', f'entrevista:{llave_entrevista}', '.', res )

        return response.json()
        
# -----------------  

