# Sync plans solution

To be able to test, after running npm install you need to run
npm install
npm i --save csvtojson
npm install jsforce

Then just creating a scratch org and pushing the code will have all set.
run node DataLoad.js to create records on the scratch org

If you want to create prices on you own test stripe account, replace on publisher.csv the BillingLiveAccessToken\_\_c

Run to execute the batch
Database.executeBatch(new SubscriptionPlansSyncBatch());
