
/*
Author-Shai Kaikov.

Here the interface of the slave. The interface include address(addr_general),
enbale(be_general),write flag(wr_general),read flag(rd_general),
data write(dwr_general),data read(drd_general),ack flag(ack_slave) and cpu flag(cpu_general).
In addition its include clock(clk) and reset flag(reset_n) that are
can change in the arbiter_top module. 
*/
interface arbiter_if_slave(input logic clk,input logic reset_n);
  logic [31:0] addr_general;
  logic [3:0] be_general;
  logic wr_general;
  logic rd_general;
  logic [31:0] dwr_general;
  logic [31:0] drd_general;
  logic ack_slave;
  logic cpu_general;
  modport DUT_SLAVE (output addr_general,output be_general,output wr_general,output rd_general,output dwr_general,input drd_general,input ack_slave,output cpu_general,input clk,input reset_n);
endinterface

