
/*
Author-Shai Kaikov.

This is the arbiter_scoreboard(scoreboard)class.
The class inherit from uvm_scoreboard class.
The scoreboard is inside the Env(arbiter_env).
This class include trans_master array(transactions)of hosts,
trans_slave(slave transaction),array of scb_export_host(in type of uvm_analysis_export)-
the connections between the hosts agents to this class,slave scb_export_slave(
in type of uvm_analysis_export)-the connection between the slave agent to this class.
In addition this class include array of hosts fifo-fifo_hosts.Each one of them belong to one
host and I have here the slave fifo for the slave.
In the class I have constructor(new),build_phase function,connect_phase function,run task,request_of_hosts function,with_who_slave_is_connect
function and the compare function.

The role of this class is to test all the cases of the DUT.
The transactions sent here only when they have for the first time(and only for
the first time)request(read or write flags)
or when we have ack or timeout.
*/
class arbiter_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(arbiter_scoreboard)

  uvm_analysis_export #(arbiter_transaction) scb_export_slave;
  uvm_analysis_export #(arbiter_transaction) scb_export_host[4];
  uvm_tlm_analysis_fifo #(arbiter_transaction) slave_fifo;
  uvm_tlm_analysis_fifo #(arbiter_transaction) fifo_hosts[4];
  arbiter_transaction trans_slave;
  arbiter_transaction trans_master[4];
  
  /*
  The constructor of the arbiter_scoreboard-
  class that inherit from uvm_scoreboard.
  The parameters of the constructor are string(name) and uvm_component(parent).
  In this constructor I create trans_slave(slave-transaction) and in for loop
  the hosts transactions-in array.
  */
  function new(string name, uvm_component parent);
    super.new(name, parent);
    trans_slave=new("trans_slave");
    for(int i=0;i<$size(trans_master);i++)begin
      trans_master[i]=new($sformatf("trans_master[%0d]",i));
    end
  endfunction
  
  /*
  Here the function build_phase that get uvm_phase parameter.
  In this I create the scb_export_slave(in type of uvm_analysis_export),
  scb_export_host(in type of uvm_analysis_export)-array each of them to one host
  ,fifo_hosts(in type of uvm_tlm_analysis_fifo)-array each of them to one host and
  slave_fifo(in type of uvm_tlm_analysis_fifo)-to the slave.
  */
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb_export_slave=new("scb_export_slave", this);
    for(int i=0;i<$size(scb_export_host);i++)begin
      scb_export_host[i]=new($sformatf("scb_export_host[%0d]",i));
    end 
    slave_fifo=new("slave_fifo", this);
    for(int i=0;i<$size(trans_master);i++)begin
      fifo_hosts[i]=new($sformatf("fifo_hosts[%0d]",i));
    end
  endfunction
  
  /*
  Here the function connect_phase that get uvm_phase parameter.
  In this function I built the connection between the scb_export_slave and the fifo of the slave. 
  In addition I built here array of connections between each element in the array to 
  one element in the fifo(every one of them express one host).
  */
  function void connect_phase(uvm_phase phase);
    scb_export_slave.connect(slave_fifo.analysis_export);
    for(int i=0;i<4;i++)begin
      scb_export_host[i].connect(fifo_hosts[i].analysis_export);
    end 
  endfunction
  
  /*
  Here the task run_phase that get uvm_phase parameter. 
  In the task I set up an array of bits-hosts_requests- this array basically represents 
  the hosts requests (read or write).
  In addition I defined an array of transactions-array_transacion_hosts-
  this array contains the transactions that requested or alternatively transactions received on them ack. 
  The current_position is a variable that represents the same host that communicates with the slave.
  mem_ack_host is represent the result of the bit previous 0 or 1 of ack.The mem_last_host_pointer is
  represent the last host that was his turn.
  In the for loop After the slave fifo executes a transaction in the loop I have two options either the 
  size of the fifo is equal to one or its size is equal to two why? Because I came across some edge cases-
  1. What happens if during the communication of the host with the slave another host requested a request 
  (read or write) and then there was a timeout? So I will have two transactions in fifo - 
  because the fifo slave transaction is not activated until you get a timeout so I will make two get here when 
  in the compare function I will make changes to the ack to 0 on the transaction of the last get
  (for the reason I will need it in the future so its ack value must be 0).2.The first condition in
  the for loop is if and when we received ack without timeout 
  (same host that communicates with the slave) and before ack and after I start communication between 
  slave and host-another host requested a request (read or write) send a transaction to his same fifo so when we get ack- 
  to the same fifo will only one transaction so there will be one get. 
  The two cases I talked about were just examples of end cases and there are other 
  examples that I did not elaborate because it is a lot to write and these are just examples 
  to understand why there are actually two conditions here within the for loop.
  in the end I activate the request_of_hosts,with_who_slave_is_connect and compare functions.
  */
  task run();
    bit mem_ack_host;
    int mem_last_host_pointer=-1;
    int pointer=-1;
    arbiter_transaction current_position=null;
    bit hosts_requests [4]='{0,0,0,0};
    arbiter_transaction  array_transacion_hosts[4]='{null,null,null,null};
    forever begin
      slave_fifo.get(trans_slave);
      for(int i=0;i<$size(fifo_hosts);i++)begin
        if(fifo_hosts[i].used()==1)begin
          fifo_hosts[i].get(trans_master[i]);
          array_transacion_hosts[i]=trans_master[i];     
        end
        else if(fifo_hosts[i].used()==2)begin
          fifo_hosts[i].get(trans_master[i]);
          fifo_hosts[i].get(trans_master[i]);
          array_transacion_hosts[i]=trans_master[i];
        end 
      end 
      request_of_hosts(hosts_requests,array_transacion_hosts);
      pointer=with_who_slave_is_connect(hosts_requests,pointer,mem_ack_host,mem_last_host_pointer);          
      compare(hosts_requests,current_position,array_transacion_hosts,pointer,mem_ack_host,mem_last_host_pointer);
    end
  endtask

  /*
  Here the function of request_of_hosts and his parameters are are kind
  of bits array(the array of requests) and arbiter_transaction array(the array of requests and ack).
  In the for loop I check if the element in the array of the transactions is not null(can be for example flags-
  of write and read 0) and if one of the flags-write or read are one-if the condition is correct-put one
  in the array of bits-hosts_requests as sign of request from the host-else put 0 as sign of no request
  from the host.
  */
  function void request_of_hosts(ref bit hosts_requests [4],ref arbiter_transaction  array_transacion_hosts[4]);
    for(int i=0;i<$size(hosts_requests);i++)begin
      if(array_transacion_hosts[i]!=null && (array_transacion_hosts[i].rd_general || array_transacion_hosts[i].wr_general))begin
        hosts_requests[i]=1;
      end
      else begin
        hosts_requests[i]=0;
      end 
    end 
  endfunction 

  /*
  Here the function of with_who_slave_is_connect and his parameters are kind
  of bits array(the array of requests),int,bit and int.
  The hosts_requests is the array of the requests.The pointer-is represent the turn of the
  specific host.mem_ack_host is represent the result of the bit previous 0 or 1 of ack(as I explained in run task).
  The mem_last_host_pointer is
  represent the last host that was his turn(as I explained in run task).
  In the for loop I pass all the array of the requests-in the first condition
  if was ack and the current pointer==to previous pointer than move the pointer
  to the next host.In the second condition I check in the current position if there
  was request if it is-his turn now of this host.In the third condition if I in
  the end of the array and there was not any request so pointer=-1.
  In the last condition I do pointer++ if the previous conditions fail.
  In the end of this function I return the pointer.
  */
  function int with_who_slave_is_connect(const ref bit hosts_requests [4],int pointer,ref bit mem_ack_host,ref int mem_last_host_pointer);
    bit flag=1;
    if(pointer==-1)begin
      pointer=0;
    end
    for(int i=0;i< $size(hosts_requests) && flag ;i++)begin
      if(mem_last_host_pointer==pointer && mem_ack_host==1)begin
        mem_last_host_pointer=-1;
        mem_ack_host=0;
        pointer=(pointer+1) % $size(hosts_requests);
      end
      else if(hosts_requests[pointer % $size(hosts_requests)]==1)begin
        flag=0;  
      end  
      else if(hosts_requests[pointer % $size(hosts_requests)]==0 && i==$size(hosts_requests)-1)begin
        pointer=-1; 
      end
      else begin
        pointer=(pointer+1) % $size(hosts_requests);
      end    
    end
    return pointer; 
  endfunction 

  /*
  This is the compare function-the role of this function is to test all the cases-due to the length
  of the function I will explain in short what is the role of every condition in the condition
  itself.
  The function get parameters in kind if bits array(hosts_requests-requests of the hosts),arbiter_transaction
  -current_position-the current host that talk with the slave,array of transactions for each host-array_transacion_hosts,
  (in type of arbiter_transaction),int-pointer,bit mem_ack_host(I have already explained) and int-mem_last_host_pointer(I have already explained).
  */
  function void compare(const ref bit hosts_requests [4],ref arbiter_transaction current_position,ref arbiter_transaction  array_transacion_hosts[4],const ref int pointer,ref bit mem_ack_host,ref int mem_last_host_pointer);
    if(pointer==-1)begin//if there no requests.
      `uvm_info("function compare-IF THERE IS NO HOST REQUEST -CONDITION",{"Test: failed!"}, UVM_LOW)
      `uvm_fatal("end!",$sformatf("end of program!"))
    end
    else begin
      current_position=array_transacion_hosts[pointer];
      for(int i=0;i<$size(array_transacion_hosts);i++)begin
        if(pointer==i)begin//for the current host that talk with the slave(if).
          `uvm_info("function compare-TESTS FOR THE CURRENT HOST THAT TALK WITH SLAVE", {"tests for current host-that talk with slave!"}, UVM_LOW);
          if(array_transacion_hosts[pointer].ack_host_general[1]==0)begin//if ack[1]==0.
            if(array_transacion_hosts[pointer].ack_host_general[0]!=trans_slave.ack_slave)begin//if the ack of the host!=slave ack
              `uvm_info("function compare-IF HOST-ACK[0]!=SLAVE_ACK -CONDITION", $sformatf("host_ack[0]=%b ,slave_hack=%b",array_transacion_hosts[pointer].ack_host_general[0],trans_slave.ack_slave), UVM_LOW);
              `uvm_info("function compare-IF HOST-ACK[0]!=SLAVE_ACK -CONDITION", {"Test: failed!"}, UVM_LOW);
              `uvm_fatal("end!",$sformatf("end of program!"))
            end
            else if(array_transacion_hosts[pointer].ack_host_general[0]==trans_slave.ack_slave)begin//if the ack of the host==slave ack.
              if(trans_slave.ack_slave==0)begin//if ack slave==0.
                if(array_transacion_hosts[pointer].rd_general==1 && array_transacion_hosts[pointer].wr_general==0)begin//if rd flag==1 and wr flag!=1(host).
                  bit a=trans_slave.cpu_general==array_transacion_hosts[pointer].cpu_general;
                  bit b=trans_slave.addr_general==array_transacion_hosts[pointer].addr_general;
                  bit c=trans_slave.rd_general==array_transacion_hosts[pointer].rd_general;
                  bit d=trans_slave.wr_general==array_transacion_hosts[pointer].wr_general;
                  bit e=trans_slave.be_general==array_transacion_hosts[pointer].be_general;
                  if(!a || !b || !c || !d || !e)begin//if slave transaction!= host transaction.
                    `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==0 AND HOST_ACK[1]!=1 AND ONE OF THE INPUT OF HOST != ONE OF THE OUTPUTS OF SLAVE(RD FLAG)  -CONDITION",{"Test: failed!"}, UVM_LOW)
                    `uvm_fatal("end!",$sformatf("end of program!"))
                  end
                end
                else if(array_transacion_hosts[pointer].rd_general==0 && array_transacion_hosts[pointer].wr_general==1)begin//if rd flag!=1 and wr flag==1(host).
                  bit a=trans_slave.cpu_general==array_transacion_hosts[pointer].cpu_general;
                  bit b=trans_slave.addr_general==array_transacion_hosts[pointer].addr_general;
                  bit c=trans_slave.rd_general==array_transacion_hosts[pointer].rd_general;
                  bit d=trans_slave.wr_general==array_transacion_hosts[pointer].wr_general;
                  bit e=trans_slave.be_general==array_transacion_hosts[pointer].be_general;
                  bit f=trans_slave.dwr_general==array_transacion_hosts[pointer].dwr_general;
                  if(!a || !b || !c || !d || !e || !f)begin//if slave transaction!= host transaction.
                    `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==0 AND HOST_ACK[1]!=1 AND ONE OF THE INPUT OF HOST != ONE OF THE OUTPUTS OF SLAVE(WR FLAG)  -CONDITION",{"Test: failed!"}, UVM_LOW)
                    `uvm_fatal("end!",$sformatf("end of program!"))
                  end
                end     
              end
              else if(trans_slave.ack_slave==1)begin//if ack slave==1.
                bit a=trans_slave.cpu_general==0;
                bit b=trans_slave.addr_general==0;
                bit c=trans_slave.rd_general==0;
                bit d=trans_slave.wr_general==0;
                bit e=trans_slave.be_general==0;
                bit f=trans_slave.dwr_general==0;
                if(!a || !b || !c || !d || !e || !f)begin//if slave transaction!=0.
                  `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==1 AND HOST_ACK[1]!=1 AND ONE OF OUTPUTS OF SLAVE NOT ZERO  -CONDITION", {"Test: failed!"},UVM_LOW)
                  `uvm_fatal("end!",$sformatf("end of program!"))
                end
                else begin//slave transaction==0.
                  `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==1 AND HOST_ACK[1]!=1 AND ALL OUTPUTS OF SLAVE ARE ZERO  -CONDITION", {"Test: good!"},UVM_LOW)
                end  
                if(array_transacion_hosts[pointer].rd_general==1 && array_transacion_hosts[pointer].drd_general==trans_slave.drd_general)begin//if the rd flag one and data read of slave ==data read of host.
                  `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==1 AND HOST_ACK[1]!=1 AND DATA_READ_SLAVE==DATA_READ_HOST(WITH RD FLAG)  -CONDITION", {"Test: good!"}, UVM_LOW)  
                end
                else if(array_transacion_hosts[pointer].rd_general==1 && array_transacion_hosts[pointer].drd_general!=trans_slave.drd_general) begin//if the rd flag one and data read of slave !=data read of host.
                  `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==1 AND HOST_ACK[1]!=1 AND DATA_READ_SLAVE!=DATA_READ_HOST(WITH RD FLAG)  -CONDITION", {"Test: failed!"},UVM_LOW)
                  `uvm_fatal("end!",$sformatf("end of program!"))
                end
                mem_ack_host=1;//memory for the ack.
                mem_last_host_pointer=pointer;//memory after the ack for the last host Who spoke with the slave.
                array_transacion_hosts[pointer]=null;
              end  
            end
          end
          else if(array_transacion_hosts[pointer].ack_host_general[1]==1)begin//if ack[1]==1(host)
            bit a=trans_slave.cpu_general==0;
            bit b=trans_slave.addr_general==0;
            bit c=trans_slave.rd_general==0;
            bit d=trans_slave.wr_general==0;
            bit e=trans_slave.be_general==0;
            bit f=trans_slave.dwr_general==0;
            if(!a || !b || !c || !d || !e || !f)begin//slave transaction!=0.
              `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==1 AND HOST_ACK[1]!=1 AND ONE OF OUTPUTS OF SLAVE NOT ZERO  -CONDITION", {"Test: failed!"},UVM_LOW)
              `uvm_fatal("end!",$sformatf("end of program!"))
            end
            else begin//slave transaction==0.
              `uvm_info("function compare-IF HOST-ACK[0]==SLAVE_ACK==1 AND HOST_ACK[1]!=1 AND ALL OUTPUTS OF SLAVE ARE ZERO  -CONDITION", {"Test: good!"},UVM_LOW)
            end
            if(array_transacion_hosts[pointer].ack_host_general[0]==0)begin//if ack[0]==0(host).
              `uvm_info("function compare-IF HOST-ACK[1]==1 AND HOST-ACK[0]==0(THE HOST THAT TALK WITH SLAVE)-CONDITION", {"Test: failed!"}, UVM_LOW)
              `uvm_fatal("end!",$sformatf("end of program!"))
            end
            else begin//if ack[0]==1(host).
              `uvm_info("function compare-IF HOST-ACK[1]==1 AND HOST-ACK[0]==1(THE HOST THAT TALK WITH SLAVE)-CONDITION", {"Test: good!"}, UVM_LOW)      
            end  
            mem_ack_host=1;//memory for the ack.
            mem_last_host_pointer=pointer;//memory after the ack for the last host Who spoke with the slave.
            array_transacion_hosts[pointer]=null;
          end  
        end
        else begin//if the current position is not the current host that talk with the slave(others host).
          if(array_transacion_hosts[i]!=null )begin//if the current element in the transactions array not null.
            if(trans_slave.ack_slave)begin//if slave ack==1.
              if(array_transacion_hosts[i].ack_host_general[0])begin//if ack[0] of the other host(that not talk with the slave)==1.
                `uvm_info("function compare-IF OTHER HOST-ACK[0]==1 WITH ACK SLAVE=1-CONDITION", {"Test: failed!"}, UVM_LOW)
                `uvm_fatal("end!",$sformatf("end of program!"))
              end
            end  
            else if(!trans_slave.ack_slave)begin//if slave ack!=1.
              if(array_transacion_hosts[i].ack_host_general[0])begin//if ack[0] of the other host(that not talk with the slave)==1.
                `uvm_info("function compare-IF OTHER HOST-ACK[0]==1 WITH ACK SLAVE=0-CONDITION", {"Test: failed!"}, UVM_LOW)
                `uvm_fatal("end!",$sformatf("end of program!"))
              end
            end  
            if(array_transacion_hosts[i].ack_host_general[1]==1 && !(current_position.ack_host_general[1] && current_position.ack_host_general[0]))begin//if ack[1]==1(others hosts) && the host that talk with the slave-ack!=11.
              `uvm_info("function compare-IF OTHER HOST-ACK[1]==1 HOST_ACK[0]==0 && HOST_ACK[1]==0-CONDITION", {"Test: failed!"}, UVM_LOW)
              `uvm_fatal("end!",$sformatf("end of program!"))
            end
            else if(array_transacion_hosts[i].ack_host_general[1]==0 &&(current_position.ack_host_general[1] && current_position.ack_host_general[0]))begin//if ack[1]==0(others hosts) && the host that talk with the slave-ack==11.
              `uvm_info("function compare-IF OTHER HOST-ACK[1]==1 HOST_ACK[0]==0 && HOST_ACK[1]==0-CONDITION", {"Test: failed!"}, UVM_LOW)
              `uvm_fatal("end!",$sformatf("end of program!"))
            end      
          end
          if(array_transacion_hosts[i]!=null && (array_transacion_hosts[i].wr_general || array_transacion_hosts[i].rd_general))begin//change of the transaction.
            array_transacion_hosts[i].ack_host_general[1]=0;
          end
          else if(array_transacion_hosts[i]!=null && (!array_transacion_hosts[i].wr_general && !array_transacion_hosts[i].rd_general))begin//change of the array of transactions
            array_transacion_hosts[i]=null;
          end     
        end 
      end         
    end      
  endfunction
endclass




