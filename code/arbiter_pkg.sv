
/*
Author-Shai Kaikov.

Here are most of the files ?? which are in a package(arbiter_pkg). 
*/
package arbiter_pkg;
   import uvm_pkg::*;
   `include "uvm_macros.svh"
   `include "arbiter_transaction.sv"
   `include "arbiter_sequencer.sv"
   `include "arbiter_sequence.sv"
   `include "slave_monitor_expected_actual.sv"
   `include "host_monitor_expected_actual.sv"
   `include "arbiter_driver_host.sv"
   `include "arbiter_driver_slave.sv"
   `include "arbiter_configuration.sv"
   `include "host_agent_expected_actual.sv"
   `include "slave_agent_expected_actual.sv"
   `include "arbiter_scoreboard.sv"
   `include "arbiter_env.sv"
   `include "arbiter_test.sv"
endpackage

