"""Configuracion centralizada de la aplicacion.

Utiliza pydantic-settings para cargar configuraciones desde
variables de entorno con el prefijo 'APP_' o usar valores por defecto.
"""

from pydantic_settings import BaseSettings


class AppConfig(BaseSettings):
    """Configuracion principal de la aplicacion.

    Los valores pueden ser sobrescritos mediante variables de entorno
    con el prefijo 'APP_'. Por ejemplo, APP_CERT_DIR sobrescribe cert_dir.

    Attributes:
        app_name: Nombre de la aplicacion para identificacion.
        app_version: Version semantica de la aplicacion.
        cert_dir: Directorio donde se almacenan los certificados.
        cert_file: Ruta completa al archivo de certificado publico (PEM).
        key_file: Ruta completa al archivo de clave privada (PEM).
    """

    app_name: str = "DigCerts"
    app_version: str = "1.0.0"
    cert_dir: str = "/app/certs"
    cert_file: str = "/app/certs/cert.pem"
    key_file: str = "/app/certs/key.pem"

    class Config:
        """Configuracion de pydantic-settings."""

        env_prefix = "APP_"
        case_sensitive = False
