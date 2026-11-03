#!/usr/bin/env bash
# Instalación nativa del driver VectorNav (VN-100) en Ubuntu 24.04 + ROS 2 Jazzy.
# Uso: ./install_driver.sh [--ws ~/ros2_ws] [--no-sim]
#   --ws PATH   workspace donde clonar y compilar (por defecto ~/ros2_ws)
#   --no-sim    no instala ros_gz (solo driver real)
# Variables: VN_REPO, VN_BRANCH para cambiar el repo/rama del driver.
set -euo pipefail

WS="${HOME}/ros2_ws"
INSTALL_SIM=1
VN_REPO="${VN_REPO:-https://github.com/dawonn/vectornav.git}"
VN_BRANCH="${VN_BRANCH:-ros2}"
ROS_DISTRO_NAME="jazzy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ws) WS="$2"; shift 2 ;;
    --no-sim) INSTALL_SIM=0; shift ;;
    *) echo "Argumento desconocido: $1"; exit 1 ;;
  esac
done

. /etc/os-release
if [[ "${VERSION_ID}" != "24.04" ]]; then
  echo "AVISO: pensado para Ubuntu 24.04 (detectado ${VERSION_ID})."
fi
if [[ ! -f "/opt/ros/${ROS_DISTRO_NAME}/setup.bash" ]]; then
  echo "ERROR: no se encuentra /opt/ros/${ROS_DISTRO_NAME}. Instala ROS 2 Jazzy primero."
  exit 1
fi

echo "==> Dependencias del sistema"
sudo apt-get update
sudo apt-get install -y \
  git build-essential cmake python3-colcon-common-extensions python3-rosdep \
  python3-vcstool libasio-dev \
  "ros-${ROS_DISTRO_NAME}-xacro" \
  "ros-${ROS_DISTRO_NAME}-robot-state-publisher"
if [[ "${INSTALL_SIM}" == "1" ]]; then
  sudo apt-get install -y \
    "ros-${ROS_DISTRO_NAME}-ros-gz-sim" \
    "ros-${ROS_DISTRO_NAME}-ros-gz-bridge"
fi

echo "==> rosdep"
if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
  sudo rosdep init
fi
rosdep update

echo "==> Clonando driver en ${WS}/src"
mkdir -p "${WS}/src"
cd "${WS}/src"
if [[ ! -d vectornav ]]; then
  git clone --recursive --branch "${VN_BRANCH}" "${VN_REPO}" vectornav
else
  echo "vectornav ya existe, se omite el clonado."
fi

echo "==> Compilando"
cd "${WS}"
set +u
# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO_NAME}/setup.bash"
set -u
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

echo "==> Permisos de puerto serie (grupo dialout)"
if ! id -nG "${USER}" | grep -qw dialout; then
  sudo usermod -aG dialout "${USER}"
  echo "Usuario añadido a dialout: cierra sesión y vuelve a entrar."
fi

cat <<EOF

Listo. Para usarlo:
  source ${WS}/install/setup.bash
  ros2 launch vectornav vectornav.launch.py     # hardware real (ajusta puerto en la config)
EOF
