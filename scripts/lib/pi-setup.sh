#!/usr/bin/env bash
# Shared Raspberry Pi install helpers for the release installer and pi-gen image.

PI240_RUNTIME_PACKAGES=(
    libqt6quick6
    libqt6qml6
    libqt6opengl6
    libqt6network6
    libqt6svg6
    qt6-svg-plugins
    qt6-wayland
    qml6-module-qtquick
    qml6-module-qtquick-controls
    qml6-module-qtquick-window
    qml6-module-qtquick-effects
    libsdl2-2.0-0
    mpv
)

pi240_is_root() {
    [ "$(id -u)" -eq 0 ]
}

pi240_root() {
    if pi240_is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

pi240_install_file_from_stdin() {
    local target="$1"
    local mode="${2:-0644}"

    if pi240_is_root; then
        install -d -m 0755 "$(dirname "$target")"
        cat > "$target"
        chmod "$mode" "$target"
    else
        local tmp
        tmp="$(mktemp)"
        cat > "$tmp"
        sudo install -D -m "$mode" "$tmp" "$target"
        rm -f "$tmp"
    fi
}

pi240_install_runtime_dependencies() {
    pi240_root apt-get update -qq
    pi240_root apt-get install -y "${PI240_RUNTIME_PACKAGES[@]}"
}

pi240_install_tty_rule() {
    pi240_install_file_from_stdin /etc/udev/rules.d/99-240mp-tty.rules 0644 <<'RULE'
KERNEL=="tty0", GROUP="tty", MODE="0620"
RULE

    if command -v udevadm >/dev/null 2>&1 && [ -e /dev/tty0 ]; then
        pi240_root udevadm control --reload-rules || true
        pi240_root udevadm trigger /dev/tty0 || true
    fi
}

pi240_install_launcher() {
    local install_dir="${1:-/opt/240mp}"
    local launcher="${2:-/usr/local/bin/240mp}"

    {
        printf '#!/usr/bin/env bash\n'
        printf '# 240-MP launcher - auto-detects display platform\n'
        printf 'INSTALL_DIR=%q\n' "$install_dir"
        cat <<'LAUNCHER'

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
elif [ -n "${DISPLAY:-}" ]; then
    QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
else
    # No display server: use EGLFS for headless/kiosk mode (RPi Lite).
    QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-eglfs}"
    export QT_QPA_EGLFS_ALWAYS_SET_MODE=1
    export QT_QPA_EGLFS_KMS_ATOMIC="${QT_QPA_EGLFS_KMS_ATOMIC:-0}"

    # Select a DRM card with display connectors. On Pi 5 the render-only v3d
    # node can enumerate first, and Qt EGLFS needs the real display card.
    KMS_CARD=""
    for s in /sys/class/drm/card*-*/status; do
        [ -e "$s" ] || continue
        if [ "$(cat "$s")" = "connected" ]; then
            n=$(basename "$(dirname "$s")")
            KMS_CARD="${n%%-*}"
            break
        fi
    done
    if [ -z "$KMS_CARD" ]; then
        for d in /sys/class/drm/card*-*; do
            [ -e "$d" ] || continue
            n=$(basename "$d")
            KMS_CARD="${n%%-*}"
            break
        done
    fi
    if [ -n "$KMS_CARD" ] && [ -e "/dev/dri/$KMS_CARD" ]; then
        KMS_CONF="${XDG_RUNTIME_DIR:-/tmp}/240mp-kms.json"
        printf '{ "device": "/dev/dri/%s" }\n' "$KMS_CARD" > "$KMS_CONF"
        export QT_QPA_EGLFS_KMS_CONFIG="$KMS_CONF"
    fi
fi

export QT_QPA_PLATFORM
export QML2_IMPORT_PATH="/usr/lib/aarch64-linux-gnu/qt6/qml"

exec "${INSTALL_DIR}/bin/240mp" "$@"
LAUNCHER
    } | pi240_install_file_from_stdin "$launcher" 0755
}

pi240_install_update_helper() {
    local service_user="${1:-mp240}"
    local helper="${2:-/usr/local/sbin/240mp-update}"
    local source_script="${3:-/opt/240mp/share/240mp/scripts/240mp-update}"

    pi240_install_file_from_stdin "$helper" 0755 <<HELPER
#!/usr/bin/env bash
exec /usr/bin/env bash "$source_script" "\$@"
HELPER

    pi240_install_file_from_stdin /etc/sudoers.d/240mp-update 0440 <<SUDOERS
${service_user} ALL=(root) NOPASSWD: ${helper}
SUDOERS

    if command -v visudo >/dev/null 2>&1; then
        pi240_root visudo -cf /etc/sudoers.d/240mp-update
    fi
}

pi240_create_service_user() {
    local service_user="${1:-mp240}"
    local service_home="${2:-/var/lib/240mp}"

    if id "$service_user" >/dev/null 2>&1; then
        pi240_root usermod -aG tty,video,input "$service_user" || true
        return 0
    fi

    pi240_root useradd \
        --system \
        --create-home \
        --home-dir "$service_home" \
        --groups tty,video,input \
        --shell /usr/sbin/nologin \
        "$service_user"
}

pi240_install_autostart() {
    local service_user="${1:-pi}"
    local launcher="${2:-/usr/local/bin/240mp}"
    local systemd_service="${3:-/etc/systemd/system/240mp.service}"
    local service_home="${4:-}"

    if [ -z "$service_home" ]; then
        service_home="$(getent passwd "$service_user" 2>/dev/null | cut -d: -f6 || true)"
    fi
    service_home="${service_home:-/home/${service_user}}"

    pi240_install_file_from_stdin "$systemd_service" 0644 <<UNIT
[Unit]
Description=240-MP Media Player
After=multi-user.target sound.target

[Service]
Type=simple
User=${service_user}
SupplementaryGroups=tty video input
AmbientCapabilities=CAP_SYS_TTY_CONFIG
CapabilityBoundingSet=CAP_SYS_TTY_CONFIG
RuntimeDirectory=240mp
RuntimeDirectoryMode=0700
Environment=HOME=${service_home}
Environment=XDG_RUNTIME_DIR=/run/240mp
Environment=QT_QPA_PLATFORM=eglfs
Environment=QT_QPA_EGLFS_ALWAYS_SET_MODE=1
Environment=QT_QPA_EGLFS_KMS_ATOMIC=0
Environment=QML2_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt6/qml
Environment=MP240_AUTOSTART=1
ExecStartPre=+-/usr/bin/systemctl stop 240mp-terminal.service
ExecStart=${launcher}
Restart=on-failure
RestartSec=5s
RestartPreventExitStatus=10
ExecStopPost=+/usr/local/bin/240mp-stop
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

pi240_install_file_from_stdin /usr/local/bin/240mp-stop 0755 <<'STOP_HELPER'
#!/usr/bin/env bash
# Called by 240mp.service ExecStopPost. systemd sets $EXIT_STATUS to the app's exit code.
if [ -e /run/240mp-updating ]; then
    exit 0
fi

case "${EXIT_STATUS:-}" in
    0)
        systemctl poweroff
        ;;
    10)
        systemctl start 240mp-terminal.service
        ;;
    *)
        systemctl start 240mp-terminal.service
        ;;
esac
STOP_HELPER

    pi240_install_file_from_stdin /etc/systemd/system/240mp-terminal.service 0644 <<'TERMINAL_UNIT'
[Unit]
Description=240-MP exit-to-terminal login shell

[Service]
Type=idle
ExecStart=-/sbin/agetty --noclear tty1 linux
StandardInput=tty
StandardOutput=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
KillMode=process
Restart=no
TERMINAL_UNIT

    # Keep tty1 reserved for the app, but leave autovt available so
    # Ctrl+Alt+F2 can open a recovery login if the display stack fails.
    pi240_root systemctl mask getty@tty1.service
    pi240_root systemctl unmask autovt@.service || true
    pi240_root systemctl daemon-reload || true
    pi240_root systemctl enable 240mp.service
}
