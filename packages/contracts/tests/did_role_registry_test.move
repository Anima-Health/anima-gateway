#[test_only]
module contracts::did_role_registry_test {
    use contracts::did_role_registry::{Self, DIDRoleRegistry};
    use iota::test_scenario::{Self as ts};
    use iota::clock;
    use std::string;
    use contracts::test_utils;

    // Test constants
    const TEST_DID: vector<u8> = x"1234567890123456789012345678901234567890123456789012345678901234";
    const TEST_DID_2: vector<u8> = x"9876543210987654321098765432109876543210987654321098765432109876";

    #[test]
    //  Test that init function creates a shared DIDRoleRegistry object
    fun test_init_creates_shared_registry() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            assert!(ts::has_most_recent_shared<DIDRoleRegistry>(), 0);
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            ts::return_shared(registry);
        };

        ts::end(scenario);
    }

    #[test]
    //  Test binding a DID to an account
    fun test_bind_did() {
        let admin = test_utils::admin();
        // let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin account
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test binding multiple accounts to same DID (hot/cold wallets)
    fun test_bind_multiple_accounts_to_did() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind first account
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind second account to same DID
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind third account to same DID
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                bob,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 3)] // ERR_ACCOUNT_ALREADY_BOUND
    //  Test that binding same account twice fails
    fun test_bind_did_fails_for_duplicate() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind first time
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to bind again (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 4)] // ERR_EMPTY_DID
    //  Test that binding with empty DID fails
    fun test_bind_did_fails_for_empty_did() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to bind with empty DID (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let empty_did = vector::empty<u8>();
            
            did_role_registry::bind_did(
                &mut registry,
                empty_did,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test unbinding a DID from an account
    fun test_unbind_did() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to alice
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Unbind admin from DID
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::unbind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_DID_NOT_FOUND
    //  Test that unbinding from non-existent DID fails
    fun test_unbind_did_fails_for_non_existent() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to unbind from non-existent DID (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::unbind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)] // ERR_ACCOUNT_NOT_BOUND
    //  Test that unbinding account not bound to DID fails
    fun test_unbind_did_fails_for_account_not_bound() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind admin to DID
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to unbind alice (not bound) (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::unbind_did(
                &mut registry,
                TEST_DID,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test granting a role to an account
    fun test_grant_role() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant ANCHORER role to ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test granting multiple roles to same account
    fun test_grant_multiple_roles() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant first role
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant second role
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_witness(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant third role
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_permit_issuer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_NOT_ADMIN
    //  Test that non-admin cannot grant roles
    fun test_grant_role_fails_for_non_admin() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, alice); // Switch to non-admin
        
        // Try to grant role as non-admin (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                bob,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test revoking a role from an account
    fun test_revoke_role() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant role to ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Revoke role from ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::revoke_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_NOT_ADMIN
    //  Test that non-admin cannot revoke roles
    fun test_revoke_role_fails_for_non_admin() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant role to ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, bob); // Switch to non-admin
        
        // Try to revoke as non-admin (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::revoke_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 3)] // ERR_ROLE_NOT_FOUND
    //  Test that revoking role from account without roles fails
    fun test_revoke_role_fails_for_no_roles() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to revoke role from account without roles (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::revoke_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test setting DID document URI
    fun test_set_did_doc_uri() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Set DID document URI
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::set_did_doc_uri(
                &mut registry,
                TEST_DID,
                string::utf8(b"https://example.com/did/doc.json"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_DID_NOT_FOUND
    //  Test that setting URI for non-existent DID fails
    fun test_set_did_doc_uri_fails_for_non_existent() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to set URI for non-existent DID (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::set_did_doc_uri(
                &mut registry,
                TEST_DID,
                string::utf8(b"https://example.com/did/doc.json"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)] // ERR_ACCOUNT_NOT_BOUND
    //  Test that setting URI with account not bound to DID fails
    fun test_set_did_doc_uri_fails_for_account_not_bound() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, alice); // Switch to alice (not bound)
        
        // Try to set URI as alice (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::set_did_doc_uri(
                &mut registry,
                TEST_DID,
                string::utf8(b"https://example.com/did/doc.json"),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 5)] // ERR_EMPTY_DID_DOC_URI
    //  Test that setting empty URI fails
    fun test_set_did_doc_uri_fails_for_empty_uri() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to set empty URI (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::set_did_doc_uri(
                &mut registry,
                TEST_DID,
                string::utf8(b""),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test rotating a key for a DID
    fun test_rotate_key() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Rotate key (admin -> alice)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::rotate_key(
                &mut registry,
                TEST_DID,
                admin,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_DID_NOT_FOUND
    //  Test that rotating key for non-existent DID fails
    fun test_rotate_key_fails_for_non_existent() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to rotate key for non-existent DID (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::rotate_key(
                &mut registry,
                TEST_DID,
                admin,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)] // ERR_ACCOUNT_NOT_BOUND
    //  Test that rotating key with wrong old account fails
    fun test_rotate_key_fails_for_wrong_account() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Try to rotate with wrong old account (should fail)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::rotate_key(
                &mut registry,
                TEST_DID,
                bob, // Wrong account
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test has_role function
    fun test_has_role() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant role to ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check has_role
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            // Check alice has anchorer role
            assert!(did_role_registry::has_role(&registry, alice, did_role_registry::role_anchorer()), 0);
            
            // Check alice does NOT have witness role
            assert!(!did_role_registry::has_role(&registry, alice, did_role_registry::role_witness()), 0);
            
            // Check bob does NOT have anchorer role
            assert!(!did_role_registry::has_role(&registry, test_utils::bob(), did_role_registry::role_anchorer()), 0);
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test get_roles function
    fun test_get_roles() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant multiple roles to ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_witness(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check get_roles
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            let roles = did_role_registry::get_roles(&registry, alice);
            assert!(roles > 0, 0); // Should have roles
            
            // Check no roles for bob
            let bob_roles = did_role_registry::get_roles(&registry, test_utils::bob());
            assert!(bob_roles == 0, 0);
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test get_did_accounts function
    fun test_get_did_accounts() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind multiple accounts to DID
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                bob,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check get_did_accounts
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            let accounts = did_role_registry::get_did_accounts(&registry, TEST_DID);
            assert!(vector::length(&accounts) == 3, 0);
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test get_did_doc_uri function
    fun test_get_did_doc_uri() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Set DID document URI
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let uri = string::utf8(b"https://example.com/did/doc.json");
            did_role_registry::set_did_doc_uri(
                &mut registry,
                TEST_DID,
                uri,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check get_did_doc_uri
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            let uri = did_role_registry::get_did_doc_uri(&registry, TEST_DID);
            assert!(*std::string::as_bytes(&uri) != &vector::empty(), 0);
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test get_key_version function
    fun test_get_key_version() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin (initial version should be 1)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check initial key version
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            let version = did_role_registry::get_key_version(&registry, TEST_DID);
            assert!(version == 1, 0);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Rotate key (should increment version)
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::rotate_key(
                &mut registry,
                TEST_DID,
                admin,
                alice,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check updated key version
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            let version = did_role_registry::get_key_version(&registry, TEST_DID);
            assert!(version == 2, 0);
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test is_did_registered function
    fun test_is_did_registered() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Bind DID to admin
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::bind_did(
                &mut registry,
                TEST_DID,
                admin,
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Check is_did_registered
        {
            let registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            
            assert!(did_role_registry::is_did_registered(&registry, TEST_DID), 0);
            assert!(!did_role_registry::is_did_registered(&registry, TEST_DID_2), 0);
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can grant roles
    fun test_governor_can_grant_role() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant GOVERNOR role to ALICE
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                alice,
                did_role_registry::role_governor(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, alice); // Switch to governor
        
        // Governor grants role
        {
            let mut registry = ts::take_shared<DIDRoleRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            did_role_registry::grant_role(
                &mut registry,
                test_utils::bob(),
                did_role_registry::role_anchorer(),
                &clock,
                ctx
            );
            
            ts::return_shared(registry);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}

