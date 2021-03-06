option(USE_CROSS_COMPILE "set use cross compile or not" ON)
option(USE_GNU_GCC "set use GNU gcc compiler or not" OFF)
option(USE_LLVM_CLANG "set use LLVM clang compiler or not" OFF)
option(USE_DEBUG "set use debug information or not" OFF)
option(USE_DYNAMIC_LIBRARY "set use dynamic library or not" OFF)
option(USE_MINSIZEREL ".so lib will be 300KB smaller but performance will be affected" OFF)

# model-tools variable
option(USE_CAFFE "set use caffe model as input or not" ON)
option(USE_ONNX "set use onnx model as input or not" ON)
option(USE_TFLITE "set use tflite model as input or not" ON)

# blas-enhance tensor_computing
option(USE_GENERAL "set use CPU serial code or not" ON)
option(USE_NEON "set use ARM NEON instruction or not" ON)
option(USE_ARMV7 "set use ARMv7 NEON instruction or not" OFF)
option(USE_ARMV8 "set use ARMv8 NEON instruction or not" ON)
option(USE_FP32 "set use ARM NEON FP32 instruction or not" ON)
option(USE_FP16 "set use ARM NEON FP16 instruction or not" ON)
option(USE_F16_MIX_PRECISION "set use ARM NEON mix precision f16/f32 instruction or not" ON)
option(USE_INT8 "set use ARM NEON INT8 instruction or not" ON)
option(BUILD_TEST "set to build unit test or not" OFF)
option(USE_OPENMP "set use OpenMP for parallel or not" ON)
option(USE_MALI "set use mali for parallel or not" ON)
option(USE_LIBRARY_TUNING "set use algorithm tuning or not" ON)

set(BOLT_ROOT $ENV{BOLT_ROOT})

function (set_policy)
    cmake_policy(SET CMP0074 NEW)
endfunction(set_policy)

macro (set_c_cxx_flags)
    set(COMMON_FLAGS "-W -Wall -Wextra -Wno-unused-command-line-argument -Wno-unused-parameter -O3")

    if (USE_LIBRARY_TUNING)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_LIBRARY_TUNING")
    endif(USE_LIBRARY_TUNING)

    if (BUILD_TEST)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_BUILD_TEST")
    endif(BUILD_TEST)

    if (USE_DEBUG)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_DEBUG")
        if (USE_LLVM_CLANG)
            set(COMMON_FLAGS "${COMMON_FLAGS} -llog")
        endif(USE_LLVM_CLANG)
    endif(USE_DEBUG)

    if (USE_GENERAL)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_GENERAL")
    endif(USE_GENERAL)

    if (USE_MALI)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_MALI")
    endif(USE_MALI)
    
    if (USE_NEON)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_NEON")

        if (USE_ARMV8)
            set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_ARMV8")
        endif (USE_ARMV8)

        if (USE_ARMV7)
            set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_ARMV7 -march=armv7-a -mfloat-abi=softfp -mfpu=neon-vfpv4")
            if (USE_LLVM_CLANG)
                set(COMMON_FLAGS "${COMMON_FLAGS} -Wl,--allow-multiple-definition")
            endif (USE_LLVM_CLANG)
        endif (USE_ARMV7)

        if (USE_FP32)
            set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_FP32")
        endif (USE_FP32)

        if (USE_FP16)
            set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_FP16")
            if (USE_F16_MIX_PRECISION)
                set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_F16_MIX_PRECISION")
            endif (USE_F16_MIX_PRECISION)
            if (USE_INT8)
                if (USE_LLVM_CLANG)
                    set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_INT8 -march=armv8-a+fp16+dotprod")
                else (USE_LLVM_CLANG)
                    set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_INT8 -march=armv8.2-a+fp16+dotprod")
                endif (USE_LLVM_CLANG)
            else (USE_INT8)
                if (USE_LLVM_CLANG)
                    set(COMMON_FLAGS "${COMMON_FLAGS} -march=armv8-a+fp16")
                else (USE_LLVM_CLANG)
                    set(COMMON_FLAGS "${COMMON_FLAGS} -march=armv8.2-a+fp16")
                endif (USE_LLVM_CLANG)
            endif (USE_INT8)
        endif (USE_FP16)
    endif(USE_NEON)

    if (USE_CAFFE)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_CAFFE_MODEL")
    endif()
    if (USE_ONNX)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_ONNX_MODEL")
    endif()
    if (USE_TFLITE)
        set(COMMON_FLAGS "${COMMON_FLAGS} -D_USE_TFLITE_MODEL")
    endif()

    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} ${COMMON_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")
    link_libraries("-static-libstdc++")

    if (USE_DEBUG)
        set(CMAKE_BUILD_TYPE "Debug")
    elseif (USE_MINSIZEREL)
        set(CMAKE_BUILD_TYPE "MinSizeRel")
    endif (USE_DEBUG)
endmacro(set_c_cxx_flags)

macro (set_test_c_cxx_flags)
    if (${USE_DYNAMIC_LIBRARY} STREQUAL "OFF")
        if (USE_CROSS_COMPILE)
            if (USE_GNU_GCC)
                set(COMMON_FLAGS "${COMMON_FLAGS} -static")
            endif(USE_GNU_GCC)
        endif(USE_CROSS_COMPILE)
    endif(${USE_DYNAMIC_LIBRARY} STREQUAL "OFF")
    
    if (USE_LLVM_CLANG)
        if (${USE_DYNAMIC_LIBRARY} STREQUAL "OFF")
            set(COMMON_FLAGS "${COMMON_FLAGS} -Wl,-allow-shlib-undefined, -static-libstdc++")
        else (${USE_DYNAMIC_LIBRARY} STREQUAL "OFF")
            set(COMMON_FLAGS "${COMMON_FLAGS} -Wl,-allow-shlib-undefined")
        endif(${USE_DYNAMIC_LIBRARY} STREQUAL "OFF")
    endif(USE_LLVM_CLANG)

    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} ${COMMON_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")
endmacro (set_test_c_cxx_flags)

macro (set_project_install_directory)
    SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
    SET(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)
endmacro (set_project_install_directory)

function(blas_enhance name)
    add_executable(${name} ${name}.cpp)
    add_dependencies(${name} blas-enhance)
    add_dependencies(${name} blas-enhance_static)
    target_link_libraries(${name} ${BLAS_ENHANCE_LIBRARY})
endfunction()

function(tensor_computing name)
    add_executable(${name} ${name}.cpp)
    add_dependencies(${name} tensor_computing)
    add_dependencies(${name} tensor_computing_static)
    target_link_libraries(${name} ${TENSOR_COMPUTING_LIBRARIES})
    if(USE_MALI)
        target_link_libraries(${name} ${OPENCL_LIBRARIES})
    endif(USE_MALI)
endfunction()

function(image name)
    add_executable(${name} ${name}.cpp)
    add_dependencies(${name} image)
    add_dependencies(${name} image_static)
    target_link_libraries(${name} ${IMAGE_LIBRARIES})
endfunction()

function(model_tools name)
    add_executable(${name} ${name}.cpp)
    if (USE_CAFFE)
        add_dependencies(${name} model-tools)
        add_dependencies(${name} model-tools_static)
        add_dependencies(${name} model-tools_caffe)
        add_dependencies(${name} model-tools_caffe_static)
        TARGET_LINK_LIBRARIES(${name} ${MODEL_TOOLS_LIBRARIES})
    endif (USE_CAFFE)

    if (USE_ONNX)
        add_dependencies(${name} model-tools)
        add_dependencies(${name} model-tools_static)
        add_dependencies(${name} model-tools_onnx)
        add_dependencies(${name} model-tools_onnx_static)
        TARGET_LINK_LIBRARIES(${name} ${MODEL_TOOLS_LIBRARIES})
    endif (USE_ONNX)

    if (USE_TFLITE)
        add_dependencies(${name} model-tools)
        add_dependencies(${name} model-tools_static)
        add_dependencies(${name} model-tools_tflite)
        add_dependencies(${name} model-tools_tflite_static)
        TARGET_LINK_LIBRARIES(${name} ${MODEL_TOOLS_LIBRARIES})
    endif (USE_TFLITE)
endfunction()

function(inference name src_name)
    add_executable(${name} ${src_name})
    if (USE_DYNAMIC_LIBRARY)
        TARGET_LINK_LIBRARIES(${name} inference)
    else (USE_DYNAMIC_LIBRARY)
        TARGET_LINK_LIBRARIES(${name} inference_static)
    endif (USE_DYNAMIC_LIBRARY)
    TARGET_LINK_LIBRARIES(${name} ${INFERENCE_LIBRARIES} ${JPEG_LIBRARY})
    if (USE_MALI)
        TARGET_LINK_LIBRARIES(${name} ${KERNELBIN_LIBRARIES} ${OPENCL_LIBRARIES})
    endif (USE_MALI)
endfunction()
