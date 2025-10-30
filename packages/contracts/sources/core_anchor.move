#[allow(unused_field, unused_const, unused_use, unused_function)]
module contracts::core_anchor {
    use std::string::String;
    use iota::event;
    use iota::table::{Self, Table};
    use iota::vec_map::{Self, VecMap};
    use iota::clock::{Self, Clock};

    // ==================== Error Codes ====================
    // Need to consider moving this in to a seperate util module
    const ERR_NOT_AUTHORIZED: u64 = 1;
    const ERR_ALREADY_ANCHORED: u64 = 2;
    const ERR_NOT_ANCHORED: u64 = 3;
    const ERR_ALREADY_WITNESSED: u64 = 4;
    const ERR_EMPTY_META_URI: u64 = 5;
    const ERR_INVALID_QUORUM: u64 = 6;
    const ERR_NOT_ADMIN: u64 = 7;

    // ==================== Role Constants ====================
    // By the default the contract is initialized with the admin role.
    // Need to consider typing this address to a multi-sig address in the future.
    const ROLE_ADMIN: u8 = 1;
    const ROLE_ANCHORER: u8 = 2;
    const ROLE_WITNESS: u8 = 3;


    // ==================== Structs ====================
    
    //  Represents a cross-chain mirror reference
    public struct Mirror has store, copy, drop {
        chain_id: String,
        tx_ref: String,
        proof_uri: String,
        timestamp: u64,
    }

    //  Main anchor record for a Merkle root
    public struct AnchorRecord has store {
        root_hash: vector<u8>,
        algo_id: String,
        batch_id: u64,
        submitter: address,
        meta_uri: String,
        timestamp: u64,
        witness_count: u64,
        quorum_met: bool,
        mirrors: vector<Mirror>,
        witnesses: VecMap<address, bool>, // Track which witnesses have attested
    }

    //  Registry storing all anchors and access control
    public struct AnimaAnchor has key {
        id: iota::object::UID,
        // Map: hash(rootHash + algoId) -> AnchorRecord
        anchors: Table<vector<u8>, AnchorRecord>,
        // Access control: address -> role bitmap
        roles: Table<address, u8>,
        witness_quorum: u64,
        admin: address,
        // Pagination support
        anchor_list: vector<vector<u8>>, // Ordered list of anchor keys
    }

    // ==================== Events ====================
    
    public struct AnchorCommitted has copy, drop {
        root_hash: vector<u8>,
        algo_id: String,
        batch_id: u64,
        submitter: address,
        meta_uri: String,
        timestamp: u64,
    }

    public struct WitnessAttested has copy, drop {
        root_hash: vector<u8>,
        witness: address,
        witness_count: u64,
        timestamp: u64,
    }

    public struct QuorumMet has copy, drop {
        root_hash: vector<u8>,
        witness_count: u64,
        timestamp: u64,
    }

    public struct MirrorSubmitted has copy, drop {
        root_hash: vector<u8>,
        chain_id: String,
        tx_ref: String,
        timestamp: u64,
    }

    public struct RoleGranted has copy, drop {
        account: address,
        role: u8,
        timestamp: u64,
    }

    public struct RoleRevoked has copy, drop {
        account: address,
        role: u8,
        timestamp: u64,
    }

    public struct QuorumUpdated has copy, drop {
        old_quorum: u64,
        new_quorum: u64,
        timestamp: u64,
    }

    // ==================== Initialization ====================
    
    //  Initialize the AnimaAnchor registry
    fun init(ctx: &mut iota::tx_context::TxContext) {
        // Gets the admin addr from the tx context
        let admin = iota::tx_context::sender(ctx);

        let mut registry = AnimaAnchor {
            id: iota::object::new(ctx),
            anchors: table::new(ctx),
            roles: table::new(ctx),
            witness_quorum: 3, // Default quorum
            admin,
            anchor_list: vector::empty(),
        };
        
        // Grant admin all roles
        table::add(&mut registry.roles, admin, ROLE_ADMIN | ROLE_ANCHORER | ROLE_WITNESS);
        
        iota::transfer::share_object(registry);
    }

    // ==================== Access Control ====================
    
    //  Check if an address has a specific role
    fun has_role(registry: &AnimaAnchor, account: address, role: u8): bool {
        if (!table::contains(&registry.roles, account)) {
            return false
        };
        let roles = *table::borrow(&registry.roles, account);
        (roles & role) != 0
    }

    //  Grant a role to an account (admin only)
    public fun grant_role(
        registry: &mut AnimaAnchor,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(iota::tx_context::sender(ctx) == registry.admin, ERR_NOT_ADMIN);
        
        if (!table::contains(&registry.roles, account)) {
            table::add(&mut registry.roles, account, role);
        } else {
            let current_roles = table::borrow_mut(&mut registry.roles, account);
            *current_roles = *current_roles | role;
        };
        
        event::emit(RoleGranted {
            account,
            role,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Revoke a role from an account (admin only)
    public fun revoke_role(
        registry: &mut AnimaAnchor,
        account: address,
        role: u8,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(iota::tx_context::sender(ctx) == registry.admin, ERR_NOT_ADMIN);
        assert!(table::contains(&registry.roles, account), ERR_NOT_AUTHORIZED);
        
        let current_roles = table::borrow_mut(&mut registry.roles, account);
        *current_roles = *current_roles & (0xFF ^ role);
        
        event::emit(RoleRevoked {
            account,
            role,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    //  Update witness quorum threshold (admin only)
    public fun update_quorum(
        registry: &mut AnimaAnchor,
        new_quorum: u64,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        assert!(iota::tx_context::sender(ctx) == registry.admin, ERR_NOT_ADMIN);
        assert!(new_quorum > 0, ERR_INVALID_QUORUM);
        
        let old_quorum = registry.witness_quorum;
        registry.witness_quorum = new_quorum;
        
        event::emit(QuorumUpdated {
            old_quorum,
            new_quorum,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ==================== Core Anchor Functions ====================
    
    //  Generate unique key for anchor lookup
    fun make_anchor_key(root_hash: &vector<u8>, algo_id: &String): vector<u8> {
        let mut key = *root_hash;
        vector::append(&mut key, *std::string::as_bytes(algo_id));
        key
    }

    //  Anchor a new Merkle root (requires ROLE_ANCHORER)
    public fun anchor_root(
        registry: &mut AnimaAnchor,
        root_hash: vector<u8>,
        algo_id: String, // Specifies the algorithm used to create the Merkle root
        batch_id: u64, // Unique identifier
        meta_uri: String, // This should be a reduct reference
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        
        assert!(has_role(registry, sender, ROLE_ANCHORER), ERR_NOT_AUTHORIZED);
        assert!(*std::string::as_bytes(&meta_uri) != &vector::empty(), ERR_EMPTY_META_URI);
        
        // Generate unique key
        let key = make_anchor_key(&root_hash, &algo_id);
        
        // Ensure this root hasn't been anchored before
        assert!(!table::contains(&registry.anchors, key), ERR_ALREADY_ANCHORED);
        
        let timestamp = clock::timestamp_ms(clock);
        
        // Create new anchor record
        let record = AnchorRecord {
            root_hash: root_hash,
            algo_id: algo_id,
            batch_id,
            submitter: sender,
            meta_uri: meta_uri,
            timestamp,
            witness_count: 0,
            quorum_met: false,
            mirrors: vector::empty(),
            witnesses: vec_map::empty(),
        };
        
        // Store the anchor
        table::add(&mut registry.anchors, key, record);
        vector::push_back(&mut registry.anchor_list, key);
        
        event::emit(AnchorCommitted {
            root_hash,
            algo_id,
            batch_id,
            submitter: sender,
            meta_uri,
            timestamp,
        });
    }

    //  Check if a root is anchored
    public fun is_anchored(
        registry: &AnimaAnchor,
        root_hash: vector<u8>,
        algo_id: String
    ): bool {
        let key = make_anchor_key(&root_hash, &algo_id);
        table::contains(&registry.anchors, key)
    }

    //  Get anchor details (returns immutable reference)
    public fun get_anchor(
        registry: &AnimaAnchor,
        root_hash: vector<u8>,
        algo_id: String
    ): &AnchorRecord {
        let key = make_anchor_key(&root_hash, &algo_id);
        assert!(table::contains(&registry.anchors, key), ERR_NOT_ANCHORED);
        table::borrow(&registry.anchors, key)
    }

    //  Witness attestation (requires ROLE_WITNESS)
    public fun witness_attest(
        registry: &mut AnimaAnchor,
        root_hash: vector<u8>,
        algo_id: String,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);
        
        assert!(has_role(registry, sender, ROLE_WITNESS), ERR_NOT_AUTHORIZED);
        
        // Get anchor record
        let key = make_anchor_key(&root_hash, &algo_id);
        assert!(table::contains(&registry.anchors, key), ERR_NOT_ANCHORED);
        
        let record = table::borrow_mut(&mut registry.anchors, key);
        
        // Ensure witness hasn't already attested
        assert!(!vec_map::contains(&record.witnesses, &sender), ERR_ALREADY_WITNESSED);
        
        vec_map::insert(&mut record.witnesses, sender, true);
        record.witness_count = record.witness_count + 1;
        
        let timestamp = clock::timestamp_ms(clock);
        
        // Emit attestation event
        event::emit(WitnessAttested {
            root_hash: root_hash,
            witness: sender,
            witness_count: record.witness_count,
            timestamp,
        });
        
        // Check if quorum is met
        if (!record.quorum_met && record.witness_count >= registry.witness_quorum) {
            record.quorum_met = true;
            event::emit(QuorumMet {
                root_hash,
                witness_count: record.witness_count,
                timestamp,
            });
        };
    }

    //  Submit cross-chain mirror reference
    public fun submit_mirror(
        registry: &mut AnimaAnchor,
        root_hash: vector<u8>,
        algo_id: String,
        chain_id: String,
        tx_ref: String,
        proof_uri: String,
        clock: &Clock,
        ctx: &mut iota::tx_context::TxContext
    ) {
        let sender = iota::tx_context::sender(ctx);

        assert!(
            has_role(registry, sender, ROLE_ANCHORER) || 
            has_role(registry, sender, ROLE_WITNESS),
            ERR_NOT_AUTHORIZED
        );
        
        let key = make_anchor_key(&root_hash, &algo_id);
        assert!(table::contains(&registry.anchors, key), ERR_NOT_ANCHORED);
        
        let record = table::borrow_mut(&mut registry.anchors, key);
        let timestamp = clock::timestamp_ms(clock);
        
        let mirror = Mirror {
            chain_id: chain_id,
            tx_ref: tx_ref,
            proof_uri: proof_uri,
            timestamp,
        };
        vector::push_back(&mut record.mirrors, mirror);
        
        event::emit(MirrorSubmitted {
            root_hash,
            chain_id,
            tx_ref,
            timestamp,
        });
    }

    // ==================== View Functions ====================
    
    //  Get latest N anchors (pagination support)
    public fun latest_anchors_count(registry: &AnimaAnchor, limit: u64): u64 {
        let total = vector::length(&registry.anchor_list);
        if (limit < total) { limit } else { total }
    }

    //  Get anchor key by index (for pagination)
    public fun get_anchor_key_at(registry: &AnimaAnchor, index: u64): vector<u8> {
        let len = vector::length(&registry.anchor_list);
        assert!(index < len, ERR_NOT_ANCHORED);
        *vector::borrow(&registry.anchor_list, len - 1 - index)
    }

    // ==================== Accessor Functions for AnchorRecord ====================
    
    public fun root_hash(record: &AnchorRecord): &vector<u8> { &record.root_hash }
    public fun meta_uri(record: &AnchorRecord): &String { &record.meta_uri }
    public fun witness_count(record: &AnchorRecord): u64 { record.witness_count }
    public fun quorum_met(record: &AnchorRecord): bool { record.quorum_met }
    

    // ==================== Test Init ====================
    
    #[test_only]
    // Exposed for testing purposes
    public fun init_for_testing(ctx: &mut iota::tx_context::TxContext) {
        init(ctx);
    }
}
