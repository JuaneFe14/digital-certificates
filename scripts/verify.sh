#!/bin/bash
# =============================================================================
# verify.sh — Script de Verificación Automatizada HTTPS
# =============================================================================
# Ejecuta una batería de pruebas para verificar que la aplicación
# funciona correctamente bajo HTTPS con el certificado auto-firmado.
#
# Uso:
#   ./scripts/verify.sh
#
# Salida:
#   [PASS] — Prueba exitosa
#   [FAIL] — Prueba fallida
# =============================================================================

set -e

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL + 1))
}

info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

echo "============================================="
echo " Verificación de Certificados Digitales SSL/TLS"
echo "============================================="
echo ""

# =============================================================================
# 1. Verificar que los certificados existen
# =============================================================================
info "Verificando certificados..."

if [ -f "certs/cert.pem" ]; then
    pass "cert.pem existe"
else
    fail "cert.pem no encontrado"
fi

if [ -f "certs/key.pem" ]; then
    pass "key.pem existe"
else
    fail "key.pem no encontrado"
fi

# =============================================================================
# 2. Verificar permisos de la clave privada
# =============================================================================
info "Verificando permisos de archivos..."

KEY_PERMS=$(stat -c %a certs/key.pem 2>/dev/null || stat -f %Lp certs/key.pem 2>/dev/null)
if [ "$KEY_PERMS" = "600" ]; then
    pass "key.pem tiene permisos 600 (seguro)"
else
    fail "key.pem tiene permisos $KEY_PERMS (debe ser 600)"
fi

CERT_PERMS=$(stat -c %a certs/cert.pem 2>/dev/null || stat -f %Lp certs/cert.pem 2>/dev/null)
if [ "$CERT_PERMS" = "644" ]; then
    pass "cert.pem tiene permisos 644"
else
    fail "cert.pem tiene permisos $CERT_PERMS (debe ser 644)"
fi

# =============================================================================
# 3. Verificar que OpenSSL puede leer el certificado
# =============================================================================
info "Verificando certificado con OpenSSL..."

if openssl x509 -in certs/cert.pem -noout -text > /dev/null 2>&1; then
    pass "OpenSSL puede leer cert.pem"
else
    fail "OpenSSL no puede leer cert.pem"
fi

# Verificar que el certificado es auto-firmado
SUBJECT=$(openssl x509 -in certs/cert.pem -noout -subject 2>/dev/null | sed 's/subject=//')
ISSUER=$(openssl x509 -in certs/cert.pem -noout -issuer 2>/dev/null | sed 's/issuer=//')

if [ "$SUBJECT" = "$ISSUER" ]; then
    pass "Certificado auto-firmado (subject == issuer)"
else
    fail "Certificado NO auto-firmado"
fi

# Verificar SAN
SAN=$(openssl x509 -in certs/cert.pem -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1)
if echo "$SAN" | grep -q "DNS:localhost"; then
    pass "SAN incluye DNS:localhost"
else
    fail "SAN no incluye DNS:localhost"
fi

# Verificar fechas
NOT_BEFORE=$(openssl x509 -in certs/cert.pem -noout -startdate 2>/dev/null | cut -d= -f2)
NOT_AFTER=$(openssl x509 -in certs/cert.pem -noout -enddate 2>/dev/null | cut -d= -f2)
info "Vigencia: $NOT_BEFORE → $NOT_AFTER"

# =============================================================================
# 4. Verificar que los contenedores Docker están corriendo
# =============================================================================
info "Verificando contenedores Docker..."

if docker compose ps --format json 2>/dev/null | grep -q '"fastapi-app"'; then
    pass "Contenedor fastapi-app está corriendo"
else
    fail "Contenedor fastapi-app NO está corriendo"
fi

if docker compose ps --format json 2>/dev/null | grep -q '"nginx-proxy"'; then
    pass "Contenedor nginx-proxy está corriendo"
else
    fail "Contenedor nginx-proxy NO está corriendo"
fi

# =============================================================================
# 5. Verificar endpoints HTTPS
# =============================================================================
info "Verificando endpoints HTTPS..."

# Health check
HEALTH=$(curl -k -s https://localhost/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    pass "GET /health → 200 OK (healthy)"
else
    fail "GET /health no retorna healthy"
fi

# Certificate info
CERT_INFO=$(curl -k -s https://localhost/certificate/info 2>/dev/null)
if echo "$CERT_INFO" | grep -q '"is_valid":true'; then
    pass "GET /certificate/info → is_valid: true"
else
    fail "GET /certificate/info → is_valid no es true"
fi

# Landing page
STATUS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost/ 2>/dev/null)
if [ "$STATUS_CODE" = "200" ]; then
    pass "GET / → 200 OK (HTML)"
else
    fail "GET / → HTTP $STATUS_CODE"
fi

# Swagger UI
DOCS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost/docs 2>/dev/null)
if [ "$DOCS_CODE" = "200" ]; then
    pass "GET /docs → 200 OK (Swagger UI)"
else
    fail "GET /docs → HTTP $DOCS_CODE"
fi

# =============================================================================
# 6. Verificar headers de seguridad
# =============================================================================
info "Verificando headers de seguridad..."

HEADERS=$(curl -k -sI https://localhost/ 2>/dev/null)

if echo "$HEADERS" | grep -qi "strict-transport-security"; then
    pass "Header HSTS presente"
else
    fail "Header HSTS ausente"
fi

if echo "$HEADERS" | grep -qi "x-content-type-options: nosniff"; then
    pass "Header X-Content-Type-Options presente"
else
    fail "Header X-Content-Type-Options ausente"
fi

if echo "$HEADERS" | grep -qi "x-frame-options: DENY"; then
    pass "Header X-Frame-Options presente"
else
    fail "Header X-Frame-Options ausente"
fi

if echo "$HEADERS" | grep -qi "content-security-policy"; then
    pass "Header Content-Security-Policy presente"
else
    fail "Header Content-Security-Policy ausente"
fi

# =============================================================================
# 7. Verificar TLS handshake
# =============================================================================
info "Verificando TLS handshake..."

TLS_INFO=$(echo | openssl s_client -connect localhost:443 2>/dev/null)
if echo "$TLS_INFO" | grep -q "Protocol: TLSv1\.[23]"; then
    TLS_VER=$(echo "$TLS_INFO" | grep "Protocol:" | head -1 | awk '{print $NF}')
    pass "TLS handshake exitoso ($TLS_VER)"
else
    fail "TLS handshake fallido"
fi

CIPHER=$(echo "$TLS_INFO" | grep "Cipher is" | head -1 | awk '{print $NF}')
if [ -n "$CIPHER" ]; then
    pass "Cipher suite: $CIPHER"
else
    fail "No se pudo determinar cipher suite"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "============================================="
echo " Resumen"
echo "============================================="
echo -e "${GREEN}PASS: $PASS${NC}"
echo -e "${RED}FAIL: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}Todas las pruebas pasaron correctamente.${NC}"
    exit 0
else
    echo -e "${RED}Algunas pruebas fallaron. Revisar la configuración.${NC}"
    exit 1
fi
