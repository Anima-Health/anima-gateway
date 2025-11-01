#[test_only]
module contracts::consent_attestor_test {
    use contracts::consent_attestor::{Self, ConsentRegistry};
    use contracts::access_control;
    use iota::test_scenario::{Self as ts};
    use iota::clock;
    use contracts::test_utils;

    #[test]
    //  Test that init function creates a shared Consent Registry object
    fun test_init_creates_shared_registry() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            assert!(ts::has_most_recent_shared<ConsentRegistry>(), 0);
            let registry = ts::take_shared<ConsentRegistry>(&scenario);
            ts::return_shared(registry);
        };

        ts::end(scenario);
    }

    #[test]
    //  Test admin can grant a role to a new account
    fun test_grant_role() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant CONSENT_ATTESTER role to ALICE
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test admin can grant multiple roles to same account
    fun test_grant_multiple_roles() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant first role
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant second role
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                1, // Different role
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
    //  Test non-admin cannot grant roles
    fun test_grant_role_fails_for_non_admin() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, alice); // Switch to non-admin
        
        // Try to grant role as non-admin, this should fail
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                bob, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test admin can revoke a role
    fun test_revoke_role() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant role to ALICE
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Revoke role from ALICE
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::revoke_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
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
    //  Test non-admin cannot revoke roles
    fun test_revoke_role_fails_for_non_admin() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant role to ALICE
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, bob); // Switch to non-admin
        
        // Try to revoke as non-admin (should fail)
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::revoke_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test creating a consent attestation
    fun test_attest() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant CONSENT_ATTESTER role to ALICE
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, alice);
        
        // ALICE creates a consent attestation
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let consent_hash = x"1111111111111111111111111111111111111111111111111111111111111111";
            let decision_hash = x"2222222222222222222222222222222222222222222222222222222222222222";
            let anchor_ref = test_utils::test_hash();
            
            consent_attestor::attest(
                &mut registry,
                consent_hash,
                std::string::utf8(b"v2.1.0"),
                decision_hash,
                anchor_ref,
                std::string::utf8(b"reduct://consent/metadata/1"),
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
    //  Test non-attester cannot create attestations
    fun test_attest_fails_for_non_attester() {
        let admin = test_utils::admin();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, bob); // BOB has no role
        
        // BOB tries to attest (should fail)
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let consent_hash = x"1111111111111111111111111111111111111111111111111111111111111111";
            let decision_hash = x"2222222222222222222222222222222222222222222222222222222222222222";
            let anchor_ref = test_utils::test_hash();
            
            consent_attestor::attest(
                &mut registry,
                consent_hash,
                std::string::utf8(b"v2.1.0"),
                decision_hash,
                anchor_ref,
                std::string::utf8(b"reduct://consent/metadata/1"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 5)]
    //  Test empty consent hash fails
    fun test_attest_fails_for_empty_consent_hash() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, alice);
        
        // ALICE tries with empty consent hash (should fail)
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let empty_hash = vector::empty<u8>();
            let decision_hash = x"2222222222222222222222222222222222222222222222222222222222222222";
            let anchor_ref = test_utils::test_hash();
            
            consent_attestor::attest(
                &mut registry,
                empty_hash,
                std::string::utf8(b"v2.1.0"),
                decision_hash,
                anchor_ref,
                std::string::utf8(b"reduct://consent/metadata/1"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test revoking an attestation
    fun test_revoke_attestation() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant CONSENT_ATTESTER role to ALICE
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, alice);
        
        // ALICE creates an attestation
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let consent_hash = x"1111111111111111111111111111111111111111111111111111111111111111";
            let decision_hash = x"2222222222222222222222222222222222222222222222222222222222222222";
            let anchor_ref = test_utils::test_hash();
            
            consent_attestor::attest(
                &mut registry,
                consent_hash,
                std::string::utf8(b"v2.1.0"),
                decision_hash,
                anchor_ref,
                std::string::utf8(b"reduct://consent/metadata/1"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Admin revokes the attestation
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::revoke(
                &mut registry,
                1,
                std::string::utf8(b"Policy violation"),
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
    //  Test non-admin cannot revoke attestations
    fun test_revoke_fails_for_non_admin() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::grant_role(
                &mut registry, 
                alice, 
                access_control::role_consent_attester(), 
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, alice);
        
        // ALICE creates an attestation
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let consent_hash = x"1111111111111111111111111111111111111111111111111111111111111111";
            let decision_hash = x"2222222222222222222222222222222222222222222222222222222222222222";
            let anchor_ref = test_utils::test_hash();
            
            consent_attestor::attest(
                &mut registry,
                consent_hash,
                std::string::utf8(b"v2.1.0"),
                decision_hash,
                anchor_ref,
                std::string::utf8(b"reduct://consent/metadata/1"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, bob); // BOB is not admin
        
        // BOB tries to revoke (should fail)
        {
            let mut registry = ts::take_shared<ConsentRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            consent_attestor::revoke(
                &mut registry,
                1,
                std::string::utf8(b"Policy violation"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

}

