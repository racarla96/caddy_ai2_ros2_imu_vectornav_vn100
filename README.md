# caddy_ai2_ros2_imu_vectornav_vn100

VectorNav VN-100 del Caddy AI2: instalación nativa del driver (Ubuntu 24.04 + ROS 2 Jazzy) y sensor simulado en Gazebo Harmonic.

Licencia: CC BY 4.0 — racarla96 - Rafael Carbonell Lázaro.

## 1. Instalar el driver (ZedBox / PC con Ubuntu 24.04)

```bash
./scripts/install_driver.sh --ws ~/ros2_ws          # driver + ros_gz
./scripts/install_driver.sh --ws ~/ros2_ws --no-sim # solo driver (ZedBox)
source ~/ros2_ws/install/setup.bash
ros2 launch vectornav vectornav.launch.py
```

Clona `dawonn/vectornav` (rama `ros2`, configurable con `VN_REPO` / `VN_BRANCH`), resuelve dependencias con rosdep, compila con colcon y añade el usuario a `dialout`.

## 2. Simulación en Gazebo Harmonic

1. Incluye el sensor en el xacro del vehículo:

```xml
<xacro:include filename="$(find caddy_ai2_ros2_imu_vectornav_vn100)/urdf/vn100.urdf.xacro"/>
<xacro:vn100 name="vn100" parent="base_link" xyz="0 0 0.3" rpy="0 0 0"/>
```

2. El mundo SDF debe cargar los sistemas `gz-sim-imu-system`, `gz-sim-magnetometer-system`, `gz-sim-air-pressure-system` (y `gz-sim-sensors-system`).
3. Lanza el puente:

```bash
ros2 launch caddy_ai2_ros2_imu_vectornav_vn100 vn100_sim.launch.py
```

Publica `vectornav/imu`, `vectornav/magnetic` y `vectornav/pressure` con `frame_id: vectornav`, igual que el driver real, así el resto del stack no cambia entre simulación y hardware.

## Pendiente de verificar

- Nombres exactos de topics del driver real (`ros2 topic list` con el sensor conectado) y rama/dependencias del repo en Jazzy.
- Ruido del URDF: valores aproximados a partir de la hoja de datos; afinar con el sensor real.
