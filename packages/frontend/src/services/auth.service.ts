import apiClient from '@/lib/api-client';

export interface ChallengeResponse {
  nonce: string;
  expires_at: number;
}

export interface LoginRequest {
  did: string;
  nonce: string;
  signature: string;
}

export interface LoginResponse {
  success: boolean;
  user_id: number;
  did: string;
  message: string;
}

export const authService = {
  /**
   * Request authentication challenge nonce
   */
  async requestChallenge(did: string): Promise<ChallengeResponse> {
    const response = await apiClient.post<ChallengeResponse>('/auth/challenge', { did });
    return response.data;
  },

  /**
   * Login with signed challenge
   * Cookie is automatically set by backend
   */
  async login(loginData: LoginRequest): Promise<LoginResponse> {
    const response = await apiClient.post<LoginResponse>('/login', loginData);
    return response.data;
  },

  /**
   * Check health endpoint (no auth required)
   */
  async checkHealth(): Promise<{ status: string }> {
    const response = await apiClient.get('/health', {
      baseURL: '', // Root path, not /api
    });
    return response.data;
  },

  /**
   * Get API info (no auth required)
   */
  async getApiInfo(): Promise<any> {
    const response = await apiClient.get('/info');
    return response.data;
  },
};

