
/*
Author-Shai Kaikov.

This is the slave-monitor class.
The class inherit from uvm_monitor class.
The monitor is inside the slave agent.
The class include -vinf_slave interface pointer(slave interface in type of arbiter_if_slave),
mon_slave_expected_actual in type of uvm_analysis_port(TLM) and
transaction object-arbiter_tran(in type of arbiter_transaction).
In addition the class contain two covergroups-cg_outputs_one_input and cg_read_input.
Why are they two? one for sample for write or read flags are one and the
second for the read data if was ack and if was read flag(this in the task run_phase).
This class contain obviously constructor(new),build_phase function and run_phase task.
This class need listen to the interface and put the signals in the
transaction.The transaction is deliver to the scoreboard when the signals
of read or write flags are one(some host talk with slave) after change.The second time that the
transaction deliver to the scoreboard-is when we send ack.The last time that 
we need to send transaction-is when we received timeout.
In addition here I check the stability of the signals(if some host talk with the slave)
until the ack and check if the signals are zero if no one talk with the slave.
*/
class slave_monitor_expected_actual extends uvm_monitor;
  `uvm_component_utils(slave_monitor_expected_actual)

  uvm_analysis_port#(arbiter_transaction) mon_slave_expected_actual;
  virtual arbiter_if_slave vinf_slave;
  arbiter_transaction arbiter_tran;
  
  /*
  The first five coverpoints are will sample if we have read or write flags one.
  The sixth coverpoint-the sample of write data only will be if was write flag=1.
  */
  covergroup cg_outputs_one_input();
    coverpoint arbiter_tran.cpu_general  iff(arbiter_tran.rd_general || arbiter_tran.wr_general)  {bins cpu[]={[0:$]};}
    coverpoint arbiter_tran.addr_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins addr[10]={[0:$]};}
    coverpoint arbiter_tran.rd_general   iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins rd_flag[]={[0:$]};}
    coverpoint arbiter_tran.wr_general   iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins wr_flag[]={[0:$]};}
    coverpoint arbiter_tran.be_general   iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins be[]={[0:$]};}
    coverpoint arbiter_tran.dwr_general  iff(arbiter_tran.wr_general){bins dwr[10]={[0:$]};}
    coverpoint arbiter_tran.ack_slave    {bins ack[]={[0:$]};}
  endgroup

  /*
  this coverpoint for read data if was ack and if was read flag(this in the task run_phase)
  */
  covergroup cg_read_input(); 
    coverpoint arbiter_tran.drd_general  iff(arbiter_tran.ack_slave){bins drd[10]={[0:$]};}
  endgroup   

  /*
  The constructor of the slave_monitor_expected_actual-
  class that inherit from uvm_monitor.
  The parameters of the constructor are string(name) and uvm_component(parent).
  Here I create the coverages-cg_outputs_one_input and cg_read_input.
  */
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_outputs_one_input=new;
    cg_read_input=new; 
  endfunction
  
  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function with uvm_config_db(UVM Configuration Database)-I get the poninter of the slave interface from database-
  and put him on vinf_slave(in type of arbiter_if_slave interface).
  In addition here I create the mon_slave_expected_actual(the TLM).
  */
  function void build_phase(uvm_phase phase);
	  super.build_phase(phase);
	  uvm_config_db#(virtual arbiter_if_slave)::get(this , "" , "arbiter_if_slave", vinf_slave);
	  mon_slave_expected_actual=new("mon_slave_expected_actual",this);
  endfunction
  
  /*
  Here the task run_phase that get uvm_phase parameter.
  As you can see first I defined variables whose origin is mem_ .. which are supposed to store as 
  memory the previous signals of the slave outputs as well as its inputs for different purposes.
  I set variables of a, b, c ... to check the stability of the signals (slave outputs).
  When the clock drops, I collect all the signals received from the slave interface for the transaction,
  as well as a sample with the coverages(pay attention that cg_read_input sample only when we on ack 
  and the previously read flag was one).In the clock rise after that-(in first condition)with one of the slave outputs 
  of one of the flags reading or writing (provided) and it is the turn of a new host (communicate with the slave) 
  so I upload the transaction to scoreboard and also keep the 
  values of the beginning of each variable that starts with mem_ .. In the second condition-if there
  is ack also pushes the transaction to scoreboard.
  The third condition is to push the transaction to the scoreboard when there is a timeout.
  The fourth condition checks the stability of the signals as long as we have not received ack.
  The fifth condition is when no host has requested a request (read or write).
  Look out!! I do a timeout counter to know when to send a transaction to the scoreboard when we reach the timeout.
  */
  task run_phase(uvm_phase phase); 
    int time_out=-1;
    bit change_of_outputs=1;
    bit mem_cpu_general=0;
    bit [31:0]mem_addr_general=0;
    bit mem_rd_general=0;
    bit mem_wr_general=0;
    bit [3:0] mem_be_general=0;
    bit [31:0] mem_dwr_general=0;
    bit [31:0] mem_drd_general=0;
    bit mem_ack_slave=0;
    bit a;
    bit b;
    bit c;
    bit d;
    bit e;
    bit f;
    arbiter_tran = arbiter_transaction::type_id::create("arbiter_tran", this);
    forever begin    
      @(negedge vinf_slave.clk)begin
     	  arbiter_tran.cpu_general=vinf_slave.cpu_general;
        arbiter_tran.addr_general=vinf_slave.addr_general;
        arbiter_tran.rd_general=vinf_slave.rd_general;
        arbiter_tran.wr_general=vinf_slave.wr_general;
        arbiter_tran.be_general=vinf_slave.be_general;
        arbiter_tran.dwr_general=vinf_slave.dwr_general;
        arbiter_tran.ack_slave=vinf_slave.ack_slave;
        arbiter_tran.drd_general=vinf_slave.drd_general;
        cg_outputs_one_input.sample();
        if(mem_rd_general)begin
          cg_read_input.sample();
        end
      end
      @(posedge vinf_slave.clk)begin
        if((arbiter_tran.wr_general==1 || arbiter_tran.rd_general==1) && change_of_outputs)begin
          change_of_outputs=0;
          time_out=0;
          mon_slave_expected_actual.write(arbiter_tran);
          mem_cpu_general=arbiter_tran.cpu_general;
          mem_addr_general=arbiter_tran.addr_general;
          mem_rd_general=arbiter_tran.rd_general;
          mem_wr_general=arbiter_tran.wr_general;
          mem_be_general=arbiter_tran.be_general;
          mem_dwr_general=arbiter_tran.dwr_general;
        end 
        else if((arbiter_tran.ack_slave==1))begin
          change_of_outputs=1;
          time_out=-1;
          mon_slave_expected_actual.write(arbiter_tran);
        end
        else if(time_out==65534)begin
          change_of_outputs=1;
          time_out=-1;
          mon_slave_expected_actual.write(arbiter_tran);
        end
        else if(!change_of_outputs)begin
          time_out++;
          a=mem_cpu_general==arbiter_tran.cpu_general;
          b=mem_addr_general==arbiter_tran.addr_general;
          c=mem_rd_general==arbiter_tran.rd_general;
          d=mem_wr_general==arbiter_tran.wr_general;
          e=mem_be_general==arbiter_tran.be_general;
          f=mem_dwr_general==arbiter_tran.dwr_general;
          if(!a || !b ||!c || !d || !e || !f)begin  
            `uvm_fatal("no stable signals!",$sformatf("end of program!"))
            time_out=-1;
          end  
        end  
        else if(arbiter_tran.wr_general==0 && arbiter_tran.rd_general==0 && arbiter_tran.ack_slave!=1)begin
          a=arbiter_tran.cpu_general==0;
          b=arbiter_tran.addr_general==0;
          c=arbiter_tran.rd_general==0;
          d=arbiter_tran.wr_general==0;
          e=arbiter_tran.be_general==0;
          f=arbiter_tran.dwr_general==0;
          if(!a || !b ||!c || !d || !e || !f)begin
            `uvm_fatal("no stable signals!",$sformatf("end of program-time_out: %d!",time_out))
            time_out=-1;
          end 
          time_out++;
        end  
      end      
    end 
  endtask
endclass


