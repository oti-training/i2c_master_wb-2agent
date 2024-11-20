//------------------------------------------------------------------------------
// File: master_to_i2c_translator.sv
// Description: Class to carefully create an I2C transaction
//
// This class serves as a transaction builder that converts master commands 
// into I2C protocol transactions. It maintains the state machine necessary
// to construct valid I2C transactions piece by piece as master commands arrive.
//
// Key Features:
// - Maintains I2C protocol state machine (START->ADDR->READ/WRITE->STOP)
// - Buffers write data and tracks expected read lengths
// - Ensures protocol compliance by validating state transitions
// - Supports both read and write transactions
//
// Usage:
// The axil_ref_model uses this translator to:
// 1. Build I2C transactions incrementally as AXI commands arrive
// 2. Track transaction state to ensure protocol compliance
// 3. Package completed transactions for the scoreboard
//------------------------------------------------------------------------------

`ifndef MASTER_TO_I2C_TRANSLATOR_SV
`define MASTER_TO_I2C_TRANSLATOR_SV

class master_to_i2c_translator extends uvm_component;
    `uvm_component_utils(master_to_i2c_translator)

    // State machine enum for tracking I2C transaction build progress
    // IDLE: No transaction in progress
    // START: START bit received, waiting for address
    // ADDR_PHASE: Address received, waiting for direction
    // READ_PHASE: Building read transaction, accumulating read count
    // WRITE_PHASE: Building write transaction, collecting write data
    // STOP: Transaction complete, ready for delivery
    typedef enum {
        IDLE,
        READ_PHASE,
        WRITE_PHASE,
        STOP,
		COMPLETE
    } build_state_t;

    // Dict as start condition checklist
    // State change from IDLE will only be allowed when 3 conditions are met:
    // > START bit has been given
    // > ADDR (Slave) has been given
    // > DIR (alongside ADDR, LSB in the packet) has been given
    typedef enum {
        START,
        ADDR,
        DIR
    } init_check_dict;
    // Checklist variable
    protected bit [3-1:0] init_checklist = 0;

    //--------------------------------------------------------------------------
    // Class Properties
    //--------------------------------------------------------------------------

    // Current state of the I2C transaction building state machine
    protected build_state_t current_state = IDLE;
    
    // Transaction being constructed
    protected i2c_transaction current_tr;
    
    // For read transactions, tracks how many bytes should be read
    // This is incremented by add_read_byte() calls
    protected int read_data_length;
    
    //--------------------------------------------------------------------------
    // I2C output methods
    //--------------------------------------------------------------------------

    // Returns true if a complete transaction is ready to be retrieved
    // Used by ref model to know when to process queued slave responses
    function bit is_ready();
        return current_state==COMPLETE;
    endfunction

    // Retrieves the completed transaction and merges in slave response data
    // for read transactions. The transaction is marked incomplete after retrieval.
    function i2c_transaction get_transaction(i2c_transaction slave_tr);
        if (!is_ready()) begin
            `uvm_error(get_type_name(), "Transaction is not complete!")
            return null;
        end

        // For read transactions, copy response data and truncate if necessary
        if (!current_tr.is_write) begin
            current_tr.payload_data = slave_tr.payload_data;
            while (current_tr.payload_data.size() > read_data_length) begin
                current_tr.payload_data.pop_back();
            end
        end

        // Reset state
        current_state = IDLE;
        init_checklist = '0;
        return current_tr;
    endfunction


    //--------------------------------------------------------------------------
    // Transaction control methods
    //--------------------------------------------------------------------------
    protected function void init_valid_check();
        if (init_checklist == '1) begin
            if (current_tr.is_write) begin
                current_state = WRITE_PHASE;
            end else begin
                current_state = READ_PHASE;
            end
        end else begin
            `uvm_info(get_type_name(), "init_valid_check not complete.", UVM_DEBUG)
        end
    endfunction


    // Initializes a new transaction when START bit is received
    // Must be called in IDLE state as repeated start is not yet supported
    function void add_start_bit();
        assert(!init_checklist[START] && current_state == IDLE)
        else
            `uvm_fatal(get_type_name(),
                {"state=", current_state.name(),
                " Add start bit error"})

        // check the list ✅😉 
        init_checklist[START] = 1'b1;
        
        // change state if init checklist is complete
        init_valid_check();
    endfunction

    // Finalizes transaction when STOP command is received explicitly
    // Validates that transaction has actual data/expected reads
    function void add_stop_bit();
        assert(current_state inside {READ_PHASE, WRITE_PHASE, IDLE})
        else `uvm_fatal(get_type_name(), 
                    {"state=", current_state.name(),
                        " Not in the state for add_stop_bit!"})

        // Check that transaction is not empty
        assert((read_data_length > 0) || (current_tr.payload_data.size > 0))
        else `uvm_fatal(get_type_name(), "Transaction is empty!")

        if (current_state == READ_PHASE || current_state == WRITE_PHASE) begin
            current_state = COMPLETE;
        end else begin
            current_state = IDLE;
            init_checklist = '0;
        end
    endfunction

    //--------------------------------------------------------------------------
    // Address phase methods
    //--------------------------------------------------------------------------

    // Records slave address
    function void add_slave_addr(bit [6:0] slave_addr);
		assert(!init_checklist[ADDR] && current_state == IDLE)
        else `uvm_fatal(get_type_name(),
            "Add slave address error")

        // check the list ✅😉 
		init_checklist[ADDR] = 1'b1;
        current_tr.slave_addr = slave_addr;
		
        // change state if init checklist is complete
        init_valid_check();
    endfunction

    // Sets transaction direction (read/write) and prepares for data phase
    // For writes: Initializes empty payload array
    // For reads: Initializes read length counter
    function void add_direction(bit is_write);
        assert(!init_checklist[DIR] && current_state == IDLE)
        else `uvm_fatal(get_type_name(),
            {"state=",current_state.name(),
            "Add r/w direction error"})

        // check the list ✅😉 
        init_checklist[DIR] = 1'b1;
        current_tr.is_write = is_write;

        if (current_tr.is_write) begin
            current_tr.payload_data = {};
        end
        else begin
            read_data_length = 0;
        end

        // change state if init checklist is complete
        init_valid_check();
    endfunction

    //--------------------------------------------------------------------------
    // Data phase methods
    //--------------------------------------------------------------------------

    // Increments expected read length for read transactions
    // Validates slave address matches transaction
    function void add_read_byte(bit [6:0] slave_addr);
        assert(current_state==READ_PHASE)
        else `uvm_fatal(get_type_name(),
            "Not in the state for add_read_byte!")

        assert(current_tr.slave_addr==slave_addr)
        else `uvm_fatal(get_type_name(),
            "Ref model has not implemented read address changing before stop!")

        read_data_length++;
    endfunction

    // Adds write data byte to payload for write transactions
    function void add_write_byte(bit [7:0] write_data);
        assert(current_state==WRITE_PHASE)
        else `uvm_fatal(get_type_name(),
            "Not in the state for add_write_byte!")

        current_tr.payload_data.push_back(write_data);
    endfunction

    //--------------------------------------------------------------------------
    // Class methods
    //--------------------------------------------------------------------------

    // Constructor
    function new(string name="master_to_i2c_translator", uvm_component parent);
        super.new(name, parent);
        current_tr = i2c_transaction::type_id::create("trans");
    endfunction

endclass

`endif