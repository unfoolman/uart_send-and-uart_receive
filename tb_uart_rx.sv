`timescale 1ns / 1ps

module tb_uart_rx();

parameter					RX_BYTE			=	1	;

logic						sys_clk		;
logic						sys_rst_n	;
logic						uart_rx_on	;
logic						rx_bit_in	;
logic						rx_valid	;
logic		[RX_BYTE*8-1:0]	rx_data		;
logic						rx_error	;

uart_rx #(
	.SYSTEM_CLK					(50_000_000			),		// system clock in
	.BPS_SPEED					(115200				),
	.RX_BYTE					(RX_BYTE			),		// receive bytes length
	.STOP_BIT					(1					),		// 1:1bit ; 2:2bit
	.CHECK_EN					(1					),		// 0:off ; 1:on
	.CHECK_PATH					(1					)		// 0:Odd ; 1:Even
)u_uart_rx(
	.sys_clk					(sys_clk			),
	.sys_rst_n					(sys_rst_n			),
	.uart_rx_on					(uart_rx_on			),		// push on ; high valid
	.rx_bit_in					(rx_bit_in			),		// bit_data input
	.rx_valid					(rx_valid			),		// aim data receive finish
	.rx_data					(rx_data			),		// aim data
	.rx_error					(rx_error			),
	.rx_busy					(					)
);

initial begin
	sys_clk = 1'h1;
	uart_rx_on = 1'h0;
	rx_bit_in = 1'h1;
end

always #10 sys_clk = ~sys_clk;

initial begin
	sys_rst_n <= 1'h0;
	#200;
	sys_rst_n <= 1'h1;
	#200;
	
	uart_rx_on = 1'h1;
	rx_data_task(8'hac,8680);
	@(rx_valid);
	uart_rx_on = 1'h0;
	#20_000;
	
	$stop;
end

task rx_data_task(
	input	[ 7:0]				data_in		,
	input	[15:0]				bit_times	
);
	rx_bit_in <= 1'h1;
	@(posedge sys_clk);
	rx_bit_in <= 1'h0;
	#bit_times;
	rx_bit_in <= data_in[0];
	#bit_times;
	rx_bit_in <= data_in[1];
	#bit_times;
	rx_bit_in <= data_in[2];
	#bit_times;
	rx_bit_in <= data_in[3];
	#bit_times;
	rx_bit_in <= data_in[4];
	#bit_times;
	rx_bit_in <= data_in[5];
	#bit_times;
	rx_bit_in <= data_in[6];
	#bit_times;
	rx_bit_in <= data_in[7];
	#bit_times;
	rx_bit_in <= 1'h1;
	#bit_times;
	rx_bit_in <= 1'h1;
	#bit_times;
endtask

endmodule