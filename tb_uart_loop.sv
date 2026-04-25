`timescale 1ns / 1ps

module tb_uart_loop();

logic						sys_clk		;
logic						sys_rst_n	;
logic						rx_bit_in	;
logic						tx_bit_out	;

uart_loop #(
	.SYSTEM_CLK				(50_000_000			),		// system clock in
	.BPS_SPEED				(115200				),
	.RX_BYTE				(3					),		// receive bytes length
	.BYTE_LENGTH			(3					),		// least must 3
	.TX_BYTE				(1					),		// send bytes length
	.STOP_BIT				(1					),		// 1:1bit ; 2:2bit
	.CHECK_EN				(0					),		// 0:off ; 1:on
	.CHECK_PATH				(0					),		// 0:once ; 1:twice
	.FRAME_HEAD				(8'h55				),
	.FRAME_END				(8'hdd				)
)uart_loop_inst(
	.sys_clk				(sys_clk			),
	.sys_rst_n				(sys_rst_n			),
	.rx_bit_in				(rx_bit_in			),
	.tx_bit_out				(tx_bit_out			)
);

initial begin
	sys_clk = 1'h1;
	rx_bit_in = 1'h1;
end

always #10 sys_clk = ~sys_clk;

initial begin
	sys_rst_n <= 1'h0;
	#200;
	sys_rst_n <= 1'h1;
	#200;
	
	rx_data_task(8'h55,8680);
	rx_data_task(8'hac,8680);
	rx_data_task(8'hdd,8680);
	#200_000;
	
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
endtask

endmodule