`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2021 09:58:13
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "L1_cache.v"
`include "memory_trace.v"

module main(clk,reset,L1_hit_count);

    parameter L1_way = 4;
    parameter L1_block_size_byte = 16;
    parameter L1_cache_size_byte = 256;

    parameter L1_block_offset_index = $rtoi($ln(L1_block_size_byte)/$ln(2));
    parameter L1_set = L1_cache_size_byte/(L1_block_size_byte*L1_way);
    parameter L1_set_index = $rtoi($ln(L1_set)/$ln(2));
    parameter L1_way_width = $rtoi($ln(L1_way)/$ln(2));

    input clk,reset;
    wire [31:0] mem_addr;
    wire trace_ready;
    
    output [9:0] L1_hit_count;
    reg updated;    
    
    // variables to divide address in tag, index and offset for L1 cache
    wire [31-L1_set_index-L1_block_offset_index:0] L1_tag;
    wire [L1_set_index-1:0] L1_index;
    wire [L1_block_offset_index-1:0] L1_block_offset;
    
    //L1 cache 
    wire L1_done,L1_found_in_cache,L1_updated;
    reg L1_start;
    

    assign L1_block_offset = mem_addr[L1_block_offset_index-1:0];
    assign L1_index = mem_addr[L1_set_index+L1_block_offset_index-1:L1_block_offset_index];
    assign L1_tag = mem_addr[31:L1_set_index+L1_block_offset_index];       
          
    memory_trace i0 (clk,reset,updated,trace_ready,mem_addr);
    L1_cache #(.way(L1_way),.block_size_byte(L1_block_size_byte),.cache_size_byte(L1_cache_size_byte)) i1  (clk,reset,mem_addr,L1_tag,L1_index,L1_block_offset,L1_start,L1_hit_count,L1_found_in_cache,L1_updated,L1_done);
    
    always @ (negedge clk)
    begin
        updated = L1_updated;
        L1_start = trace_ready;
    end    
endmodule
