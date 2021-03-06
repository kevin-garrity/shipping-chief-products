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

- [x] finish writing some acceptance tests
  - [x]  shared example correct rates for
  - [x]  get product cache stub from lifemap
    - [x]  create credentials
    - [x]  load in shest
    - [ ]  delete credentials
- [x]  setup heroku app
- [x]  push
- [ ]  test


# add metafield support
- [ ] automatically add variant & product metafields with namespace "wby.*" to item hash
  - [ ] name the keys "wby.ship.lifemap:key"
- [ ] convert lifemap product cache stub
  


# Combo Order
- add item_price (quantity * price)


add to rufus decision:
class EmptyValue < Numeric
  def to_s; ''; end
  def to_str; ''; end
  def to_i; 0; end
  def to_int; 0; end
  def to_f; 0.0; end

  def +(other)
   case other
   when String
     to_s + other
   when Fixnum
     to_i + other
   when Float
     to_f + other
   end
  end
end
