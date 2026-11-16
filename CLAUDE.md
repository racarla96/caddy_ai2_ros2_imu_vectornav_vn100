# caddy_ai2_ros2_imu_vectornav_vn100 — contexto para Claude Code

Proyecto: CERVAREC / Caddy AI2 (vehículo agrícola autónomo). Dueño: Rafa (racarla96), habla español.
Stack: Ubuntu 24.04, ROS 2 Jazzy, Gazebo Harmonic, instalación NATIVA (sin Docker) en el PC de
desarrollo y en la Jetson Orin NX / ZedBox (aarch64). Jazzy es requisito duro.

## Objetivo
Paquete autocontenido para el IMU VectorNav VN-100(-VT):
1. Instalar el driver real (submódulo `third_party/vectornav` = fork `racarla96/vectornav`, rama `robotnik-jazzy-devel`: Robotnik `jazzy-devel` + `frame_convention`).
2. Simularlo en Gazebo Harmonic con los MISMOS topics que el driver real, para que el stack no cambie entre sim y hardware.

## Convenciones de Rafa
- Licencia: CC BY 4.0, titular "racarla96 - Rafael Carbonell Lázaro". Paquetes `ament_cmake` (C++).
- Nombre del repo: `caddy_ai2_ros2_imu_vectornav_vn100` (rama `jazzy`, remoto SSH `git@github.com:racarla96/...`).
- Ecosistema: repo de integración `caddy_ai2_ros2_sim` (rama jazzy; workspace raíz con submódulos en `src/`:
  description, gazebo_simulation, sensors_ydlidar_x4, sensors_sick_lms_291, control_sensors_sbg_ig_500n,
  bicycle_to_ackermann_{steering,traction}_adapter, robot_description_publisher, localization, navigation,
  sensors_rs_helios_5515). Los sensores existentes aportan fragmento URDF + driver en su propio submódulo.
  Hay un repo de contenedores de sensores para la ZedBox: `caddy_ai2_ros2_zedbox_sensors` (orquestador).

## Hecho y verificado
- Topics del driver real (leídos del código): `vectornav/imu`, `vectornav/magnetic`, `vectornav/pressure`,
  `vectornav/temperature` (el nodo único `vectornav_node` publica `data`, `mag`, `atm_pressure` y se remapean en el launch).
  Parámetros: `serial_port`, `serial_baud` (921600), `async_output_rate` (200), `frame_id`, `frame_convention` (rep103|enu_rfu|nwu|ned).
- Launch real: `vn100.launch.py` (arg `port`, por defecto `/dev/vn100`). Regla udev en `udev/99-vn100.rules`
  (idVendor/idProduct por defecto FTDI 0403:6001: AJUSTAR con `udevadm info`).
- Sim: `urdf/vn100.urdf.xacro` (macro `vn100`: IMU, magnetómetro, presión) + `config/vn100_gz_bridge.yaml`
  + `launch/vn100_sim.launch.py` (ros_gz_bridge).
- `scripts/install_driver.sh`: submódulos, apt, rosdep, `colcon build --base-paths <repo> <repo>/third_party/vectornav`
  (el paquete raíz impide a colcon descender al submódulo, por eso base-paths explícito). Flags `--no-sim`, `--no-udev`, `--ws`.

## NO verificado todavía (hacer primero)
- Nada se ha compilado ni ejecutado (en la sesión de origen no había ROS). Ejecutar `./scripts/install_driver.sh` en este equipo y corregir lo que falle.
- Con hardware: `ros2 topic hz /vectornav/imu`, comprobar `frame_id` y udev.
- En Gazebo: el mundo debe cargar los sistemas `imu`, `magnetometer`, `air-pressure` y `sensors`;
  comprobar que los tipos del bridge (`gz.msgs.IMU`, `gz.msgs.Magnetometer`, `gz.msgs.FluidPressure`) y `<gz_frame_id>` son correctos en Harmonic.
- Ruido del URDF: valores aproximados, afinar con la hoja de datos.

## Pendiente de integrar en caddy_ai2_ros2_sim
1. Añadir este repo como submódulo (`src/caddy_ai2_ros2_imu_vectornav_vn100`, rama jazzy) y el driver:
   al estar anidado no lo descubre colcon, así que o se añade también `vectornav` como submódulo propio en `src/`
   (`git submodule add -b ros2 https://github.com/dawonn/vectornav.git src/vectornav`) o se usa `--base-paths`.
2. Incluir la macro `vn100` en el xacro del vehículo (parent/xyz según montaje real).
3. Lanzar `vn100_sim.launch.py` desde `sim.launch.py`; añadir los paquetes a la lista de `colcon build`.
4. Cargar los sistemas de sensores en el mundo SDF.
5. Opcional: alimentar el EKF de `caddy_ai2_ros2_localization` con `vectornav/imu`.
6. Jetson Orin NX: instalar con `--no-sim`; encaja con el contenedor/orquestador de sensores de la ZedBox si se decide dockerizar.
