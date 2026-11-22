#!/usr/bin/env bash
# ==============================================================================
# install-java25.sh - Instalador multi-distro de OpenJDK 25 LTS (Eclipse Temurin)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

JDK_DIR="${HOME}/.local/opt/jdk-25"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${HOME}/.local/opt" "${BIN_DIR}"

echo "=== Java 25 LTS (Eclipse Temurin OpenJDK 25) ==="

if [ -x "${JDK_DIR}/bin/java" ] && "${JDK_DIR}/bin/java" -version 2>&1 | grep -q '"25\.'; then
    echo "  [✓] Java 25 ya está instalado en ${JDK_DIR}."
else
    case "${ARCH}" in
        x86_64|amd64)  ADOPTIUM_ARCH="x64" ;;
        aarch64|arm64) ADOPTIUM_ARCH="aarch64" ;;
        *)
            echo "  [!] Arquitectura ${ARCH} no soportada por Adoptium Temurin 25."
            exit 0
            ;;
    esac

    API_URL="https://api.adoptium.net/v3/binary/latest/25/ga/linux/${ADOPTIUM_ARCH}/jdk/hotspot/normal/eclipse"
    TMP_DIR="/tmp/temurin25-$$"
    mkdir -p "${TMP_DIR}"

    echo "  [+] Descargando OpenJDK 25 LTS (${ADOPTIUM_ARCH})..."
    if safe_download "${API_URL}" "${TMP_DIR}/jdk25.tar.gz" 300; then
        rm -rf "${JDK_DIR}"
        mkdir -p "${JDK_DIR}"
        if tar -xzf "${TMP_DIR}/jdk25.tar.gz" -C "${JDK_DIR}" --strip-components=1 2>/dev/null; then
            echo "  [✓] Java 25 extraído en ${JDK_DIR}."
        else
            echo "  [!] Error al descomprimir OpenJDK 25."
            rm -rf "${JDK_DIR}"
        fi
    else
        echo "  [!] No se pudo descargar OpenJDK 25 desde Adoptium."
    fi
    rm -rf "${TMP_DIR}"
fi

if [ -x "${JDK_DIR}/bin/java" ]; then
    for tool in java javac jar jshell javadoc javap jlink; do
        if [ -x "${JDK_DIR}/bin/${tool}" ]; then
            ln -sf "${JDK_DIR}/bin/${tool}" "${BIN_DIR}/${tool}"
        fi
    done

    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.profile"; do
        if [ -f "$rc" ] && ! grep -Fq 'JAVA_HOME="$HOME/.local/opt/jdk-25"' "$rc" 2>/dev/null; then
            printf '\n# Java 25 LTS (Linux-Setup)\nexport JAVA_HOME="$HOME/.local/opt/jdk-25"\nexport PATH="$JAVA_HOME/bin:$PATH"\n' >> "$rc"
        fi
    done

    export JAVA_HOME="${JDK_DIR}"
    export PATH="${JDK_DIR}/bin:${PATH}"
    echo "  [✓] Java 25 listo: $("${JDK_DIR}/bin/java" -version 2>&1 | head -n1)"
fi
