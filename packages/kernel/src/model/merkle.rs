use sha2::{Sha256, Digest};
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MerkleRoot {
    pub root_hash: Vec<u8>,
    pub algo_id: String,
    pub batch_id: u64,
    pub record_count: usize,
    pub timestamp: u64,
}

pub struct MerkleTree {
    leaves: Vec<Vec<u8>>,
    // Store patient IDs for proof generation
    leaf_ids: Vec<String>,
}

/// Merkle proof for verifying a leaf is in the tree
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MerkleProof {
    pub leaf_hash: String,
    pub leaf_index: usize,
    pub proof_hashes: Vec<String>,
    pub root_hash: String,
    pub patient_id: String,
}

impl MerkleTree {
    pub fn new() -> Self {
        Self {
            leaves: Vec::new(),
            leaf_ids: Vec::new(),
        }
    }

    /// Add a data item to the tree with patient ID (will be hashed)
    pub fn add_leaf_with_id(&mut self, data: &[u8], patient_id: String) {
        let mut hasher = Sha256::new();
        hasher.update(data);
        self.leaves.push(hasher.finalize().to_vec());
        self.leaf_ids.push(patient_id);
    }

    /// Add a data item to the tree (will be hashed)
    pub fn add_leaf(&mut self, data: &[u8]) {
        let mut hasher = Sha256::new();
        hasher.update(data);
        self.leaves.push(hasher.finalize().to_vec());
        self.leaf_ids.push(String::new()); // Empty ID for backwards compat
    }

    /// Add an already-hashed leaf
    pub fn add_hash(&mut self, hash: Vec<u8>) {
        self.leaves.push(hash);
    }

    /// Calculate the Merkle root
    pub fn root(&self) -> Option<Vec<u8>> {
        if self.leaves.is_empty() {
            return None;
        }

        let mut level = self.leaves.clone();

        while level.len() > 1 {
            let mut next_level = Vec::new();

            for chunk in level.chunks(2) {
                let mut hasher = Sha256::new();
                hasher.update(&chunk[0]);
                
                // If odd number, duplicate the last hash
                if chunk.len() == 2 {
                    hasher.update(&chunk[1]);
                } else {
                    hasher.update(&chunk[0]);
                }

                next_level.push(hasher.finalize().to_vec());
            }

            level = next_level;
        }

        Some(level[0].clone())
    }

    /// Get the number of leaves
    pub fn leaf_count(&self) -> usize {
        self.leaves.len()
    }

    /// Clear all leaves
    pub fn clear(&mut self) {
        self.leaves.clear();
        self.leaf_ids.clear();
    }
    
    /// Generate a Merkle proof for a specific leaf index
    pub fn generate_proof(&self, leaf_index: usize) -> Option<MerkleProof> {
        if leaf_index >= self.leaves.len() {
            return None;
        }

        let root = self.root()?;
        let mut proof_hashes = Vec::new();
        let mut level = self.leaves.clone();
        let mut index = leaf_index;

        // Build proof by collecting sibling hashes at each level
        while level.len() > 1 {
            let mut next_level = Vec::new();
            
            for (i, chunk) in level.chunks(2).enumerate() {
                if i * 2 == index || i * 2 + 1 == index {
                    // This chunk contains our target, save the sibling
                    if chunk.len() == 2 {
                        if index % 2 == 0 {
                            // We're the left node, save right sibling
                            proof_hashes.push(hash_to_hex(&chunk[1]));
                        } else {
                            // We're the right node, save left sibling
                            proof_hashes.push(hash_to_hex(&chunk[0]));
                        }
                    } else {
                        // Odd node, duplicated
                        proof_hashes.push(hash_to_hex(&chunk[0]));
                    }
                }

                // Compute next level hash
                let mut hasher = Sha256::new();
                hasher.update(&chunk[0]);
                if chunk.len() == 2 {
                    hasher.update(&chunk[1]);
                } else {
                    hasher.update(&chunk[0]);
                }
                next_level.push(hasher.finalize().to_vec());
            }

            level = next_level;
            index /= 2;
        }

        Some(MerkleProof {
            leaf_hash: hash_to_hex(&self.leaves[leaf_index]),
            leaf_index,
            proof_hashes,
            root_hash: hash_to_hex(&root),
            patient_id: self.leaf_ids.get(leaf_index).cloned().unwrap_or_default(),
        })
    }
    
    /// Get all leaves (for reconstruction)
    pub fn get_leaves(&self) -> &[Vec<u8>] {
        &self.leaves
    }
    
    /// Get leaf IDs
    pub fn get_leaf_ids(&self) -> &[String] {
        &self.leaf_ids
    }
}

/// Verify a Merkle proof
pub fn verify_proof(proof: &MerkleProof) -> bool {
    let mut current_hash = hex::decode(&proof.leaf_hash).unwrap();
    let mut index = proof.leaf_index;
    
    for sibling_hex in &proof.proof_hashes {
        let sibling = hex::decode(sibling_hex).unwrap();
        let mut hasher = Sha256::new();
        
        if index % 2 == 0 {
            // We're left, sibling is right
            hasher.update(&current_hash);
            hasher.update(&sibling);
        } else {
            // We're right, sibling is left
            hasher.update(&sibling);
            hasher.update(&current_hash);
        }
        
        current_hash = hasher.finalize().to_vec();
        index /= 2;
    }
    
    hash_to_hex(&current_hash) == proof.root_hash
}

/// Hash a single piece of data with SHA256
pub fn hash_data(data: &[u8]) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().to_vec()
}

/// Convert hash bytes to hex string
pub fn hash_to_hex(hash: &[u8]) -> String {
    hex::encode(hash)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_merkle_single_leaf() {
        let mut tree = MerkleTree::new();
        tree.add_leaf(b"hello");
        let root = tree.root().unwrap();
        assert!(!root.is_empty());
    }

    #[test]
    fn test_merkle_multiple_leaves() {
        let mut tree = MerkleTree::new();
        tree.add_leaf(b"data1");
        tree.add_leaf(b"data2");
        tree.add_leaf(b"data3");
        
        let root = tree.root().unwrap();
        assert_eq!(root.len(), 32); // SHA256 produces 32 bytes
        assert_eq!(tree.leaf_count(), 3);
    }

    #[test]
    fn test_merkle_deterministic() {
        let mut tree1 = MerkleTree::new();
        tree1.add_leaf(b"test");
        tree1.add_leaf(b"data");

        let mut tree2 = MerkleTree::new();
        tree2.add_leaf(b"test");
        tree2.add_leaf(b"data");

        assert_eq!(tree1.root(), tree2.root());
    }
}

