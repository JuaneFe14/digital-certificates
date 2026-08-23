# =============================================================================
# Dockerfile - Nginx Reverse Proxy con TLS
# =============================================================================
# Construye una imagen de Nginx configurada para:
#   - Termination TLS (descifrado HTTPS)
#   - Reverse proxy a FastAPI
#   - Headers de seguridad HTTP
#
# Imagen base: nginx:alpine (~25MB)
# =============================================================================

# Imagen base ligera Alpine
FROM nginx:alpine

# Eliminar configuracion por defecto de Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copiar configuracion TLS y reverse proxy
COPY default.conf /etc/nginx/conf.d/default.conf

# Exponer puerto HTTPS
EXPOSE 443

# Iniciar Nginx en primer plano (daemon off para Docker)
CMD ["nginx", "-g", "daemon off;"]
