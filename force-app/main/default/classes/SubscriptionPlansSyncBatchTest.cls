@isTest
private class SubscriptionPlansSyncBatchTest {
  @isTest
  static void syncPlans_NoPlans() {
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();
  }

  @isTest
  static void syncPlans_OneTime() {
    RecordType rt = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'SelfCheckout'
      LIMIT 1
    ];
    Publisher__c pub = new Publisher__c(
      Name = 'Publisher 1',
      BillingLiveAccessToken__c = 'Stripe_test',
      CheckoutSignUpStatus__c = 'Live'
    );
    insert pub;
    Listing__c listing = new Listing__c(
      Name = 'Listing 1',
      Publisher__c = pub.Id
    );
    insert listing;
    SubscriptionPlan__c sp1 = new SubscriptionPlan__c(
      Name = 'Test',
      Charge__c = 1000,
      Active__c = true,
      Currency__c = 'USD',
      Frequency__c = 'One-Time',
      RecordTypeId = rt.Id,
      Listing__c = listing.Id
    );
    insert sp1;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();

    SubscriptionPlan__c sp = [
      SELECT Id, Name, ExternalId__c
      FROM SubscriptionPlan__c
      WHERE Id = :sp1.Id
    ];
    System.assertEquals(
      'price_1LUwmiHBeka1JxuI40lJAKXf',
      sp.ExternalId__c,
      'The Stripe Id is invalid'
    );
  }

  @isTest
  static void syncPlans_PlansAlreadySync() {
    RecordType rt = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'SelfCheckout'
      LIMIT 1
    ];
    Publisher__c pub = new Publisher__c(
      Name = 'Publisher 1',
      BillingLiveAccessToken__c = 'Stripe_test',
      CheckoutSignUpStatus__c = 'Live'
    );
    insert pub;
    Listing__c listing = new Listing__c(
      Name = 'Listing 1',
      Publisher__c = pub.Id
    );
    insert listing;
    SubscriptionPlan__c sp1 = new SubscriptionPlan__c(
      Name = 'Test',
      Charge__c = 1000,
      Active__c = true,
      Currency__c = 'USD',
      Frequency__c = 'One-Time',
      RecordTypeId = rt.Id,
      Listing__c = listing.Id,
      ExternalId__c = 'testId'
    );
    insert sp1;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();

    SubscriptionPlan__c sp = [
      SELECT Id, Name, ExternalId__c
      FROM SubscriptionPlan__c
      WHERE Id = :sp1.Id
    ];
    System.assertEquals(
      sp1.ExternalId__c,
      sp.ExternalId__c,
      'The Stripe Id is invalid'
    );
  }

  @isTest
  static void syncPlans_OneTimeAndRecurring() {
    RecordType rt = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'SelfCheckout'
      LIMIT 1
    ];
    Publisher__c pub = new Publisher__c(
      Name = 'Publisher 1',
      BillingLiveAccessToken__c = 'Stripe_test',
      CheckoutSignUpStatus__c = 'Live'
    );
    insert pub;
    Listing__c listing = new Listing__c(
      Name = 'Listing 1',
      Publisher__c = pub.Id
    );
    insert listing;

    List<SubscriptionPlan__c> plans = new List<SubscriptionPlan__c>();
    plans.add(
      new SubscriptionPlan__c(
        Name = 'Test1',
        Charge__c = 1000,
        Active__c = true,
        Currency__c = 'USD',
        Frequency__c = 'One-Time',
        RecordTypeId = rt.Id,
        Listing__c = listing.Id
      )
    );
    plans.add(
      new SubscriptionPlan__c(
        Name = 'Test2',
        Charge__c = 1000,
        Active__c = true,
        Currency__c = 'USD',
        Frequency__c = 'Recurring',
        RecordTypeId = rt.Id,
        ExternalId__c = 'testId',
        Listing__c = listing.Id
      )
    );
    insert plans;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();

    List<SubscriptionPlan__c> plans1 = [
      SELECT Id, Name, ExternalId__c
      FROM SubscriptionPlan__c
    ];
    System.assertEquals(
      'price_1LUwmiHBeka1JxuI40lJAKXf',
      plans1.get(0).ExternalId__c,
      'The Stripe Id is invalid'
    );
    System.assertEquals(
      'testId',
      plans1.get(1).ExternalId__c,
      'The Stripe Id is invalid'
    );
  }

  @isTest
  static void syncPlans_OneTimePublisherNone() {
    RecordType rt = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'SelfCheckout'
      LIMIT 1
    ];
    Publisher__c pub = new Publisher__c(
      Name = 'Publisher 1',
      BillingLiveAccessToken__c = 'Stripe_test',
      CheckoutSignUpStatus__c = 'None'
    );
    insert pub;
    Listing__c listing = new Listing__c(
      Name = 'Listing 1',
      Publisher__c = pub.Id
    );
    insert listing;
    SubscriptionPlan__c sp1 = new SubscriptionPlan__c(
      Name = 'Test',
      Charge__c = 1000,
      Active__c = true,
      Currency__c = 'USD',
      Frequency__c = 'One-Time',
      RecordTypeId = rt.Id,
      Listing__c = listing.Id
    );
    insert sp1;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();

    SubscriptionPlan__c sp = [
      SELECT Id, Name, ExternalId__c
      FROM SubscriptionPlan__c
      WHERE Id = :sp1.Id
    ];
    System.assertEquals(null, sp.ExternalId__c, 'The Stripe Id is invalid');
  }

  @isTest
  static void syncPlans_NoPublisherAccessToken() {
    RecordType rt = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'SelfCheckout'
      LIMIT 1
    ];
    Publisher__c pub = new Publisher__c(
      Name = 'Publisher 1',
      CheckoutSignUpStatus__c = 'Live'
    );
    insert pub;
    Listing__c listing = new Listing__c(
      Name = 'Listing 1',
      Publisher__c = pub.Id
    );
    insert listing;
    SubscriptionPlan__c sp1 = new SubscriptionPlan__c(
      Name = 'Test',
      Charge__c = 1000,
      Active__c = true,
      Currency__c = 'USD',
      Frequency__c = 'One-Time',
      RecordTypeId = rt.Id,
      Listing__c = listing.Id
    );
    insert sp1;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();

    SubscriptionPlan__c sp = [
      SELECT Id, Name, ExternalId__c
      FROM SubscriptionPlan__c
      WHERE Id = :sp1.Id
    ];
    System.assertEquals(null, sp.ExternalId__c, 'The Stripe Id is invalid');
  }

  @isTest
  static void syncPlans_NoListingRelated() {
    RecordType rt = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'SelfCheckout'
      LIMIT 1
    ];
    Publisher__c pub = new Publisher__c(
      Name = 'Publisher 1',
      CheckoutSignUpStatus__c = 'Live'
    );
    insert pub;
    Listing__c listing = new Listing__c(
      Name = 'Listing 1',
      Publisher__c = pub.Id
    );
    insert listing;
    SubscriptionPlan__c sp1 = new SubscriptionPlan__c(
      Name = 'Test',
      Charge__c = 1000,
      Active__c = true,
      Currency__c = 'USD',
      Frequency__c = 'One-Time',
      RecordTypeId = rt.Id
    );
    insert sp1;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SyncBatchMock());
    Database.executeBatch(new SubscriptionPlansSyncBatch());
    Test.stopTest();

    SubscriptionPlan__c sp = [
      SELECT Id, Name, ExternalId__c
      FROM SubscriptionPlan__c
      WHERE Id = :sp1.Id
    ];
    System.assertEquals(null, sp.ExternalId__c, 'The Stripe Id is invalid');
  }
}
