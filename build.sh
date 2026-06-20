#!/bin/bash
set -e

ARCH=arm64
CONFIG="gki_defconfig"
CROSS_COMPILE=aarch64-linux-gnu-
DIST="dist"
JOBS=$(nproc)
LLVM=1
OUT="out"

export ARCH CONFIG CROSS_COMPILE LLVM

error() { printf "\033[1;31m[!] %s\033[0m\n" "$1"; exit 1; }
info()  { printf "\033[1;34m[*] %s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m[+] %s\033[0m\n" "$1"; }

while true; do
    printf "\033[1;34m[*] Clean build? (y/n): \033[0m"
    read -r -n 1 REPLY
    printf "\n"
    case "$REPLY" in
        [Yy]) info "Cleaning directories"; rm -rf "$DIST" "$OUT"; break ;;
        [Nn]) break ;;
        *) printf "\033[1;31m    Use 'y' or 'n'.\033[0m\n" ;;
    esac
done

mkdir -p "$DIST" "$OUT"

info "Configuring $CONFIG"
make O="$OUT" "$CONFIG" || error "Configuration failed"

info "Compiling with $JOBS jobs"
make O="$OUT" -j"$JOBS" || error "Build failed"

info "Exporting artifacts"
cp "$OUT/.config" "$DIST/config"
cp "$OUT/arch/arm64/boot/Image" "$DIST/kernel"
cp "$OUT/vmlinux" "$DIST/vmlinux"

ok "Build successful: ./$DIST/kernel"
