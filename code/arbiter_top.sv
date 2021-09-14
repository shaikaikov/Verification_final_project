/*
Author-Shai Kaikov.

This file include the interfaces of slave and host files.
In addition the file include the DUT(arbiter) and the package(arbiter_pkg)
with the rest of the files.
*/
`include "arbiter_pkg.sv"
`include "arbiter.sv"
`include "arbiter_if_host.sv"
`include "arbiter_if_slave.sv"

/*
Here the module-top in the name of arbiter_top.
Here I set four interfaces ?? each for each host and one interface for the slave.
Here I inserted into each host interface the bit of the predefined cpu for each host
(host_one_cpu,host_two_cpu,host_three_cpu,host_four_cpu).
In addition I put both the clock(clk) and the reset(reset_n) in both the hosts interfaces and 
the slave interface and then I created an event with the connection of the interfaces to the DUT (arbiter).
The slave interface will go to the slave agent and each host interface will go to each host agent.
Then I defined in uvm_config_db(UVM Configuration Database) which each host interface the host agent would go to
except the interface of the slave-that go to everyone(in the end only the slave monitor used this interface
and not the others).
*/
module arbiter_top;
  import uvm_pkg::*;
  import arbiter_pkg::*;

  bit clk=0;
  bit reset_n=1;
  bit host_one_cpu=1;
  bit host_two_cpu=0;
  bit host_three_cpu=0;
  bit host_four_cpu=0;
  always #2 clk=~clk;
   
  arbiter_if_host host_if_one(clk,reset_n,host_one_cpu);
  arbiter_if_host host_if_two(clk,reset_n,host_two_cpu);
  arbiter_if_host host_if_three(clk,reset_n,host_three_cpu);
  arbiter_if_host host_if_four(clk,reset_n,host_four_cpu);
  arbiter_if_slave slave_if(clk,reset_n);

  arbiter a1(host_if_one.cpu_general,host_if_one.addr_general,
    host_if_one.rd_general,host_if_one.wr_general,host_if_one.be_general,
    host_if_one.dwr_general,host_if_one.drd_general,host_if_one.ack_host_general,

    host_if_two.cpu_general,host_if_two.addr_general,
    host_if_two.rd_general,host_if_two.wr_general,host_if_two.be_general,
    host_if_two.dwr_general,host_if_two.drd_general,host_if_two.ack_host_general,
   
    host_if_three.cpu_general,host_if_three.addr_general,
    host_if_three.rd_general,host_if_three.wr_general,host_if_three.be_general,
    host_if_three.dwr_general,host_if_three.drd_general,host_if_three.ack_host_general,
   
    host_if_four.cpu_general,host_if_four.addr_general,
    host_if_four.rd_general,host_if_four.wr_general,host_if_four.be_general,
    host_if_four.dwr_general,host_if_four.drd_general,host_if_four.ack_host_general,
  
    slave_if.addr_general,slave_if.be_general,
    slave_if.wr_general,slave_if.rd_general,
    slave_if.dwr_general,
    slave_if.drd_general,
    slave_if.ack_slave,slave_if.cpu_general,
    slave_if.clk,slave_if.reset_n);
  
  initial begin 
    uvm_config_db#(virtual arbiter_if_host)::set(null, "uvm_test_top.arbiter_en.hos_agent_expected_actual_one.*" , "arbiter_if_host", host_if_one);
    uvm_config_db#(virtual arbiter_if_host)::set(null, "uvm_test_top.arbiter_en.hos_agent_expected_actual_two.*" , "arbiter_if_host", host_if_two);
    uvm_config_db#(virtual arbiter_if_host)::set(null, "uvm_test_top.arbiter_en.hos_agent_expected_actual_three.*" , "arbiter_if_host", host_if_three);
    uvm_config_db#(virtual arbiter_if_host)::set(null, "uvm_test_top.arbiter_en.hos_agent_expected_actual_four.*" , "arbiter_if_host", host_if_four);
    uvm_config_db#(virtual arbiter_if_slave)::set(null, "*" , "arbiter_if_slave", slave_if);
    run_test("arbiter_test");
  end
endmodule 






