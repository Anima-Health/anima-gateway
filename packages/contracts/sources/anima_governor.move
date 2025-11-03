#[allow(unused_field, unused_const, unused_use, unused_function)]
module contracts::anima_governor {
    use std::string::String;
    use iota::event;
    use iota::table::{Self, Table};
    use iota::clock::{Self, Clock};
    use contracts::access_control::{Self, AccessControl};

    // ==================== Error Codes ====================
    const ERR_NOT_ADMIN: u64 = 1;
    const ERR_NOT_GUARDIAN: u64 = 2;
    const ERR_SCHEDULE_NOT_FOUND: u64 = 3;
    const ERR_NOT_EXECUTABLE: u64 = 4;
    const ERR_ALREADY_PAUSED: u64 = 5;
    const ERR_NOT_PAUSED: u64 = 6;
    const ERR_INVALID_DELAY: u64 = 7;
    const ERR_INVALID_PARAM_KEY: u64 = 8;

    // ==================== Role Constants ====================
    const ROLE_ADMIN: u8 = 1;
    const ROLE_GOVERNOR: u8 = 32; // Same as in did_role_registry
    const ROLE_GUARDIAN: u8 = 64; // 2^6 - Emergency pause only

    // ==================== Target Contract Types ====================
    const TARGET_CORE_ANCHOR: u8 = 1;
    const TARGET_CONSENT_ATTESTOR: u8 = 2;
    const TARGET_DID_ROLE_REGISTRY: u8 = 3;
    const TARGET_GOVERNOR: u8 = 4; // Self-reference for governance params

    // ==================== Operation Types ====================
    const OP_ROLE_GRANT: u8 = 1;
    const OP_ROLE_REVOKE: u8 = 2;
    const OP_UPDATE_QUORUM: u8 = 3;
    const OP_SET_PARAM: u8 = 4;
    const OP_TRANSFER_ADMIN: u8 = 5;
    const OP_PAUSE: u8 = 6;
    const OP_UNPAUSE: u8 = 7;

    // ==================== Structs ====================
    
    //  Scheduled operation waiting for timelock delay
    public struct ScheduledOperation has store, drop {
        id: u64,
        target: u8,              // Which contract to operate on
        operation: u8,            // What operation to perform
        params: vector<u8>,       // Serialized parameters (specific to operation type)
        eta: u64,                // Execution timestamp (must be >= current_time + delay)
        executed: bool,
        executor: address,
        timestamp: u64,
    }

    //  Parameter storage for contract configuration
    public struct Parameter has store, copy, drop {
        key: String,
        value: vector<u8>,        // Generic value storage
        updated_at: u64,
        updated_by: address,
    }

    //  Main governance contract
    public struct AnimaGovernor has key {
        id: iota::object::UID,
        access: AccessControl,
        // Scheduled operations awaiting execution
        scheduled_ops: Table<u64, ScheduledOperation>,
        next_op_id: u64,
        // Contract pause states
        paused: Table<u8, bool>,
        // Parameters for each contract (contract_id -> param_key -> Parameter)
        parameters: Table<u8, Table<String, Parameter>>,
        // Timelock delay (minimum delay for scheduled operations)
        timelock_delay: u64,
        // Unpause window (time allowed for unpause after pause)
        unpause_window: u64,
    }

    // ==================== Events ====================
    
    public struct TimelockScheduled has copy, drop {
        id: u64,
        target: u8,
        operation: u8,
        eta: u64,
        scheduler: address,
        timestamp: u64,
    }

    public struct TimelockExecuted has copy, drop {
        id: u64,
        target: u8,
        operation: u8,
        executor: address,
        timestamp: u64,
    }

    public struct Paused has copy, drop {
        target: u8,
        pauser: address,
        reason: String,
        timestamp: u64,
    }

    public struct Unpaused has copy, drop {
        target: u8,
        unpauser: address,
        timestamp: u64,
    }

    public struct ParamChanged has copy, drop {
        target: u8,
        key: String,
        old_value: vector<u8>,
        new_value: vector<u8>,
        changed_by: address,
        timestamp: u64,
    }

    public struct TimelockDelayUpdated has copy, drop {
        old_delay: u64,
        new_delay: u64,
        updated_by: address,
        timestamp: u64,
    }

    public struct UnpauseWindowUpdated has copy, drop {
        old_window: u64,
        new_window: u64,
        updated_by: address,
        timestamp: u64,
    }

    // ==================== Initialization ====================
    
    //  Initialize the AnimaGovernor
    fun init(ctx: &mut iota::tx_context::TxContext) {
        let admin = iota::tx_context::sender(ctx);

        let governor = AnimaGovernor {
            id: iota::object::new(ctx),
            access: access_control::new(admin, ctx),
            scheduled_ops: table::new(ctx),
            next_op_id: 1,
            paused: table::new(ctx),
            parameters: table::new(ctx),
            timelock_delay: 86400000, // Default: 24 hours in milliseconds
            unpause_window: 604800000, // Default: 7 days in milliseconds
        };
        
        iota::transfer::share_object(governor);
    }

    // ==================== Governance Functions ====================
    
    //  Grant a role to an account (admin/governor only)
    public fun grant_role(
        governor: &mut AnimaGovernor,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        access_control::grant_role(&mut governor.access, account, role, clock, ctx);
    }

    //  Revoke a role from an account (admin/governor only)
    public fun revoke_role(
        governor: &mut AnimaGovernor,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        access_control::revoke_role(&mut governor.access, account, role, clock, ctx);
    }

    //  Transfer admin to new address
    public fun transfer_admin(
        governor: &mut AnimaGovernor,
        new_admin: address,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        access_control::transfer_admin(&mut governor.access, new_admin, clock, ctx);
    }

    // ==================== Timelock Functions ====================
    
    //  Schedule an operation for future execution (admin/governor only)
    public fun schedule(
        governor: &mut AnimaGovernor,
        target: u8,
        operation: u8,
        params: vector<u8>,
        eta: u64,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ): u64 {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        let current_time = clock::timestamp_ms(clock);
        let min_eta = current_time + governor.timelock_delay;
        assert!(eta >= min_eta, ERR_INVALID_DELAY);

        let id = governor.next_op_id;
        governor.next_op_id = id + 1;

        let op = ScheduledOperation {
            id,
            target,
            operation,
            params,
            eta,
            executed: false,
            executor: sender,
            timestamp: current_time,
        };

        table::add(&mut governor.scheduled_ops, id, op);

        event::emit(TimelockScheduled {
            id,
            target,
            operation,
            eta,
            scheduler: sender,
            timestamp: current_time,
        });

        id
    }

    //  Execute a scheduled operation (anyone can execute once delay has passed)
    public fun execute(
        governor: &mut AnimaGovernor,
        id: u64,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        assert!(table::contains(&governor.scheduled_ops, id), ERR_SCHEDULE_NOT_FOUND);

        let op = table::borrow_mut(&mut governor.scheduled_ops, id);
        assert!(!op.executed, ERR_SCHEDULE_NOT_FOUND); // Already executed
        assert!(clock::timestamp_ms(clock) >= op.eta, ERR_NOT_EXECUTABLE);

        op.executed = true;
        op.executor = iota::tx_context::sender(ctx);

        let current_time = clock::timestamp_ms(clock);

        event::emit(TimelockExecuted {
            id,
            target: op.target,
            operation: op.operation,
            executor: op.executor,
            timestamp: current_time,
        });
    }

    //  Cancel a scheduled operation (admin/governor only)
    public fun cancel(
        governor: &mut AnimaGovernor,
        id: u64,
        _clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        assert!(table::contains(&governor.scheduled_ops, id), ERR_SCHEDULE_NOT_FOUND);
        let op = table::borrow_mut(&mut governor.scheduled_ops, id);
        assert!(!op.executed, ERR_SCHEDULE_NOT_FOUND);

        // Remove the operation
        table::remove(&mut governor.scheduled_ops, id);
    }

    // ==================== Pause Functions ====================
    
    //  Pause a contract (admin/governor/guardian can pause)
    //  Guardian can only pause, cannot unpause
    public fun pause(
        governor: &mut AnimaGovernor,
        target: u8,
        reason: String,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        
        // Check permissions: admin, governor, or guardian
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR) ||
            access_control::has_role(&governor.access, sender, ROLE_GUARDIAN),
            ERR_NOT_ADMIN
        );

        // Check if already paused
        if (table::contains(&governor.paused, target)) {
            let is_paused = *table::borrow(&governor.paused, target);
            assert!(!is_paused, ERR_ALREADY_PAUSED);
        } else {
            table::add(&mut governor.paused, target, true);
        };

        let current_time = clock::timestamp_ms(clock);

        event::emit(Paused {
            target,
            pauser: sender,
            reason,
            timestamp: current_time,
        });
    }

    //  Unpause a contract (admin/governor only, guardian cannot unpause)
    public fun unpause(
        governor: &mut AnimaGovernor,
        target: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        
        // Guardian cannot unpause
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        assert!(table::contains(&governor.paused, target), ERR_NOT_PAUSED);
        let is_paused = table::borrow_mut(&mut governor.paused, target);
        assert!(*is_paused, ERR_NOT_PAUSED);

        *is_paused = false;

        let current_time = clock::timestamp_ms(clock);

        event::emit(Unpaused {
            target,
            unpauser: sender,
            timestamp: current_time,
        });
    }

    // ==================== Parameter Management ====================
    
    //  Set a parameter for a contract (admin/governor only, typically via timelock)
    public fun set_param(
        governor: &mut AnimaGovernor,
        target: u8,
        key: String,
        value: vector<u8>,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        assert!(*std::string::as_bytes(&key) != &vector::empty(), ERR_INVALID_PARAM_KEY);

        // Initialize target parameter table if needed
        if (!table::contains(&governor.parameters, target)) {
            let param_table = table::new(ctx);
            table::add(&mut governor.parameters, target, param_table);
        };

        let param_table = table::borrow_mut(&mut governor.parameters, target);
        let current_time = clock::timestamp_ms(clock);

        let old_value = if (table::contains(param_table, key)) {
            let param = table::borrow(param_table, key);
            param.value
        } else {
            vector::empty<u8>()
        };

        let param = Parameter {
            key,
            value,
            updated_at: current_time,
            updated_by: sender,
        };

        if (table::contains(param_table, param.key)) {
            let existing = table::borrow_mut(param_table, param.key);
            *existing = param;
        } else {
            table::add(param_table, param.key, param);
        };

        event::emit(ParamChanged {
            target,
            key: param.key,
            old_value,
            new_value: param.value,
            changed_by: sender,
            timestamp: current_time,
        });
    }

    //  Get a parameter value
    public fun get_param(
        governor: &AnimaGovernor,
        target: u8,
        key: String
    ): vector<u8> {
        if (!table::contains(&governor.parameters, target)) {
            return vector::empty<u8>()
        };

        let param_table = table::borrow(&governor.parameters, target);
        if (!table::contains(param_table, key)) {
            return vector::empty<u8>()
        };

        let param = table::borrow(param_table, key);
        param.value
    }

    // ==================== Configuration Functions ====================
    
    //  Update timelock delay (admin/governor only, typically via timelock)
    public fun set_timelock_delay(
        governor: &mut AnimaGovernor,
        new_delay: u64,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        assert!(new_delay > 0, ERR_INVALID_DELAY);

        let old_delay = governor.timelock_delay;
        governor.timelock_delay = new_delay;

        event::emit(TimelockDelayUpdated {
            old_delay,
            new_delay,
            updated_by: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Update unpause window (admin/governor only)
    public fun set_unpause_window(
        governor: &mut AnimaGovernor,
        new_window: u64,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&governor.access, sender) ||
            access_control::has_role(&governor.access, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        let old_window = governor.unpause_window;
        governor.unpause_window = new_window;

        event::emit(UnpauseWindowUpdated {
            old_window,
            new_window,
            updated_by: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ==================== View Functions ====================
    
    //  Check if a contract is paused
    public fun is_paused(governor: &AnimaGovernor, target: u8): bool {
        if (!table::contains(&governor.paused, target)) {
            return false
        };
        *table::borrow(&governor.paused, target)
    }

    //  Get timelock delay
    public fun timelock_delay(governor: &AnimaGovernor): u64 {
        governor.timelock_delay
    }

    //  Get unpause window
    public fun unpause_window(governor: &AnimaGovernor): u64 {
        governor.unpause_window
    }

    //  Get scheduled operation details
    public fun get_scheduled_op(
        governor: &AnimaGovernor,
        id: u64
    ): (u8, u8, u64, bool) {
        assert!(table::contains(&governor.scheduled_ops, id), ERR_SCHEDULE_NOT_FOUND);
        let op = table::borrow(&governor.scheduled_ops, id);
        (op.target, op.operation, op.eta, op.executed)
    }

    //  Check if a scheduled operation is executable
    public fun is_executable(
        governor: &AnimaGovernor,
        id: u64,
        clock: &Clock
    ): bool {
        if (!table::contains(&governor.scheduled_ops, id)) {
            return false
        };
        let op = table::borrow(&governor.scheduled_ops, id);
        !op.executed && clock::timestamp_ms(clock) >= op.eta
    }

    // ==================== Role Constants Accessors ====================
    
    public fun role_admin(): u8 { ROLE_ADMIN }
    public fun role_governor(): u8 { ROLE_GOVERNOR }
    public fun role_guardian(): u8 { ROLE_GUARDIAN }

    // ==================== Target Constants Accessors ====================
    
    public fun target_core_anchor(): u8 { TARGET_CORE_ANCHOR }
    public fun target_consent_attestor(): u8 { TARGET_CONSENT_ATTESTOR }
    public fun target_did_role_registry(): u8 { TARGET_DID_ROLE_REGISTRY }
    public fun target_governor(): u8 { TARGET_GOVERNOR }

    // ==================== Operation Constants Accessors ====================
    
    public fun op_role_grant(): u8 { OP_ROLE_GRANT }
    public fun op_role_revoke(): u8 { OP_ROLE_REVOKE }
    public fun op_update_quorum(): u8 { OP_UPDATE_QUORUM }
    public fun op_set_param(): u8 { OP_SET_PARAM }
    public fun op_transfer_admin(): u8 { OP_TRANSFER_ADMIN }
    public fun op_pause(): u8 { OP_PAUSE }
    public fun op_unpause(): u8 { OP_UNPAUSE }

    // ==================== Test Init ====================
    
    #[test_only]
    public fun init_for_testing(ctx: &mut iota::tx_context::TxContext) {
        init(ctx);
    }
}

