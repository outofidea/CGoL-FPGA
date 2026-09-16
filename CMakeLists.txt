cmake_minimum_required(VERSION 4.2.3)
project(CGoL_sim)

find_package(SDL3 REQUIRED CONFIG REQUIRED COMPONENTS SDL3-shared)
find_package(verilator)

add_subdirectory(rtl)

set(RTL_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/rtl)

set(VERILATION_SOURCES
	${RTL_SOURCE_DIR}/game/cell_address_package.sv
	${RTL_SOURCE_DIR}/display/disp_data_package.sv

	${RTL_SOURCE_DIR}/misc/debounce.sv

	${RTL_SOURCE_DIR}/game/state_bram.sv
	${RTL_SOURCE_DIR}/game/state.sv
	${RTL_SOURCE_DIR}/game/life.sv

	${RTL_SOURCE_DIR}/display/lcd.sv
	${RTL_SOURCE_DIR}/display/display.sv

	${RTL_SOURCE_DIR}/top_sim.sv
)

add_executable(sim_top ./sim_src/sim_top.cpp)
verilate(
	sim_top
	SOURCES
	${VERILATION_SOURCES}
    TOP_MODULE top_sim
    PREFIX Vtop_sim
	VERILATOR_ARGS
	--Wno-WIDTHEXPAND
	--Wno-WIDTHTRUNC
)