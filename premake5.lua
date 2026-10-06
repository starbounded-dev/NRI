-- NRI (NVIDIA Render Interface) premake5 build for LuxEngine.
-- Mirrors CMakeLists.txt for the parts Lux uses: NRI-Shared, NRI-VK, NRI-Validation, NRI-NONE, NRI.
-- Not built: D3D11/D3D12 (Lux is Vulkan-only), WGPU, NVTX, the NRIImgui extension and the
-- upscaler SDKs (NGX/FFX/XeSS/NIS); CMake defaults the SDKs off as well.
--
-- Expects the workspace global "outputdir". Vulkan headers are NRI's own (External/VulkanHeaders,
-- the version CMake fetches): NRI needs newer extensions than the engine's Vulkan SDK may have, and
-- NRI's public headers carry no Vulkan types, so the engine keeps compiling against its SDK.

local NRI_DIR = path.getabsolute(".")

-- CMake passes these to every target (COMPILE_DEFINITIONS + NRI_Shared's public defines).
local NRI_COMMON_DEFINES = {
	"NRI_STATIC_LIBRARY=1",
	"NRI_ENABLE_VK_SUPPORT=1",
	"NRI_ENABLE_VALIDATION_SUPPORT=1",
	"NRI_ENABLE_NONE_SUPPORT=1",
	"NRI_ENABLE_DEBUG_NAMES_AND_ANNOTATIONS=1",
	"NRI_STREAMER_THREAD_SAFE=1",
	"WIN32_LEAN_AND_MEAN",
	"NOMINMAX",
	"_CRT_SECURE_NO_WARNINGS"
}

local function NRICommonSettings()
	language "C++"
	cppdialect "C++17"
	staticruntime "off"

	targetdir ("bin/" .. outputdir .. "/%{prj.name}")
	objdir ("bin-int/" .. outputdir .. "/%{prj.name}")

	defines(NRI_COMMON_DEFINES)

	includedirs {
		NRI_DIR .. "/Include",
		NRI_DIR .. "/Source/Shared",
	}

	externalincludedirs {
		NRI_DIR .. "/External/VulkanHeaders/include",
	}

	filter "system:windows"
		systemversion "latest"
	filter "system:linux"
		-- Window-system support; the matching VK_USE_PLATFORM_* macros are NRI-VK only (as in
		-- CMake), so no other NRI translation unit pulls in X11's global "Window" typedef.
		defines {
			"NRI_ENABLE_XLIB_SUPPORT=1",
			"NRI_ENABLE_WAYLAND_SUPPORT=1",
		}
	filter {}

	-- Suppress warnings in vendor code
	filter "action:vs*"
		buildoptions { "/w" }
	filter "toolset:gcc or toolset:clang"
		buildoptions { "-w" }
	filter {}

	-- Match the engine's runtime library per config so the static libs link into every Lux
	-- target without an _ITERATOR_DEBUG_LEVEL mismatch. Optimisation, symbols, LTO and the
	-- Debug-AS sanitizer come from the workspace filters.
	filter "configurations:Debug or configurations:Debug-AS"
		runtime "Debug"
	filter "configurations:Release or configurations:Dist"
		runtime "Release"
	filter {}
end

----------------------------------------------------------------------
-- NRI-Shared: helper, streamer, upscaler (stub) and imgui interfaces
----------------------------------------------------------------------
project "NRI-Shared"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/NRIConfig.h",
		NRI_DIR .. "/Source/Shared/Shared.cpp",
		NRI_DIR .. "/Source/Shared/**.h",
		NRI_DIR .. "/Source/Shared/**.hpp",
	}

----------------------------------------------------------------------
-- NRI-VK: Vulkan backend
-- ImplVK.cpp is a single translation unit that #includes every .hpp
----------------------------------------------------------------------
project "NRI-VK"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/VK/ImplVK.cpp",
		NRI_DIR .. "/Source/VK/**.h",
		NRI_DIR .. "/Source/VK/**.hpp",
		NRI_DIR .. "/External/VMA/vk_mem_alloc.h",
	}

	includedirs {
		NRI_DIR .. "/Source/VK",
	}

	-- The VMA copy CMake pins (VMA_IMPLEMENTATION lives in MemoryAllocatorVK.h).
	externalincludedirs {
		NRI_DIR .. "/External/VMA",
	}

	filter "system:windows"
		defines { "VK_USE_PLATFORM_WIN32_KHR" }
	filter "system:linux"
		defines {
			"VK_USE_PLATFORM_XLIB_KHR",
			"VK_USE_PLATFORM_WAYLAND_KHR",
		}
	filter {}

----------------------------------------------------------------------
-- NRI-Validation: validation layer over any backend
-- ImplVal.cpp is a single translation unit that #includes every .hpp
----------------------------------------------------------------------
project "NRI-Validation"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/Validation/ImplVal.cpp",
		NRI_DIR .. "/Source/Validation/**.h",
		NRI_DIR .. "/Source/Validation/**.hpp",
	}

	includedirs {
		NRI_DIR .. "/Source/Validation",
	}

----------------------------------------------------------------------
-- NRI-NONE: dummy backend
----------------------------------------------------------------------
project "NRI-NONE"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/NONE/ImplNONE.cpp",
	}

----------------------------------------------------------------------
-- NRI: device creation and interface lookup
-- Link order for GNU ld (Dependencies.lua): NRI, NRI-VK, NRI-Validation, NRI-NONE, NRI-Shared.
----------------------------------------------------------------------
project "NRI"
	kind "StaticLib"
	NRICommonSettings()

	files {
		NRI_DIR .. "/Source/Creation/Creation.cpp",
		NRI_DIR .. "/Include/**.h",
		NRI_DIR .. "/Include/**.hlsl",
	}

	filter "files:**.hlsl"
		flags { "ExcludeFromBuild" }
	filter {}
