#[test_only]
module contracts::core_anchor_tests {
    use contracts::core_anchor::{Self, AnimaAnchor, ERR_INVALID_QUORUM, ERR_ALREADY_ANCHORED, ERR_EMPTY_META_URI, ERR_NOT_ANCHORED, ERR_ALREADY_WITNESSED};
    use iota::test_scenario::{Self as ts};
    use iota::clock;
    use std::string;
    
    // Test constants - values aligned with test_utils conventions
    const ADMIN: address = @0xAD;
    const ALICE: address = @0xB1;
    const BOB: address = @0xB2;
    const CHARLIE: address = @0xB3;
    const ROLE_ANCHORER: u8 = 2;
    const ROLE_WITNESS: u8 = 3;

    #[test]
    /// Test that init function creates a shared Anima Anchor object
    /// I wonder the usefulness of intergration testing
    fun test_init_creates_shared_registry() {
        let mut scenario = ts::begin(ADMIN);
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Verify the AnimaAnchor object was created and shared
        {
            assert!(ts::has_most_recent_shared<AnimaAnchor>(), 0);
            let registry = ts::take_shared<AnimaAnchor>(&scenario);
            ts::return_shared(registry);
        };

        ts::end(scenario);
    }

    #[test]
    //  Test that admin can grant a role to a new account
    fun test_grant_role_to_new_account() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        // Initialize the registry
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test that admin can grant multiple roles to the same account
    fun test_grant_multiple_roles_to_same_account() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);

        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant WITNESS role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_WITNESS, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    /// Test that non-admin cannot grant roles
    fun test_grant_role_fails_for_non_admin() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        // Initialize the registry
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ALICE); // Switch to non-admin user
        
        // Try to grant role as non-admin (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                BOB, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    // Test admin can revoke a role from an account
    fun test_revoke_role() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Revoke ANCHORER role from ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::revoke_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    // Test non-admin cannot revoke roles
    fun test_revoke_role_fails_for_non_admin() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, BOB); // Switch to non-admin
        
        // Try to revoke as non-admin (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::revoke_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    // Test admin can update quorum
    fun test_update_quorum() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Update quorum to 5
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::update_quorum(
                &mut registry, 
                5, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    // Test non-admin cannot update quorum
    fun test_update_quorum_fails_for_non_admin() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ALICE); // Switch to non-admin
        
        // Try to update quorum as non-admin (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::update_quorum(
                &mut registry, 
                5, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ERR_INVALID_QUORUM)]
    // Test updating quorum to 0 fails
    fun test_update_quorum_fails_for_zero() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Try to update quorum to 0 (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::update_quorum(
                &mut registry, 
                0, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    // Test anchoring a Merkle root successfully
    fun test_anchor_root() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE anchors a Merkle root
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    // Test that non-anchorer cannot anchor roots
    fun test_anchor_root_fails_for_non_anchorer() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, BOB); // BOB has no roles
        
        // BOB tries to anchor (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ERR_ALREADY_ANCHORED)]
    // Test that same root cannot be anchored twice, this is very important
    fun test_anchor_root_fails_for_duplicate() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE anchors a root
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE tries to anchor the same root again (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                99999, // Different batch_id
                string::utf8(b"reduct://bucket/metadata/batch-99999"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ERR_EMPTY_META_URI)]
    // Test that empty meta_uri fails
    fun test_anchor_root_fails_for_empty_meta_uri() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut registry, 
                ALICE, 
                ROLE_ANCHORER, 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE tries to anchor with empty meta_uri (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b""), // Empty meta_uri
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    // Test witness attestation
    fun test_witness_attest() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant roles to ALICE (anchorer) and BOB (witness)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, ALICE, ROLE_ANCHORER, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, BOB, ROLE_WITNESS, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE anchors a root
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, BOB);
        
        // BOB witnesses the anchor
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    // Test non-witness cannot attest
    fun test_witness_attest_fails_for_non_witness() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant ANCHORER role to ALICE only
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, ALICE, ROLE_ANCHORER, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE anchors a root
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, BOB); // BOB has no witness role
        
        // BOB tries to witness (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ERR_NOT_ANCHORED)]
    // Test witnessing non-existent anchor fails
    fun test_witness_attest_fails_for_non_existent_anchor() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant WITNESS role to BOB
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, BOB, ROLE_WITNESS, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, BOB);
        
        // BOB tries to witness a non-existent anchor - expect to fail
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"9999999999999999999999999999999999999999999999999999999999999999";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ERR_ALREADY_WITNESSED)]
    // Test witness cannot attest twice
    fun test_witness_attest_fails_for_duplicate() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant roles
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, ALICE, ROLE_ANCHORER, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, BOB, ROLE_WITNESS, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE anchors a root
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, BOB);
        
        // BOB witnesses the anchor
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, BOB);
        
        // BOB tries to witness again (should fail)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    // Test quorum is met with multiple witnesses
    fun test_witness_attest_quorum_met() {
        let mut scenario = ts::begin(ADMIN);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        // Grant roles to ALICE (anchorer) and BOB, CHARLIE (witnesses)
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, ALICE, ROLE_ANCHORER, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, BOB, ROLE_WITNESS, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(&mut registry, CHARLIE, ROLE_WITNESS, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN);
        
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            // Also give ADMIN witness role
            core_anchor::grant_role(&mut registry, ADMIN, ROLE_WITNESS, &clock, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ALICE);
        
        // ALICE anchors a root
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::anchor_root(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                12345,
                string::utf8(b"reduct://bucket/metadata/batch-12345"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        // First witness (BOB)
        ts::next_tx(&mut scenario, BOB);
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        // Second witness (CHARLIE)
        ts::next_tx(&mut scenario, CHARLIE);
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        // Third witness (ADMIN) - should trigger quorum (default is 3)
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut registry = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let root_hash = x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
            
            core_anchor::witness_attest(
                &mut registry,
                root_hash,
                string::utf8(b"sha256"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

}
