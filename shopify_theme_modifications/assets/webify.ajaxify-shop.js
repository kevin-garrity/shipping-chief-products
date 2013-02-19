/**
* Shopify Ajaxify Shop.
*
* @uses Modified Shopify jQuery API (link to it)
*
*/

// //console.log("start")

webifyJQ(document).ready(function() {
  //Begin Wrapper

  var jQ = webifyJQ;

  /**
  * Collection of Selectors for various pieces on the page we need to update
  *
  * I've tried to keep these as general and flexible as possible, but
  * if you are doing your own markup, you may find you need to change some of these.
  *
  */
  var selectors = {
    // Any elements(s) with this selector will have the total item count put there on add to cart.
    TOTAL_ITEMS: '.cart-total-items, .num-items-in-cart',
    TOTAL_PRICE: '.cart-total-price',

    SUBMIT_ADD_TO_CART: 'input[type=image], input.submit-add-to-cart',

    FORM_ADD_TO_CART: 'form[action*=/cart/add]',

    FORM_UPDATE_CART: 'form[name=cartform]',

    //The actual Update Button
    FORM_UPDATE_CART_BUTTON: 'form[name=cartform] input[name=update]',
    //All the buttons on the form
    FORM_UPDATE_CART_BUTTONS: 'input[type=image], input.button-update-cart',

    LINE_ITEM_ROW: '.cart-line-item',
    LINE_ITEM_QUANTITY_PREFIX: 'input#updates_',
    LINE_ITEM_PRICE_PREFIX: '.cart-line-item-price-',

    LINE_ITEM_REMOVE: '.remove a',
    LINE_ITEM_CHANGE_QUANTITY: '.change-quantity a',

    EMPTY_CART_MESSAGE: '#empty'
  };


  /**
  * Collection of text strings. This is where you would change for a diff language, for example.
  *
  */
  var text = {
    ITEM: 'Item',
    ITEMS: 'Items'
  };

  //Convenience method to format money.
  //Can just transform the amount here if needed
  var formatMoney = function(price) {
    return Webify.formatMoney(price , '${{ amount }}');
};


//Attach Submit Handler to all forms with the /cart/add action.
jQ('form[action*=\\/cart\\/add]').submit(function(e) {
  //console.log("in FORM_ADD_TO_CART")
  e.preventDefault();
  //Disable the Add To Cart button, add a disabled class.
  jQ(e.target).find(selectors.SUBMIT_ADD_TO_CART).attr('disabled', true).addClass('disabled');

  //Can't use updateCartFromForm since you need the item added before you can update (otherwise, would have been more convenient)
  //So, in onItemAdded, we Webify.getCart() to force the repaint of items in cart.
  Webify.addItemFromForm(e.target);
  //console.log("out FORM_ADD_TO_CART")
});


//We only want to interrupt the UPDATE, not the CHECKOUT process
jQ(selectors.FORM_UPDATE_CART_BUTTON).click(function(e) {
  //console.log("in FORM_UPDATE_CART_BUTTON")
  e.preventDefault();
  jQ(e.target.form).find(selectors.FORM_UPDATE_CART_BUTTONS).attr('disabled', true).addClass('disabled');
  Webify.updateCartFromForm(e.target.form);
  //console.log("out FORM_UPDATE_CART_BUTTON")
});

//Delegate the Remove Link functionality on the cart page.
jQ(selectors.FORM_UPDATE_CART).delegate(selectors.LINE_ITEM_REMOVE, 'click', function(e) {
  //console.log("in LINE_ITEM_REMOVE")
  e.preventDefault();
  //Get the variant ID from the URL
  var vid = this.href.split('/').pop().split('?').shift();
  Webify.removeItem(vid);
  jQ(this).parents(selectors.LINE_ITEM_ROW).remove();
  //console.log("out LINE_ITEM_REMOVE")
});

jQ(selectors.FORM_UPDATE_CART).delegate(selectors.LINE_ITEM_CHANGE_QUANTITY, 'click', function(e) {
  //console.log("in LINE_ITEM_CHANGE_QUANTITY")
  e.preventDefault();
  //Get the variant ID from the URL
  var vid = jQ(selectors.FORM_UPDATE_CART + " > input[name=shipping_variant_id]").attr("value");
  var quantity = jQ(selectors.FORM_UPDATE_CART + " > input[name=quantity]").attr("value");
  Webify.changeItem(vid, quantity);
  jQ(this).parents(selectors.LINE_ITEM_ROW).remove();
  //console.log("out LINE_ITEM_CHANGE_QUANTITY")
});

/**
* Webify.onItemAdded
*
* Triggered by the response when something is added to the cart via the add to cart button.
* This is where you would want to put any flash messaging, for example.
*
* @param object line_item
* @param HTMLelement/String Form HTMLElement, or selector
*/
Webify.onItemAdded = function(line_item) {
  //console.log("in onItemAdded")
  //Default behaviour for this modification:
  //You can add any extra messaging you would want here.

  //Get the state of the cart, which will trigger onCartUpdate
  Webify.getCart();
  //console.log("out onItemAdded")
};

/**
* This updates the N item/items left in your cart
*
* It's setup to match the HTML used to display the Cart Count on Load. If you change that (in your theme.liquid)
* you will probably want to change the message html here.
* This will update the HTML in ANY element with the class defined in selectors.TOTAL_ITEMS
*
* @param object the cart object.
* @param HTMLElement form. If included, we know its an Update of the CART FORM, which will trigger additional behaviour.
*/
Webify.onCartUpdate = function(cart, form) {
  //console.log("in onCartUpdate")

  // Total Items Update
  // we only want to count items that are not shipping items
  var index;
  var non_shipping_items_count = 0;
  for (index = 0; index < cart.items.length; index++) {
    if (cart.items[index].title != 'Shipping') {
      non_shipping_items_count += 1;
    }
  }

  var message = '<span class="count">'+ non_shipping_items_count +'</span> ' +
    ((non_shipping_items_count == 1) ? text.ITEM : text.ITEMS );
  jQ(selectors.TOTAL_ITEMS).html(message);

  // Price update - any element matching the selector will have their contents updated with the cart price.
  var price = formatMoney(cart.total_price);
  jQ(selectors.TOTAL_PRICE).html(price);

  //If the EMPTY_CART_MESSAGE element exiss, we should show it, and hide the form.
  if( (jQ(selectors.EMPTY_CART_MESSAGE).length > 0) && cart.item_count == 0) {
    jQ(selectors.FORM_UPDATE_CART).hide();
    jQ(selectors.EMPTY_CART_MESSAGE).show();
  }

  // A form was passed in?
  form = form || false;
  //so it's the cart page form update, trigger behaviours for that page
//  if(form) {
    //Nothing left in cart, we reveal the Nothing in cart content, hide the form.
    if(cart.item_count > 0) {
      //Loops through cart items, update the prices.
      jQ.each(cart.items, function(index, cartItem) {
        jQ(selectors.LINE_ITEM_PRICE_PREFIX + cartItem.id).html(formatMoney(cartItem.line_price));
        jQ(selectors.LINE_ITEM_QUANTITY_PREFIX + cartItem.id).val(cartItem.quantity);
      });

      //And remove any line items with 0
      jQ(form).find('input[value=0]').parents(selectors.LINE_ITEM_ROW).remove();

      //Since we are on the cart page, reenable the buttons we disabled
      jQ(form).find(selectors.FORM_UPDATE_CART_BUTTONS).attr('disabled', false).removeClass('disabled');

    }
    //You can add any extra messaging you would want here.
    //successMessage('Cart Updated.');
 // }
  //console.log("out onCartUpdate")
};


//What to display when there is an error. You tell me?! I've left in a commented out example.
// You can tie this in to any sort of flash messages, or lightbox, or whatnot you want.
Webify.onError = function(XMLHttpRequest, textStatus) {
  //console.log("in onError")
  // Shopify returns a description of the error in XMLHttpRequest.responseText.
  // It is JSON.
  // Example: {"description":"The product 'Amelia - Small' is already sold out.","status":500,"message":"Cart Error"}
  // var data = eval('(' + XMLHttpRequest.responseText + ')');
  // //console.log(data.message + '(' + data.status + '): ' + data.description);
  //console.log("out onError")
};

//End Wrapper
});
