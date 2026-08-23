#!/bin/bash
# =============================================================================
# generate-certs.sh
# =============================================================================
# Genera un certificado digital auto-firmado X.509 con OpenSSL.
#
# Utiliza Curva Eliptica (EC) con prime256v1 para mayor seguridad
# y eficiencia comparado con RSA. El certificado es auto-firmado
# (self-signed), ideal para desarrollo y demostraciones academicas.
#
# Uso:
#   ./scripts/generate-certs.sh
#
# Salida:
#   - certs/cert.pem  (certificado publico, chmod 644)
#   - certs/key.pem   (clave privada, chmod 600)
#
# Nota: El script detecta si corre dentro de Docker (/app escribible)
#       o en el host (usa ruta relativa ./certs).
# =============================================================================

set -e

# Detectar directorio del script para rutas relativas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detectar entorno: Docker (con /app) o host local
if [ -d "/app" ] && [ -w "/app" ]; then
    CERT_DIR="/app/certs"
else
    CERT_DIR="${SCRIPT_DIR}/../certs"
fi

CERT_FILE="${CERT_DIR}/cert.pem"
KEY_FILE="${CERT_DIR}/key.pem"

# Crear directorio de certificados si no existe
mkdir -p "${CERT_DIR}"

# Saltar generacion si los certificados ya existen
if [ -f "${CERT_FILE}" ] && [ -f "${KEY_FILE}" ]; then
    echo "[INFO] Certificados ya existen. Saltando generacion."
    exit 0
fi

echo "[INFO] Generando certificado auto-firmado con OpenSSL..."

# Generar certificado X.509 auto-firmado con Curva Eliptica
# -x509:         Crea certificado auto-firmado (no CSR)
# -newkey ec:    Genera clave de Curva Eliptica (mas segura que RSA)
# -pkeyopt:      Parametro de curva prime256v1 (NIST P-256)
# -keyout:       Archivo de clave privada de salida
# -out:          Archivo de certificado publico de salida
# -days 365:     Validez de 1 ano (365 dias)
# -nodes:        Sin password en la clave privada (para Nginx)
# -subj:         Datos del sujeto en formato DN
#   C=US:         Pais (Country)
#   ST=Development: Estado (State)
#   L=Local:      Ciudad (Locality)
#   O=DigitalCertificates: Organizacion
#   CN=localhost:  Common Name (nombre del servidor)
# -addext:       Extensiones adicionales (SAN)
#   DNS:localhost:   Nombre de dominio valido
#   IP:127.0.0.1:   Direccion IP valida
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -days 365 -nodes \
    -subj "/C=US/ST=Development/L=Local/O=DigitalCertificates/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Establecer permisos de seguridad
# 600: Solo el propietario puede leer/escribir (clave privada)
# 644: Todos pueden leer (certificado publico)
chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"

echo "[INFO] Certificado generado exitosamente:"
echo "  - ${CERT_FILE}"
echo "  - ${KEY_FILE}"
