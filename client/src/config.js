// API Configuration
const getApiUrl = () => {
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  // Automatically connect to the deployed Render backend when hosted on Render
  if (typeof window !== 'undefined' && window.location.hostname.includes('onrender.com')) {
    return 'https://intellistock-api.onrender.com/api';
  }
  return '/api';
};

export const API_URL = getApiUrl();

// Other configs
export const APP_NAME = 'IntelliStock';
