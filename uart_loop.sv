`timescale 1ns / 1ps

module uart_loop #(
	parameter		SYSTEM_CLK	=	50_000_000	,		// system clock in
	parameter		BPS_SPEED	=	115200		,
	parameter		RX_BYTE		=	16			,		// receive bytes length
	parameter		BYTE_LENGTH	=	RX_BYTE		,		// least must 3
	parameter		TX_BYTE		=	RX_BYTE-2	,		// send bytes length
	parameter		STOP_BIT	=	2			,		// 1:1bit ; 2:2bit
	parameter		CHECK_EN	=	1			,		// 0:off ; 1:on
	parameter		CHECK_PATH	=	0			,		// 0:once ; 1:twice
	parameter		FRAME_HEAD	=	"U"			,
	parameter		FRAME_END	=	"?"			
)(
	input	logic							sys_clk			,
	input	logic							sys_rst_n		,
	input	logic							rx_bit_in		,
	output	logic							tx_bit_out		
);

logic							rx_valid		;
logic	[RX_BYTE*8-1:0]			rx_data			;
logic							rx_error		;
logic							rx_busy			;
logic							tx_busy			;
logic							buffer_error	;
logic							tx_on_edge		;
logic	[(BYTE_LENGTH-2)*8-1:0]	tx_data			;
logic							tx_valid		;

uart_rx #(
	.SYSTEM_CLK							(SYSTEM_CLK			),		// system clock in
	.BPS_SPEED							(BPS_SPEED			),
	.RX_BYTE							(RX_BYTE			),		// receive bytes length
	.STOP_BIT							(STOP_BIT			),		// 1:1bit ; 2:2bit
	.CHECK_EN							(CHECK_EN			),		// 0:off ; 1:on
	.CHECK_PATH							(CHECK_PATH			)		// 0:once ; 1:twice
)uart_rx_inst0(
	.sys_clk							(sys_clk			),
	.sys_rst_n							(sys_rst_n			),
	.uart_rx_on							(1'h1				),		// push on ; high edge valid
	.rx_bit_in							(rx_bit_in			),		// bit_data input
	.rx_valid							(rx_valid			),		// aim data receive finish
	.rx_data							(rx_data			),		// aim data
	.rx_error							(rx_error			),
	.rx_busy							(rx_busy			)
);

uart_buffer #(
	.SYSTEM_CLOCK						(SYSTEM_CLK			),
	.BYTE_LENGTH						(BYTE_LENGTH		),
	.FRAME_HEAD							(FRAME_HEAD			),
	.FRAME_END							(FRAME_END			)
)uart_buffer_inst0(
	.sys_clk							(sys_clk			),
	.sys_rst_n							(sys_rst_n			),
	.rx_busy							(rx_busy			),
	.rx_valid							(rx_valid			),
	.tx_busy							(tx_busy			),
	.buffer_error						(buffer_error		),
	.tx_on_edge							(tx_on_edge			),
	.data_in							(rx_data			),
	.data_out							(tx_data			)
);

uart_tx #(
	.SYSTEM_CLK							(SYSTEM_CLK			),		// system clock in
	.BPS_SPEED							(BPS_SPEED			),
	.TX_BYTE							(TX_BYTE			),		// send bytes length
	.STOP_BIT							(STOP_BIT			),		// 1:1bit ; 2:2bit
	.CHECK_EN							(CHECK_EN			),		// 0:off ; 1:on
	.CHECK_PATH							(CHECK_PATH			)		// 0:once ; 1:twice
)uart_tx_inst0(
	.sys_clk							(sys_clk			),
	.sys_rst_n							(sys_rst_n			),
	.uart_tx_on							(tx_on_edge			),		// push on ; high edge valid
	.tx_data							(tx_data			),		// aim data
	.tx_bit_out							(tx_bit_out			),		// bit_data output
	.tx_valid							(tx_valid			),		// aim data send finish
	.tx_busy							(tx_busy			)			// high busy ; low ready
);

endmodule