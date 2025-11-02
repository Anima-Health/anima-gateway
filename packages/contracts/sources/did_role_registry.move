#[allow(unused_field, unused_const, unused_use, unused_function)]
module contracts::did_role_registry {
    use std::string::String;
    use iota::event;
    use iota::table::{Self, Table};
    use iota::clock::{Self, Clock};
    use contracts::access_control::{Self, AccessControl};

    // ==================== Error Codes ====================
    const ERR_DID_NOT_FOUND: u64 = 1;
    const ERR_ACCOUNT_NOT_BOUND: u64 = 2;
    const ERR_ACCOUNT_ALREADY_BOUND: u64 = 3;
    const ERR_EMPTY_DID: u64 = 4;
    const ERR_EMPTY_DID_DOC_URI: u64 = 5;
    const ERR_NOT_ADMIN: u64 = 1; 
    const ERR_ROLE_NOT_FOUND: u64 = 3; 

    // ==================== Role Constants ====================
    //  System-wide roles (powers of 2 for bitwise operations)
    const ROLE_ADMIN: u8 = 1;              // 2^0
    const ROLE_ANCHORER: u8 = 2;           // 2^1
    const ROLE_WITNESS: u8 = 4;            // 2^2
    const ROLE_CONSENT_ATTESTER: u8 = 8;   // 2^3
    const ROLE_PERMIT_ISSUER: u8 = 16;     // 2^4
    const ROLE_GOVERNOR: u8 = 32;          // 2^5

    // ==================== Structs ====================
    
    //  Main registry for DID-account bindings and system-wide roles
    public struct DIDRoleRegistry has key {
        id: iota::object::UID,
        access: AccessControl,
        // DID → accounts mapping (one DID can map to multiple accounts)
        did_accounts: Table<vector<u8>, vector<address>>,
        account_roles: Table<address, u8>,
        did_doc_uris: Table<vector<u8>, String>,
        key_versions: Table<vector<u8>, u64>,
    }

    // ==================== Events ====================
    
    public struct DIDBound has copy, drop {
        did: vector<u8>,
        account: address,
        binder: address,
        timestamp: u64,
    }

    public struct DIDUnbound has copy, drop {
        did: vector<u8>,
        account: address,
        unbinder: address,
        timestamp: u64,
    }

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

    public struct KeyRotated has copy, drop {
        did: vector<u8>,
        old_account: address,
        new_account: address,
        key_version: u64,
        rotator: address,
        timestamp: u64,
    }

    public struct DIDDocURISet has copy, drop {
        did: vector<u8>,
        uri: String,
        setter: address,
        timestamp: u64,
    }

    // ==================== Initialization ====================
    
    //  Initialize the DIDRoleRegistry
    fun init(ctx: &mut iota::tx_context::TxContext) {
        let admin = iota::tx_context::sender(ctx);

        let registry = DIDRoleRegistry {
            id: iota::object::new(ctx),
            access: access_control::new(admin, ctx),
            did_accounts: table::new(ctx),
            account_roles: table::new(ctx),
            did_doc_uris: table::new(ctx),
            key_versions: table::new(ctx),
        };
        
        iota::transfer::share_object(registry);
    }

    // ==================== Governance Functions ====================
    
    //  Grant a role to an account (admin/governor only)
    public fun grant_role(
        registry: &mut DIDRoleRegistry,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        // Require admin or governor
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&registry.access, sender) ||
            has_role(registry, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );

        if (!table::contains(&registry.account_roles, account)) {
            table::add(&mut registry.account_roles, account, role);
        } else {
            let current_roles = table::borrow_mut(&mut registry.account_roles, account);
            *current_roles = *current_roles | role;
        };

        event::emit(RoleGranted {
            account,
            role,
            granter: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Revoke a role from an account (admin/governor only)
    public fun revoke_role(
        registry: &mut DIDRoleRegistry,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        // Require admin or governor
        let sender = iota::tx_context::sender(ctx);
        assert!(
            access_control::is_admin(&registry.access, sender) ||
            has_role(registry, sender, ROLE_GOVERNOR),
            ERR_NOT_ADMIN
        );
        assert!(table::contains(&registry.account_roles, account), ERR_ROLE_NOT_FOUND);

        let current_roles = table::borrow_mut(&mut registry.account_roles, account);
        *current_roles = *current_roles & (0xFF ^ role);

        event::emit(RoleRevoked {
            account,
            role,
            revoker: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Transfer admin to new address
    public fun transfer_admin(
        registry: &mut DIDRoleRegistry,
        new_admin: address,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        access_control::transfer_admin(&mut registry.access, new_admin, clock, ctx);
    }

    // ==================== DID Binding Functions ====================
    
    //  Bind a DID to an account (allows multiple accounts per DID for hot/cold wallets)
    public fun bind_did(
        registry: &mut DIDRoleRegistry,
        did: vector<u8>,
        account: address,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(vector::length(&did) > 0, ERR_EMPTY_DID);
        let sender = iota::tx_context::sender(ctx);

        // Initialize DID entry if it doesn't exist
        if (!table::contains(&registry.did_accounts, did)) {
            let accounts = vector::empty<address>();
            table::add(&mut registry.did_accounts, did, accounts);
            // Initialize key version to 1
            table::add(&mut registry.key_versions, did, 1);
        };

        let accounts = table::borrow_mut(&mut registry.did_accounts, did);
        
        // Check if account is already bound to this DID
        let len = vector::length(accounts);
        let mut i = 0;
        while (i < len) {
            if (*vector::borrow(accounts, i) == account) {
                abort ERR_ACCOUNT_ALREADY_BOUND
            };
            i = i + 1;
        };

        // Add account to DID's account list
        vector::push_back(accounts, account);

        event::emit(DIDBound {
            did,
            account,
            binder: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Unbind an account from a DID
    public fun unbind_did(
        registry: &mut DIDRoleRegistry,
        did: vector<u8>,
        account: address,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(vector::length(&did) > 0, ERR_EMPTY_DID);
        assert!(table::contains(&registry.did_accounts, did), ERR_DID_NOT_FOUND);
        let sender = iota::tx_context::sender(ctx);

        let accounts = table::borrow_mut(&mut registry.did_accounts, did);
        
        // Find and remove the account
        let len = vector::length(accounts);
        let mut i = 0;
        let mut found = false;
        while (i < len) {
            if (*vector::borrow(accounts, i) == account) {
                vector::remove(accounts, i);
                found = true;
                break
            };
            i = i + 1;
        };

        assert!(found, ERR_ACCOUNT_NOT_BOUND);

        // If no accounts left, optionally clean up DID entry
        // (Keeping it for audit trail - can be cleaned up later if needed)

        event::emit(DIDUnbound {
            did,
            account,
            unbinder: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ==================== DID Document Management ====================
    
    //  Set or update the DID document URI for a DID
    public fun set_did_doc_uri(
        registry: &mut DIDRoleRegistry,
        did: vector<u8>,
        uri: String,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(vector::length(&did) > 0, ERR_EMPTY_DID);
        assert!(*std::string::as_bytes(&uri) != &vector::empty(), ERR_EMPTY_DID_DOC_URI);
        let sender = iota::tx_context::sender(ctx);

        // Verify sender has account bound to this DID
        assert!(table::contains(&registry.did_accounts, did), ERR_DID_NOT_FOUND);
        let accounts = table::borrow(&registry.did_accounts, did);
        
        let len = vector::length(accounts);
        let mut i = 0;
        let mut has_binding = false;
        while (i < len) {
            if (*vector::borrow(accounts, i) == sender) {
                has_binding = true;
                break
            };
            i = i + 1;
        };
        assert!(has_binding, ERR_ACCOUNT_NOT_BOUND);

        if (!table::contains(&registry.did_doc_uris, did)) {
            table::add(&mut registry.did_doc_uris, did, uri);
        } else {
            let existing_uri = table::borrow_mut(&mut registry.did_doc_uris, did);
            *existing_uri = uri;
        };

        event::emit(DIDDocURISet {
            did,
            uri,
            setter: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ==================== Key Rotation ====================
    
    //  Rotate key for a DID (add new account, optionally remove old one)
    public fun rotate_key(
        registry: &mut DIDRoleRegistry,
        did: vector<u8>,
        old_account: address,
        new_account: address,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(vector::length(&did) > 0, ERR_EMPTY_DID);
        assert!(table::contains(&registry.did_accounts, did), ERR_DID_NOT_FOUND);
        let sender = iota::tx_context::sender(ctx);

        // Verify sender is the old account (or has permission)
        assert!(sender == old_account || has_role(registry, sender, ROLE_GOVERNOR), ERR_ACCOUNT_NOT_BOUND);

        // Remove old account
        let accounts = table::borrow_mut(&mut registry.did_accounts, did);
        let len = vector::length(accounts);
        let mut i = 0;
        let mut found = false;
        while (i < len) {
            if (*vector::borrow(accounts, i) == old_account) {
                vector::remove(accounts, i);
                found = true;
                break
            };
            i = i + 1;
        };
        assert!(found, ERR_ACCOUNT_NOT_BOUND);

        // Add new account
        vector::push_back(accounts, new_account);

        // Increment key version
        let key_version = table::borrow_mut(&mut registry.key_versions, did);
        *key_version = *key_version + 1;

        event::emit(KeyRotated {
            did,
            old_account,
            new_account,
            key_version: *key_version,
            rotator: sender,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ==================== View Functions ====================
    
    //  Check if an account has a specific role
    public fun has_role(registry: &DIDRoleRegistry, account: address, role: u8): bool {
        if (!table::contains(&registry.account_roles, account)) {
            return false
        };
        let roles = *table::borrow(&registry.account_roles, account);
        (roles & role) != 0
    }

    //  Get all roles for an account (returns bitmap)
    public fun get_roles(registry: &DIDRoleRegistry, account: address): u8 {
        if (!table::contains(&registry.account_roles, account)) {
            return 0
        };
        *table::borrow(&registry.account_roles, account)
    }

    //  Get all accounts bound to a DID
    public fun get_did_accounts(registry: &DIDRoleRegistry, did: vector<u8>): vector<address> {
        if (!table::contains(&registry.did_accounts, did)) {
            return vector::empty<address>()
        };
        *table::borrow(&registry.did_accounts, did)
    }

    //  Get DID document URI for a DID
    public fun get_did_doc_uri(registry: &DIDRoleRegistry, did: vector<u8>): String {
        if (!table::contains(&registry.did_doc_uris, did)) {
            return std::string::utf8(b"")
        };
        *table::borrow(&registry.did_doc_uris, did)
    }

    //  Get key version for a DID
    public fun get_key_version(registry: &DIDRoleRegistry, did: vector<u8>): u64 {
        if (!table::contains(&registry.key_versions, did)) {
            return 0
        };
        *table::borrow(&registry.key_versions, did)
    }

    //  Check if a DID is registered
    public fun is_did_registered(registry: &DIDRoleRegistry, did: vector<u8>): bool {
        table::contains(&registry.did_accounts, did)
    }

    //  Check if an account is bound to any DID
    public fun is_account_bound(_registry: &DIDRoleRegistry, _account: address): bool {
        // This is expensive - would need to iterate all DIDs
        // For now, return false (can be optimized with reverse index if needed)
        false
    }

    // ==================== Role Constants Accessors ====================
    
    public fun role_admin(): u8 { ROLE_ADMIN }
    public fun role_anchorer(): u8 { ROLE_ANCHORER }
    public fun role_witness(): u8 { ROLE_WITNESS }
    public fun role_consent_attester(): u8 { ROLE_CONSENT_ATTESTER }
    public fun role_permit_issuer(): u8 { ROLE_PERMIT_ISSUER }
    public fun role_governor(): u8 { ROLE_GOVERNOR }

    // ==================== Test Init ====================
    
    #[test_only]
    public fun init_for_testing(ctx: &mut iota::tx_context::TxContext) {
        init(ctx);
    }
}

