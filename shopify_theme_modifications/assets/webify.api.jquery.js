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

Webify.resizeImage = function(image, size) {
  try {
    if(size == 'original') { return image; }
    else {
      var matches = image.match(/(.*\/[\w\-\_\.]+)\.(\w{2,4})/);
      return matches[1] + '_' + size + '.' + matches[2];
    }
  } catch (e) { return image; }
};

/* Ajax API */

// -------------------------------------------------------------------------------------
// POST to cart/add.js returns the JSON of the line item associated with the added item.
// -------------------------------------------------------------------------------------
Webify.addItem = function(variant_id, quantity, callback) {
  quantity = quantity || 1;
  var params = {
    type: 'POST',
    url: '/cart/add.js',
    data: 'quantity=' + quantity + '&id=' + variant_id,
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
// POST to cart/add.js returns the JSON of the line item.
// ---------------------------------------------------------
//Allow use of form element instead of id.
//This makes it a bit more flexible. Every form doesn't need an id.
//Once you are having someone pass in an id, might as well make it selector based, or pass in the element itself.
//Since you are just wrapping it in a jq(). The same rationale is behind the change for updateCartFromForm
//@param HTMLElement the form element which was submitted. Or you could pass in a string selector such as the form id.
//@param function callback callback fuction if you like, but I just override Webify.onItemAdded() instead
Webify.addItemFromForm = function(form, callback) {
  var params = {
    type: 'POST',
    url: '/cart/add.js',
    data: webifyJQ(form).serialize(),
    dataType: 'json',
    success: function(line_item) {
      if ((typeof callback) === 'function') {
        callback(line_item, form);
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
  console.log("getCart")
  webifyJQ.getJSON('/cart.js', function (cart, textStatus) {
    if ((typeof callback) === 'function') {
      callback(cart);
    }
    else {
      Webify.onCartUpdate(cart);
    }
  });
};

// ---------------------------------------------------------
// GET products/<product-handle>.js returns the product in JSON.
// ---------------------------------------------------------
Webify.getProduct = function(handle, callback) {
  webifyJQ.getJSON('/products/' + handle + '.js', function (product, textStatus) {
    if ((typeof callback) === 'function') {
      callback(product);
    }
    else {
      Webify.onProduct(product);
    }
  });
};

// ---------------------------------------------------------
// POST to cart/change.js returns the cart in JSON.
// ---------------------------------------------------------
Webify.changeItem = function(variant_id, quantity, callback) {
  console.log("changeItem")
  var params = {
    type: 'POST',
    url: '/cart/change.js',
    data: 'quantity='+quantity+'&id='+variant_id,
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

// ---------------------------------------------------------
// POST to cart/clear.js returns the cart in JSON.
// It removes all the items in the cart, but does
// not clear the cart attributes nor the cart note.
// ---------------------------------------------------------
Webify.clear = function(callback) {
  console.log("clear")

  var params = {
    type: 'POST',
    url: '/cart/clear.js',
    data: '',
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

// ---------------------------------------------------------
// POST to cart/update.js returns the cart in JSON.
// ---------------------------------------------------------
//Allow use of form element instead of id.
//This makes it a bit more flexible. Every form doesn't need an id.
//Once you are having someone pass in an id, might as well make it selector based, or pass in the element itself,
//since you are just wrapping it in a jq().
//@param HTMLElement the form element which was submitted. Or you could pass in a string selector such as the #form_id.
//@param function callback callback fuction if you like, but I just override Webify.onCartUpdate() instead
Webify.updateCartFromForm = function(form, callback) {
  console.log("updateCartFromForm")
  var params = {
    type: 'POST',
    url: '/cart/update.js',
    data: webifyJQ(form).serialize(),
    dataType: 'json',
    success: function(cart) {
      if ((typeof callback) === 'function') {
        callback(cart, form);
      }
      else {
        Webify.onCartUpdate(cart, form);
      }
    },
    error: function(XMLHttpRequest, textStatus) {
      Webify.onError(XMLHttpRequest, textStatus);
    }
  };
  webifyJQ.ajax(params);
};

// ---------------------------------------------------------
// POST to cart/update.js returns the cart in JSON.
// To clear a particular attribute, set its value to an empty string.
// Receives attributes as a hash or array. Look at comments below.
// ---------------------------------------------------------
Webify.updateCartAttributes = function(attributes, callback) {
  console.log("updateCartAttributes")
  var data = '';
  // If attributes is an array of the form:
  // [ { key: 'my key', value: 'my value' }, ... ]
  if (webifyJQ.isArray(attributes)) {
    webifyJQ.each(attributes, function(indexInArray, valueOfElement) {
      var key = attributeToString(valueOfElement.key);
      if (key !== '') {
        data += 'attributes[' + key + ']=' + attributeToString(valueOfElement.value) + '&';
      }
    });
  }
  // If attributes is a hash of the form:
  // { 'my key' : 'my value', ... }
  else if ((typeof attributes === 'object') && attributes !== null) {
    webifyJQ.each(attributes, function(key, value) {
      data += 'attributes[' + attributeToString(key) + ']=' + attributeToString(value) + '&';
    });
  }
  var params = {
    type: 'POST',
    url: '/cart/update.js',
    data: data,
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

// ---------------------------------------------------------
// POST to cart/update.js returns the cart in JSON.
// ---------------------------------------------------------
Webify.updateCartNote = function(note, callback) {
  console.log("updateCartNote")
  var params = {
    type: 'POST',
    url: '/cart/update.js',
    data: 'note=' + attributeToString(note),
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

/* Used by Tools */

function floatToString(numeric, decimals) {
  var amount = numeric.toFixed(decimals).toString();
  if(amount.match(/^\.\d+/)) {return "0"+amount; }
  else { return amount; }
}

/* Used by API */

function attributeToString(attribute) {
  if ((typeof attribute) !== 'string') {
    // Converts to a string.
    attribute += '';
    if (attribute === 'undefined') {
      attribute = '';
    }
  }
  // Removing leading and trailing whitespace.
  return webifyJQ.trim(attribute);
}
