"""Modelos de respuesta Pydantic para la API REST.

Cada modelo define la estructura JSON de una respuesta especifica,
garantizando validacion automatica y documentacion en /docs.
"""

from pydantic import BaseModel


class WelcomeResponse(BaseModel):
    """Modelo de respuesta para el endpoint de bienvenida.

    Attributes:
        message: Mensaje descriptivo del proposito de la aplicacion.
        status: Estado actual de la aplicacion (activo/inactivo).
        protocol: Protocolo de comunicacion utilizado (HTTPS).
        endpoints: Lista de endpoints disponibles en la API.
    """

    message: str
    status: str
    protocol: str
    endpoints: list[str]


class HealthResponse(BaseModel):
    """Modelo de respuesta para el endpoint de health check.

    Attributes:
        status: Estado de salud del servicio (healthy/unhealthy).
        service: Nombre del servicio verificado.
        version: Version del servicio en formato semantico.
        tls_enabled: Indica si TLS esta habilitado en la conexion.
    """

    status: str
    service: str
    version: str
    tls_enabled: bool
