## Contract Design Plan


### AnimaAnchor — that folds in all necessary features:
* Core anchoring: immutable registry of Merkle batch roots.
* Witness quorum: optional M-of-N attestations without a separate contract.
* Mirror references: optional pointers to cross-chain anchors (index only, no verification).
* Governance: role control + simple timelock in the same contract.
* Hash/Merkle domain allowlist and pause switch baked in.



This will be subject to modification in the future

Merkel Hashing off chain considerations

Witness quorum system for proof-of-data-attestation



## How they work together
1. Kernel/Pod makes commit → Journal CAE (off-chain)
2. Batcher builds Merkle root; Anchorer calls AnimaAnchor.anchorRoot → AnchorCommitted.
3. Consent layer hashes current consent state & decision → ConsentAttestor.attest.
If data access is granted, issue a time-boxed DataPermit for the accessor; clients show PermitIssued reference when fetching off-chain data.
DIDRoleRegistry is used by all calls to verify the caller’s role (Anchorer, Witness, Permit Issuer, etc.).
Any sensitive parameter/role changes are done via AnimaGovernor and are visible on-chain (plus you journal them off-chain).



## Considering mirroring functions
1. Hospital creates patient records → Merkle batch
2. Anchor on IOTA (primary blockchain)
3. Insurance company needs proof
4. Mirror to Ethereum
5. Submit mirror reference pointing to Ethereum TX
6. Patient moves to EU hospital
7. Mirror to EU-compliant chain
One source of truth with multiple access points