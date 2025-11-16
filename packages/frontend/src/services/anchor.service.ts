import apiClient from '@/lib/api-client';

export interface AnchoredBatch {
  batch_id: number;
  root_hash_hex: string;
  algo_id: string;
  record_count: number;
  timestamp: number;
  meta_uri: string;
}

export interface AnchorBatchResponse {
  success: boolean;
  batch?: AnchoredBatch;
  tx_hash?: string;
  message: string;
}

export interface PendingCountResponse {
  pending_count: number;
}

export const anchorService = {
  /**
   * Create Merkle batch from pending records
   */
  async createBatch(): Promise<AnchorBatchResponse> {
    const response = await apiClient.post<AnchorBatchResponse>('/anchor/batch', {});
    return response.data;
  },

  /**
   * Get count of pending records
   */
  async getPendingCount(): Promise<number> {
    const response = await apiClient.get<PendingCountResponse>('/anchor/pending');
    return response.data.pending_count;
  },
};

