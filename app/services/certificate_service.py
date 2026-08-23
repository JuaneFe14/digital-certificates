"""Servicio de lectura y validacion de certificados digitales X.509.

Este modulo proporciona CertificateService, una clase que ejecuta
comandos OpenSSL para extraer metadatos de certificados y validar
su vigencia temporal.

El servicio utiliza subprocess para ejecutar 'openssl x509' y
expresiones regulares para parsear la salida, siguiendo el patron
de Dependency Inversion (SOLID).
"""

import subprocess
import re
from datetime import datetime
from pathlib import Path
from typing import Optional

from pydantic import BaseModel


class CertificateInfo(BaseModel):
    """Modelo de datos que representa la informacion de un certificado X.509.

    Attributes:
        subject: Sujeto del certificado (propietario). Formato DN.
        issuer: Emisor del certificado. Auto-firmado si subject == issuer.
        serial_number: Numero de serie unico en formato hexadecimal.
        not_before: Fecha de inicio de validez en formato ISO 8601.
        not_after: Fecha de expiracion en formato ISO 8601.
        is_valid: True si la fecha actual esta dentro del periodo de validez.
        file_path: Ruta del archivo PEM del certificado.
    """

    subject: str
    issuer: str
    serial_number: str
    not_before: str
    not_after: str
    is_valid: bool
    file_path: str


class CertificateService:
    """Servicio para leer y validar certificados digitales.

    Ejecuta comandos OpenSSL para extraer metadatos de un archivo
    certificado PEM y valida si se encuentra dentro de su periodo
    de vigencia.

    Attributes:
        _cert_path: Ruta al archivo de certificado PEM.
    """

    def __init__(self, cert_path: str) -> None:
        """Inicializa el servicio con la ruta al certificado.

        Args:
            cert_path: Ruta absoluta al archivo cert.pem.
        """
        self._cert_path = Path(cert_path)

    def get_certificate_info(self) -> Optional[CertificateInfo]:
        """Obtiene la informacion completa del certificado.

        Ejecuta 'openssl x509' para extraer subject, issuer, serial
        y fechas. Valida la vigencia comparando fechas con datetime.now().

        Returns:
            CertificateInfo con los metadatos del certificado,
            o None si el archivo no existe o OpenSSL falla.

        Raises:
            subprocess.TimeoutExpired: Si OpenSSL tarda mas de 10 segundos.
            FileNotFoundError: Si el binario openssl no esta disponible.
        """
        if not self._cert_path.exists():
            return None

        try:
            result = subprocess.run(
                [
                    "openssl", "x509",
                    "-in", str(self._cert_path),
                    "-noout",
                    "-subject", "-issuer", "-serial",
                    "-dates", "-text",
                ],
                capture_output=True,
                text=True,
                timeout=10,
            )

            if result.returncode != 0:
                return None

            output = result.stdout
            not_before = self._parse_date(self._extract_field(output, r"notBefore\s*=\s*(.+)"))
            not_after = self._parse_date(self._extract_field(output, r"notAfter\s*=\s*(.+)"))
            return CertificateInfo(
                subject=self._extract_field(output, r"subject\s*=\s*(.+)"),
                issuer=self._extract_field(output, r"issuer\s*=\s*(.+)"),
                serial_number=self._extract_field(output, r"serial\s*=\s*(.+)"),
                not_before=not_before,
                not_after=not_after,
                is_valid=self._check_validity(not_before, not_after),
                file_path=str(self._cert_path),
            )
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return None

    def _extract_field(self, text: str, pattern: str) -> str:
        """Extrae un campo del output de OpenSSL usando regex.

        Args:
            text: Texto completo de la salida de openssl x509.
            pattern: Expresion regular con un grupo de captura (.*).

        Returns:
            Valor capturado limpiado de espacios, o "N/A" si no se encuentra.
        """
        match = re.search(pattern, text)
        return match.group(1).strip() if match else "N/A"

    def _parse_date(self, date_str: str) -> str:
        """Convierte formato de fecha OpenSSL a ISO 8601.

        OpenSSL retorna fechas como 'Aug 23 21:37:08 2026 GMT'.
        Este metodo las convierte a '2026-08-23T21:37:08'.

        Args:
            date_str: Fecha en formato OpenSSL (%b %d %H:%M:%S %Y %Z).

        Returns:
            Fecha en formato ISO 8601, o el string original si falla.
        """
        try:
            dt = datetime.strptime(date_str, "%b %d %H:%M:%S %Y %Z")
            return dt.isoformat()
        except (ValueError, TypeError):
            return date_str

    def _check_validity(self, not_before: str, not_after: str) -> bool:
        """Valida si el certificado esta vigente.

        Compara la fecha actual con el periodo de validez
        del certificado (not_before <= now <= not_after).

        Args:
            not_before: Fecha de inicio en formato ISO 8601.
            not_after: Fecha de expiracion en formato ISO 8601.

        Returns:
            True si la fecha actual esta dentro del periodo valido,
            False si esta expirado, aun no inicia, o las fechas son invalidas.
        """
        now = datetime.now()
        try:
            start = datetime.fromisoformat(not_before)
            end = datetime.fromisoformat(not_after)
            return start <= now <= end
        except (ValueError, TypeError):
            return False
