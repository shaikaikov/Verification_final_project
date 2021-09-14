
/*
Author-Shai Kaikov.

Here the class of the slave driver.The class inherit from uvm_driver class.
The driver is inside the slave agent.The driver use the interface of the
slave(vinf_slave)-that communicate with the DUT.
Here I have the constructor("new") of this class,build_phase function,
run_phase task and drive2 task.
*/
class arbiter_driver_slave extends uvm_driver#(arbiter_transaction);
  `uvm_component_utils(arbiter_driver_slave)

  virtual arbiter_if_slave vinf_slave; //the slave interface.

  /*
  The constructor of the arbiter_driver_slave-
  class that inherit from uvm_driver.
  the parameters of the constructor are string(name) and uvm_component(parent).
  */
  function new(string name, uvm_component parent);
	  super.new(name, parent);
  endfunction

  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function with uvm_config_db(UVM Configuration Database)-I get the poninter of the slave interface from database-
  and put him on vinf_host(in type of arbiter_if_slave interface).
  */
  function void build_phase(uvm_phase phase);
	  super.build_phase(phase);
    uvm_config_db#(virtual arbiter_if_slave)::get(this , "" , "arbiter_if_slave", vinf_slave);
  endfunction

  /*
  Here the task run_phase that get uvm_phase parameter.
  The task activate the drive2 task.  
  */
  task run_phase(uvm_phase phase);
	  drive2();
  endtask

  /*
  Here the task drive2.
  At the beginning I declare three variables - which I will now detail what their function is.
  At the beginning of the loop I choose the variable time_send_ack
  (a variable that actually represents the number of clocks in which I will send the ack) a random number
  in the range between 140,000 and 0 Why actually?
  To divide by a 50 percent probability that the same host that communicates with 
  the slave will have a timeout and the remaining fifty percent will be for sending the ack of the response 
  from the slave.Note! the driver of the slave himself dont know the real timeout-and when I have zero in read and write
  flags I actually reset everything(if was sent ack before timeout I will reset everything also)
  -in order to start everything to the next host turn. 
  For the read variable I choose a random number of 32 bits.
  The count represents to me the count of clock drops in order to 
  finally reach the number of the time_send_ack to send the ack.
  After the DUT ouput read or write flag is one I start the count the loop untill the ack(time_send_ack) will be send.
  Of course the count constantly rises only one more of the flags of reading or writing 
  (outputs of the DUT of the slave) are equal to one and the sending of the ack and the read data are
  sent only when the count has reached and equal to time_send_ack and also 
  when one of the flags is equal to one.
  Than I reset everything -in order to start everything to the next host turn. 
  */
  virtual task drive2(); 
	  int time_send_ack;
    int count;
    bit[31:0] read;
	  forever begin
      std::randomize(time_send_ack) with {0 <= time_send_ack; time_send_ack <= 140000;};
      std::randomize(read) with {{32{1'b0}} <= read; read <= {32{1'b1}};};
      count=-1;
      wait(vinf_slave.rd_general==1 || vinf_slave.wr_general==1);
      while(vinf_slave.rd_general==1 || vinf_slave.wr_general==1)begin
        count++;
        @(negedge vinf_slave.clk)begin
          if((time_send_ack==count) &&(vinf_slave.rd_general==1 || vinf_slave.wr_general==1))begin
            vinf_slave.ack_slave<=1;
            vinf_slave.drd_general<=read;
          end  
          else begin
            vinf_slave.ack_slave<=0;
          end
        end  
      end      
	  end
  endtask
endclass





