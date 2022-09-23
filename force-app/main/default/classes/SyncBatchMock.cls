@isTest
global class SyncBatchMock implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(
      '{"id":"price_1LUwmiHBeka1JxuI40lJAKXf","object":"price","active":true,"billing_scheme":"per_unit","created":1660068248,"currency":"usd","custom_unit_amount":null,"livemode":false,"lookup_key":null,"metadata":{},"nickname":null,"product":"prod_M6dNqQ1tFvzJzO","tax_behavior":"unspecified","tiers_mode":null,"transform_quantity":null,"type":"one-time","unit_amount":3300,"unit_amount_decimal":"3300"}'
    );
    res.setStatusCode(200);
    return res;
  }
}
