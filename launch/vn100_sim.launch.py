"""Puente ros_gz_bridge del VN-100 simulado (el sensor se declara en el URDF/xacro).

La simulación del vehículo debe cargar en el mundo los sistemas de sensores:
  gz-sim-sensors-system (render_engine no necesario para IMU),
  gz-sim-imu-system, gz-sim-magnetometer-system, gz-sim-air-pressure-system.
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    pkg = get_package_share_directory('caddy_ai2_ros2_imu_vectornav_vn100')
    bridge_cfg = os.path.join(pkg, 'config', 'vn100_gz_bridge.yaml')

    use_sim_time = LaunchConfiguration('use_sim_time')

    bridge = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        name='vn100_gz_bridge',
        output='screen',
        parameters=[{
            'config_file': bridge_cfg,
            'use_sim_time': use_sim_time,
        }],
    )

    return LaunchDescription([
        DeclareLaunchArgument('use_sim_time', default_value='true'),
        bridge,
    ])
