// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

    counter #(
        .BITS(BITS)
    ) counter(
        .clk(clk),
        .reset(la_data_in[0]),
        .trace_ready(la_data_in[1]),
        .mem_addr(la_data_in[33:2]),
        .L1_hit_count(la_data_out[9:0]),
        .L2_hit_count4(la_data_out[19:10]),
        .L2_hit_count8(la_data_out[29:20]),
        .L2_hit_count16(la_data_out[39:30]),
        .L2_ss1_count4(la_data_out[49:40]),
        .L2_ss1_count8(la_data_out[59:50]),
        .L2_ss1_count16(la_data_out[69:60]),
        .L2_ss2_count4(la_data_out[79:70]),
        .L2_ss2_count8(la_data_out[89:80]),
        .L2_ss2_count16(la_data_out[99:90])
    );

endmodule

module main(clk,reset,trace_ready,mem_addr,L1_hit_count,L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16);

    parameter L1_way = 4;
    parameter L1_block_size_byte = 16;
    parameter L1_cache_size_byte = 1*1024;
    
    parameter L2_way = 16;
    parameter L2_block_size_byte = 16;
    parameter L2_set_size = 64;
    
    parameter L1_block_offset_index = $rtoi($ln(L1_block_size_byte)/$ln(2));
    parameter L1_set = L1_cache_size_byte/(L1_block_size_byte*L1_way);
    parameter L1_set_index = $rtoi($ln(L1_set)/$ln(2));
    parameter L1_way_width = $rtoi($ln(L1_way)/$ln(2));
    
    parameter L2_block_offset_index = $rtoi($ln(L2_block_size_byte)/$ln(2));
    parameter L2_set_index = $rtoi($ln(L2_set_size)/$ln(2));
    parameter L2_way_width = $rtoi($ln(L2_way)/$ln(2));

    input clk,trace_ready,reset;
    input [31:0] mem_addr;
    
    output [19:0] L1_hit_count,L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16;
    wire updated;    
    
    // variables to divide address in tag, index and offset for L1 cache
    wire [31-L1_set_index-L1_block_offset_index:0] L1_tag;
    wire [L1_set_index-1:0] L1_index;
    wire [L1_block_offset_index-1:0] L1_block_offset;
    
    // variables to divide address in tag, index and offset for L2 cache
    wire [31-L2_set_index-L2_block_offset_index:0] L2_tag;
    wire [L2_set_index-1:0] L2_index;
    wire [L2_block_offset_index-1:0] L2_block_offset;
    
    //L1 cache 
    wire L1_done,L1_found_in_cache,L1_updated;
    
    //L2 cache
    wire L2_done,L2_found_in_cache,L2_updated ;    
    wire [L2_way_width:0] L2_hit_way;
    
    //Subset cache1
    wire ss1_found_in_cache,ss1_updated;
    wire [L2_way_width:0] ss1_hit_way;
    
    //Subset cache2
    wire ss2_found_in_cache,ss2_updated;
    wire [L2_way_width:0] ss2_hit_way;
    wire [L2_set_index-2:0] ss1_index;
    
    //prefetcher
    wire prefetch_hit,prefetch_done;
    

    assign L1_block_offset = mem_addr[L1_block_offset_index-1:0];
    assign L1_index = mem_addr[L1_set_index+L1_block_offset_index-1:L1_block_offset_index];
    assign L1_tag = mem_addr[31:L1_set_index+L1_block_offset_index];
    
    assign L2_block_offset = mem_addr[L2_block_offset_index-1:0];
    assign L2_index = mem_addr[L2_set_index+L2_block_offset_index-1:L2_block_offset_index];
    assign L2_tag = mem_addr[31:L2_set_index+L2_block_offset_index]; 
    
    assign ss1_index = L2_index[L2_set_index-2:0];
    assign updated = !prefetch_hit&&ss1_updated ? 1'b1 : L1_updated&&(prefetch_hit||L1_found_in_cache) ? 1'b1 :  1'b0;      
    
    L1_cache #(.way(L1_way),.block_size_byte(L1_block_size_byte),.cache_size_byte(L1_cache_size_byte)) i1  (clk,reset,L1_tag,L1_index,L1_block_offset,trace_ready,prefetch_hit,L2_found_in_cache,L1_hit_count,L1_found_in_cache,L1_updated,L1_done,prefetch_done);
    L2_cache #(.way(L2_way),.block_size_byte(L2_block_size_byte),.set_size(L2_set_size)) i2 (clk,reset,L2_tag,L2_index,L2_block_offset,(prefetch_done && !prefetch_hit),L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_found_in_cache,L2_hit_way,L2_done,L2_updated);
    L2_cache_subset #(.way(L2_way),.block_size_byte(L2_block_size_byte),.set_size(L2_set_size/2)) i3 (clk,reset,L2_index,L2_updated,L2_found_in_cache,L2_hit_way,ss1_found_in_cache,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,ss1_hit_way,ss1_updated);
    L2_cache_subset #(.way(L2_way),.block_size_byte(L2_block_size_byte),.set_size(L2_set_size/4)) i4 (clk,reset,ss1_index,ss1_updated,ss1_found_in_cache,ss1_hit_way,ss2_found_in_cache,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16,ss2_hit_way,ss2_updated);
    prefetcher #(.way(L1_way),.block_size_byte(L1_block_size_byte),.cache_size_byte(L1_cache_size_byte)) i5(clk,mem_addr,(L1_done && !L1_found_in_cache),prefetch_hit);
    
endmodule

module L1_cache(clk,reset,tag,index,block_offset,find_start,prefetch_hit,L2_cache_hit,cache_hit_count,found_in_cache,updated,done_L1,done_prefetch);

    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    parameter cache_line_width = 32-set_index-block_offset_index+1;
    
    input clk,find_start,L2_cache_hit,prefetch_hit,reset;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    output reg found_in_cache;
    output reg [19:0] cache_hit_count;
    output reg updated,done_L1,done_prefetch;
    
    reg [1:0]find_state;
    reg [1:0]flag;
    reg bi_flag;
    reg [way_width:0] way_index;
    reg [way_width-1:0] hit_way;
    reg [cache_line_width-1:0] cache [0:set-1][0:way-1];
    reg [cache_line_width-1:0] temp_content;
    reg [cache_line_width-1:0] temp_content1 [0:way-1];
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count = 0;        
        find_state = 0;
        flag = 0;
        bi_flag = 0;
        updated = 0;
        done_prefetch = 0;
        for (i=0;i<set;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;
            cache_hit_count = 0;
            //cache_miss_count = 0;
            find_state = 0;
            flag = 0;
            bi_flag = 0;
            updated = 0;
            done_prefetch = 0;
            for (i=0;i<set;i=i+1)
                for (j=0;j<way;j=j+1)
                    cache[i][j] = 0;     
        end
        else
        begin
            case (find_state)
                2'b00: begin          
                        found_in_cache = 1'b0;
                        if(find_start)
                        begin                        
                            find_state = 2'b01;                        
                            done_L1 = 1'b0;
                        end        
                      end
                      
                2'b01: begin
                  
                        if (done_L1 && !found_in_cache)
                        begin
                            find_state = 2'b10;
                            done_L1 = 1'b0;
                        end    
                        else if (done_L1 && found_in_cache)
                        begin
                            find_state = 2'b11;
                            done_L1 = 1'b0;
                        end    
                        else
                        begin
                            for (way_index=0;way_index<way;way_index=way_index+1'b1)
                            begin
                                if(cache[index][way_index][cache_line_width-1]) // valid bit
                                begin
                                    if(cache[index][way_index][cache_line_width-2:0]==tag) // tag comparison
                                    begin
                                        found_in_cache = 1'b1;                                    
                                        hit_way = way_index;                                    
                                        temp_content = cache[index][way_index];
                                        cache_hit_count = cache_hit_count + 1'b1;
                                        done_L1 = 1'b1;                                    
                                    end
                               end                                                                                                                                                                                                                                                                                                                                                                                                                                
                            end                                               
                            if (way_index==way&&!found_in_cache)
                            begin
                                    //cache_miss_count = cache_miss_count + 1'b1; 
                                    found_in_cache = 1'b0;                                
                                    done_L1 = 1'b1;
                            end                                                  
                        end 
                       end
    
                2'b10: begin
                        if(done_prefetch)
                        begin
                            find_state= 2'b11;
                            done_prefetch = 1'b0;
                            flag = 1'b0;
                        end   
                        else
                        begin
                            if(!flag)
                                flag = 1'b1;
                            else
                            begin
                                if(prefetch_hit&flag)                        
                                begin
                                    flag = 1'b0;
                                    cache_hit_count = cache_hit_count + 1'b1;                                     
                                end
                                //else                                                                
                                    //cache_miss_count = cache_miss_count + 1'b1;                              
                                done_prefetch = 1'b1;
                            end            
                        end
                       end                                                        
                       
                2'b11: begin                
                        if(updated)
                        begin
                            find_state = 2'b00;
                            updated = 1'b0;
                        end
                        
                        else
                        begin
                            if(found_in_cache) // hit
                            begin  
                                if(hit_way != 0)
                                    begin
                                        cache[index][hit_way] = cache[index][hit_way-1];
                                        hit_way = hit_way - 1;
                                    end
                                    else
                                    begin            
                                        cache[index][0] = temp_content;
                                        updated = 1'b1;
                                    end                                    
                            end 
                            
                            else // miss
                            begin
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                            
                                    cache[index][way_index+1] = cache[index][way_index];                                    
        
                                cache[index][1] = cache[index][0];
                                cache[index][0] = {1'b1,tag};  
                                updated = 1'b1;                                                  
                            end                                                                                                                                                                                                              
                        end 
                                                  
                       end                     
            endcase
         end       
    end   
    
endmodule

module L2_cache(clk,reset,tag,index,block_offset,find_start,cache_hit_count4,cache_hit_count8,cache_hit_count16,found_in_cache,hit_way,done,updated);

    parameter way = 16;
    parameter block_size_byte = 16;
    parameter set_size = 64;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2)); 
    parameter set_index = $rtoi($ln(set_size)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    parameter cache_line_width = 32-set_index-block_offset_index+1; 
    
    input clk,find_start,reset;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    output reg found_in_cache;
    // this needs to get parameterized based on number of max associativity        
    output reg [19:0] cache_hit_count4;
    output reg [19:0] cache_hit_count8;
    output reg [19:0] cache_hit_count16;
    output reg [way_width:0] hit_way;   
    output reg updated,done;        
    
    reg [1:0]find_state;
    reg [way_width:0] way_index;    
    reg [cache_line_width-1:0] cache [0:set_size-1][0:way-1];
    reg [cache_line_width-1:0] temp_content;
    //reg [19:0] hit_count [way-1:0];
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;        
        cache_hit_count4 = 0;        
        cache_hit_count8 = 0;
        cache_hit_count16 = 0;                
        find_state = 0;
        updated = 0;        
        for (i=0;i<set_size;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;        
            cache_hit_count4 = 0;        
            cache_hit_count8 = 0;
            cache_hit_count16 = 0;                   
            find_state = 0;
            updated = 0;            
            for (i=0;i<set_size;i=i+1)
                for (j=0;j<way;j=j+1)
                    cache[i][j] = 0;    
        end
        else
        begin
            case (find_state)
                2'b00: begin          
                        found_in_cache = 1'b0;                             
                        if(find_start)
                        begin
                            find_state = 2'b01;                        
                            done = 1'b0;
                        end        
                      end
                      // Find cache state (to check if particular memory address data is present in cache or not)
                      
                2'b01: begin
                  
                        if (done)
                        begin
                            find_state = 2'b10;                                                   
                        end        
                        else
                        begin
                            for (way_index=0;way_index<way;way_index=way_index+1'b1)
                            begin
                                if(cache[index][way_index][cache_line_width-1]) // valid bit
                                begin
                                    if(cache[index][way_index][cache_line_width-2:0]==tag) // tag comparison
                                    begin
                                        found_in_cache = 1'b1;                                    
                                        hit_way = way_index;                                    
                                        temp_content = cache[index][way_index];                                    
                                    end
                               end                                                                                          
                            end                        
                            if (found_in_cache)
                            begin
                                if (hit_way>=0 && hit_way<4)
                                begin
                                    cache_hit_count4 = cache_hit_count4 + 1;
                                    cache_hit_count8 = cache_hit_count8 + 1;
                                    cache_hit_count16 = cache_hit_count16 + 1;
                                end
                                else if (hit_way>=4 && hit_way<8)
                                begin
                                    cache_hit_count8 = cache_hit_count8 + 1;
                                    cache_hit_count16 = cache_hit_count16 + 1;
                                end
                                else if (hit_way>=8 && hit_way<16)
                                begin                                    
                                    cache_hit_count16 = cache_hit_count16 + 1;
                                end
                                done = 1'b1;
                                way_index = hit_way;                                                                                      
                            end  
                            else                                                                
                            begin
                                hit_way = way;
                                done = 1'b1;
                            end                                                  
                        end 
                       end
                      
                       // Updation of cache according LRU shift register policy
                2'b10: begin                
                        if(updated)
                        begin
                            find_state = 2'b00;
                            updated = 1'b0;
                        end
                        else
                        begin                            
                            if(found_in_cache) // hit
                            begin 
                                   if(way_index != 0)
                                    begin
                                        cache[index][way_index] = cache[index][way_index-1];
                                        way_index = way_index - 1;
                                    end
                                    else
                                    begin            
                                        cache[index][0] = temp_content;
                                        updated = 1'b1;
                                    end                                                                       
                            end    
                            else // miss
                            begin                                                                                          
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                            
                                  cache[index][way_index+1] = cache[index][way_index];                                    
    
                                cache[index][1] = cache[index][0];
                                cache[index][0] = {1'b1,tag};
                                updated = 1'b1;             
                            end                                                                                    
                        end                           
                       end 
                        
            endcase
         end       
    end  
endmodule

module L2_cache_subset(clk,reset,msb_index,find_start,L2_found_in_cache,hit_way,found_in_cache,cache_hit_count4,cache_hit_count8,cache_hit_count16,hit_source,updated);

    parameter way = 16;
    parameter block_size_byte = 16;
    parameter set_size = 512;   
    parameter set_index = $rtoi($ln(set_size)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    
    
    input clk,find_start,reset,L2_found_in_cache;
    input [way_width:0] hit_way;
    input [set_index:0] msb_index;
    output reg found_in_cache;
    // this needs to get parameterized based on number of max associativity
    output reg [19:0] cache_hit_count4;
    output reg [19:0] cache_hit_count8;
    output reg [19:0] cache_hit_count16;
    output reg updated;
    output reg [way_width:0] hit_source;
    
    reg msb_indexbit,msb_update,mask_update;
    reg [set_index-1:0] index;        
    reg [way_width:0] way_index; 
      
    reg mask0 [0:set_size-1][0:way-1];
    reg mask1 [0:set_size-1][0:way-1];
    reg [1:0] source [0:set_size-1][0:way-1];
    reg [1:0] temp_data;
    reg temp_source;
    reg [way_width:0] count;
    //reg [19:0] hit_count [way-1:0];
    
    reg [1:0]find_state;
    reg done;    
    
    integer i,j;
    
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count4 = 0;        
        cache_hit_count8 = 0;
        cache_hit_count16 = 0;
        //cache_miss_count = 0;        
        find_state = 0;
        temp_data = 0;   
        msb_update = 0;  
        mask_update = 0;   
        for (i=0;i<set_size;i=i+1)
        begin
            for (j=0;j<way;j=j+1)
            begin
                source[i][j] = 0;
                mask0[i][j] = 0;
                mask1[i][j] = 0;
            end
        end
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;
            cache_hit_count4 = 0;        
            cache_hit_count8 = 0;
            cache_hit_count16 = 0;                    
            find_state = 0;
            temp_data = 0;            
            for (i=0;i<set_size;i=i+1)
            begin
                for (j=0;j<way;j=j+1)
                begin
                    source[i][j] = 0;
                    mask0[i][j] = 0;
                    mask1[i][j] = 0;
                end
            end
        end
        else
        begin
            case (find_state)
                2'b00: begin          
                                                     
                        if(find_start)
                        begin
                            found_in_cache = 1'b0;
                            find_state = 2'b01;                        
                            done = 1'b0;                        
                        end                            
                       end
                       
                2'b01: begin
                       
                       if (done)
                       begin
                           find_state = 2'b10;
                           count = 0;
                       end     
                       else
                       begin
                          // to check if there is hit in cache 
                          msb_indexbit = msb_index[set_index];
                          index[set_index-1:0] = msb_index[set_index-1:0];                          
                          if (L2_found_in_cache)
                          begin
                              if (msb_indexbit)
                              begin                          
                                 if(mask1[index][hit_way])
                                 begin                            
                                    temp_source = 1'b1;                         
                                    found_in_cache = 1'b1;
                                 end                               
                              end
                              else if (!msb_indexbit)
                              begin                                                    
                                 if(mask0[index][hit_way]) // mask0[0][16]
                                 begin                           
                                    temp_source = 1'b0;
                                    found_in_cache = 1'b1;
                                 end   
                              end
                              if (found_in_cache)                      
                              begin                         
                                 way_index = 0;
                                 if(temp_source)
                                 begin
                                    for(way_index=0;way_index<way;way_index=way_index+1)
                                    begin
                                        if(source[index][way_index]==2'b11&&count<hit_way+1)
                                            count = count + 1;
                                        if(count==hit_way+1)
                                        begin                                    
                                            temp_data =  source[index][way_index]; 
                                            hit_source = way_index;
                                            count = count + 1;
                                        end                                    
                                    end               
                                 end
                                 else if (!temp_source)
                                 begin
                                    for(way_index=0;way_index<way;way_index=way_index+1)
                                    begin
                                        if(source[index][way_index]==2'b10&&count<hit_way+1)
                                            count = count + 1;
                                        if(count==hit_way+1)
                                        begin                                    
                                            temp_data =  source[index][way_index]; 
                                            hit_source = way_index;
                                            count = count + 1;
                                        end                                    
                                    end                                                   
                                 end                                                         
                                 
                                    if (hit_source>=0 && hit_source<4)
                                    begin
                                        cache_hit_count4 = cache_hit_count4 + 1;
                                        cache_hit_count8 = cache_hit_count8 + 1;
                                        cache_hit_count16 = cache_hit_count16 + 1;
                                    end
                                    else if (hit_source>=4 && hit_source<8)
                                    begin
                                        cache_hit_count8 = cache_hit_count8 + 1;
                                        cache_hit_count16 = cache_hit_count16 + 1;
                                    end
                                    else if (hit_source>=8 && hit_source<16)
                                    begin                                    
                                        cache_hit_count16 = cache_hit_count16 + 1;
                                    end
                                 way_index = hit_source;
                                 done = 1'b1;                              
                            end
                            else
                            begin                                                          
                             hit_source = way;
                             done = 1'b1;      
                            end

                          end
                          
                          else
                          begin                            
                             hit_source = way;
                             done = 1'b1;      
                          end
                       end     
                       end
               2'b10: begin
                      
                      if(updated)
                      begin
                        find_state = 2'b00;
                        updated = 1'b0;
                        count = 0;
                      end
                      else
                      begin
                        if(found_in_cache)
                        begin
                            
                           if(msb_indexbit && !msb_update && !mask_update)
                           begin
                              if(way_index != 0)
                              begin
                                mask1[index][way_index] = mask1[index][way_index-1];
                                way_index = way_index - 1;
                              end
                              else
                              begin            
                                mask1[index][0] = 1'b1;
                                msb_update = 1'b1;
                              end                                                                                                                               
                                                               
                           end
                           else if (!msb_indexbit && !msb_update && !mask_update)
                           begin
                              if(way_index != 0)
                              begin
                                mask0[index][way_index] = mask0[index][way_index-1];
                                way_index = way_index - 1;
                              end
                              else
                              begin            
                                mask0[index][0] = 1'b1;
                                msb_update = 1'b1;                                
                              end                                                                                                                               
                                                               
                           end
                           if (msb_update && !mask_update)
                           begin
                            for(way_index=0;way_index<way;way_index=way_index+1)
                            begin
                                if(mask0[index][way_index])
                                    count = count + 1;
                                if(mask1[index][way_index])
                                    count = count + 1;    
                            end                                                       
                            
                            // if count>way then we have to change one of mask from 1 to 0 based on LRU
                            if(count>way)
                            begin
                                if(source[index][way-1] == 2'b11)
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask1[index][way_index])
                                        way_index = way_index - 1;
                                    mask1[index][way_index] = 1'b0;                                   
                                end
                                else if (source[index][way-1] == 2'b10)
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask0[index][way_index])
                                        way_index = way_index - 1;
                                    mask0[index][way_index] = 1'b0;                                
                                end    
                            end
                            mask_update = 1'b1;
                            way_index = hit_source;
                            msb_update = 1'b0;
                           end
                           if(mask_update)
                           begin
                               if(way_index != 0)
                               begin
                                    source[index][way_index] = source[index][way_index-1];
                                    way_index = way_index - 1;
                               end
                               else
                               begin
                                    mask_update = 1'b0;                                           
                                    source[index][0] = temp_data;
                                    updated = 1'b1;
                               end                                                                                                                               
                           end                                                      
                        end                   
                        else // cache miss
                        begin
                                                                       
                            // update mask register
                            if(msb_indexbit)
                            begin
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                                         
                                    mask1[index][way_index+1] = mask1[index][way_index];
                                mask1[index][1] = mask1[index][0];
                                mask1[index][0] = 1'b1;                                  
                            end
                            else
                            begin
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                                         
                                    mask0[index][way_index+1] = mask0[index][way_index];
                                mask0[index][1] = mask0[index][0];
                                mask0[index][0] = 1'b1;           
                            end
                            
                            // after updating  the mask registers check count of 1's in both mask 0 and 1                        
                            for(way_index=0;way_index<way;way_index=way_index+1)
                            begin
                                if(mask0[index][way_index])
                                    count = count + 1;
                                if(mask1[index][way_index])
                                    count = count + 1;    
                            end                                                       
                            
                            // if count>way then we have to change one of mask from 1 to 0 based on LRU
                            if(count>way)
                            begin
                                if(source[index][way-1] == 2'b11)
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask1[index][way_index])
                                        way_index = way_index - 1;
                                    mask1[index][way_index] = 1'b0;                                   
                                end
                                else if (source[index][way-1] == 2'b10)
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask0[index][way_index])
                                        way_index = way_index - 1;
                                    mask0[index][way_index] = 1'b0;                                
                                end    
                            end
                            
                             // update source register
                            for(way_index=way-2;way_index>0;way_index=way_index-1)                                         
                                source[index][way_index+1] = source[index][way_index];                                                                                               
                            source[index][1] = source[index][0];
                            source[index][0] = {1'b1,msb_indexbit};                               
                            updated = 1'b1;
                                    
                        end
                      end
               
                      end
                                  
            endcase
         end                 
    end    
endmodule


module prefetcher (clk,address,cache_miss,prefetch_hit);

    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));  //2
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
     
    parameter prefetch_width = 32-block_offset_index  + 1; // without data (tag+index+valid) 
    
    input clk,cache_miss;
    input [31:0]address;
    output reg prefetch_hit;
    
    
    wire [31-set_index-block_offset_index:0] tag;      // 23 bits..22:0
    wire [set_index-1:0] index;                        //7 bits...6:0
    wire [block_offset_index-1:0] block_offset;         //2 bits...1:0
    
     
    wire [set_index-1:0]temp_index;
    wire [5:0]prefetch_fill_index;
    wire valid_buffer_check, valid_fill_check;
    
    reg [prefetch_width-1:0]prefetch_buffer[0:7];
    wire [2:0] hit_index;
    reg [2:0] way_index;    
    reg [1:0] find_state;
    reg done,updated;
    reg [prefetch_width-1:0] temp_data;
    integer k;
     
     assign block_offset = address[block_offset_index-1:0];
     assign index = address[set_index+block_offset_index-1:block_offset_index];
     assign tag =address[31:set_index+block_offset_index];
     assign temp_index = index + 1;
         
     assign valid_buffer_check = (prefetch_buffer[0][prefetch_width-1] && (prefetch_buffer[0][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[1][prefetch_width-1] && (prefetch_buffer[1][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[2][prefetch_width-1] && (prefetch_buffer[2][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[3][prefetch_width-1] && (prefetch_buffer[3][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[4][prefetch_width-1] && (prefetch_buffer[4][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[5][prefetch_width-1] && (prefetch_buffer[5][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[6][prefetch_width-1] && (prefetch_buffer[6][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[7][prefetch_width-1] && (prefetch_buffer[7][prefetch_width-2:0]==address[31:block_offset_index])); 
     
     assign hit_index = (prefetch_buffer[0][prefetch_width-1] && (prefetch_buffer[0][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b000 :     
                        (prefetch_buffer[1][prefetch_width-1] && (prefetch_buffer[1][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b001 :
                        (prefetch_buffer[2][prefetch_width-1] && (prefetch_buffer[2][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b010 :
                        (prefetch_buffer[3][prefetch_width-1] && (prefetch_buffer[3][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b011 : 
                        (prefetch_buffer[4][prefetch_width-1] && (prefetch_buffer[4][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b100 :
                        (prefetch_buffer[5][prefetch_width-1] && (prefetch_buffer[5][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b101 :
                        (prefetch_buffer[6][prefetch_width-1] && (prefetch_buffer[6][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b110 : 3'b111;
                        
     
     assign valid_fill_check = (prefetch_buffer[0][prefetch_width-1] && (prefetch_buffer[0][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[1][prefetch_width-1] && (prefetch_buffer[1][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[2][prefetch_width-1] && (prefetch_buffer[2][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[3][prefetch_width-1] && (prefetch_buffer[3][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[4][prefetch_width-1] && (prefetch_buffer[4][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[5][prefetch_width-1] && (prefetch_buffer[5][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[6][prefetch_width-1] && (prefetch_buffer[6][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[7][prefetch_width-1] && (prefetch_buffer[7][prefetch_width-2:0]=={tag,temp_index}));
     initial
     begin
        for (k=0;k<8;k=k+1)
            prefetch_buffer[k] = 0;
        done = 0;
        updated = 0;
        prefetch_hit = 0;
        find_state = 0;        
    end
    
    always @ (posedge clk)
    begin
        case(find_state)
            2'b00: begin
                    done = 1'b0;
	                prefetch_hit = 1'b0;
                    if(cache_miss)
                    begin
                        find_state = 2'b01;
                    end    
                  end
                  
            2'b01: begin
                    if(done)
                        find_state = 2'b10;
                    else
                    begin                                           
                        if(valid_buffer_check)
                        begin
                            prefetch_hit = 1'b1;
                            done = 1'b1;
                        end
                        else 
                        begin
                            done =1'b1;
                            prefetch_hit=1'b0;
                        end
                     end                                                        
                   end
            
            2'b10: begin
                    if(updated)
                    begin
                        find_state = 2'b00;
                        updated = 1'b0;
                    end
                    else
                    begin
                        if(!prefetch_hit)
                        begin
                            if(valid_fill_check)
                                updated = 1'b1;
                            else
                            begin    
                                prefetch_buffer[7] = prefetch_buffer[6];
                                prefetch_buffer[6] = prefetch_buffer[5];
                                prefetch_buffer[5] = prefetch_buffer[4];
                                prefetch_buffer[4] = prefetch_buffer[3];
                                prefetch_buffer[3] = prefetch_buffer[2];
                                prefetch_buffer[2] = prefetch_buffer[1];
                                prefetch_buffer[1] = prefetch_buffer[0];
                                prefetch_buffer[0] = {1'b1,tag,temp_index};
                                updated = 1'b1;
                             end                                                                     
                        end
                        
                        if(prefetch_hit)
                        begin
                            temp_data = prefetch_buffer[hit_index];
                            for (way_index=0;way_index<hit_index;way_index=way_index+1)
                                prefetch_buffer[hit_index-way_index]= prefetch_buffer[hit_index-way_index-1];
                            prefetch_buffer[0] = temp_data;
                                                        
                            updated = 1'b1;             
                        end
                                                
                    end
                   end       
        endcase
    end
endmodule
