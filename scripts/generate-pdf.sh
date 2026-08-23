#!/bin/bash
# =============================================================================
# generate-pdf.sh — Genera PDF desde README.md
# =============================================================================
# Convierte el archivo README.md a PDF usando Python (markdown + weasyprint).
# El PDF incluye imagenes de la carpeta captures/.
#
# Requisitos:
#   pip3 install markdown weasyprint
#
# Uso:
#   ./scripts/generate-pdf.sh
#
# Salida:
#   DigCerts.pdf
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
README="${PROJECT_DIR}/README.md"
OUTPUT="${PROJECT_DIR}/DigCerts.pdf"

if [ ! -f "${README}" ]; then
    echo "[ERROR] README.md no encontrado en ${PROJECT_DIR}"
    exit 1
fi

echo "[INFO] Generando PDF desde README.md..."

python3 -c "
import markdown
import weasyprint

with open('${README}', 'r') as f:
    md_content = f.read()

html_content = markdown.markdown(md_content, extensions=['tables', 'fenced_code'])

full_html = f'''
<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\">
    <style>
        body {{ font-family: sans-serif; margin: 40px; line-height: 1.6; }}
        h1 {{ color: #0366d6; border-bottom: 2px solid #0366d6; padding-bottom: 10px; }}
        h2 {{ color: #24292e; border-bottom: 1px solid #e1e4e8; padding-bottom: 5px; }}
        h3 {{ color: #586069; }}
        code {{ background: #f6f8fa; padding: 2px 6px; border-radius: 3px; font-size: 0.9em; }}
        pre {{ background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto; }}
        pre code {{ background: none; padding: 0; }}
        table {{ border-collapse: collapse; width: 100%; margin: 16px 0; }}
        th, td {{ border: 1px solid #e1e4e8; padding: 8px 12px; text-align: left; }}
        th {{ background: #f6f8fa; }}
        img {{ max-width: 100%; height: auto; }}
        blockquote {{ border-left: 4px solid #0366d6; margin: 16px 0; padding: 8px 16px; background: #f6f8fa; }}
        a {{ color: #0366d6; }}
        hr {{ border: none; border-top: 1px solid #e1e4e8; margin: 24px 0; }}
    </style>
</head>
<body>
{html_content}
</body>
</html>
'''

weasyprint.HTML(string=full_html, base_url='${PROJECT_DIR}').write_pdf('${OUTPUT}')
"

echo "[INFO] PDF generado exitosamente: ${OUTPUT}"
