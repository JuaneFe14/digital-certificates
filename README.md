# DigCerts — Certificados Digitales SSL/TLS

**Integrantes:** Juan Felipe Quintero Gutierrez

**Curso:** Seguridad en Software

**Fecha de entrega:** 23 de agosto de 2026

**Repositorio:** [https://github.com/JuaneFe14/digital-certificates](https://github.com/JuaneFe14/digital-certificates)

---

## 1. Introducción

En el contexto actual de la seguridad informática, los certificados digitales SSL/TLS son fundamentales para garantizar la confidencialidad, integridad y autenticación en las comunicaciones web. HTTPS se ha convertido en un estándar obligatorio para cualquier aplicación que maneje datos sensibles.

Este taller presenta la implementación práctica de un certificado digital auto-firmado en una aplicación web, utilizando Docker, Python (FastAPI) y Nginx como reverse proxy con TLS termination.

### Importancia de los certificados digitales

- **Confidencialidad:** Cifran la información para que solo el destinatario pueda leerla.
- **Integridad:** Garantizan que los datos no fueron modificados en tránsito.
- **Autenticación:** Verifican la identidad del servidor al que se conecta el cliente.
- **Confiabilidad:** Los navegadores solo permiten HTTPS en sitios con certificados válidos.

## 2. Descripción

**DigCerts** es una aplicación web académica que demuestra la instalación, configuración y validación de un certificado digital SSL/TLS auto-firmado utilizando OpenSSL. La aplicación web sirve sobre HTTPS, garantizando confidencialidad e integridad en las comunicaciones cliente-servidor.

## 3. Objetivos

### Objetivo General

Reforzar competencias en configuración de seguridad web mediante la generación, instalación y validación de certificados digitales SSL/TLS.

### Objetivos Específicos

1. Comprender la utilidad práctica de los certificados digitales y su relación con el protocolo HTTPS.
2. Generar un certificado auto-firmado con OpenSSL (Curva Elíptica P-256).
3. Configurar Nginx como reverse proxy con TLS 1.2+ y cipher suites seguros.
4. Implementar una aplicación FastAPI que consuma el certificado.
5. Containerizar la solución con Docker y Docker Compose.
6. Documentar el proceso completo de forma reproducible por terceros.

## 4. Stack Tecnológico

| Componente | Tecnología | Versión |
|------------|------------|---------|
| Backend | Python + FastAPI | 3.11 / 0.104.1 |
| Reverse Proxy | Nginx | Alpine (latest) |
| Criptografía | OpenSSL | Curva EC prime256v1 |
| Contenedores | Docker + Docker Compose | - |
| TLS | TLS 1.2 / 1.3 | - |

## 5. Prerrequisitos

- [Docker](https://docs.docker.com/get-docker/) instalado (>= 20.10)
- [Docker Compose](https://docs.docker.com/compose/install/) (>= 2.0)
- [OpenSSL](https://www.openssl.org/) (para generación local de certificados)
- Git (para clonar el repositorio)

## 6. Instalación Paso a Paso

### 6.1 Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd digital-certificates
```

### 6.2 Generar certificados

```bash
chmod +x scripts/generate-certs.sh
./scripts/generate-certs.sh
```

Esto genera:
- `certs/cert.pem` — Certificado público (chmod 644)
- `certs/key.pem` — Clave privada (chmod 600)

### 6.3 Levantar servicios Docker

```bash
docker compose up --build -d
```

### 6.4 Verificar funcionamiento

```bash
# Ejecutar script de verificación
chmod +x scripts/verify.sh
./scripts/verify.sh

# O manualmente:
curl -k https://localhost/health
curl -k https://localhost/certificate/info
```

Abrir en el navegador: **https://localhost**

> El navegador mostrará una advertencia de certificado auto-firmado. Hacer clic en "Avanzado" → "Proceed to localhost (unsafe)".

## 7. Estructura del Proyecto

```
digital-certificates/
├── docker-compose.yml          # Orquestación de contenedores
├── .gitignore                  # Excluye certs/ y archivos temporales
├── docker/
│   ├── fastapi/
│   │   ├── Dockerfile          # Multi-stage build para FastAPI
│   │   └── requirements.txt    # Dependencias Python
│   └── nginx/
│       ├── Dockerfile          # Nginx Alpine con TLS
│       └── default.conf        # Configuración TLS + reverse proxy
├── certs/                      # Generado por generate-certs.sh
│   ├── cert.pem                # Certificado público
│   └── key.pem                 # Clave privada
├── scripts/
│   ├── generate-certs.sh       # Generación de certificados OpenSSL
│   └── verify.sh               # Verificación automatizada HTTPS
├── app/
│   ├── __init__.py
│   ├── main.py                 # Punto de entrada FastAPI
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py           # AppConfig (pydantic-settings)
│   ├── services/
│   │   ├── __init__.py
│   │   └── certificate_service.py  # Lectura y validación de certificados
│   ├── models/
│   │   ├── __init__.py
│   │   └── responses.py        # Modelos Pydantic de respuesta
│   └── templates/
│       └── index.html          # Landing page HTML
├── README.md                   # Este archivo
└── AGENTS.md                   # Reglas del proyecto
```

## 8. Endpoints de la API

| Método | Ruta | Descripción | Formato |
|--------|------|-------------|---------|
| GET | `/` | Landing page HTML | HTML |
| GET | `/health` | Health check del servidor | JSON |
| GET | `/certificate/info` | Información del certificado instalado | JSON |
| GET | `/docs` | Swagger UI (documentación interactiva) | HTML |
| GET | `/redoc` | ReDoc (documentación alternativa) | HTML |

### Ejemplo de respuesta `/health`

```json
{
  "status": "healthy",
  "service": "Digital Certificates Demo",
  "version": "1.0.0",
  "tls_enabled": true
}
```

### Ejemplo de respuesta `/certificate/info`

```json
{
  "subject": "C=US, ST=Development, L=Local, O=DigitalCertificates, CN=localhost",
  "issuer": "C=US, ST=Development, L=Local, O=DigitalCertificates, CN=localhost",
  "serial_number": "220C9B290737473BF807076EE3B2223E46C0651A",
  "not_before": "2026-08-23T21:37:08",
  "not_after": "2027-08-23T21:37:08",
  "is_valid": true,
  "file_path": "/app/certs/cert.pem"
}
```

## 9. Pruebas y Validación

### 9.1 Verificación con curl

```bash
# Verificar conexión HTTPS y headers
curl -k -sI https://localhost/

# Verificar health check
curl -k -s https://localhost/health

# Verificar información del certificado
curl -k -s https://localhost/certificate/info

# Verificar TLS handshake detallado
curl -v https://localhost/ 2>&1 | grep -E "SSL|TLS|subject|issuer"
```

### 9.2 Verificación en navegador

1. Abrir **https://localhost** en el navegador
2. Hacer clic en "Avanzado" → "Proceed to localhost (unsafe)"
3. Verificar que la página carga correctamente

### 9.3 Script de verificación automatizada

```bash
./scripts/verify.sh
```

El script ejecuta automáticamente todas las verificaciones y muestra resultados con estados `[PASS]` o `[FAIL]`.

### 9.4 Evidencia de Funcionamiento

A continuación se presentan las capturas de pantalla que demuestran el funcionamiento correcto de la aplicación bajo HTTPS con certificado auto-firmado.

##### 1. Generación de certificados

![Generación de certificados](captures/evidencia-01-generacion.png)

##### 2. Build de Docker

![Build de Docker](captures/evidencia-02-build.png)

##### 3. Contenedores corriendo

![Contenedores corriendo](captures/evidencia-03-contenedores.png)

##### 4. Landing page en navegador

![Landing page](captures/evidencia-04-landing.png)

##### 5. Salida de verify.sh

![verify.sh](captures/evidencia-05-verify.png)

##### 6. Health check JSON

![Health check](captures/evidencia-06-health.png)

## 10. Configuración de Seguridad

### 10.1 TLS 1.2+ y Cipher Suites

La configuración de Nginx (`docker/nginx/default.conf`) establece:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...;
ssl_prefer_server_ciphers on;
```

**¿Por qué TLS 1.2+?**
- TLS 1.0: Vulnerable a BEAST y POODLE
- TLS 1.1: Vulnerable a ataques de padding
- TLS 1.2: Seguro con cipher suites correctos
- TLS 1.3: Más rápido y seguro (sin renegociación)

**Cipher suites explicados:**
- `ECDHE` = Exchange de clave efímero (Forward Secrecy)
- `AES128-GCM` = Cifrado simétrico autenticado
- `SHA256` = Hash para integridad

### 10.2 Headers de Seguridad HTTP

| Header | Propósito |
|--------|-----------|
| `Strict-Transport-Security` | Forzar HTTPS por 2 años (HSTS) |
| `X-Content-Type-Options` | Prevenir MIME-sniffing |
| `X-Frame-Options` | Prevenir clickjacking (DENY) |
| `X-XSS-Protection` | Protección XSS en navegadores antiguos |
| `Content-Security-Policy` | Controlar recursos externos |

### 10.3 Almacenamiento de Claves Privadas

La clave privada (`key.pem`) se almacena con permisos restriccitivos:

```bash
chmod 600 key.pem  # Solo el propietario puede leer/escribir
```

**Recomendaciones:**
- Nunca compartir la clave privada
- No subir `key.pem` a repositorios (excluido en `.gitignore`)
- Usar permisos `600` o `400` en producción
- En producción, usar vaults de secrets (HashiCorp Vault, AWS Secrets Manager)
- Rotar claves periódicamente (mínimo anual)

## 11. Certificados Digitales

### 11.1 Auto-firmados vs Autoridad Certificadora

| Característica | Auto-firmado | Autoridad Certificadora (CA) |
|----------------|--------------|------------------------------|
| Emisor | Uno mismo | Empresa verificada (Let's Encrypt, DigiCert) |
| Confianza | No confiable por defecto | Confiable por navegadores |
| Uso recomendado | Desarrollo, testing, intranet | Producción, sitios públicos |
| Costo | Gratis | Variable (Let's Encrypt es gratis) |
| Validación | No valida identidad | Valida dominio y/o organización |
| Navegador | Muestra advertencia | Candado verde |

**En este proyecto:** Se usa certificado auto-firmado porque es un entorno de desarrollo/demostración académica.

### 11.2 Ciclo de Vida de un Certificado

```
1. GENERACIÓN
   openssl req -x509 → Genera cert + clave

2. INSTALACIÓN
   Nginx carga cert.pem + key.pem

3. VALIDACIÓN (durante handshake TLS)
   Cliente verifica: firma, fechas, dominio

4. USO
   Comunicaciones HTTPS cifradas

5. EXPIRACIÓN
   after not_after → Certificado inválido

6. RENOVACIÓN
   Generar nuevo cert → Reinstalar → Reiniciar Nginx
```

### 11.3 Renovación

```bash
# 1. Generar nuevos certificados
./scripts/generate-certs.sh

# 2. Reiniciar Nginx para cargar el nuevo certificado
docker compose restart nginx

# 3. Verificar
openssl s_client -connect localhost:443 | openssl x509 -noout -dates
```

**Nota:** El script `generate-certs.sh` no sobreescribe certificados existentes. Para renovar, eliminar los actuales primero:

```bash
rm certs/cert.pem certs/key.pem
./scripts/generate-certs.sh
docker compose restart nginx
```

## 12. Arquitectura Docker

```
┌─────────────────────────────────────────────────────┐
│                    HOST (puerto 443)                 │
│                        │                             │
│    ┌───────────────────▼───────────────────┐        │
│    │         nginx-proxy                   │        │
│    │    ┌──────────────────────────┐       │        │
│    │    │  TLS Termination         │       │        │
│    │    │  cert.pem + key.pem      │       │        │
│    │    │  Headers de seguridad    │       │        │
│    │    └──────────┬───────────────┘       │        │
│    │               │ HTTP (red interna)    │        │
│    └───────────────┼───────────────────────┘        │
│                    │                                │
│    ┌───────────────▼───────────────────────┐        │
│    │         fastapi-app                   │        │
│    │    ┌──────────────────────────┐       │        │
│    │    │  FastAPI (puerto 8000)   │       │        │
│    │    │  Python 3.11-slim        │       │        │
│    │    │  Usuario no-root         │       │        │
│    │    └──────────────────────────┘       │        │
│    └───────────────────────────────────────┘        │
│                                                     │
│    Red: backend-net (bridge)                        │
│    Volumes: ./certs (solo lectura)                  │
└─────────────────────────────────────────────────────┘
```

## 13. Comandos Útiles

```bash
# Levantar servicios
docker compose up --build -d

# Ver logs
docker compose logs -f nginx
docker compose logs -f fastapi

# Verificar certificado
openssl s_client -connect localhost:443
openssl x509 -in certs/cert.pem -noout -text

# Detener servicios
docker compose down

# Reconstruir desde cero
docker compose down --rmi all
docker compose up --build -d

# Verificar puertos
docker compose ps
```

---

**DigCerts** — Proyecto Académico de Certificados Digitales en una Aplicación Web Segura
