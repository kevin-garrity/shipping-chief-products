class HelpController < ApplicationController
  around_filter :shopify_session
  before_filter :check_payment

  def index
  end
  
end