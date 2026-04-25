`timescale 1ns / 1ps

module uart_rx #(
	parameter	SYSTEM_CLK	=	50_000_000	,		// system clock in
	parameter	BPS_SPEED	=	115200		,
	parameter	RX_BYTE		=	1			,		// receive bytes length
	parameter	STOP_BIT	=	1			,		// 1:1bit ; 2:2bit
	parameter	CHECK_EN	=	0			,		// 0:off ; 1:on
	parameter	CHECK_PATH	=	0					// 0:once ; 1:twice
)(
	input	logic							sys_clk			,
	input	logic							sys_rst_n		,
	input	logic							uart_rx_on		,		// push on ; high edge valid
	input	logic							rx_bit_in		,		// bit_data input
	output	logic							rx_valid		,		// aim data receive finish
	output	logic	[RX_BYTE*8-1:0]			rx_data			,		// aim data
	output	logic							rx_error		,
	output	logic							rx_busy			
);

localparam			BIT_TIMES				=	SYSTEM_CLK / BPS_SPEED	;

logic				rx_in_sync	[0:1]	;
logic				rx_in_nege			;
logic				rx_start			;
logic	[	3:0]	rx_bit_total		;
logic	[  15:0]	bit_cnt				;
logic	[	3:0]	rx_bit_cnt			;
logic				rx_temp_valid		;
logic	[	7:0]	rx_temp_data		;
logic	[	3:0]	crc_bit_cnt			;
logic	[RX_BYTE*8-1:0]	rx_byte_cnt		;

always_comb begin
	case(CHECK_EN)
		'b0:begin
			case(STOP_BIT)
				'h1:begin
					rx_bit_total = 'd10;
				end
				'h2:begin
					rx_bit_total = 'd11;
				end
				default:begin
					rx_bit_total = 'd10;
				end
			endcase
		end
		'b1:begin
			case(STOP_BIT)
				'h1:begin
					rx_bit_total = 'd11;
				end
				'h2:begin
					rx_bit_total = 'd12;
				end
				default:begin
					rx_bit_total = 'd11;
				end
			endcase
		end
		default:begin
			case(STOP_BIT)
				'h1:begin
					rx_bit_total = 'd10;
				end
				'h2:begin
					rx_bit_total = 'd11;
				end
				default:begin
					rx_bit_total = 'd10;
				end
			endcase
		end
	endcase
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_in_sync[0] <= 'h1;
		rx_in_sync[1] <= 'h1;
	end else begin
		rx_in_sync[0] <= rx_bit_in;
		rx_in_sync[1] <= rx_in_sync[0];
	end
end

assign rx_in_nege = (~rx_in_sync[0]) && (rx_in_sync[1]) ;

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_start <= 'h0;
	end else if(uart_rx_on)begin
		if(rx_in_nege)begin
			rx_start <= 'h1;
		end else if(rx_valid)begin
			rx_start <= 'h0;
		end else begin
			rx_start <= rx_start;
		end
	end else begin
		rx_start <= 'h0;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		bit_cnt <= 'h0;
	end else if(rx_start)begin
		if(bit_cnt == BIT_TIMES - 1'h1)begin
			bit_cnt <= 'h0;
		end else begin
			bit_cnt <= bit_cnt + 1'h1;
		end
	end else begin
		bit_cnt <= 'h0;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_bit_cnt <= 'h0;
	end else if(rx_start)begin
		if(bit_cnt == BIT_TIMES - 1'h1)begin
			if(rx_bit_cnt == rx_bit_total - 1'h1)begin
				rx_bit_cnt <= 'h0;
			end else begin
				rx_bit_cnt <= rx_bit_cnt + 1'h1;
			end
		end else begin
			rx_bit_cnt <= rx_bit_cnt;
		end
	end else begin
		rx_bit_cnt <= 'h0;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_error = 'h0;
		rx_temp_data <= 'h00;
		crc_bit_cnt <= 'h0;
	end else if(rx_start && (bit_cnt == (BIT_TIMES >> 1'h1) - 1'h1))begin
		case(rx_bit_cnt)
			'd0:begin
				rx_error = 'h0;
				crc_bit_cnt <= 'h0;
			end
			'd1:begin
				rx_temp_data[0] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd2:begin
				rx_temp_data[1] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd3:begin
				rx_temp_data[2] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd4:begin
				rx_temp_data[3] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd5:begin
				rx_temp_data[4] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd6:begin
				rx_temp_data[5] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd7:begin
				rx_temp_data[6] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd8:begin
				rx_temp_data[7] <= rx_in_sync[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (rx_in_sync[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd9:begin
				if(CHECK_EN)begin
					if(CHECK_PATH)begin
						rx_error <= (crc_bit_cnt%2 == 1'h1) ? 1'h1 : 1'h0;
					end else begin
						rx_error <= (crc_bit_cnt%2 == 1'h1) ? 1'h0 : 1'h1;
					end
				end
			end
			default:begin
				rx_error = 'h0;
			end
		endcase
	end
end

assign rx_temp_valid = ((rx_bit_cnt == rx_bit_total - 1'h1) && (bit_cnt == BIT_TIMES - 1'h1)) ? 1'h1 : 1'h0;

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_byte_cnt <= 'h0;
	end else if(rx_start)begin
		if(rx_temp_valid)begin
			if(rx_byte_cnt == RX_BYTE - 1'h1)begin
				rx_byte_cnt <= 'h0;
			end else begin
				rx_byte_cnt <= rx_byte_cnt + 1'h1;
			end
		end
	end else begin
		rx_byte_cnt <= 'h0;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rx_data <= 'h0;
		rx_valid <= 'h0;
	end else if(rx_start)begin
		if(rx_temp_valid)begin
			if(rx_byte_cnt == RX_BYTE - 1'h1)begin
				rx_valid <= 'h1;
			end
			if(RX_BYTE == 1'h1)begin
				rx_data <= rx_temp_data[7:0];
			end else begin
				rx_data <= {rx_data[(RX_BYTE-1)*8-1:0],rx_temp_data[7:0]};
			end
		end
	end else begin
		rx_valid <= 'h0;
	end
end

assign rx_busy = rx_start ? 1'h1 : 1'h0;

endmodule