
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
    output wire [DATA_WIDTH-1:0]    rd_data,
    output wire                     empty
);

localparam PTR_WIDTH = ADDR_WIDTH + 1;


reg [PTR_WIDTH-1:0] wr_ptr_bin, rd_ptr_bin;
reg [PTR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
reg [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
reg [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

reg [DATA_WIDTH-1:0] fifo_mem [0:($clog2(ADDR_WIDTH))-1];


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

wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];
always @(posedge wr_clk) begin
    if (wr_en && !full)
        fifo_mem[wr_addr] <= wr_data;
end


wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] rd_data_reg;
always @(posedge rd_clk) begin
    if (rd_en && !empty)
        rd_data_reg <= fifo_mem[rd_addr];
end
assign rd_data = rd_data_reg;

assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

wire [PTR_WIDTH-1:0] wr_ptr_gray_next = (wr_ptr_bin + 1) ^ ((wr_ptr_bin + 1) >> 1);

assign full = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2], rd_ptr_gray_sync2[PTR_WIDTH-3:0]});

endmodule
