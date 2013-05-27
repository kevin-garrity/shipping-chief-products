# Rufus Decision
* debugging decision tables
  1. run a single product through all tables
    * generate RuleTest scaffold
    * just implement RuleTest#new for now
    * for now, just a textfield for variant_id, qty, country, province, zip
    * generate shopify order hash
    * run through service fetch_rates
    * display the results
  2. show intermediate results
    * after each run of a hash through a decision
    * show in tree form
      * item
        * item1
          * decision1
            * result1
              * decision2
            * result2
              * decision2
      * order
  3. Persist tests
    * save whole order hash
    * expected result editor
    * save whole expected result hash

# Lifemap
## Deploy

* finish writing some acceptance tests
  * shared example correct rates for
  * get product cache stub from lifemap
    * create credentials
    * load in shest
    * delete credentials
* setup heroku app
* push
* test
