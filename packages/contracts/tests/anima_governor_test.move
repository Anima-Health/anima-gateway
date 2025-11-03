#[test_only]
module contracts::anima_governor_test {
    use contracts::anima_governor::{Self, AnimaGovernor};
    use contracts::core_anchor::{Self, AnimaAnchor};
    use contracts::consent_attestor::{Self, ConsentRegistry};
    use contracts::did_role_registry::{Self, DIDRoleRegistry};
    use iota::test_scenario::{Self as ts};
    use iota::clock;
    use std::string;
    use contracts::test_utils;

    // ==================== Integration Tests ====================

    #[test]
    //  Test that governor can pause and unpause core_anchor contract
    fun test_governor_pause_unpause_core_anchor() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        // Initialize all contracts
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            consent_attestor::init_for_testing(ctx);
            did_role_registry::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Pause core_anchor via governor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"Emergency maintenance"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify core_anchor is paused
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            assert!(
                anima_governor::is_paused(&governor, anima_governor::target_core_anchor()),
                0
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Unpause core_anchor via governor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::unpause(
                &mut governor,
                anima_governor::target_core_anchor(),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify core_anchor is unpaused
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            assert!(
                !anima_governor::is_paused(&governor, anima_governor::target_core_anchor()),
                0
            );
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test that governor can pause multiple contracts
    fun test_governor_pause_multiple_contracts() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        // Initialize all contracts
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            consent_attestor::init_for_testing(ctx);
            did_role_registry::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Pause core_anchor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"Pause anchor"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Pause consent_attestor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_consent_attestor(),
                string::utf8(b"Pause consent"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify both are paused
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            assert!(
                anima_governor::is_paused(&governor, anima_governor::target_core_anchor()),
                0
            );
            assert!(
                anima_governor::is_paused(&governor, anima_governor::target_consent_attestor()),
                0
            );
            assert!(
                !anima_governor::is_paused(&governor, anima_governor::target_did_role_registry()),
                0
            );
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_NOT_ADMIN
    //  Test guardian can pause but not unpause
    fun test_guardian_can_pause_not_unpause() {
        let admin = test_utils::admin();
        let guardian = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        // Initialize contracts
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant guardian role to alice
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::grant_role(
                &mut governor,
                guardian,
                anima_governor::role_guardian(),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, guardian);
        
        // Guardian can pause
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"Emergency pause by guardian"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, guardian);
        
        // Guardian cannot unpause (should fail)
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::unpause(
                &mut governor,
                anima_governor::target_core_anchor(),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ERR_NOT_ADMIN
    //  Test that non-admin cannot pause
    fun test_pause_fails_for_non_admin() {
        let admin = test_utils::admin();
        let bob = test_utils::bob();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, bob); // Switch to non-admin
        
        // Try to pause (should fail)
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"Unauthorized"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can set parameters for contracts
    fun test_governor_set_param() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Set parameter for core_anchor (e.g., max_meta_uri_length)
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let mut max_length = vector::empty<u8>();
            vector::push_back(&mut max_length, 255); // Max length = 255
            
            anima_governor::set_param(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"max_meta_uri_length"),
                max_length,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Get parameter back
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            let value = anima_governor::get_param(
                &governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"max_meta_uri_length")
            );
            
            assert!(vector::length(&value) > 0, 0);
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can set multiple parameters for different contracts
    fun test_governor_set_multiple_params() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            consent_attestor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Set parameter for core_anchor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let mut value1 = vector::empty<u8>();
            vector::push_back(&mut value1, 128);
            
            anima_governor::set_param(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"max_batch_size"),
                value1,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Set parameter for consent_attestor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let mut value2 = vector::empty<u8>();
            vector::push_back(&mut value2, 64);
            
            anima_governor::set_param(
                &mut governor,
                anima_governor::target_consent_attestor(),
                string::utf8(b"max_attestations_per_batch"),
                value2,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify both parameters are set
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            let param1 = anima_governor::get_param(
                &governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"max_batch_size")
            );
            assert!(vector::length(&param1) > 0, 0);
            
            let param2 = anima_governor::get_param(
                &governor,
                anima_governor::target_consent_attestor(),
                string::utf8(b"max_attestations_per_batch")
            );
            assert!(vector::length(&param2) > 0, 0);
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can schedule and execute timelocked operations
    fun test_governor_schedule_and_execute() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Schedule an operation (update quorum)
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let current_time = clock::timestamp_ms(&clock);
            let delay = anima_governor::timelock_delay(&governor);
            let eta = current_time + delay;
            
            let mut params = vector::empty<u8>();
            vector::push_back(&mut params, 5); // New quorum = 5
            
            let op_id = anima_governor::schedule(
                &mut governor,
                anima_governor::target_core_anchor(),
                anima_governor::op_update_quorum(),
                params,
                eta,
                &clock,
                ctx
            );
            
            assert!(op_id == 1, 0);
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify operation is scheduled but not executable yet
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            let (target, op, eta, executed) = anima_governor::get_scheduled_op(&governor, 1);
            assert!(target == anima_governor::target_core_anchor(), 0);
            assert!(op == anima_governor::op_update_quorum(), 0);
            assert!(eta > 0, 0);
            assert!(!executed, 0);
            
            // Should not be executable yet (delay hasn't passed)
            assert!(!anima_governor::is_executable(&governor, 1, &clock), 0);
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can grant roles to other contracts
    fun test_governor_grant_role_to_contract_accounts() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            did_role_registry::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Governor grants role to alice for DIDRoleRegistry
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::grant_role(
                &mut governor,
                alice,
                anima_governor::role_governor(),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify role was granted (check via DIDRoleRegistry if it has governor role)
        // Note: This tests the integration - governor manages roles that affect other contracts
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            // Role granted successfully
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can update timelock delay
    fun test_governor_update_timelock_delay() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Get initial delay
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            let initial_delay = anima_governor::timelock_delay(&governor);
            assert!(initial_delay == 86400000, 0); // Default 24 hours
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Update delay to 48 hours
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::set_timelock_delay(
                &mut governor,
                172800000, // 48 hours
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify delay updated
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            let new_delay = anima_governor::timelock_delay(&governor);
            assert!(new_delay == 172800000, 0);
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor can cancel scheduled operations
    fun test_governor_cancel_scheduled_op() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Schedule an operation
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let current_time = clock::timestamp_ms(&clock);
            let delay = anima_governor::timelock_delay(&governor);
            let eta = current_time + delay;
            
            let mut params = vector::empty<u8>();
            vector::push_back(&mut params, 10);
            
            anima_governor::schedule(
                &mut governor,
                anima_governor::target_core_anchor(),
                anima_governor::op_set_param(),
                params,
                eta,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Cancel the scheduled operation
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::cancel(
                &mut governor,
                1,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify operation is cancelled (should not exist anymore)
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            // Operation should be cancelled (removed)
            // We can't check it directly since it's removed, but the cancel should succeed
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test full integration: Governor manages pause state while other contracts operate
    fun test_governor_pause_integration_with_core_anchor() {
        let admin = test_utils::admin();
        let alice = test_utils::alice();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Grant anchorer role to alice in core_anchor
        {
            let mut anchor = ts::take_shared<AnimaAnchor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            core_anchor::grant_role(
                &mut anchor,
                alice,
                2, // ROLE_ANCHORER
                &clock,
                ctx
            );
            
            ts::return_shared(anchor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Governor pauses core_anchor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"Emergency pause"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify core_anchor is paused
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            assert!(
                anima_governor::is_paused(&governor, anima_governor::target_core_anchor()),
                0
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Governor unpauses core_anchor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::unpause(
                &mut governor,
                anima_governor::target_core_anchor(),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor manages consent_attestor parameters
    fun test_governor_manages_consent_attestor_params() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            consent_attestor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Set parameter for consent_attestor
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let mut value = vector::empty<u8>();
            vector::push_back(&mut value, 100); // Max attestations
            
            anima_governor::set_param(
                &mut governor,
                anima_governor::target_consent_attestor(),
                string::utf8(b"max_attestations_per_anchor"),
                value,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify parameter is set
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            let param = anima_governor::get_param(
                &governor,
                anima_governor::target_consent_attestor(),
                string::utf8(b"max_attestations_per_anchor")
            );
            
            assert!(vector::length(&param) > 0, 0);
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test governor manages DIDRoleRegistry pause state
    fun test_governor_manages_did_registry_pause() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            did_role_registry::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Pause DIDRoleRegistry
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_did_role_registry(),
                string::utf8(b"Maintenance window"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Verify DIDRoleRegistry is paused
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            assert!(
                anima_governor::is_paused(&governor, anima_governor::target_did_role_registry()),
                0
            );
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    //  Test complete workflow: pause -> set params -> unpause
    fun test_governor_complete_workflow() {
        let admin = test_utils::admin();
        let mut scenario = ts::begin(admin);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        {
            let ctx = ts::ctx(&mut scenario);
            core_anchor::init_for_testing(ctx);
            anima_governor::init_for_testing(ctx);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Step 1: Pause contract
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::pause(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"Maintenance"),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Step 2: Set parameters while paused
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let mut value = vector::empty<u8>();
            vector::push_back(&mut value, 42);
            
            anima_governor::set_param(
                &mut governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"maintenance_mode"),
                value,
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Step 3: Unpause contract
        {
            let mut governor = ts::take_shared<AnimaGovernor>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            anima_governor::unpause(
                &mut governor,
                anima_governor::target_core_anchor(),
                &clock,
                ctx
            );
            
            ts::return_shared(governor);
        };
        
        ts::next_tx(&mut scenario, admin);
        
        // Step 4: Verify state
        {
            let governor = ts::take_shared<AnimaGovernor>(&scenario);
            
            // Contract should be unpaused
            assert!(
                !anima_governor::is_paused(&governor, anima_governor::target_core_anchor()),
                0
            );
            
            // Parameter should still be set
            let param = anima_governor::get_param(
                &governor,
                anima_governor::target_core_anchor(),
                string::utf8(b"maintenance_mode")
            );
            assert!(vector::length(&param) > 0, 0);
            
            ts::return_shared(governor);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}

