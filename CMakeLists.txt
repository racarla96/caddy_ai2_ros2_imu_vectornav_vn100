cmake_minimum_required(VERSION 3.8)
project(caddy_ai2_ros2_imu_vectornav_vn100)

find_package(ament_cmake REQUIRED)

install(DIRECTORY urdf config launch udev description
  DESTINATION share/${PROJECT_NAME})

# Simulation parameters, read by caddy_ai2_ros2_gazebo_simulation/spawn_robot.launch.py
install(DIRECTORY bringup
  DESTINATION share/${PROJECT_NAME})

install(PROGRAMS scripts/install_driver.sh
  DESTINATION lib/${PROJECT_NAME})

ament_package()
