import { useContext } from 'react';
import { ApiContext } from './apiContext';

// Custom hook to use the API client
export function useApi() {
  const context = useContext(ApiContext);

  if (!context) {
    throw new Error('useApi must be used within an ApiProvider');
  }

  return context;
}

// Convenience hook that provides the raw client
export function useApiClient() {
  return useApi().apiClient;
}

// Convenience hook for accessing auth-related states
export function useApiAuth() {
  const { isAuthReady, isAuthenticated, authError } = useApi();
  return { isAuthReady, isAuthenticated, authError };
}