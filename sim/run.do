# Run this script from the workspace root:
#   vsim -do sim/run.do

if {![file exists work]} {
    vlib work
}

vcom -93 src/spi_master.vhd
vcom -93 tb/tb_spi_master.vhd
vsim work.tb_spi_master
add wave -r /*
run 2 us
quit -f
