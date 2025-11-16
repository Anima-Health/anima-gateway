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
}

impl MerkleTree {
    pub fn new() -> Self {
        Self {
            leaves: Vec::new(),
        }
    }

    /// Add a data item to the tree (will be hashed)
    pub fn add_leaf(&mut self, data: &[u8]) {
        let mut hasher = Sha256::new();
        hasher.update(data);
        self.leaves.push(hasher.finalize().to_vec());
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
    }
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

