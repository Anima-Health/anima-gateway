import apiClient from '@/lib/api-client';

export interface MerkleProof {
  leaf_hash: string;
  leaf_index: number;
  proof_hashes: string[];
  root_hash: string;
  patient_id: string;
}

export interface VerificationResponse {
  success: boolean;
  patient_id?: string;
  proof?: MerkleProof;
  verified?: boolean;
  message: string;
}

export const verifyService = {
  /**
   * Verify a patient record using Merkle proof
   */
  async verifyPatient(patientId: string): Promise<VerificationResponse> {
    const response = await apiClient.get<VerificationResponse>(`/anchor/verify/${patientId}`);
    return response.data;
  },
};

