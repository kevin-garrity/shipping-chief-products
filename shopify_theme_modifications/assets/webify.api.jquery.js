// (c) Copyright 2009 Jaded Pixel. Author: Caroline Schnapp. All Rights Reserved.

/*

IMPORTANT:

Ajax requests that update Shopify's cart must be queued and sent synchronously to the server.
Meaning: you must wait for your 1st ajax callback to send your 2nd request, and then wait
for its callback to send your 3rd request, etc.

*/

/**
* Modified by Mitchell Amihod
* We make some mods. consider them feedback :) See comments/commit messages
* Changes include:
* addItemFromForm: allow for passing in of form element, OR string selector
* updateCartFromForm: allow for passing in of form element, OR string selector
*
* To see how I make use of these changes, see [link to ajaxify-shop.js]
*
* Sept 02, 2010
*/
if ((typeof Webify) === 'undefined') {
  Webify = {};
}

/*

Override so that Webify.formatMoney returns pretty
money values instead of cents.

*/

Webify.money_format = 'webifyJQ {{amount}}';

Webify.formatMoney = function(cents, format) {
  var value = '';
  var patt = /\{\{\s*(\w+)\s*\}\}/;
  var formatString = (format || this.money_format);
  switch(formatString.match(patt)[1]) {
    case 'amount':
      value = floatToString(cents/100.0, 2).replace(/(\d+)(\d{3}[\.,]?)/,'$1 $2');
      break;
    case 'amount_no_decimals':
      value = floatToString(cents/100.0, 0).replace(/(\d+)(\d{3}[\.,]?)/,'$1 $2');
      break;
    case 'amount_with_comma_separator':
      value = floatToString(cents/100.0, 2).replace(/\./, ',').replace(/(\d+)(\d{3}[\.,]?)/,'$1.$2');
      break;
  }
  return formatString.replace(patt, value);
};

/* AJAX API OVERRIDES */

// ---------------------------------------------------------
// POST to cart/change.js returns the cart in JSON.
// ---------------------------------------------------------
Webify.removeItem = function(variant_id, callback) {
  var params = {
    type: 'POST',
    url: '/cart/change.js',
    data: 'quantity=0&id='+variant_id,
    dataType: 'json',
    success: function(cart) {
      if ((typeof callback) === 'function') {
        callback(cart);
      }
      else {
        Webify.onCartUpdate(cart);
      }
    },
    error: function(XMLHttpRequest, textStatus) {
      Webify.onError(XMLHttpRequest, textStatus);
    }
  };
  webifyJQ.ajax(params);
};

// -------------------------------------------------------------------------------------
// POST to cart/add.js returns the JSON of the line item associated with the added item.
// -------------------------------------------------------------------------------------
Webify.addItem = function(variant_id, quantity, line_item_properties, callback) {
  quantity = quantity || 1;

  var encoded_data = 'quantity=' + quantity + '&id=' + variant_id

  webifyJQ.each(line_item_properties, function(key, value) {
    property_key = encodeURIComponent('properties[' + key + ']')
    property_value = value
    encoded_data += '&' + property_key + '=' + property_value
  });

  var params = {
    type: 'POST',
    url: '/cart/add.js',
    data: encoded_data,
    dataType: 'json',
    success: function(line_item) {
      if ((typeof callback) === 'function') {
        callback(line_item);
      }
      else {
        Webify.onItemAdded(line_item);
      }
    },
    error: function(XMLHttpRequest, textStatus) {
      Webify.onError(XMLHttpRequest, textStatus);
    }
  };
  webifyJQ.ajax(params);
};

// ---------------------------------------------------------
// GET cart.js returns the cart in JSON.
// ---------------------------------------------------------
Webify.getCart = function(callback) {
  webifyJQ.getJSON('/cart.js', function (cart, textStatus) {
    if ((typeof callback) === 'function') {
      callback(cart);
    }
    else {
      Webify.onCartUpdate(cart);
    }
  });
};

