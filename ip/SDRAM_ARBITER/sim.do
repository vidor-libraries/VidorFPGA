vlog -reportprogress 300 -work work ../FBST/FBST.v
vlog -reportprogress 300 -work work sdram_arbiter_tb.v
vlog -reportprogress 300 -work work SDRAM_ARBITER.v

vsim -gui work.sdram_arbiter_tb -L altera_mf_ver
add wave -position insertpoint -radix hex \
-divider "clocks" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*CLK \
-divider "FB IF" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*FB* \
-divider "MIPI IF" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*MIPI* \
-divider "AVL" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*AVL* \
-divider "SDRAM" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*SDRAM* \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*ADDRESS* \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*BURST* \
sim:/sdram_arbiter_tb/sdram_arbiter_0/*CLIENT* \
sim:/sdram_arbiter_tb/sdram_arbiter_0/rREAD \
sim:/sdram_arbiter_tb/sdram_arbiter_0/rWRITE \
-divider "mipi fifo" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/mipi_fifo/rdreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/mipi_fifo/wrreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/mipi_fifo/rdempty  \
sim:/sdram_arbiter_tb/sdram_arbiter_0/mipi_fifo/rdusedw \
-divider "fbfifo" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/fb_fifo/rdreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/fb_fifo/wrreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/fb_fifo/wrusedw \
-divider "fbfifo2" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/fb_fifo2/rdreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/fb_fifo2/wrreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/fb_fifo2/w_wrusedw \
-divider "cmd" \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/data \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/empty \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/full \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/q \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/rdreq \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/usedw \
sim:/sdram_arbiter_tb/sdram_arbiter_0/cmd_fifo/wrreq
run 1 ms
