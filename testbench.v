`timescale 1ns / 1ns
module testbench();

parameter clk_period = 10;
reg clk;
initial
    clk = 0;
always #(clk_period/2) clk = ~clk;

reg rst_n;
initial
begin
    rst_n = 1'b0;
    #clk_period;
    rst_n = 1'b1;
end

// LTC2324_16
wire            valid;
wire[15:0]      ch1;
wire[15:0]      ch2;
wire[15:0]      ch3;
wire[15:0]      ch4;

wire            CNV;
wire            SCK;
wire            CLKOUT;
wire            SDO1;
wire            SDO2;
wire            SDO3;
reg             SDO4;

// 模拟采样控制信号
parameter sample_en_period = clk_period * 55 * 4;
reg sample_en;
initial
    sample_en = 0;
always #(sample_en_period/2) sample_en = ~sample_en;

// 模拟数据信号
assign SDO1 = 1'b0;
assign SDO2 = 1'b1;
assign SDO3 = 1'bz;
initial
    SDO4 = 0;
always #(clk_period/5) SDO4 = ~SDO4;

LTC2324_16 #(.USE_SCK_SHIFT_DATA(1'b1))
ltc2324
(
    .clk        (clk),
    .rst_n      (rst_n),

    .CNV        (CNV),
    .SCK        (SCK),
    .CLKOUT     (CLKOUT),
    .SDO1       (SDO1),
    .SDO2       (SDO2),
    .SDO3       (SDO3),
    .SDO4       (SDO4),

    .sample_en  (sample_en),

    .valid      (valid),
    .ch1        (ch1),
    .ch2        (ch2),
    .ch3        (ch3),
    .ch4        (ch4)
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
