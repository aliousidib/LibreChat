export const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? '/api'  // Will be proxied through nginx
  : 'http://localhost:3080/api'; 