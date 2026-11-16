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

## Frecuencia y baudios (medido en la ZED Box Orin NX)

`config/vn100.yaml` deja el sensor a **921600 baudios y 200 Hz** (`BO1.rateDivisor: 4`,
800 Hz / 4) con `asyncMode: 1` (solo puerto serie 1). Verificado de extremo a extremo:
`/vectornav/imu` 200.0 Hz, hueco máximo 7.6 ms, `/vectornav/magnetic` 199.9 Hz; CPU ~18 % +
~9 % de un núcleo (`vn_sensor_msgs` + `vectornav`).

Máximo que responde con `commonField: 0x7FFF` (todos los campos comunes):

| Baudios | Máximo | Primer fallo |
|---|---|---|
| 115200 | 20 Hz | 50 Hz |
| 230400 | 50 Hz | 100 Hz |
| 460800 | 100 Hz | 200 Hz |
| 921600 | **200 Hz** | 400 Hz |

- El límite sigue la velocidad del puerto: cada mensaje es grande por pedir todos los campos.
  Pidiendo solo los necesarios (no probado) subiría el máximo.
- `asyncMode: 3` (BOTH, el valor por defecto del driver) hace que el sensor responda
  `InsufficientBaudRate` por encima de 20 Hz aunque el baudrate sea alto, y el driver aborta.
  Usar `1` (puerto 1).
- Nada de esto se graba en la memoria del sensor: al reiniciarlo vuelve a 115200 y 20 Hz,
  y el driver lo reconfigura al conectar.

## Pendiente de verificar

- Nombres exactos de topics del driver real (`ros2 topic list` con el sensor conectado) y rama/dependencias del repo en Jazzy.
- Ruido del URDF: valores aproximados a partir de la hoja de datos; afinar con el sensor real.
