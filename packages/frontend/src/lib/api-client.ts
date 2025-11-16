import axios, { AxiosInstance } from 'axios';

// API client with cookie support
const apiClient: AxiosInstance = axios.create({
  baseURL: '/api', // Proxied to backend via next.config.js
  withCredentials: true, // Important: Send cookies
  headers: {
    'Content-Type': 'application/json',
  },
});

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

export default apiClient;

