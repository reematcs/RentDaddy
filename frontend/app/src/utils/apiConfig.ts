/**
 * Utility functions for API configuration and URL handling
 */

// Get environment variables with fallbacks
const DOMAIN_URL = import.meta.env.VITE_DOMAIN_URL || 'localhost';
const PORT = import.meta.env.VITE_PORT || '8080';
const ENV = import.meta.env.ENV || 'development';

/**
 * Constructs the API base URL based on environment
 * - In production: Uses domain without appending port
 * - In development: Uses domain with port
 * 
 * @returns The base API URL for the current environment
 */
export const getApiBaseUrl = (): string => {
  // Check if we're in production environment
  const isProduction = ENV === 'production';
  
  // Check if domain already includes protocol
  const hasProtocol = DOMAIN_URL.startsWith('http://') || DOMAIN_URL.startsWith('https://');
  
  // For production environment
  if (isProduction) {
    if (hasProtocol) {
      return DOMAIN_URL.replace(/\/$/, ''); // Remove trailing slash if present
    }
    return `https://${DOMAIN_URL}`.replace(/\/$/, '');
  }
  
  // For development environment
  if (hasProtocol) {
    return DOMAIN_URL.replace(/\/$/, '');
  }
  
  // Local development with port
  return `http://${DOMAIN_URL}:${PORT}`.replace(/\/$/, '');
};

/**
 * The base API URL for the application
 */
export const API_URL = getApiBaseUrl();

/**
 * Constructs a full API endpoint URL
 * 
 * @param path - The API endpoint path (with or without leading slash)
 * @returns The complete API URL
 */
export const getApiUrl = (path: string): string => {
  // Ensure path starts with a slash
  const formattedPath = path.startsWith('/') ? path : `/${path}`;
  return `${API_URL}${formattedPath}`;
};