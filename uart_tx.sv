`timescale 1ns / 1ps

module uart_tx #(
	parameter	SYSTEM_CLK	=	50_000_000	,		// system clock in
	parameter	BPS_SPEED	=	115200		,
	parameter	TX_BYTE		=	1			,		// send bytes length
	parameter	STOP_BIT	=	1			,		// 1:1bit ; 2:2bit
	parameter	CHECK_EN	=	0			,		// 0:off ; 1:on
	parameter	CHECK_PATH	=	0					// 0:once ; 1:twice
)(
	input	logic							sys_clk			,
	input	logic							sys_rst_n		,
	input	logic							uart_tx_on		,		// push on ; high edge valid
	input	logic	[TX_BYTE*8-1:0]			tx_data			,		// aim data
	output	logic							tx_bit_out		,		// bit_data output
	output	logic							tx_valid		,		// aim data send finish
	output	logic							tx_busy					// high busy ; low ready
);

localparam			BIT_TIMES				=	SYSTEM_CLK / BPS_SPEED	;

logic				tx_on_sync	[0:1]	;
logic				tx_on_pose			;
logic				tx_start			;
logic	[	3:0]	tx_bit_total		;
logic	[  15:0]	bit_cnt				;
logic	[	3:0]	tx_bit_cnt			;
logic				tx_temp_valid		;
logic	[	7:0]	tx_temp_data		;
logic				crc_bit				;
logic	[	3:0]	crc_bit_cnt			;
logic	[TX_BYTE*8-1:0]	tx_byte_cnt		;
logic	[TX_BYTE*8-1:0]	tx_data_reg		;

always_comb begin
	case(CHECK_EN)
		'b0:begin
			case(STOP_BIT)
				'h1:begin
					tx_bit_total = 'd10;
				end
				'h2:begin
					tx_bit_total = 'd11;
				end
				default:begin
					tx_bit_total = 'd10;
				end
			endcase
		end
		'b1:begin
			case(STOP_BIT)
				'h1:begin
					tx_bit_total = 'd11;
				end
				'h2:begin
					tx_bit_total = 'd12;
				end
				default:begin
					tx_bit_total = 'd11;
				end
			endcase
		end
		default:begin
			case(STOP_BIT)
				'h1:begin
					tx_bit_total = 'd10;
				end
				'h2:begin
					tx_bit_total = 'd11;
				end
				default:begin
					tx_bit_total = 'd10;
				end
			endcase
		end
	endcase
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_on_sync[0] <= 1'h0;
		tx_on_sync[1] <= 1'h0;
	end else begin
		tx_on_sync[0] <= uart_tx_on;
		tx_on_sync[1] <= tx_on_sync[0];
	end
end

assign tx_on_pose = (tx_on_sync[0]) && (~tx_on_sync[1]);

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_start <= 'h0;
	end else if(tx_on_pose)begin
		tx_start <= 'h1;
	end else if(tx_valid)begin
		tx_start <= 'h0;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		bit_cnt <= 'h0;
	end else if(tx_start)begin
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
		tx_bit_cnt <= 'h0;
	end else if(tx_start)begin
		if(bit_cnt == BIT_TIMES - 1'h1)begin
			if(tx_bit_cnt == tx_bit_total - 1'h1)begin
				tx_bit_cnt <= 'h0;
			end else begin
				tx_bit_cnt <= tx_bit_cnt + 1'h1;
			end
		end else begin
			tx_bit_cnt <= tx_bit_cnt;
		end
	end else begin
		tx_bit_cnt <= 'h0;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_bit_out <= 'h1;
		crc_bit <= 'h0;
		crc_bit_cnt <= 'h0;
	end else if(tx_start && (bit_cnt == (BIT_TIMES >> 1'h1) - 1'h1))begin
		case(tx_bit_cnt)
			'd0:begin
				tx_bit_out <= 'h0;
				crc_bit_cnt <= 'h0;
			end
			'd1:begin
				tx_bit_out <= tx_temp_data[0];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[0] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd2:begin
				tx_bit_out <= tx_temp_data[1];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[1] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd3:begin
				tx_bit_out <= tx_temp_data[2];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[2] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd4:begin
				tx_bit_out <= tx_temp_data[3];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[3] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd5:begin
				tx_bit_out <= tx_temp_data[4];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[4] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd6:begin
				tx_bit_out <= tx_temp_data[5];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[5] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd7:begin
				tx_bit_out <= tx_temp_data[6];
				if(CHECK_EN)begin
					crc_bit_cnt <= (tx_temp_data[6] == 1'h1) ? (crc_bit_cnt + 1'h1) : crc_bit_cnt;
				end
			end
			'd8:begin
				tx_bit_out <= tx_temp_data[7];
				if(CHECK_EN)begin
					if(tx_temp_data[7] == 1'h1)begin
						crc_bit_cnt <= crc_bit_cnt + 1'h1;
						crc_bit <= ((crc_bit_cnt + 1) % 2) ? 1'h1 : 1'h0;
					end else begin
						crc_bit_cnt <= crc_bit_cnt;
						crc_bit <= (crc_bit_cnt % 2) ? 1'h1 : 1'h0;
					end
				end
			end
			'd9:begin
				if(CHECK_EN)begin
					if(CHECK_PATH)begin
						tx_bit_out <= crc_bit ? 1'h1 : 1'h0;
					end else begin
						tx_bit_out <= ~crc_bit ? 1'h1 : 1'h0;
					end
				end else begin
					tx_bit_out <= 1'h1;
				end
			end
			'd10:begin
				tx_bit_out <= 1'h1;
			end
			'd11:begin
				tx_bit_out <= 1'h1;
			end
			default:begin
				tx_bit_out <= 1'h1;
			end
		endcase
	end
end

assign tx_temp_valid = ((tx_bit_cnt == tx_bit_total - 1'h1) && (bit_cnt == (BIT_TIMES >> 2'h2) * 3 - 1'h1)) ? 1'h1 : 1'h0;

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_byte_cnt <= 'h0;
	end else if(tx_valid)begin
		tx_byte_cnt <= 'h0;
	end else if(tx_temp_valid)begin
		tx_byte_cnt <= tx_byte_cnt + 1'h1;
	end
end

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_temp_data <= 'h0;
		tx_data_reg <= 'h0;
	end else if(tx_on_pose)begin
		if(TX_BYTE == 1'h1)begin
			tx_temp_data <= tx_data;
		end else begin
			tx_temp_data <= tx_data_reg[TX_BYTE*8-1:(TX_BYTE-1)*8];
			tx_data_reg <= tx_data_reg << 8;
		end
	end	else if(tx_temp_valid)begin
		if(TX_BYTE == 1'h1)begin
			tx_temp_data <= tx_data;
		end else begin
			tx_temp_data <= tx_data_reg[TX_BYTE*8-1:(TX_BYTE-1)*8];
			tx_data_reg <= tx_data_reg<<8;
		end
	end else if(~tx_busy)begin
		tx_data_reg <= tx_data;
	end
end

assign tx_valid = (tx_temp_valid) && (tx_byte_cnt == TX_BYTE - 1'h1) ? 1'h1 : 1'h0;
assign tx_busy = tx_start ? 1'h1 : 1'h0;

endmodule