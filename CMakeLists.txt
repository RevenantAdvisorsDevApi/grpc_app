cmake_minimum_required(VERSION 3.20)
project(MarketDataGRPC LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# -------------------------------
# Automatically detect vcpkg on Windows
# -------------------------------
if (WIN32 AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    if(DEFINED ENV{VCPKG_ROOT})
        set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
            CACHE STRING "Vcpkg toolchain file")
    elseif(EXISTS "$ENV{USERPROFILE}/vcpkg/scripts/buildsystems/vcpkg.cmake")
        set(CMAKE_TOOLCHAIN_FILE "$ENV{USERPROFILE}/vcpkg/scripts/buildsystems/vcpkg.cmake"
            CACHE STRING "Vcpkg toolchain file")
    endif()
endif()

# -------------------------------
# Find dependencies
# -------------------------------
find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)
find_package(CURL CONFIG REQUIRED)
find_package(Threads REQUIRED)

# Include directories
include_directories(${Protobuf_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_BINARY_DIR})  # for generated proto files

# -------------------------------
# Proto files
# -------------------------------
set(PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/proto")
set(PROTO_FILES "${PROTO_DIR}/market.proto")
set(GENERATED_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
file(MAKE_DIRECTORY ${GENERATED_SRC_DIR})

# Detect protoc and grpc plugin
if(NOT Protobuf_PROTOC_EXECUTABLE)
    find_program(Protobuf_PROTOC_EXECUTABLE protoc)
endif()
if(NOT gRPC_CPP_PLUGIN_EXECUTABLE)
    find_program(gRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
endif()

# Generate C++ and gRPC code from proto
foreach(proto_file ${PROTO_FILES})
    get_filename_component(proto_name ${proto_file} NAME_WE)

    set(proto_src "${GENERATED_SRC_DIR}/${proto_name}.pb.cc")
    set(proto_hdr "${GENERATED_SRC_DIR}/${proto_name}.pb.h")
    set(grpc_src "${GENERATED_SRC_DIR}/${proto_name}.grpc.pb.cc")
    set(grpc_hdr "${GENERATED_SRC_DIR}/${proto_name}.grpc.pb.h")

    add_custom_command(
        OUTPUT ${proto_src} ${proto_hdr} ${grpc_src} ${grpc_hdr}
        COMMAND ${Protobuf_PROTOC_EXECUTABLE}
        ARGS --grpc_out=${GENERATED_SRC_DIR} --cpp_out=${GENERATED_SRC_DIR}
             --plugin=protoc-gen-grpc=${gRPC_CPP_PLUGIN_EXECUTABLE}
             -I ${PROTO_DIR}
             ${proto_file}
        DEPENDS ${proto_file}
        COMMENT "Generating C++ and gRPC files from ${proto_file}"
        VERBATIM
    )

    list(APPEND PROTO_SRCS ${proto_src} ${grpc_src})
    list(APPEND PROTO_HDRS ${proto_hdr} ${grpc_hdr})
endforeach()

# -------------------------------
# Executables
# -------------------------------
add_executable(server src/server.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(server PRIVATE gRPC::grpc++ protobuf::libprotobuf CURL::libcurl Threads::Threads)

add_executable(client_app src/client.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(client_app PRIVATE gRPC::grpc++ protobuf::libprotobuf CURL::libcurl Threads::Threads)

add_executable(main_app src/main.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(main_app PRIVATE gRPC::grpc++ protobuf::libprotobuf CURL::libcurl Threads::Threads)

add_executable(test_integration tests/test_basic.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(test_integration PRIVATE gRPC::grpc++ protobuf::libprotobuf CURL::libcurl Threads::Threads)
