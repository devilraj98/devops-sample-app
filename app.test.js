const request = require('supertest');
const app = require('./app');

describe('DevOps Sample App', () => {
  test('GET / should return app info', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body.message).toBe('DevOps Sample Application');
    expect(response.body.version).toBe('1.0.1');
  });

  test('GET /health should return health status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
    expect(response.body).toHaveProperty('uptime');
  });

  afterAll(() => {
    // Close any open handles
    setTimeout(() => process.exit(), 1000);
  });
});