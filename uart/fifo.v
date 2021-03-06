
//`define UART_HEX
`define UART_BIN


module fifo(
	Enable, 
	CLK, 
	RESET, 
	LED,
	uart_addr_o, 
	uart_wdata_o, 
	uart_rdata_i, 
	uart_we_o, 
	uart_re_o,
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

//=================================================================================================================
// paramaters 

parameter DATA_WIDTH = 12; // real width of lst file  : equal to number of scan_cell  
parameter DATA_DEPTH = 8;


parameter DATA_BIT = 8;
parameter LED_BIT = 5;

parameter ST_IDLE  = 8'd0;
parameter ST_DL_MSB  = 8'd1;
parameter ST_DL_LSB  = 8'd2;
parameter ST_LCR  = 8'd3;
parameter ST_FCR  = 8'd4;
parameter ST_IER  = 8'd5;
parameter ST_SEND_TEST_CHAR  = 8'd6;
parameter ST_READ_LSR  = 8'd7;
parameter ST_CHECK_LSR  = 8'd8;
parameter ST_READ_DATA_COME  = 8'd9;
parameter ST_SEND_TEST_CHAR_WAIT  = 8'd10;

parameter ST_READ_DUT_INIT  = 8'd11;
parameter ST_READ_DUT_PRE  = 8'd12;
parameter ST_READ_DUT  = 8'd13;
parameter ST_READ_DUT_WAIT  = 8'd14;
parameter ST_SEND_DUT_DATA_UART  = 8'd15;
parameter ST_READ_DUT_COUNT_ADDR  = 8'd16;
parameter ST_SEND_DUT_DATA_UART_WAIT  = 8'd17;

parameter ST_WRITE_DUT_INIT  = 8'd18;
parameter ST_WRITE_DUT_PRE  = 8'd19;
parameter ST_WRITE_DUT  = 8'd20;
parameter ST_WRITE_DUT_WAIT  = 8'd21;
parameter ST_WRITE_DUT_COUNT_ADDR  = 8'd22;

parameter ST_SER_DUT_INIT = 8'd23;
parameter ST_SER_DUT_READ_PRE = 8'd24;
parameter ST_SER_DUT_READ = 8'd25;
parameter ST_SER_DUT_READ_WAIT = 8'd26;
parameter ST_SER_DUT_SEND_DATA_UART = 8'd27;
parameter ST_SER_DUT_SEND_DATA_UART_WAIT = 8'd28;
parameter ST_SER_DUT_REWRITE_PRE = 8'd29;
parameter ST_SER_DUT_REWRITE = 8'd30;
parameter ST_SER_DUT_REWRITE_WAIT = 8'd31;
parameter ST_SER_DUT_COUNT_ADDR = 8'd32;
parameter ST_SER_DUT_CHECK_DATA = 8'd33;
parameter ST_READ_DUT_CHECK_DATA = 8'd34;

parameter ST_TID = 8'd35;
parameter ST_TID_PRE = 8'd36;
parameter ST_TID_START = 8'd37;
parameter ST_TID_WAIT = 8'd38;
parameter ST_TID_GET_DATA = 8'd39;
parameter ST_TID_GET_DATA_WAIT = 8'd40;
parameter ST_TID_GET_DATA_2 = 8'd41;
parameter ST_TID_GET_DATA_WAIT_2 = 8'd42;
parameter ST_TID_GET_DATA_3 = 8'd43;
parameter ST_TID_GET_DATA_WAIT_3 = 8'd44;
parameter ST_TID_GET_DATA_4 = 8'd45;
parameter ST_TID_GET_DATA_WAIT_4 = 8'd46;
parameter ST_TID_COUNT_ADDR = 8'd47;



// Command table
parameter CM_SEND_TEST_CHAR  = 8'h54; // 'T' = 8'h54
parameter CM_READ_DUT  = 8'h55; // 'U' = 8'h55
parameter CM_WRITE_AA_DUT  = 8'h41; // 'A' = 8'h41
parameter CM_WRITE_00_DUT  = 8'h30; // '0' = 8'h30
parameter CM_WRITE_FF_DUT  = 8'h46; // 'F' = 8'h46
parameter CM_WRITE_A5_DUT  = 8'h35; // '5' = 8'h35
parameter CM_WRITE_55_DUT  = 8'h36; // '6' = 8'h36
parameter CM_SER_DUT_STANDARD  = 8'h45; // 'E' = 8'h45
parameter CM_SER_DUT_RANDOM  = 8'h65; // 'e' = 8'h65
parameter CM_REP_SW0 = 8'h31; // '1'
parameter CM_REP_SW1 = 8'h32; // '2'
parameter CM_REP_SW2 = 8'h33; //'3'

parameter CM_READ_ONE = 8'h72; // 'r', this command has addition paramaters
parameter CM_WRITE_ONE = 8'h77; // 'w' , this command has addition paramaters

parameter CM_TID = 8'h74; // 't' TID sensor check 








//=================================================================================================================
// input, output ports

input wire Enable;
input wire CLK;
input wire RESET;

output [LED_BIT-1:0] LED; // limit 15:0

output reg [2:0] uart_addr_o;
output reg [7:0] uart_wdata_o;
input wire [7:0] uart_rdata_i;
output reg uart_we_o;
output reg uart_re_o;

output wire DUT_ctr_rst;
output wire DUT_ctr_en;
output  [7:0] DUT_ctr_cmd;
input 		DUT_ctr_in_process;
input [7:0] DUT_dout;
output [7:0]	DUT_din;
output [7:0]	DUT_row_addr;
output [3:0]	DUT_col_addr;
output [3:0]	DUT_sub_addr;
output	DUT_sram_mode;
output [7:0] DUT_tid_index;
input [31:0] DUT_tid_data;

//===========================================================================================================================


//===========================================================================================================================
// internal registers

reg [7:0] state;
reg [31:0] r_counter;
reg [31:0] r_counter2;

reg [7:0] r_dut_row_addr;
reg [3:0] r_dut_col_addr;
reg [7:0] r_dut_din;
reg [7:0] r_dut_dout;
reg [7:0] r_dut_dout_tma_0;
reg [7:0] r_dut_dout_tma_1;
reg [7:0] r_dut_dout_tma_2;
reg [7:0] r_dut_ctr_cmd;
reg 		r_dut_ctr_reset_n;
reg		r_dut_ctr_enable;
reg [3:0] r_dut_sub_addr;
reg 		r_dut_sram_mode;

reg [7:0] r_data_pattern;

reg [2:0] r_replica_sw;

reg [7:0] r_tid_index;

wire [7:0] w_dut_dout_tma;

assign DUT_ctr_rst = r_dut_ctr_reset_n;
assign DUT_ctr_en = r_dut_ctr_enable;
assign DUT_ctr_cmd = r_dut_ctr_cmd;
assign DUT_din = r_dut_din;
assign DUT_row_addr = r_dut_row_addr;
assign DUT_col_addr = r_dut_col_addr;
assign DUT_sub_addr = r_dut_sub_addr;
assign DUT_sram_mode = r_dut_sram_mode;
assign DUT_tid_index = r_tid_index;

//===========================================================================================================================


//start of source 
always @(posedge RESET or posedge CLK)
begin
	if(RESET)
	begin
		/*
			To board sram, initial value is for [not writing] == [read]
		*/
		uart_addr_o <= 3'b000;
		uart_wdata_o <= 8'h00;
		uart_we_o <= 1'b0;
		uart_re_o <= 1'b0;

		state <= ST_IDLE;
		r_counter <= 32'd0;
		r_counter2 <= 32'd0;
		
		r_dut_row_addr <= 8'b0;
	   r_dut_col_addr <= 4'b0;
		r_dut_din <= 8'b0;
		r_dut_ctr_cmd <= 8'b0;
		r_dut_ctr_reset_n <= 1'b0;
		r_dut_ctr_enable	<= 1'b0;
		r_dut_sub_addr	<= 4'b0;
		r_dut_sram_mode <=1'b0;
		
		r_data_pattern <= 8'b0;
		r_dut_dout <= 8'b0;
		r_replica_sw <= 3'b001;
		
		r_tid_index <= 8'd0;

	end
	else begin
			case (state) 
				/*
					From here, Uart initialization senario starts
				*/
       		ST_IDLE : begin
					/*
						LCR = 0x83;   
					*/
					uart_addr_o <= 3'b011;
					uart_wdata_o <= 8'h83;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					r_counter <= 32'd0;
					r_counter2 <= 32'd0;
					
					r_dut_ctr_cmd[0] <= 1'b1; 
					r_dut_ctr_cmd[1] <= 1'b1; 
					r_dut_din <= 8'b0; 
					r_dut_ctr_reset_n <= 1'b0;
					r_dut_ctr_enable	<= 1'b0;
					r_dut_sram_mode <=1'b0;
					r_dut_sub_addr	<= 4'b0;
					r_dut_col_addr <= 4'b0;
					r_dut_row_addr <= 8'b0;
					r_tid_index <= 8'd0;
					
					r_data_pattern <= 8'b0;
					r_dut_dout <= 8'b0;
					r_replica_sw <= 3'b001;
					if(Enable == 1'b1)
						state <= ST_DL_MSB;
					else
						state <= ST_IDLE;

				end	
				ST_DL_MSB : begin
					/* 25MHz = 0x0E, 50MHz = 0x1B, 12.5MHz = 0x07 
						RB_THR = 0x0E
						Baudrate = 9600 ==> Divisor Latches = 00A3
					*/
					uart_addr_o <= 3'b001;
					uart_wdata_o <= 8'h00;
					uart_we_o <= 1'b1;
					state <= ST_DL_LSB;
				end
				ST_DL_LSB : begin
					/* 25MHz = 0x0E, 50MHz = 0x1B, 12.5MHz = 0x07
						RB_THR = 0x0E
						Baudrate = 9600 ==> Divisor Latches = 00A3
						Baudrate = 115200 ==> DL = 000E
					*/
					uart_addr_o <= 3'b000;
					uart_wdata_o <= 8'h0E; // we use 25MHz clock and baudrate = 115200
					uart_we_o <= 1'b1;
					state <= ST_LCR;
				end
				ST_LCR : begin
					/*
						LCR = 0x03;   
					*/
					uart_addr_o <= 3'b011;
					uart_wdata_o <= 8'h03;
					uart_we_o <= 1'b1;
					state <= ST_FCR;

				end
				ST_FCR : begin
					/*
						IIR_FCR = 0x01;   
					*/
					uart_addr_o <= 3'b010;
					uart_wdata_o <= 8'b00000001;
					uart_we_o <= 1'b1;
					state <= ST_IER;
				end
				ST_IER : begin
					/*
						IER = 0x01;   
					*/
					uart_addr_o <= 3'b001;
					uart_wdata_o <= 8'h01;
					uart_we_o <= 1'b1;
					state <= ST_SEND_TEST_CHAR;
				end
				ST_SEND_TEST_CHAR: begin
					// test pattern == just write 'T' character to the terminal screen

					// below 4 lines is disables in case with tty test
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= 8'b01010110;
					if (r_counter<32'd4095) begin
						r_counter <= r_counter + 32'd1;
						r_counter2 <= 32'd0;
						state <= ST_SEND_TEST_CHAR_WAIT;
					end else begin 
						state <= ST_READ_LSR;
					end
				end	
				
				ST_SEND_TEST_CHAR_WAIT: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_SEND_TEST_CHAR_WAIT;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						state <= ST_SEND_TEST_CHAR;
					end
				end
				
				ST_READ_LSR : begin
					/*
						Iteration from this state to ST12
						1_1 - READ from LSR :  Don't need to wait 1 or 2 cycle - immediately reading 
						1_2 - check LSR value is 0x21
						2 - Then, Read from Buffer(RB_THR) and write memory
					*/
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b1;
					
					// standby signal for SRAM 
					/*
					r_dut_sram_mode <= 1'b0;
					r_dut_sub_addr <= 4'b0100;
					r_dut_col_addr <= 4'b1111;
					r_dut_row_addr <= 8'b11111111;
					r_dut_ctr_cmd[0] <= 1'b1; // reading
					r_dut_ctr_cmd[1] <= 1'b1;
					r_dut_din <= 8'b11111111;
					r_dut_ctr_reset_n <= 1'b0;
					*/
					state <= ST_CHECK_LSR;
				end

					/*
						LSR value == 0x21 ?? Receive at least one character?
					*/
				ST_CHECK_LSR : begin	 
					if (uart_rdata_i[0]) begin // if a command come
						uart_addr_o <= 3'b000;
						uart_we_o <= 1'b0;
						uart_re_o <= 1'b1;
						state <= ST_READ_DATA_COME;
					end
					else begin // Continue read for received data
						state <= ST_READ_LSR;
					end

				end
				
					/*
						READ from RB_THR;   
					*/
					
				ST_READ_DATA_COME : begin  // show the received data on led, if "space" or "\n" then go to transmition step
					uart_re_o <= 1'b0;
					// Command decode
					case (uart_rdata_i)
						CM_SEND_TEST_CHAR: begin
							r_counter <= 32'd0;
							state <= ST_SEND_TEST_CHAR;
						end
						CM_READ_DUT: begin
							state <= ST_READ_DUT_INIT;
						end
						CM_WRITE_AA_DUT: begin
							r_data_pattern <= 8'b10101010;
							state <= ST_WRITE_DUT_INIT;
						end
						CM_WRITE_00_DUT: begin
							r_data_pattern <= 8'b0;
							state <= ST_WRITE_DUT_INIT;
						end
						CM_WRITE_FF_DUT: begin
							r_data_pattern <= 8'b11111111;
							state <= ST_WRITE_DUT_INIT;
						end
						CM_WRITE_A5_DUT: begin
							r_data_pattern <= 8'b10100101;
							state <= ST_WRITE_DUT_INIT;
						end
						CM_WRITE_55_DUT: begin // change to 5A to test fliping data after aging
							r_data_pattern <= 8'b01011010;
							state <= ST_WRITE_DUT_INIT;
						end
						CM_SER_DUT_RANDOM: begin
							r_data_pattern <= 8'h65; //CM_SER_DUT_RANDOM; 
							state <= ST_SER_DUT_INIT;
						end
						CM_SER_DUT_STANDARD: begin
							//r_data_pattern <= 8'b01010101; // Same data pattern with previous writing
							state <= ST_SER_DUT_INIT;
						end
						CM_REP_SW0: begin
							r_replica_sw = 3'b001;
							state <= ST_READ_LSR;
						end
						CM_REP_SW1: begin
							r_replica_sw = 3'b010;
							state <= ST_READ_LSR;
						end
						CM_REP_SW2: begin
							r_replica_sw = 3'b100;
							state <= ST_READ_LSR;
						end
						CM_TID: begin
							state <= ST_TID;
						end
						default: begin
							state <= ST_READ_LSR;
						end
					endcase
					
				end
				
				/******** DUT SRAM function ***********/
				ST_READ_DUT_INIT: begin
					r_dut_ctr_cmd[0] <= 1'b1; // reading
					r_dut_ctr_cmd[1] <= 1'b1; // 
					r_dut_din[2:0] <= r_replica_sw; // replica select.
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					r_dut_sram_mode <=1'b0;
					r_dut_sub_addr	<= 4'b0;
					r_dut_col_addr <= 4'b0;
					r_dut_row_addr <= 8'b0;
					r_counter <= 32'b0;
					
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= 8'h52; // 'R'


					state <= ST_READ_DUT_PRE;
				end
				
				ST_READ_DUT_PRE: begin
					r_dut_ctr_cmd[0] <= 1'b1; // reading
					r_dut_ctr_cmd[1] <= 1'b1; // 
					r_dut_din[2:0] <= r_replica_sw; // replica select
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					
					if (DUT_ctr_in_process) begin // SRAM controller be Initial state (busy flag = 1)
						state <= ST_READ_DUT;
					end else begin 
						state <= ST_READ_DUT_PRE;
					end
				end
				
				ST_READ_DUT: begin
					r_dut_ctr_enable	<= 1'b1;
					state <= ST_READ_DUT_WAIT;
				end
				
				ST_READ_DUT_WAIT: begin
					if (DUT_ctr_in_process) begin // DUT in busy
						state <= ST_READ_DUT_WAIT;
					end else begin 
						state <=ST_READ_DUT_CHECK_DATA;
					end
				end
				ST_READ_DUT_CHECK_DATA: begin
					if (r_counter< 32'd2)begin
						state <= ST_READ_DUT_PRE;
						r_counter <= r_counter + 32'd1;
					end else begin 
						r_counter <= 32'b0;
						state <=ST_SEND_DUT_DATA_UART;
					end
					if (r_counter==32'd0) begin r_dut_dout_tma_0 <= DUT_dout; end
					if (r_counter==32'd1) begin r_dut_dout_tma_1 <= DUT_dout; end
					if (r_counter==32'd2) begin r_dut_dout_tma_2 <= DUT_dout; end
				end
				ST_SEND_DUT_DATA_UART: begin
				//		state <= ST_READ_DUT_COUNT_ADDR;
				// below 4 lines is disables in case with tty test
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= w_dut_dout_tma;
					r_counter2<=32'd0;
					state <= ST_SEND_DUT_DATA_UART_WAIT;
				end	
				
				ST_SEND_DUT_DATA_UART_WAIT: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_SEND_DUT_DATA_UART_WAIT;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						state <= ST_READ_DUT_COUNT_ADDR;
					end
				end
				
				ST_READ_DUT_COUNT_ADDR: begin
				// count to read all memory
					if (r_dut_row_addr < 8'b11111111) begin // count row 
						r_dut_row_addr <= r_dut_row_addr + 8'b00000001;
						state <= ST_READ_DUT_PRE;
					end else begin
						r_dut_row_addr <= 8'b0;
						if (r_dut_col_addr < 4'b1111) begin // count colum
							r_dut_col_addr <= r_dut_col_addr + 4'b0001;
							state <= ST_READ_DUT_PRE;
						end else begin
							r_dut_col_addr <=4'b0;
							if (r_dut_sub_addr < 4'b1111) begin
								if (r_dut_sram_mode<1'b1) begin
									r_dut_sub_addr <= r_dut_sub_addr+4'b0001;
									state <= ST_READ_DUT_PRE;
								end else begin 
									r_dut_sram_mode <= 1'b0;
									r_dut_sub_addr <= 4'b0000;
									state <= ST_READ_LSR;
								end
							end else begin
								r_dut_sub_addr <= 4'b0001;
								r_dut_sram_mode <= 1'b1;
								state <= ST_READ_DUT_PRE;
							end
						end
					end
				end
				
				
				/************ write *****************/
				ST_WRITE_DUT_INIT: begin
					r_dut_ctr_cmd[0] <= 1'b0; // writing
					r_dut_ctr_cmd[1] <= 1'b1; // write normal
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					r_dut_din <= r_data_pattern;
					r_dut_sram_mode <=1'b0;
					r_dut_sub_addr	<= 4'b0;
					r_dut_col_addr <= 4'b0;
					r_dut_row_addr <= 8'b0;
					
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= 8'h57; // 'W'
					
					state <= ST_WRITE_DUT_PRE;
				end
				ST_WRITE_DUT_PRE: begin
					r_dut_ctr_cmd[0] <= 1'b0; // writing
					r_dut_ctr_cmd[1] <= 1'b1; // write normal
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					
					if (DUT_ctr_in_process) begin // SRAM controller be Initial state (busy flag = 1)
						state <= ST_WRITE_DUT;
						if (r_data_pattern==8'b10100101) begin
							if (r_dut_row_addr[0]==1'b0) begin 
								r_dut_din<=8'b10100101;
							end else begin 
								r_dut_din <= 8'b01011010;
							end
						end else if (r_data_pattern==8'b01011010) begin
							if (r_dut_row_addr[0]==1'b0) begin 
								r_dut_din<=8'b01011010;
							end else begin 
								r_dut_din <= 8'b10100101;
							end
						end else begin
							// not change data pattern
						end
					end else begin 
						state <= ST_WRITE_DUT_PRE;
					end
				end
				
				ST_WRITE_DUT: begin
					r_dut_ctr_enable	<= 1'b1;
					state <= ST_WRITE_DUT_WAIT;
				end
				
				ST_WRITE_DUT_WAIT: begin
					if (DUT_ctr_in_process) begin // DUT in busy
						state <= ST_WRITE_DUT_WAIT;
					end else begin 
						state <=ST_WRITE_DUT_COUNT_ADDR;
					end
				end
				ST_WRITE_DUT_COUNT_ADDR: begin
					if (r_dut_row_addr < 8'b11111110) begin // count row 
						r_dut_row_addr <= r_dut_row_addr + 8'b00000001;
						state <= ST_WRITE_DUT_PRE;
					end else begin
						r_dut_row_addr <= 8'b0;
						if (r_dut_col_addr < 4'b1111) begin // count colum
							r_dut_col_addr <= r_dut_col_addr + 4'b0001;
							state <= ST_WRITE_DUT_PRE;
						end else begin
							r_dut_col_addr <=4'b0;
							if (r_dut_sub_addr < 4'b1111) begin
								if (r_dut_sram_mode<1'b1) begin
									r_dut_sub_addr <= r_dut_sub_addr+4'b0001;
									state <= ST_WRITE_DUT_PRE;
								end else begin 
									r_dut_sram_mode <= 1'b0;
									r_dut_sub_addr <= 4'b0000;
									// If not auto read back, uncomment the below line
									state <= ST_READ_LSR;
									// Auto read back
									//state <= ST_READ_DUT_INIT;
								end
							end else begin
								r_dut_sub_addr <= 4'b0001;
								r_dut_sram_mode <= 1'b1;
								state <= ST_WRITE_DUT_PRE;
							end
						end
					end
				end
				/************* SER dynamic check ************/
				// Read first then re-write original data or standard data
				ST_SER_DUT_INIT: begin
					r_dut_ctr_cmd[0] <= 1'b1; // reading
					r_dut_ctr_cmd[1] <= 1'b1; // 
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					r_dut_sram_mode <=1'b0;
					r_dut_sub_addr	<= 4'b0;
					r_dut_col_addr <= 4'b0;
					r_dut_row_addr <= 8'b0;
					r_counter <= 32'd0;
					
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= 8'h53; // 'S'
					
					state <= ST_SER_DUT_READ_PRE;
				end
				
				ST_SER_DUT_READ_PRE: begin
					r_dut_ctr_cmd[0] <= 1'b1; // reading
					r_dut_ctr_cmd[1] <= 1'b1; // 
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					
					if (DUT_ctr_in_process) begin // SRAM controller be Initial state (busy flag = 1)
						state <= ST_SER_DUT_READ;
					end else begin 
						state <= ST_SER_DUT_READ_PRE;
					end
				end
				
				ST_SER_DUT_READ: begin
					r_dut_ctr_enable	<= 1'b1;
					state <= ST_SER_DUT_READ_WAIT;
				end
				
				ST_SER_DUT_READ_WAIT: begin
					if (DUT_ctr_in_process) begin // DUT in busy
						state <= ST_SER_DUT_READ_WAIT;
					end else begin 
						state <=ST_SER_DUT_CHECK_DATA;
					end
				end
				
				ST_SER_DUT_CHECK_DATA: begin
					if (r_counter< 32'd2)begin
						state <= ST_SER_DUT_READ_PRE;
						r_counter <= r_counter + 32'd1;
					end else begin 
						r_counter <= 32'b0;
						state <=ST_SER_DUT_SEND_DATA_UART;
					end
					if (r_counter==32'd0) begin r_dut_dout_tma_0 <= DUT_dout; end
					if (r_counter==32'd1) begin r_dut_dout_tma_1 <= DUT_dout; end
					if (r_counter==32'd2) begin r_dut_dout_tma_2 <= DUT_dout; end
				end
				
				ST_SER_DUT_SEND_DATA_UART: begin
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= w_dut_dout_tma;
					r_dut_dout <= w_dut_dout_tma;
					r_counter2<=32'd0;
					state <= ST_SER_DUT_SEND_DATA_UART_WAIT;
				end	
				
				ST_SER_DUT_SEND_DATA_UART_WAIT: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_SER_DUT_SEND_DATA_UART_WAIT;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						if (r_dut_row_addr==8'b11111111) begin // do not write on the 255th row (test row, fixed data)
							state <= ST_SER_DUT_COUNT_ADDR;
						end else begin
							state <= ST_SER_DUT_REWRITE_PRE;
						end
					end
				end
				
				ST_SER_DUT_REWRITE_PRE: begin
					r_dut_ctr_cmd[0] <= 1'b0; // writing
					r_dut_ctr_cmd[1] <= 1'b1; // write normal
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					if (DUT_ctr_in_process) begin // SRAM controller be Initial state (busy flag = 1)
						state <= ST_SER_DUT_REWRITE;
						if (r_data_pattern==8'b10100101) begin
							if (r_dut_row_addr[0]==1'b0) begin 
								r_dut_din<=8'b10100101;
							end else begin 
								r_dut_din <= 8'b01011010;
							end
						end else if (r_data_pattern == 8'h65)  begin // Random mode: rewrite the read data from the cell
							r_dut_din <= r_dut_dout;
						end else if (r_data_pattern==8'b01011010) begin
							if (r_dut_row_addr[0]==1'b0) begin 
								r_dut_din<=8'b01011010;
							end else begin 
								r_dut_din <= 8'b10100101;
							end
						end else begin
							r_dut_din <= r_data_pattern;
						end 
					end else begin 
						state <= ST_SER_DUT_REWRITE_PRE;
					end
				end
				
				ST_SER_DUT_REWRITE: begin
					r_dut_ctr_enable	<= 1'b1;
					state <= ST_SER_DUT_REWRITE_WAIT;
				end
				
				ST_SER_DUT_REWRITE_WAIT: begin
					if (DUT_ctr_in_process) begin // DUT in busy
						state <= ST_SER_DUT_REWRITE_WAIT;
					end else begin 
						state <=ST_SER_DUT_COUNT_ADDR;
					end
				end
				
				ST_SER_DUT_COUNT_ADDR: begin
				// count to read all memory, ecept the 255th row
					if (r_dut_row_addr < 8'b11111111) begin // count row 
						r_dut_row_addr <= r_dut_row_addr + 8'b00000001;
						state <= ST_SER_DUT_READ_PRE;
					end else begin
						r_dut_row_addr <= 8'b0;
						if (r_dut_col_addr < 4'b1111) begin // count colum
							r_dut_col_addr <= r_dut_col_addr + 4'b0001;
							state <= ST_SER_DUT_READ_PRE;
						end else begin
							r_dut_col_addr <=4'b0;
							if (r_dut_sub_addr < 4'b1111) begin
								if (r_dut_sram_mode<1'b1) begin
									r_dut_sub_addr <= r_dut_sub_addr+4'b0001;
									state <= ST_SER_DUT_READ_PRE;
								end else begin 
									r_dut_sram_mode <= 1'b0;
									r_dut_sub_addr <= 4'b0000;
									state <= ST_READ_LSR;
								end
							end else begin
								r_dut_sub_addr <= 4'b0001;
								r_dut_sram_mode <= 1'b1;
								state <= ST_SER_DUT_READ_PRE;
							end
						end
					end
				end
				
				/******** Check TID sensors *****************/
				ST_TID: begin
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					r_dut_sram_mode <=1'b1;
					r_dut_sub_addr	<= 4'b0;
					r_counter <= 32'b0;
					r_tid_index <= 8'd0;
					
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= 8'h74; // 't'

					state <= ST_TID_PRE;
				end
				
				ST_TID_PRE: begin
					r_dut_ctr_reset_n <= 1'b1;
					r_dut_ctr_enable	<= 1'b0;
					
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					
					if (DUT_ctr_in_process) begin // SRAM controller be Initial state (busy flag = 1)
						state <= ST_TID_START;
					end else begin 
						state <= ST_TID_PRE;
					end
				end
				
				ST_TID_START: begin
					r_dut_ctr_enable <= 1'b1;
					state <= ST_TID_WAIT;
				end
				
				ST_TID_WAIT: begin
					r_dut_ctr_enable <= 1'b1;
					if (DUT_ctr_in_process) begin // DUT in busy
						state <= ST_TID_WAIT;
					end else begin 
						state <=ST_TID_GET_DATA;
						r_counter <= 0;
					end
				end
				
				ST_TID_GET_DATA: begin
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= DUT_tid_data[7:0];
					r_counter2<=32'd0;
					state <= ST_TID_GET_DATA_WAIT;
				end	
				
				ST_TID_GET_DATA_WAIT: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_TID_GET_DATA_WAIT;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						state <= ST_TID_GET_DATA_2;
					end
				end
				ST_TID_GET_DATA_2: begin
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= DUT_tid_data[15:8];
					r_counter2<=32'd0;
					state <= ST_TID_GET_DATA_WAIT_2;
				end	
				
				ST_TID_GET_DATA_WAIT_2: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_TID_GET_DATA_WAIT_2;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						state <= ST_TID_GET_DATA_3;
					end
				end
				ST_TID_GET_DATA_3: begin
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= DUT_tid_data[23:16];
					r_counter2<=32'd0;
					state <= ST_TID_GET_DATA_WAIT_3;
				end	
				
				ST_TID_GET_DATA_WAIT_3: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_TID_GET_DATA_WAIT_3;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						state <= ST_TID_GET_DATA_4;
					end
				end
				
				ST_TID_GET_DATA_4: begin
					uart_addr_o <= 3'b000;
					uart_we_o <= 1'b1;
					uart_re_o <= 1'b0;
					uart_wdata_o <= DUT_tid_data[31:24];
					r_counter2<=32'd0;
					state <= ST_TID_GET_DATA_WAIT_4;
				end	
				
				ST_TID_GET_DATA_WAIT_4: begin 
					uart_addr_o <= 3'b101;
					uart_we_o <= 1'b0;
					uart_re_o <= 1'b0;
					if (r_counter2<32'd2000) begin
						state <= ST_TID_GET_DATA_WAIT_4;
						r_counter2 <= r_counter2 + 32'd1;
					end else begin
						state <= ST_TID_COUNT_ADDR;
					end
				end
				
				ST_TID_COUNT_ADDR: begin
					if (r_tid_index<8'd11) begin
						r_tid_index <= r_tid_index + 8'd1;
						state <= ST_TID_PRE;
					end else begin
						r_dut_sram_mode <= 1'b0;
						r_dut_sub_addr <= 4'b0000;
						state <= ST_READ_LSR;
					end
				end

				default: begin
					state <= ST_IDLE;
				end
			endcase	
	end
end

// tma the data from dut
tma Utma(
 .byte0(r_dut_dout_tma_0),
 .byte1(r_dut_dout_tma_1),
 .byte2(r_dut_dout_tma_2),
 .byteout(w_dut_dout_tma)
);
endmodule
