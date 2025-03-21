-- xmake.lua for OSRM-backend
-- Generated based on CMakeLists.txt

-- Set project info
set_project("OSRM")
set_version("6.0.0")
set_languages("c++20")  -- Changed to C++20
set_license("BSD-2-Clause")

-- Add build options
option("enable_assertions", {description = "Use assertions in release mode", default = false})
option("enable_ccache", {description = "Speed up incremental rebuilds via ccache", default = true})
option("enable_clang_tidy", {description = "Enables clang-tidy checks", default = false})
option("enable_conan", {description = "Use conan for dependencies", default = false})
option("enable_coverage", {description = "Build with coverage instrumentalisation", default = false})
option("enable_debug_logging", {description = "Use debug logging in release mode", default = false})
option("enable_fuzzing", {description = "Fuzz testing using LLVM's libFuzzer", default = false})
option("enable_lto", {description = "Use Link Time Optimisation", default = true})
option("enable_node_bindings", {description = "Build NodeJs bindings", default = false})
option("enable_sanitizer", {description = "Use memory sanitizer for Debug build", default = false})

-- Set build modes
if is_mode("debug") then
    add_defines("BOOST_ENABLE_ASSERT_HANDLER")
    add_defines("ENABLE_DEBUG_LOGGING")
end

-- Add required packages
add_requires("boost 1.85.0", {configs = {
    date_time = true,
    iostreams = true,
    program_options = true,
    thread = true,
    unit_test_framework = true,
    regex = true,
    python = false,
    coroutine = false,
    stacktrace = false,
    cobalt = false
}})
add_requires("tbb 2021.12.0")
add_requires("expat 2.6.2")
add_requires("bzip2 1.0.8", {configs = {shared = true}})
add_requires("lua 5.4.6")
add_requires("zlib 1.3.1")
add_requires("xz", {configs = {shared = true}})

-- Set option for conan integration
set_policy("package.requires_lock", false)

-- Skip flatbuffers test package
set_policy("build.across_targets_in_parallel", false)
before_build(function(target)
    if target:name() == "test_package" then
        target:set("enabled", false)
    end
end)

-- Parse version from package.json
local version_major = "6"
local version_minor = "0"
local version_patch = "0"
local version_prerelease_build = ""

-- Generate version.hpp
after_load(function (target)
    local version_file = path.join(os.projectdir(), "include/util/version.hpp")
    local content = [[
#ifndef VERSION_HPP
#define VERSION_HPP

#define OSRM_VERSION_MAJOR               ]] .. version_major .. [[

#define OSRM_VERSION_MINOR               ]] .. version_minor .. [[

#define OSRM_VERSION_PATCH               ]] .. version_patch .. [[

#define OSRM_VERSION_PRERELEASE_BUILD    "]] .. version_prerelease_build .. [["

#define OSRM_VERSION__(A,B,C,D) "v" #A "." #B "." #C D
#define OSRM_VERSION_(A,B,C,D) OSRM_VERSION__(A,B,C,D)
#define OSRM_VERSION OSRM_VERSION_(OSRM_VERSION_MAJOR, OSRM_VERSION_MINOR, OSRM_VERSION_PATCH, OSRM_VERSION_PRERELEASE_BUILD)

#endif // VERSION_HPP
]]
    io.writefile(version_file, content)
end)

-- Add include directories
add_includedirs("include")
add_includedirs("generated/include", {public = true})
add_includedirs("third_party/sol2/include", {public = true})
add_includedirs("third_party/rapidjson/include", {public = true})
add_includedirs("third_party/microtar/src", {public = true})
add_includedirs("third_party/protozero/include", {public = true})
add_includedirs("third_party/vtzero/include", {public = true})
add_includedirs("third_party/flatbuffers/include", {public = true})
add_includedirs("third_party/fmt/include", {public = true})
add_includedirs("third_party/libosmium/include", {public = true})

-- Add common definitions
add_defines("BOOST_SPIRIT_USE_PHOENIX_V3", "BOOST_RESULT_OF_USE_DECLTYPE", "BOOST_PHOENIX_STL_TUPLE_H_", "FMT_HEADER_ONLY")
add_defines("OSRM_PROJECT_DIR=\"" .. os.projectdir() .. "\"")
add_defines("BOOST_VARIANT_USE_RELAXED_GET_BY_DEFAULT")
add_defines("USE_BOOST_VARIANT")
add_defines("BOOST_ASIO_USE_TS_EXECUTOR_AS_DEFAULT")
add_defines("BOOST_BIND_GLOBAL_PLACEHOLDERS")

-- Add build directory to environment
if not is_plat("windows") then
    set_config("buildir", "build")
    -- Use os.setenv is not available in xmake, so we'll skip this
    -- os.setenv("OSRM_BUILD_DIR", "$(buildir)")
end

-- Configure compiler flags
if is_plat("windows") then
    add_defines("WIN32_LEAN_AND_MEAN", "BOOST_LIB_DIAGNOSTIC", "_CRT_SECURE_NO_WARNINGS", "NOMINMAX", "_WIN32_WINNT=0x0501", "XML_STATIC")
    add_syslinks("ws2_32", "wsock32")
elseif is_plat("linux") then
    add_syslinks("rt")
    add_cxxflags("-ftemplate-depth=1024", "-fno-strict-aliasing", "-std=c++20", "-fpermissive")
    add_includedirs("include/osrm")  -- Add the osrm include directory for the PCH
end

-- Define microtar library
target("microtar")
    set_kind("object")
    add_files("third_party/microtar/src/microtar.c")
    set_warnings("none", {
        flags = {"-Wno-unused-variable", "-Wno-format"}
    })
    add_cflags("-fPIC")

-- Define utility library
target("util")
    set_kind("object")
    add_files("src/util/*.cpp", "src/util/*/*.cpp")
    add_packages("boost", "tbb", "zlib")
    add_cxxflags("-fPIC")

-- Define extractor library
target("extractor")
    set_kind("object")
    add_files("src/extractor/*.cpp", "src/extractor/*/*.cpp")
    add_packages("boost", "tbb", "expat", "bzip2", "lua", "zlib")
    add_cxxflags("-fPIC")

-- Define guidance library
target("guidance")
    set_kind("object")
    add_files("src/guidance/*.cpp")
    add_packages("boost", "tbb", "lua")
    add_cxxflags("-fPIC")

-- Define partitioner library
target("partitioner")
    set_kind("object")
    add_files("src/partitioner/*.cpp")
    add_packages("boost", "tbb")
    add_cxxflags("-fPIC")

-- Define customizer library
target("customizer")
    set_kind("object")
    add_files("src/customize/*.cpp")
    add_packages("boost", "tbb", "zlib")
    add_cxxflags("-fPIC")

-- Define contractor library
target("contractor")
    set_kind("object")
    add_files("src/contractor/*.cpp")
    add_packages("boost", "tbb", "lua")
    add_cxxflags("-fPIC")

-- Define updater library
target("updater")
    set_kind("object")
    add_files("src/updater/*.cpp")
    add_packages("boost", "tbb", "zlib")
    add_cxxflags("-fPIC")

-- Define storage library
target("storage")
    set_kind("object")
    add_files("src/storage/*.cpp")
    add_packages("boost", "tbb")
    add_cxxflags("-fPIC")

-- Define engine library
target("engine")
    set_kind("object")
    add_files("src/engine/*.cpp", "src/engine/**/*.cpp")
    add_packages("boost", "tbb", "zlib")
    add_cxxflags("-fPIC")

-- Define server library
target("server")
    set_kind("static")
    add_files("src/server/*.cpp", "src/server/**/*.cpp")
    add_packages("boost", "tbb", "zlib")
    add_cxxflags("-fPIC")
    add_defines("BOOST_IOSTREAMS_USE_ZLIB")
    add_syslinks("boost_iostreams", "z")
    if is_plat("windows") then
        add_syslinks("ws2_32", "wsock32")
    end

-- Define main libraries
target("osrm")
    set_kind("shared")
    add_files("src/osrm/osrm.cpp")
    add_deps("engine", "storage", "microtar", "util")
    add_packages("boost", "tbb", "zlib")

target("osrm_contract")
    set_kind("shared")
    add_files("src/osrm/contractor.cpp")
    add_deps("contractor", "util", "storage", "updater", "microtar")
    add_packages("boost", "tbb", "lua")
    add_deps("osrm_update", "osrm_store")

target("osrm_extract")
    set_kind("shared")
    add_files("src/osrm/extractor.cpp")
    add_deps("extractor", "microtar", "util", "guidance")
    add_deps("osrm_guidance")
    add_packages("boost", "tbb", "expat", "bzip2", "lua", "zlib")

target("osrm_guidance")
    set_kind("shared")
    add_deps("guidance", "util")
    add_packages("boost", "tbb", "lua")

target("osrm_partition")
    set_kind("shared")
    add_files("src/osrm/partitioner.cpp")
    add_deps("partitioner", "microtar", "util")
    add_packages("boost", "tbb")

target("osrm_update")
    set_kind("shared")
    add_deps("updater", "microtar", "util")
    add_packages("boost", "tbb", "zlib")

target("osrm_store")
    set_kind("shared")
    add_deps("storage", "microtar", "util")
    add_packages("boost", "tbb")

target("osrm_customize")
    set_kind("shared")
    add_files("src/osrm/customizer.cpp")
    add_deps("customizer", "microtar", "util", "osrm_update", "osrm_store", "updater")
    add_packages("boost", "tbb", "zlib")

-- Define executables
target("osrm-extract")
    set_kind("binary")
    add_files("src/tools/extract.cpp")
    add_deps("osrm_extract")
    add_packages("boost")

target("osrm-partition")
    set_kind("binary")
    add_files("src/tools/partition.cpp")
    add_deps("osrm_partition")
    add_packages("boost")

target("osrm-customize")
    set_kind("binary")
    add_files("src/tools/customize.cpp")
    add_deps("osrm_customize", "storage")
    add_packages("boost")

target("osrm-contract")
    set_kind("binary")
    add_files("src/tools/contract.cpp")
    add_deps("osrm_contract", "storage", "updater")
    add_packages("boost")

target("osrm-datastore")
    set_kind("binary")
    add_files("src/tools/store.cpp")
    add_deps("microtar", "util", "osrm_store", "storage")
    add_packages("boost")

target("osrm-routed")
    set_kind("binary")
    add_files("src/tools/routed.cpp")
    add_deps("server", "util", "osrm")
    add_packages("boost", "zlib")
    add_defines("BOOST_IOSTREAMS_USE_ZLIB")
    add_syslinks("boost_iostreams", "z")
    if is_plat("windows") then
        add_syslinks("ws2_32", "wsock32")
    end

target("osrm-components")
    set_kind("binary")
    add_files("src/tools/components.cpp")
    add_deps("microtar", "util")
    add_packages("tbb", "boost")

target("osrm-io-benchmark")
    set_kind("binary")
    add_files("src/tools/io-benchmark.cpp")
    add_deps("util")
    add_packages("boost", "tbb")

-- Task to generate compile_commands.json
task("gen_compile_commands")
    set_category("plugin")
    on_run(function ()
        os.exec("xmake project -k compile_commands")
        if not os.isdir("build") then
            os.mkdir("build")
        end
        os.mv("compile_commands.json", "build/compile_commands.json")
        cprint("${bright green}compile_commands.json has been generated in the build directory")
    end)
    set_menu {
        usage = "xmake gen_compile_commands",
        description = "Generate compile_commands.json file in build directory"
    }