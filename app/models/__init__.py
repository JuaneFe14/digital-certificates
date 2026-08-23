"""Modelos de respuesta Pydantic para la API.

Define los modelos de datos que estructuran las respuestas
JSON de los endpoints de la aplicacion.
"""

from app.models.responses import WelcomeResponse, HealthResponse

__all__ = ["WelcomeResponse", "HealthResponse"]
