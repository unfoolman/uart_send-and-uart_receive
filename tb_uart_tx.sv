`timescale 1ns / 1ps

module tb_uart_tx();

parameter					TX_BYTE			=	3	;

logic						sys_clk		;
logic						sys_rst_n	;
logic						uart_tx_on	;
logic		[TX_BYTE*8-1:0]	tx_data		;
logic						tx_bit_out	;
logic						tx_valid	;
logic						tx_busy		;

uart_tx #(
	.SYSTEM_CLK				(50_000_000			),		// system clock in
	.BPS_SPEED				(115200				),
	.TX_BYTE				(TX_BYTE			),		// receive bytes length
	.STOP_BIT				(2					),		// 1:1bit ; 2:2bit
	.CHECK_EN				(1					),		// 0:off ; 1:on
	.CHECK_PATH				(0					)		// 0:once ; 1:twice
)u_uart_tx(
	.sys_clk				(sys_clk			),
	.sys_rst_n				(sys_rst_n			),
	.uart_tx_on				(uart_tx_on			),		// push on ; high valid
	.tx_data				(tx_data			),		// aim data
	.tx_bit_out				(tx_bit_out			),		// bit_data input
	.tx_valid				(tx_valid			),		// aim data receive finish
	.tx_busy				(tx_busy			)			// high busy ; low ready
);

initial begin
	sys_clk = 1'h1;
	uart_tx_on = 1'h0;
	tx_data = 'h0;
end

always #10 sys_clk = ~sys_clk;

initial begin
	sys_rst_n <= 1'h0;
	#200;
	sys_rst_n <= 1'h1;
	#200;
	
	tx_data_task(24'hdf86aa);
	@(tx_valid);
	#20_000;
	
	$stop;
end

task tx_data_task(
	input	[TX_BYTE*8-1:0]			data_in		
);
	uart_tx_on <= 1'h0;
	tx_data <= data_in;
	@(posedge sys_clk);
	uart_tx_on <= 1'h1;
	@(posedge sys_clk);
endtask

endmodule