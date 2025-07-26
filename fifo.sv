
module dual_clock_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4 
)(
    input  wire                     wr_clk,
    input  wire                     rd_clk,
    input  wire                     rst_n,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    input  wire                     wr_en,
    output wire                     full,
    input  wire                     rd_en,
    output reg [DATA_WIDTH-1:0]    rd_data,
    output wire                     empty
);




reg [ADDR_WIDTH-1:0] wr_ptr_bin, rd_ptr_bin;
reg [ADDR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
reg [ADDR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
reg [ADDR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

reg [DATA_WIDTH-1:0] fifo_mem [($clog2(ADDR_WIDTH))-1:0];


always @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr_bin  <= 0;
        wr_ptr_gray <= 0;
    end else if (wr_en && !full) begin
        wr_ptr_bin  <= wr_ptr_bin + 1;
        wr_ptr_gray <= (wr_ptr_bin + 1) ^ ((wr_ptr_bin + 1) >> 1);
    end
end


always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr_bin  <= 0;
        rd_ptr_gray <= 0;
    end else if (rd_en && !empty) begin
        rd_ptr_bin  <= rd_ptr_bin + 1;
        rd_ptr_gray <= (rd_ptr_bin + 1) ^ ((rd_ptr_bin + 1) >> 1);
    end
end


always @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end


always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end


always @(posedge wr_clk) begin
    if (wr_en && !full)
        fifo_mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
end



always @(posedge rd_clk) begin
    if (rd_en && !empty)
        rd_data <= fifo_mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
end


assign empty = (rd_ptr_gray == wr_ptr_gray_sync2)?1:0;

wire [ADDR_WIDTH-1:0] wr_ptr_gray_next = (wr_ptr_bin + 1) ^ ((wr_ptr_bin + 1) >> 1);

assign full = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[ADDR_WIDTH-1:ADDR_WIDTH-2], rd_ptr_gray_sync2[ADDR_WIDTH-3:0]})?1:0;

endmodule
