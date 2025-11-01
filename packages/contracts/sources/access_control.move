#[allow(unused_field, unused_const, unused_use, unused_function)]
module contracts::access_control {
    use iota::table::{Self, Table};
    use iota::clock::{Self, Clock};
    use iota::event;

    // ==================== Error Codes ====================
    const ERR_NOT_ADMIN: u64 = 1;
    const ERR_NOT_AUTHORIZED: u64 = 2;
    const ERR_ROLE_NOT_FOUND: u64 = 3;

    // ==================== Role Constants ====================
    const ROLE_ADMIN: u8 = 1;
    const ROLE_ANCHORER: u8 = 2;
    const ROLE_WITNESS: u8 = 3;
    const ROLE_CONSENT_ATTESTER: u8 = 4;

    // ==================== Structs ====================
    
    //  Reusable access control component
    //  Can be embedded in any registry/contract that needs role-based permissions
    public struct AccessControl has store {
        roles: Table<address, u8>,
        admin: address,
    }

    // ==================== Events ====================
    
    public struct RoleGranted has copy, drop {
        account: address,
        role: u8,
        granter: address,
        timestamp: u64,
    }

    public struct RoleRevoked has copy, drop {
        account: address,
        role: u8,
        revoker: address,
        timestamp: u64,
    }

    public struct AdminTransferred has copy, drop {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }

    // ==================== Core Functions ====================
    
    //  Create a new access control instance
    public fun new(admin: address, ctx: &mut iota::tx_context::TxContext): AccessControl {
        let mut ac = AccessControl {
            roles: table::new(ctx),
            admin,
        };
        
        // Grant admin all default roles
        table::add(&mut ac.roles, admin, ROLE_ADMIN | ROLE_ANCHORER | ROLE_WITNESS | ROLE_CONSENT_ATTESTER);
        
        ac
    }

    //  Check if an address has a specific role
    public fun has_role(ac: &AccessControl, account: address, role: u8): bool {
        if (!table::contains(&ac.roles, account)) {
            return false
        };
        let roles = *table::borrow(&ac.roles, account);
        (roles & role) != 0
    }

    //  Check if sender is admin
    public fun is_admin(ac: &AccessControl, account: address): bool {
        account == ac.admin
    }

    //  Get current admin address
    public fun admin(ac: &AccessControl): address {
        ac.admin
    }

    //  Require admin permission (aborts if not admin)
    public fun require_admin(ac: &AccessControl, ctx: &iota::tx_context::TxContext) {
        assert!(iota::tx_context::sender(ctx) == ac.admin, ERR_NOT_ADMIN);
    }

    //  Require specific role (aborts if account doesn't have role)
    public fun require_role(ac: &AccessControl, account: address, role: u8) {
        assert!(has_role(ac, account, role), ERR_NOT_AUTHORIZED);
    }

    //  Grant a role to an account (admin only)
    public fun grant_role(
        ac: &mut AccessControl,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        require_admin(ac, ctx);
        
        if (!table::contains(&ac.roles, account)) {
            table::add(&mut ac.roles, account, role);
        } else {
            let current_roles = table::borrow_mut(&mut ac.roles, account);
            *current_roles = *current_roles | role;
        };
        
        event::emit(RoleGranted {
            account,
            role,
            granter: iota::tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Revoke a role from an account (admin only)
    public fun revoke_role(
        ac: &mut AccessControl,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        require_admin(ac, ctx);
        assert!(table::contains(&ac.roles, account), ERR_ROLE_NOT_FOUND);
        
        let current_roles = table::borrow_mut(&mut ac.roles, account);
        *current_roles = *current_roles & (0xFF ^ role);
        
        event::emit(RoleRevoked {
            account,
            role,
            revoker: iota::tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Transfer admin to a new address (admin only)
    public fun transfer_admin(
        ac: &mut AccessControl,
        new_admin: address,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        require_admin(ac, ctx);
        
        let old_admin = ac.admin;
        ac.admin = new_admin;
        
        // Grant new admin all roles
        if (!table::contains(&ac.roles, new_admin)) {
            table::add(&mut ac.roles, new_admin, ROLE_ADMIN | ROLE_ANCHORER | ROLE_WITNESS | ROLE_CONSENT_ATTESTER);
        } else {
            let roles = table::borrow_mut(&mut ac.roles, new_admin);
            *roles = *roles | ROLE_ADMIN | ROLE_ANCHORER | ROLE_WITNESS | ROLE_CONSENT_ATTESTER;
        };
        
        event::emit(AdminTransferred {
            old_admin,
            new_admin,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Get all roles for an account (returns bitmap)
    public fun get_roles(ac: &AccessControl, account: address): u8 {
        if (!table::contains(&ac.roles, account)) {
            return 0
        };
        *table::borrow(&ac.roles, account)
    }

    // ==================== Role Constants Accessors ====================
    
    public fun role_admin(): u8 { ROLE_ADMIN }
    public fun role_anchorer(): u8 { ROLE_ANCHORER }
    public fun role_witness(): u8 { ROLE_WITNESS }
    public fun role_consent_attester(): u8 { ROLE_CONSENT_ATTESTER }
}

