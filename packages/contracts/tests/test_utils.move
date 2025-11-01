#[test_only]
module contracts::test_utils {
    // ==================== Test Address Functions ====================
    
    public fun admin(): address { @0xAD }
    public fun alice(): address { @0xB1 }
    public fun bob(): address { @0xB2 }
    public fun charlie(): address { @0xB3 }
    public fun dave(): address { @0xB4 }

    // ==================== Role Constant Functions ====================
    
    public fun role_admin(): u8 { 1 }
    public fun role_anchorer(): u8 { 2 }
    public fun role_witness(): u8 { 3 }
    public fun role_consent_attester(): u8 { 2 }

    // ==================== Test Data Helpers ====================
    
    public fun test_hash(): vector<u8> { 
        x"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"
    }
    
    public fun test_hash_2(): vector<u8> { 
        x"9999999999999999999999999999999999999999999999999999999999999999"
    }
}
