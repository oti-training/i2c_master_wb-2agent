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
        START,
        ADDR_PHASE,
        READ_PHASE,
        WRITE_PHASE,
        STOP,
		COMPLETE
    } build_state_t;

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
        assert(current_state==COMPLETE)
        else `uvm_fatal(get_type_name(),
            "Transaction is not complete!")

        // For read transactions, copy response data from slave
        // and truncate to expected length if necessary
        if (!current_tr.is_write) begin
            current_tr.payload_data = slave_tr.payload_data;

            while (current_tr.payload_data.size() > read_data_length) begin
                current_tr.payload_data.pop_back();
            end
        end

        current_state = IDLE;
        return current_tr;
    endfunction

    //--------------------------------------------------------------------------
    // Transaction control methods
    //--------------------------------------------------------------------------

    // Initializes a new transaction when START bit is received
    // Must be called in IDLE state as repeated start is not yet supported
    function void add_start_bit();
        assert(current_state==IDLE)
        else
            `uvm_fatal(get_type_name(),
                {"state=", current_state.name(),
                " Ref model has not implemented repeated start!"})

        current_tr = i2c_transaction::type_id::create("trans");
        current_state = START;
    endfunction

    // Finalizes transaction when STOP command is received explicitly
    // Validates that transaction has actual data/expected reads
    function void add_stop_bit();
        assert(current_state inside {READ_PHASE, WRITE_PHASE, IDLE})
        else `uvm_fatal(get_type_name(), {"state=",current_state.name(),
            " Not in the state for add_stop_bit!"})

        assert((read_data_length > 0) || (current_tr.payload_data.size > 0))
        else `uvm_fatal(get_type_name(), "Transaction is empty!")

		if (current_state inside {READ_PHASE, WRITE_PHASE})
        	current_state = COMPLETE;

		// covers stop command when nothing is going on
		else
			current_state = IDLE;
    endfunction

    //--------------------------------------------------------------------------
    // Address phase methods
    //--------------------------------------------------------------------------

    // Records slave address after START
    // Must be called before setting direction
    function void add_slave_addr(bit [6:0] slave_addr);
        assert(current_state==START)
        else `uvm_fatal(get_type_name(),
            "add_slave_addr was called before add_start_bit!")

        current_state = ADDR_PHASE;
        current_tr.slave_addr = slave_addr;
    endfunction

    // Sets transaction direction (read/write) and prepares for data phase
    // For writes: Initializes empty payload array
    // For reads: Initializes read length counter
    function void add_direction(bit is_write);
        assert(current_state==ADDR_PHASE)
        else `uvm_fatal(get_type_name(),
            {"state=",current_state.name(),
            " add_direction was called before add_slave_addr!"})

        current_tr.is_write = is_write;

        if (current_tr.is_write) begin
            current_state = WRITE_PHASE;
            current_tr.payload_data = {};
        end
        else begin
            current_state = READ_PHASE;
            read_data_length = 0;
        end
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
    endfunction

endclass

`endif