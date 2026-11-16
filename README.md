# caddy_ai2_ros2_imu_vectornav_vn100

VectorNav VN-100 del Caddy AI2: instalación nativa del driver (Ubuntu 24.04 + ROS 2 Jazzy) y sensor simulado en Gazebo Harmonic.

Licencia: CC BY 4.0 — racarla96 - Rafael Carbonell Lázaro.

## 1. Instalar el driver (ZedBox / PC con Ubuntu 24.04)

```bash
./scripts/install_driver.sh --ws ~/ros2_ws          # driver + ros_gz
./scripts/install_driver.sh --ws ~/ros2_ws --no-sim # solo driver (ZedBox)
source ~/ros2_ws/install/setup.bash
ros2 launch caddy_ai2_ros2_imu_vectornav_vn100 vn100.launch.py
```

Compila el submódulo `third_party/vectornav` (fork `racarla96/vectornav`, rama `robotnik-jazzy-devel`: driver de [RobotnikAutomation/vectornav](https://github.com/RobotnikAutomation/vectornav) `jazzy-devel` más la opción `frame_convention`), resuelve dependencias con rosdep, compila con colcon, instala la regla udev (`/dev/vn100`) y añade el usuario a `dialout`.

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

## Driver y frecuencia (medido en la ZED Box Orin NX)

Un solo nodo, `vectornav_node` (Robotnik `jazzy-devel`), a **921600 baudios y 200 Hz** con
salida solo por el puerto 1. Topics, remapeados a los de la simulación: `vectornav/imu`,
`vectornav/magnetic`, `vectornav/pressure`, `vectornav/temperature`.

Comparado con el driver anterior (`dawonn/vectornav` `ros2` + `vn_sensor_msgs`), mismo sensor y
configuración (VN-100T-CR, FW 3.1.0.0):

| | `dawonn` + `vn_sensor_msgs` | Robotnik `jazzy-devel` |
|---|---|---|
| Frecuencia `/vectornav/imu` | 200,0 Hz | 200,0 Hz |
| Hueco máximo | 7,6 ms | 6,1 ms |
| CPU | 24,6 % de un núcleo (2 nodos) | 6,2 % (1 nodo) |

Con el driver anterior el máximo era 200 Hz a 921600 baudios y bajaba con el baudrate
(115200 → 20 Hz, 230400 → 50, 460800 → 100), y dejaba `asyncMode: 3` (ambos puertos), con el
que el sensor responde `InsufficientBaudRate` por encima de 20 Hz. El fork de Robotnik usa
`ASYNCMODE_PORT1` y pide menos campos. Más de 200 Hz no está probado (su parámetro solo admite
hasta 200).

Nada de esto se graba en la memoria del sensor: al reiniciarlo vuelve a 115200 y 20 Hz, y el
driver lo reconfigura al conectar.

## Convención de ejes (`frame_convention`)

Se elige con el argumento del launch o en `config/vn100.yaml`:

```bash
ros2 launch caddy_ai2_ros2_imu_vectornav_vn100 vn100.launch.py frame_convention:=rep103
```

| Valor | Mundo | Cuerpo | |
|---|---|---|---|
| `rep103` (por defecto) | ENU | FLU: x delante, y izquierda, z arriba | **Convención ROS (REP-103/145)**; la misma que la simulación |
| `enu_rfu` | ENU | RFU: x derecha, y delante, z arriba | Lo que publicaba `dawonn/vectornav` con `use_enu` |
| `nwu` | NWU | FLU | La de Robotnik |
| `ned` | NED | FRD | Sensor en bruto |

`rep103` y `nwu` solo difieren en el mundo: `yaw_enu = yaw_nwu + 90°`. `frame_convention` es un
parche nuestro sobre el fork de Robotnik; si se deja vacío, valen sus parámetros `tf_ned_to_*`.

Comprobado con la IMU quieta y sin tocarla entre capturas: `enu_rfu` da exactamente la misma
orientación y aceleración que el driver anterior; `rep103` da el mismo balanceo y cabeceo que
`nwu` y un rumbo +90° respecto a él, con la aceleración en +z (arriba). **Pendiente:** moverla
físicamente para comprobar signos y sentido de giro.

## Pendiente de verificar

- Ruido del URDF: valores aproximados a partir de la hoja de datos; afinar con el sensor real.
