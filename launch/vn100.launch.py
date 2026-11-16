"""Lanza el VN-100 real: un solo nodo (fork de Robotnik, rama robotnik-jazzy-devel).

Publica con los MISMOS nombres que usa la simulación (vectornav/imu, vectornav/magnetic,
vectornav/pressure, vectornav/temperature), remapeando los suyos (data, mag, atm_pressure).

Argumentos:
  port              puerto serie (por defecto /dev/vn100, ver udev/99-vn100.rules)
  frame_convention  convención de ejes de la salida (por defecto rep103):
                      rep103   mundo ENU, cuerpo FLU (x delante, y izquierda, z arriba): REP-103/145
                      enu_rfu  mundo ENU, cuerpo RFU (x derecha, y delante, z arriba)
                      nwu      mundo NWU, cuerpo FLU
                      ned      sensor en bruto: NED, cuerpo FRD
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    pkg = get_package_share_directory('caddy_ai2_ros2_imu_vectornav_vn100')
    cfg = os.path.join(pkg, 'config', 'vn100.yaml')

    return LaunchDescription([
        DeclareLaunchArgument('port', default_value='/dev/vn100'),
        DeclareLaunchArgument(
            'frame_convention', default_value='rep103',
            description='rep103 | enu_rfu | nwu | ned (ver cabecera de este fichero).'),
        Node(
            package='vectornav', executable='vectornav_node', name='vectornav',
            output='screen',
            parameters=[cfg, {
                'serial_port': LaunchConfiguration('port'),
                'frame_convention': LaunchConfiguration('frame_convention'),
            }],
            remappings=[
                ('/vectornav/data', '/vectornav/imu'),
                ('/vectornav/mag', '/vectornav/magnetic'),
                ('/vectornav/atm_pressure', '/vectornav/pressure'),
            ]),
    ])
