/* 
* File: config_seq.sv
* 
* This file defines the config_seq class, which is responsible for configuring
* the DUT by writing to its control registers.
*
* TODO:
* - Expand configuration options to cover all possible DUT settings
* - Add checks to verify that configuration was successful
* - Consider parameterizing the configuration values for more flexibility
*
* NOTE: This sequence currently only configures the prescale register. It should
* be expanded to provide a more comprehensive setup of the DUT.
*/
`ifndef CONFIG_SEQ
`define CONFIG_SEQ

class config_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(config_seq)

    function new(string name = "config_seq");
        super.new(name);
    endfunction

    task body();
        axil_seq_item req;

        req = axil_seq_item::type_id::create("req");
        start_item(req);
        req.addr = PRESCALE_REG;
        req.data = 1; // TODO: Make this configurable or derive from system clock
        req.read = 0;
        req.strb = 4'hF;
        finish_item(req);
    endtask
endclass

`endif
