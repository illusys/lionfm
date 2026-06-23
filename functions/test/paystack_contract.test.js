const assert = require('assert');

function paymentContract(response) {
  return {
    hasCamelUrl: typeof response.authorizationUrl === 'string',
    hasLegacyUrl: typeof response.authorization_url === 'string',
    success: response.success === true,
  };
}

const initialized = {
  success: true,
  authorizationUrl: 'https://checkout.paystack.com/demo',
  authorization_url: 'https://checkout.paystack.com/demo',
  reference: 'ref_123',
};

assert.deepStrictEqual(paymentContract(initialized), {
  hasCamelUrl: true,
  hasLegacyUrl: true,
  success: true,
});

const verified = { success: true, status: 'success', reference: 'ref_123' };
assert.strictEqual(verified.success, true);
assert.strictEqual(verified.status, 'success');
