
/*
Author-Shai Kaikov.

This is the host-monitor class.
The class inherit from uvm_monitor class.
The monitor is inside the host agent.
The class include -vinf_host interface pointer(host interface in type of arbiter_if_host),
mon_host_expected_actual in type of uvm_analysis_port(TLM) and
transaction object-arbiter_tran(in type of arbiter_transaction).
In addition the class contain two covergroups-cg_flag_one and cg_flag_zero.
Why are they two? one for sample for write or read flags are one and the
second for two of them(read and write flags) are zero.
This class contain obviously constructor(new),build_phase function and run_phase task.

This class need listen to the interface and put the signals in the
transaction.The transaction is deliver to the scoreboard when the signals
of read or write flags are one for the first time.The second time that the
transaction deliver to the scoreboard-is when we received ack.The last time that 
we need to send transaction-is when we received timeout.
*/
class host_monitor_expected_actual extends uvm_monitor;
  `uvm_component_utils(host_monitor_expected_actual)

  uvm_analysis_port#(arbiter_transaction) mon_host_expected_actual;
  virtual arbiter_if_host vinf_host;
  arbiter_transaction arbiter_tran;
  
  /*
  The first six coverpoints will sample if we have read or write flags one.
  The last coverpoint-the sample of read data only will be if was read flag=1 and was ack
  with no timeout.
  */
  covergroup cg_flag_one();
    coverpoint arbiter_tran.cpu_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins cpu[]={[0:$]};}
    coverpoint arbiter_tran.addr_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins addr[10]={[0:$]};}
    coverpoint arbiter_tran.rd_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins rd_flag[]={[0:$]};}
    coverpoint arbiter_tran.wr_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins wr_flag[]={[0:$]};}
    coverpoint arbiter_tran.be_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins be[]={[0:$]};}
    coverpoint arbiter_tran.dwr_general iff(arbiter_tran.rd_general || arbiter_tran.wr_general){bins dwr[10]={[0:$]};}
    coverpoint arbiter_tran.ack_host_general{bins ack[]={[0:$]};}////
    coverpoint arbiter_tran.drd_general iff(arbiter_tran.ack_host_general[0]==1 && arbiter_tran.ack_host_general[1]==0 && arbiter_tran.rd_general){bins drd[10]={[0:$]};}
  endgroup
   
  /*
  Here I sample the coverage only when we have read and write flags zero(the first four coverpoints).
  The last cover point sample only when we have 00 or 10(timeout)(when in fact we have read and write flags zero).
  */
  covergroup cg_flag_zero();
    coverpoint arbiter_tran.cpu_general iff(arbiter_tran.rd_general==0 && arbiter_tran.wr_general==0){bins cpu[]={[0:$]};}
    coverpoint arbiter_tran.addr_general iff(arbiter_tran.rd_general==0 && arbiter_tran.wr_general==0){bins addr[10]={[0:$]};}
    coverpoint arbiter_tran.be_general iff(arbiter_tran.rd_general==0 && arbiter_tran.wr_general==0){bins be[]={[0:$]};}
    coverpoint arbiter_tran.dwr_general iff(arbiter_tran.rd_general==0 && arbiter_tran.wr_general==0){bins dwr[10]={[0:$]};}
    coverpoint arbiter_tran.ack_host_general{ignore_bins ack={1,3};} 
  endgroup
 
  /*
  The constructor of the host_monitor_expected_actual-
  class that inherit from uvm_monitor.
  The parameters of the constructor are string(name) and uvm_component(parent).
  Here I create the coverages-cg_flag_one and cg_flag_zero.
  */
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_flag_one=new;
    cg_flag_zero=new;
  endfunction

  /*
  Here the function build_phase that get uvm_phase parameter.
  In this function with uvm_config_db(UVM Configuration Database)-I get the poninter of the host interface from database-
  and put him on vinf_host(in type of arbiter_if_host interface).
  In addition here I create the mon_host_expected_actual(the TLM).
  */
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(virtual arbiter_if_host)::get(this , "" , "arbiter_if_host", vinf_host);
    mon_host_expected_actual= new("mon_host_expected_actual" , this);
  endfunction
  
  /*
  Here the task run_phase that get uvm_phase parameter.
  As can be seen in the loop-in the down of the clock I collect the signals from the
  interface into a transaction and also sample the data of the coverages.
  In the first condition (if) -if the first time we got one of the flags of writing or reading one
  (and before that the signals were zero or were otherwise) then send the transaction to the scoreboard.
  In the second condition if we have received ack you will also send the transaction to the scoreboard.
  In the last condition if there was a timeout you will also send to the scoreboard.
  */
  task run_phase(uvm_phase phase);
    bit from_zero_to_one_flag=1;
    arbiter_tran = arbiter_transaction::type_id::create("arbiter_tran", this);  
    forever begin
      @(negedge vinf_host.clk)begin
        arbiter_tran.cpu_general=vinf_host.cpu_general;
        arbiter_tran.addr_general=vinf_host.addr_general;
        arbiter_tran.rd_general=vinf_host.rd_general;
        arbiter_tran.wr_general=vinf_host.wr_general;
        arbiter_tran.be_general=vinf_host.be_general;
        arbiter_tran.dwr_general=vinf_host.dwr_general;
        arbiter_tran.drd_general=vinf_host.drd_general;
        arbiter_tran.ack_host_general=vinf_host.ack_host_general;
        cg_flag_one.sample();
        cg_flag_zero.sample();
      end
      if((arbiter_tran.rd_general==1 || arbiter_tran.wr_general==1) && (from_zero_to_one_flag))begin
        from_zero_to_one_flag=0;
        mon_host_expected_actual.write(arbiter_tran);
      end
      else if(arbiter_tran.ack_host_general[0]==1 )begin
        from_zero_to_one_flag=1;
        mon_host_expected_actual.write(arbiter_tran);
        @(negedge vinf_host.clk);
      end
      else if(arbiter_tran.ack_host_general[1]==1)begin
        mon_host_expected_actual.write(arbiter_tran);
      end   
    end 
  endtask
endclass


