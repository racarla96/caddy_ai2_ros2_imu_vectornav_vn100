"""Lanza el VN-100 real: nodo vectornav (raw) + vn_sensor_msgs (sensor_msgs).

Usa el yaml completo del driver (third_party/vectornav) como base y aplica encima
config/vn100.yaml y el argumento `port`.
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    drv = get_package_share_directory('vectornav')
    pkg = get_package_share_directory('caddy_ai2_ros2_imu_vectornav_vn100')
    base_cfg = os.path.join(drv, 'config', 'vectornav.yaml')
    caddy_cfg = os.path.join(pkg, 'config', 'vn100.yaml')
    port = LaunchConfiguration('port')

    return LaunchDescription([
        DeclareLaunchArgument('port', default_value='/dev/vn100'),
        Node(package='vectornav', executable='vectornav', output='screen',
             parameters=[base_cfg, caddy_cfg, {'port': port}]),
        Node(package='vectornav', executable='vn_sensor_msgs', output='screen',
             parameters=[base_cfg, caddy_cfg]),
    ])
