
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:32:19 04/20/2017 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_top(
	CLK,
	RESET,
	ENABLE,
	UART_TXD,
	UART_RXD,
	BAUD_OUT,
	LED,
	DUT_ctr_rst,
	DUT_ctr_en,
	DUT_ctr_cmd,
	DUT_ctr_in_process,
	DUT_dout,
	DUT_din,
	DUT_row_addr,
	DUT_col_addr,
	DUT_sub_addr,
	DUT_sram_mode,
	DUT_tid_index,
	DUT_tid_data
    );
input wire CLK;
input wire RESET,ENABLE;
output wire UART_TXD;
input wire UART_RXD;
output wire [5:0] LED;
output wire BAUD_OUT; 

output wire DUT_ctr_rst;
output wire DUT_ctr_en;
output [7:0] DUT_ctr_cmd;
input 		DUT_ctr_in_process;

input [7:0] DUT_dout;
output [7:0]	DUT_din;
output [7:0]	DUT_row_addr;
output [3:0]	DUT_col_addr;
output [3:0]	DUT_sub_addr;
output	DUT_sram_mode;
output [7:0] DUT_tid_index;
input [31:0] DUT_tid_data;

// test block
reg [31:0] counter;

// fun uart


wire [2:0] w_uart_addr;
wire [7:0] w_uart_wdata;
wire [7:0] w_uart_rdata;
wire w_uart_we;
wire w_uart_re;


// UART controller
fifo U_control(
	.Enable(ENABLE), 
	.CLK(CLK), 
	.RESET(RESET), 
	.LED(LED[4:0]),
	.uart_addr_o(w_uart_addr), 
	.uart_wdata_o(w_uart_wdata), 
	.uart_rdata_i(w_uart_rdata), 
	.uart_we_o(w_uart_we), 
	.uart_re_o(w_uart_re),
	.DUT_ctr_rst(DUT_ctr_rst),
	.DUT_ctr_en(DUT_ctr_en),
	.DUT_ctr_cmd(DUT_ctr_cmd),
	.DUT_ctr_in_process(DUT_ctr_in_process),
	.DUT_dout(DUT_dout),
	.DUT_din(DUT_din),
	.DUT_row_addr(DUT_row_addr),
	.DUT_col_addr(DUT_col_addr),
	.DUT_sub_addr(DUT_sub_addr),
	.DUT_sram_mode(DUT_sram_mode),
	.DUT_tid_index(DUT_tid_index),
	.DUT_tid_data(DUT_tid_data)
);


// USB UART
uart_regs Uregs(
.clk         (CLK),
.wb_rst_i    (RESET),
.wb_addr_i   (w_uart_addr),
.wb_dat_i    (w_uart_wdata),
.wb_dat_o    (w_uart_rdata),
.wb_we_i     (w_uart_we),
.wb_re_i     (w_uart_re),
.modem_inputs({~ctsn, dsr_pad_i, ri_pad_i,  dcd_pad_i}), // not use
.stx_pad_o   (UART_TXD),
.srx_pad_i   (UART_RXD),
.rts_pad_o   (rts_internal), 	// not use
.dtr_pad_o   (dtr_pad_o),		// not use
.int_o       (),
.baud_o		(BAUD_OUT)
);


endmodule
