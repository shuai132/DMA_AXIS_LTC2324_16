`timescale 1ns / 1ns
module testbench();

parameter clk_period = 10;
reg adc_clk;
initial
    adc_clk = 0;
always #(clk_period/2) adc_clk = ~adc_clk;

reg dma_clk;
initial
    dma_clk = 0;
always #(clk_period/10) dma_clk = ~dma_clk;

reg rst_n;
initial
begin
    rst_n = 1'b0;
    #clk_period;
    rst_n = 1'b1;
end

wire            adc_CNV;
wire            adc_SCK;
wire            adc_CLKOUT;
wire            adc_SDO1;
wire            adc_SDO2;
wire            adc_SDO3;
reg             adc_SDO4;

// 模拟采样控制信号
parameter sample_en_period = clk_period * 55 * 10;
reg sample_en;
initial
begin
    sample_en = 0;
    #100
    sample_en = 1;
end
always #(sample_en_period/2) sample_en = ~sample_en;

// 模拟数据信号
assign adc_SDO1 = 1'b0;
assign adc_SDO2 = 1'b1;
assign adc_SDO3 = 1'bz;
initial
    adc_SDO4 = 0;
always #(clk_period/5) adc_SDO4 = ~adc_SDO4;

AXI_DMA_LTC2324_16 #(.TEST_MODE(1'b1))
AXI_DMA_LTC2324_16_inst
(
    .adc_clk        (adc_clk),
    .adc_rst_n      (rst_n),

    .adc_CNV        (adc_CNV),
    .adc_SCK        (adc_SCK),
    .adc_CLKOUT     (adc_CLKOUT),
    .adc_SDO1       (adc_SDO1),
    .adc_SDO2       (adc_SDO2),
    .adc_SDO3       (adc_SDO3),
    .adc_SDO4       (adc_SDO4),

    .sample_len     (32'd128),
    .sample_start   (sample_en),

    .DMA_CLK        (dma_clk),
    .DMA_AXIS_tready(1'b1),
    .DMA_RST_N      (rst_n)
);

integer k = 0;
initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, testbench);

  for (k = 0; k < sample_en_period * 2; k = k + 1)
    #1 $display("%d ns", k);
  $finish;
end

endmodule
