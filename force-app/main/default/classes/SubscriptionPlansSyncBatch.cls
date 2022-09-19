/*
 * Batch to sync One-Time plans into Stripe
 * Since Stripe start using One-Time plans, and the new Checkout will use APIs that will implement this ones, we need to have legacy
 * Subscription Plans sync into Stripe so it wont brake
 * Once all Plans are migrated and old Publishing Console is no longed available, this batch wont be used any more
 */
public with sharing class SubscriptionPlansSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
  public void execute(SchedulableContext sc) {
    SubscriptionPlansSyncBatch b = new SubscriptionPlansSyncBatch();
    Database.executeBatch(b);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    // collect the batches of records or objects to be passed to execute
    // Limit to 100 because of callout limits
    String query = 'SELECT Id, Name, ExternalId__c, Charge__c, Currency__c, Listing__r.Name, Listing__r.Publisher__r.BillingLiveAccessToken__c FROM SubscriptionPlan__c WHERE ExternalId__c = null AND Active__c = true AND Frequency__c = \'One-Time\' AND RecordType.DeveloperName = \'SelfCheckout\' AND Listing__r.Publisher__r.BillingLiveAccessToken__c != null AND Listing__r.Publisher__r.CheckoutSignUpStatus__c = \'Live\' LIMIT 100';
    return Database.getQueryLocator(query);
  }

  public void execute(
    Database.BatchableContext bc,
    List<SubscriptionPlan__c> records
  ) {
    List<SubscriptionPlan__c> toUpdate = new List<SubscriptionPlan__c>();
    // process each batch of records
    for (SubscriptionPlan__c sp : records) {
      // Make callout to stripe with each Subscription Plan
      Map<String, String> params = new Map<String, String>();
      params.put(
        'unit_amount',
        String.valueOf(Integer.valueOf(sp.Charge__c * 100))
      );
      params.put('currency', sp.Currency__c.toLowerCase());
      params.put('product_data[name]', sp.Listing__r.Name);

      // Set Body
      Map<String, Object> resp = SubscriptionPlansSyncBatch.makeCallout(
        getURLStringFromMap(params),
        sp.Listing__r.Publisher__r.BillingLiveAccessToken__c
      );
      String priceId = String.valueOf(resp.get('id'));
      if (priceId != null) {
        sp.ExternalId__c = priceId;
        toUpdate.add(sp);
      }
    }
    if (!toUpdate.isEmpty()) {
      update toUpdate;
    }
  }

  public static String getURLStringFromMap(Map<String, String> stringMap) {
    String ret = '', separator;
    Boolean flagSeparator = false;
    for (String s : stringMap.keySet()) {
      if (!String.isEmpty((String) stringMap.get(s))) {
        separator = flagSeparator ? '&' : '';
        ret +=
          separator +
          s +
          '=' +
          EncodingUtil.urlEncode((String) stringMap.get(s), 'UTF-8');
        flagSeparator = true;
      }
    }
    return ret;
  }

  private static Map<String, Object> makeCallout(
    String body,
    String APIAccessKey
  ) {
    String url;
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    String uri = 'https://api.stripe.com/v1/prices';
    req.setHeader(
      'Authorization',
      'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(APIAccessKey + ':'))
    );
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setEndpoint(uri);
    req.setMethod('POST');
    req.setBody(body);

    try {
      HttpResponse response = h.send(req);
      String responseBody;
      if (!String.isEmpty(response.getBody())) {
        responseBody = response.getBody();
      }

      return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    } catch (System.Exception e) {
      system.debug(e.getMessage());
    }

    return null;
  }

  public void finish(Database.BatchableContext bc) {
    // execute any post-processing operations
  }
}
