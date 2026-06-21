#!/bin/bash
set -e
set -o pipefail

ARCH=arm64
CONFIG="onyx_defconfig"
DIST="dist"
JOBS=$(nproc)
OUT="out"
LOG="build.log"
CLANG_DIR="$HOME/clang"
CLANG_URL="https://github.com/XSans0/WeebX-Clang/releases/download/WeebX-Clang-19.1.5-release/WeebX-Clang-19.1.5.tar.gz"

error() {
    printf "\033[1;31m[!] %s\033[0m\n" "$1"
    if [ -f "$LOG" ]; then
        printf "\033[1;33m--- Last 20 lines of log ---\033[0m\n"
        tail -n 20 "$LOG"
    fi
    exit 1
}

info()  { printf "\033[1;34m[*] %s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m[+] %s\033[0m\n" "$1"; }

if [ ! -d "$CLANG_DIR/bin" ]; then
    info "Clang not found. Downloading..."
    mkdir -p "$CLANG_DIR"
    curl -LSs "$CLANG_URL" | tar -xzC "$CLANG_DIR" || error "Failed to setup toolchain"
else
    info "Clang found at $CLANG_DIR"
fi

export PATH="$CLANG_DIR/bin:$PATH"
export ARCH CONFIG
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export LD_LIBRARY_PATH="$CLANG_DIR/lib:$LD_LIBRARY_PATH"

while true; do
    printf "\033[1;34m[*] Clean build? (y/n): \033[0m"
    read -r -n 1 REPLY
    printf "\n"
    case "$REPLY" in
        [Yy]) info "Cleaning"; rm -rf "$DIST" "$OUT" "$LOG"; break ;;
        [Nn]) rm -f "$LOG"; break ;;
        *) printf "\033[1;31m    Use 'y' or 'n'.\033[0m\n" ;;
    esac
done

mkdir -p "$DIST" "$OUT"

info "Configuring $CONFIG"
make O="$OUT" "$CONFIG" 2>&1 | tee "$LOG" || error "Configuration failed"

info "Compiling with $JOBS jobs"
make O="$OUT" -j"$JOBS" \
    CC=clang \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip 2>&1 | tee -a "$LOG" || error "Build failed"

info "Exporting artifacts"
cp "$OUT/.config" "$DIST/config"
cp "$OUT/arch/arm64/boot/Image" "$DIST/kernel"
[ -f "$OUT/vmlinux" ] && cp "$OUT/vmlinux" "$DIST/vmlinux"

ok "Build successful: ./$DIST/kernel"
