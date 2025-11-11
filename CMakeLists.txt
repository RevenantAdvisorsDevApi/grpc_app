cmake_minimum_required(VERSION 3.20)
project(MarketDataGRPC LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# -------------------------------
# Find dependencies
# -------------------------------
find_package(Protobuf REQUIRED)
find_package(Threads REQUIRED)
find_package(CURL REQUIRED)

# gRPC via pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(GRPC REQUIRED grpc++ grpc)
include_directories(${GRPC_INCLUDE_DIRS})
link_directories(${GRPC_LIBRARY_DIRS})
add_definitions(${GRPC_CFLAGS_OTHER})

# Include directories
include_directories(${Protobuf_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_BINARY_DIR}) # for generated proto files

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
# Client library
# -------------------------------
add_library(client_lib src/client.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(client_lib PRIVATE ${GRPC_LIBRARIES} protobuf curl Threads::Threads)

# -------------------------------
# Server executable
# -------------------------------
add_executable(server src/server.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(server PRIVATE ${GRPC_LIBRARIES} protobuf curl Threads::Threads)

# -------------------------------
# Main app executable
# -------------------------------
add_executable(main_app src/main.cpp ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(main_app PRIVATE client_lib ${GRPC_LIBRARIES} protobuf curl Threads::Threads)

# -------------------------------
# Optional test
# -------------------------------
#add_executable(test_integration tests/test_basic.cpp ${PROTO_SRCS} ${PROTO_HDRS})
#target_link_libraries(test_integration PRIVATE client_lib ${GRPC_LIBRARIES} protobuf curl Threads::Threads)
