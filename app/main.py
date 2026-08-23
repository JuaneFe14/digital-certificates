"""Punto de entrada de la aplicacion FastAPI.

Define los endpoints HTTP de la API y configura la instancia
de FastAPI con los servicios de certificados digitales.

Endpoints:
    GET /           - Pagina de inicio (HTML estatico)
    GET /health     - Health check del servidor (JSON)
    GET /certificate/info - Informacion del certificado instalado (JSON)
    GET /docs       - Swagger UI (documentacion interactiva)
"""

from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

from app.core.config import AppConfig
from app.models.responses import WelcomeResponse, HealthResponse
from app.services.certificate_service import CertificateService

# Configuracion centralizada
config = AppConfig()

# Instancia de FastAPI con metadatos para /docs
app = FastAPI(
    title=config.app_name,
    version=config.app_version,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Servicio de certificados (Dependency Inversion)
cert_service = CertificateService(config.cert_file)

# Directorio de templates HTML
_templates_dir = Path(__file__).parent / "templates"


@app.get("/", response_class=HTMLResponse)
async def welcome() -> HTMLResponse:
    """Sirve la pagina de inicio como HTML estatico.

    Retorna un archivo HTML con informacion del proyecto,
    estado del sistema, datos del certificado y links
    a los endpoints de la API.

    Returns:
        HTMLResponse con el contenido de index.html.
    """
    html_content = (_templates_dir / "index.html").read_text()
    return HTMLResponse(content=html_content)


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    """Endpoint de health check para monitoreo del servicio.

    Retorna el estado de salud de la aplicacion, util para
    health checks de Docker y load balancers.

    Returns:
        HealthResponse con status, nombre del servicio,
        version y estado de TLS.
    """
    return HealthResponse(
        status="healthy",
        service=config.app_name,
        version=config.app_version,
        tls_enabled=True,
    )


@app.get("/certificate/info")
async def certificate_info():
    """Endpoint que retorna los metadatos del certificado instalado.

    Ejecuta OpenSSL para leer el certificado PEM y extraer
    subject, issuer, serial, fechas y estado de validez.

    Returns:
        dict con los metadatos del certificado, o error si
        el certificado no es legible.
    """
    info = cert_service.get_certificate_info()
    if info is None:
        return {"error": "Certificate not found or could not be read"}
    return info.model_dump()
