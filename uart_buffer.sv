`timescale 1ns / 1ps

module uart_buffer #(
	parameter		SYSTEM_CLOCK	=	50_000_000	,
	parameter		BYTE_LENGTH		=	'h3			,		// least must 3
	parameter		FRAME_HEAD		=	8'h55		,
	parameter		FRAME_END		=	8'hdd		
)(
	input	logic							sys_clk			,
	input	logic							sys_rst_n		,
	input	logic							rx_busy			,
	input	logic							rx_valid		,
	input	logic							tx_busy			,
	output	logic							buffer_error	,
	output	logic							tx_on_edge		,
	input	logic	[BYTE_LENGTH*8-1:0]		data_in			,
	output	logic	[(BYTE_LENGTH-2)*8-1:0]	data_out		
);

always_ff @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		buffer_error <= 'h0;
		tx_on_edge <= 'h0;
		data_out <= 'h0;
	end else if(rx_valid && !tx_busy)begin
		if((data_in[BYTE_LENGTH*8-1:(BYTE_LENGTH-1)*8] == FRAME_HEAD)
			&& (data_in[7:0] == FRAME_END))begin
			tx_on_edge <= 'h1;
			data_out <= data_in[(BYTE_LENGTH-1)*8-1:8];
		end else begin
			buffer_error <= 'h1;
		end
	end else begin
		buffer_error <= 'h0;
		tx_on_edge <= 'h0;
	end
end

endmodule