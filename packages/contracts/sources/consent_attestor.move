#[allow(unused_field, unused_const, unused_use, unused_function)]
module contracts::consent_attestor {
    use std::string::String;
    use iota::event;
    use iota::table::{Self, Table};
    use iota::clock::{Self, Clock};
    use contracts::core_anchor;
    use contracts::access_control::{Self, AccessControl};

    // ==================== Error Codes ====================
    const ERR_ATTESTATION_NOT_FOUND: u64 = 2;
    const ERR_ALREADY_REVOKED: u64 = 3;
    const ERR_EMPTY_HASH: u64 = 5;
    const ERR_EMPTY_META_URI: u64 = 6;

    // ==================== Structs ====================
    
    //  Represents a single consent attestation record
    public struct ConsentAttestation has store, copy, drop {
        id: u64,
        consent_state_hash: vector<u8>,    // Hash of subject's consent graph
        policy_version_id: String,          // Semantic version 
        decision_hash: vector<u8>,          // Hash of policy evaluation decision - need to implement this
        anchor_ref: vector<u8>,             // Reference to AnimaAnchor root_hash
        submitter: address,                 // Service account with ROLE_CONSENT_ATTESTER
        meta_uri: String,                   // Off-chain metadata reference
        timestamp: u64,
        is_revoked: bool,
        revoke_reason: String,              // Empty if not revoked
        revoke_timestamp: u64,              
    }

    //  Main registry for all consent attestations
    public struct ConsentRegistry has key {
        id: iota::object::UID,
        // Map: attestation_id -> ConsentAttestation
        attestations: Table<u64, ConsentAttestation>,
        // Map: anchor_ref -> vector of attestation IDs
        anchor_index: Table<vector<u8>, vector<u64>>,
        // Access control component
        access: AccessControl,
        next_id: u64,
        attestation_list: vector<u64>, // Might need to refactor this in the future
    }

    // ==================== Events ====================
    
    public struct ConsentAttested has copy, drop {
        id: u64,
        consent_state_hash: vector<u8>,
        policy_version_id: String,
        decision_hash: vector<u8>,
        anchor_ref: vector<u8>,
        submitter: address,
        meta_uri: String,
        timestamp: u64,
    }

    public struct ConsentRevoked has copy, drop {
        id: u64,
        reason: String,
        revoker: address,
        timestamp: u64,
    }

    // ==================== Initialization ====================
    
    //  Initialize the ConsentRegistry
    fun init(ctx: &mut iota::tx_context::TxContext) {
        let admin = iota::tx_context::sender(ctx);

        let registry = ConsentRegistry {
            id: iota::object::new(ctx),
            attestations: table::new(ctx),
            anchor_index: table::new(ctx),
            access: access_control::new(admin, ctx),
            next_id: 1,
            attestation_list: vector::empty(),
        };
        
        iota::transfer::share_object(registry);
    }

    // ==================== Access Control ====================
    
    //  Grant a role to an account
    public fun grant_role(
        registry: &mut ConsentRegistry,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        access_control::grant_role(&mut registry.access, account, role, clock, ctx);
    }

    //  Revoke a role from an account
    public fun revoke_role(
        registry: &mut ConsentRegistry,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        access_control::revoke_role(&mut registry.access, account, role, clock, ctx);
    }

    //  Transfer admin to new address
    public fun transfer_admin(
        registry: &mut ConsentRegistry,
        new_admin: address,
        clock: &Clock,
        ctx: &iota::tx_context::TxContext
    ) {
        access_control::transfer_admin(&mut registry.access, new_admin, clock, ctx);
    }

    // ==================== Core Attestation Functions ====================
    
    //  Attest to consent compliance for a specific action
    //  Requires ROLE_CONSENT_ATTESTER
    public fun attest(
        registry: &mut ConsentRegistry,
        consent_state_hash: vector<u8>,
        policy_version_id: String,
        decision_hash: vector<u8>,
        anchor_ref: vector<u8>,
        meta_uri: String,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ): u64 {
        let sender = iota::tx_context::sender(ctx);
        
        access_control::require_role(&registry.access, sender, access_control::role_consent_attester());
        assert!(vector::length(&consent_state_hash) > 0, ERR_EMPTY_HASH);
        assert!(vector::length(&decision_hash) > 0, ERR_EMPTY_HASH);
        assert!(vector::length(&anchor_ref) > 0, ERR_EMPTY_HASH);
        assert!(*std::string::as_bytes(&meta_uri) != &vector::empty(), ERR_EMPTY_META_URI);
        
        let id = registry.next_id;
        registry.next_id = registry.next_id + 1;
        
        let timestamp = clock::timestamp_ms(clock);
        
        let attestation = ConsentAttestation {
            id,
            consent_state_hash,
            policy_version_id: policy_version_id,
            decision_hash,
            anchor_ref: anchor_ref,
            submitter: sender,
            meta_uri: meta_uri,
            timestamp,
            is_revoked: false,
            revoke_reason: std::string::utf8(b""),
            revoke_timestamp: 0,
        };
        
        // Store attestation
        table::add(&mut registry.attestations, id, attestation);
        vector::push_back(&mut registry.attestation_list, id);
        
        // Update anchor index
        if (!table::contains(&registry.anchor_index, anchor_ref)) {
            let new_list = vector::empty<u64>();
            table::add(&mut registry.anchor_index, anchor_ref, new_list);
        };
        let anchor_list = table::borrow_mut(&mut registry.anchor_index, anchor_ref);
        vector::push_back(anchor_list, id);
        
        // Emit event
        event::emit(ConsentAttested {
            id,
            consent_state_hash,
            policy_version_id,
            decision_hash,
            anchor_ref,
            submitter: sender,
            meta_uri,
            timestamp,
        });
        
        id
    }

    //  Get a specific attestation by ID
    public fun get_attestation(
        registry: &ConsentRegistry,
        id: u64
    ): &ConsentAttestation {
        assert!(table::contains(&registry.attestations, id), ERR_ATTESTATION_NOT_FOUND);
        table::borrow(&registry.attestations, id)
    }

    //  Find all attestations linked to a specific anchor
    public fun find_by_anchor(
        registry: &ConsentRegistry,
        anchor_ref: vector<u8>
    ): vector<u64> {
        if (!table::contains(&registry.anchor_index, anchor_ref)) {
            return vector::empty<u64>()
        };
        *table::borrow(&registry.anchor_index, anchor_ref)
    }

    //  Get latest N attestations (pagination support)
    public fun latest_attestations(
        registry: &ConsentRegistry,
        limit: u64,
        offset: u64
    ): vector<u64> {
        let total = vector::length(&registry.attestation_list);
        let mut result = vector::empty<u64>();
        
        if (offset >= total) {
            return result
        };
        
        let mut count = 0;
        let mut idx = total - 1 - offset;
        
        while (count < limit && idx >= 0) {
            let id = *vector::borrow(&registry.attestation_list, idx);
            vector::push_back(&mut result, id);
            count = count + 1;
            
            if (idx == 0) {
                break
            };
            idx = idx - 1;
        };
        
        result
    }

    //  Revoke an attestation (admin only)
    //  Keeps tombstone for audit trail
    public fun revoke(
        registry: &mut ConsentRegistry,
        id: u64,
        reason: String,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        access_control::require_admin(&registry.access, ctx);
        assert!(table::contains(&registry.attestations, id), ERR_ATTESTATION_NOT_FOUND);
        
        let attestation = table::borrow_mut(&mut registry.attestations, id);
        assert!(!attestation.is_revoked, ERR_ALREADY_REVOKED);
        
        let timestamp = clock::timestamp_ms(clock);
        
        attestation.is_revoked = true;
        attestation.revoke_reason = reason;
        attestation.revoke_timestamp = timestamp;
        
        event::emit(ConsentRevoked {
            id,
            reason,
            revoker: iota::tx_context::sender(ctx),
            timestamp,
        });
    }

    // ==================== View Functions ====================
    
    //  Check if an attestation exists
    public fun attestation_exists(registry: &ConsentRegistry, id: u64): bool {
        table::contains(&registry.attestations, id)
    }

    //  Get total number of attestations
    public fun total_attestations(registry: &ConsentRegistry): u64 {
        vector::length(&registry.attestation_list)
    }

    // ==================== Accessor Functions ====================
    
    public fun attestation_id(attestation: &ConsentAttestation): u64 { 
        attestation.id 
    }
    
    public fun consent_state_hash(attestation: &ConsentAttestation): &vector<u8> { 
        &attestation.consent_state_hash 
    }
    
    public fun policy_version_id(attestation: &ConsentAttestation): &String { 
        &attestation.policy_version_id 
    }
    
    public fun decision_hash(attestation: &ConsentAttestation): &vector<u8> { 
        &attestation.decision_hash 
    }
    
    public fun anchor_ref(attestation: &ConsentAttestation): &vector<u8> { 
        &attestation.anchor_ref 
    }
    
    public fun submitter(attestation: &ConsentAttestation): address { 
        attestation.submitter 
    }
    
    public fun meta_uri(attestation: &ConsentAttestation): &String { 
        &attestation.meta_uri 
    }
    
    public fun timestamp(attestation: &ConsentAttestation): u64 { 
        attestation.timestamp 
    }
    
    public fun is_revoked(attestation: &ConsentAttestation): bool { 
        attestation.is_revoked 
    }
    
    public fun revoke_reason(attestation: &ConsentAttestation): &String { 
        &attestation.revoke_reason 
    }
    
    public fun revoke_timestamp(attestation: &ConsentAttestation): u64 { 
        attestation.revoke_timestamp 
    }

    // ==================== Test Init ====================
    
    #[test_only]
    public fun init_for_testing(ctx: &mut iota::tx_context::TxContext) {
        init(ctx);
    }
}
