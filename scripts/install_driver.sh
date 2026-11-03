#!/usr/bin/env bash
# Instalación autocontenida del VectorNav VN-100 (driver + paquete Caddy AI2).
# Válido para x86_64 (PC de desarrollo) y aarch64 (Jetson Orin NX / ZedBox),
# ambos con Ubuntu 24.04 + ROS 2 Jazzy instalado de forma nativa.
#
# Uso: ./scripts/install_driver.sh [--ws ~/vn100_ws] [--no-sim] [--no-udev]
#   --ws PATH    workspace de colcon (build/install/log) (por defecto ~/vn100_ws)
#   --no-sim     no instala ros_gz (recomendado en la Jetson)
#   --no-udev    no instala la regla udev (/dev/vn100)
# El código fuente NO se copia: se compila directamente desde este repo y su
# submódulo third_party/vectornav (dawonn/vectornav, rama ros2).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${HOME}/vn100_ws"
INSTALL_SIM=1
INSTALL_UDEV=1
ROS_DISTRO_NAME="jazzy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ws) WS="$2"; shift 2 ;;
    --no-sim) INSTALL_SIM=0; shift ;;
    --no-udev) INSTALL_UDEV=0; shift ;;
    *) echo "Argumento desconocido: $1"; exit 1 ;;
  esac
done

. /etc/os-release
ARCH="$(uname -m)"
echo "==> Sistema: Ubuntu ${VERSION_ID} / ${ARCH}"
[[ "${VERSION_ID}" == "24.04" ]] || echo "AVISO: pensado para Ubuntu 24.04."
if [[ ! -f "/opt/ros/${ROS_DISTRO_NAME}/setup.bash" ]]; then
  echo "ERROR: falta /opt/ros/${ROS_DISTRO_NAME}. Instala ROS 2 Jazzy (ros-jazzy-ros-base como mínimo)."
  exit 1
fi

echo "==> Submódulos"
git -C "${REPO}" submodule update --init --recursive
[[ -f "${REPO}/third_party/vectornav/vectornav/package.xml" ]] || { echo "ERROR: submódulo vectornav vacío"; exit 1; }

echo "==> Dependencias del sistema"
sudo apt-get update
sudo apt-get install -y git build-essential cmake python3-colcon-common-extensions python3-rosdep \
  "ros-${ROS_DISTRO_NAME}-xacro"
if [[ "${INSTALL_SIM}" == "1" ]]; then
  sudo apt-get install -y "ros-${ROS_DISTRO_NAME}-ros-gz-sim" "ros-${ROS_DISTRO_NAME}-ros-gz-bridge"
fi

echo "==> rosdep"
[[ -f /etc/ros/rosdep/sources.list.d/20-default.list ]] || sudo rosdep init
rosdep update
set +u; source "/opt/ros/${ROS_DISTRO_NAME}/setup.bash"; set -u
rosdep install --from-paths "${REPO}" "${REPO}/third_party/vectornav" --ignore-src -r -y \
  --skip-keys "ros_gz_sim ros_gz_bridge vectornav"

echo "==> Compilando en ${WS}"
mkdir -p "${WS}"
cd "${WS}"
# --base-paths explícito: el paquete raíz no deja a colcon descender al submódulo.
colcon build --symlink-install --base-paths "${REPO}" "${REPO}/third_party/vectornav" \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

if [[ "${INSTALL_UDEV}" == "1" ]]; then
  echo "==> udev + grupo dialout"
  sudo install -m 644 "${REPO}/udev/99-vn100.rules" /etc/udev/rules.d/99-vn100.rules
  sudo udevadm control --reload-rules && sudo udevadm trigger
  if ! id -nG "${USER}" | grep -qw dialout; then
    sudo usermod -aG dialout "${USER}"
    echo "Usuario añadido a dialout: cierra sesión y vuelve a entrar."
  fi
fi

cat <<EOF

Listo. Cada terminal:
  source ${WS}/install/setup.bash
Hardware real (VN-100 por USB-serie, /dev/vn100 o /dev/ttyUSB0):
  ros2 launch caddy_ai2_ros2_imu_vectornav_vn100 vn100.launch.py port:=/dev/vn100
  ros2 topic echo /vectornav/imu
Simulación (Gazebo Harmonic): ver README.md
EOF
