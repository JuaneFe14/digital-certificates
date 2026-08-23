# =============================================================================
# Dockerfile - FastAPI Application (Multi-stage Build)
# =============================================================================
# Construye una imagen optimizada para la aplicacion FastAPI.
#
# Estrategia Multi-stage:
#   Stage 1 (builder): Instala dependencias en una imagen temporal
#   Stage 2 (runtime): Copia solo las dependencias y el codigo
#
# Beneficios:
#   - Imagen final ~150MB (vs ~900MB sin multi-stage)
#   - Sin pip, compilers ni cache de build en produccion
#   - Usuario no-root para mayor seguridad
# =============================================================================

# Stage 1: Builder - Instalacion de dependencias
FROM python:3.11-slim AS builder

WORKDIR /build

# Copiar y instalar dependencias en directorio temporal
COPY docker/fastapi/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime - Imagen final minimizada
FROM python:3.11-slim

# Crear usuario sin privilegios (seguridad Docker)
# -r: usuario del sistema
# -g: grupo primario
# -d: directorio home
# -s: shell (ninguno para usuario de servicio)
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Copiar dependencias instaladas del stage builder
COPY --from=builder /install /usr/local

# Copiar codigo fuente de la aplicacion
COPY app/ /app/app/

# Asignar propiedad al usuario no-root
RUN chown -R appuser:appuser /app

# Ejecutar como usuario no-root
USER appuser

# Exponer puerto de FastAPI
EXPOSE 8000

# Comando de inicio: uvicorn con host 0.0.0.0 (accesible desde Docker)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
