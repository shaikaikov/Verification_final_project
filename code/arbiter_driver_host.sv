
/*
Author-Shai Kaikov.

Here the class of the host driver.The class inherit from uvm_driver class.
The driver is inside the host agent.The driver use the interface of the
host(vinf_host)-that communicate with the DUT.
Here I have the constructor("new") of this class,build_phase function,
run_phase task and drive task.
Note! in the drive task I only get new transaction after the current host finished his turn
with the slave or when the flags of read and write are zero(in the task I will explain in detail).
*/
class arbiter_driver_host extends uvm_driver#(arbiter_transaction);
  `uvm_component_utils(arbiter_driver_host) 

  virtual arbiter_if_host vinf_host; //the host interface.

  /*
  The constructor of the arbiter_driver_host-
  class that inherit from uvm_driver.
  The parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
	  super.new(name, parent);
  endfunction

  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function with uvm_config_db(UVM Configuration Database)-I get the poninter of the host interface from database-
  and put him on vinf_host(in type of arbiter_if_host interface).
  */
  function void build_phase(uvm_phase phase);
	  super.build_phase(phase);
    uvm_config_db#(virtual arbiter_if_host)::get(this , "" , "arbiter_if_host", vinf_host);
  endfunction

  /*
  Here the task run_phase that get uvm_phase parameter.
  The task activate the drive task.  
  */
  task run_phase(uvm_phase phase);
	  drive();
  endtask
  
  /*
  here the task drive.
  here the driver communicate with the sequencer(with TLM port-seq_item_port)-
  to get the data and put him in arbiter_tran variable(transaction).
  With arbiter_tran variable I push the signals to the vinf_host interface-that
  send the signals as inputs to the DUT.
  The push of the signals are done in the first falling of the clock in the loop.
  in the second falling of the clock I wait to end of the timeout(ack-host: 11) of the host(that connect with slave now) 
  or wait for ack (that connect with slave now-ack-host: 01) or read and write flags are zero than I continue-in the future 
  I will get new data into the transaction-and push it into the interface host.

  in fact I need the wait in the reason that I only get new tranaction when the current host finished his turn with
  the slave or when the flags(read and write are zero).
  the number of the falling clocks were in order of synchronization.
  */
  virtual task drive();
    arbiter_transaction arbiter_tran;
	  forever begin   	 
      seq_item_port.get_next_item(arbiter_tran);//TLM port-get new data.
      @(negedge vinf_host.clk)begin
  	    vinf_host.addr_general<=arbiter_tran.addr_general;
  	    vinf_host.rd_general<=arbiter_tran.rd_general;
  	    vinf_host.wr_general<=arbiter_tran.wr_general;
  	    vinf_host.be_general<=arbiter_tran.be_general;
  	    vinf_host.dwr_general<=arbiter_tran.dwr_general;
      end
      @(negedge vinf_host.clk)begin     
        wait(vinf_host.ack_host_general[0]==1 || (vinf_host.ack_host_general[1]==1 && vinf_host.ack_host_general[0]==1) || (vinf_host.wr_general==0 && vinf_host.rd_general==0));
        if(vinf_host.ack_host_general[0]==1 || vinf_host.ack_host_general[1]==1)begin
          @(negedge vinf_host.clk);
        end
      end
      seq_item_port.item_done();//TLM finished with the data.
	  end
  endtask
endclass


