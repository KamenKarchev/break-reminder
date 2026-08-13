cmake_minimum_required(VERSION 3.16)
project(break-reminder-korg-helper)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(KPim6Akonadi REQUIRED)
find_package(KF6CalendarCore REQUIRED)

add_executable(break-reminder-korg-helper main.cpp)
target_link_libraries(break-reminder-korg-helper
    Qt6::Core
    KPim6::AkonadiCore
    KF6::CalendarCore
)
