require 'rufus-decision'
require "rudelo/matchers/set_logic"
require 'webify/hash_expand'
module Carriers
  class RufusService < ::Carriers::Service
    attr_accessor :item_columns, :aggregate_columns, :service_names, :service_name_column, :service_columns

    # def default_options
    # end

    def fetch_rates
      services = nil
      withShopify do
        construct_item_columns!
        construct_aggregate_columns!
        # add_service_names!
        transform_decisions!
        services = construct_services!
      end
      return services
    end
 
    def transform_decisions!
      decisions['item'].each do decision
        decision.transform! decision_items
      end
      decisions['order'].each do decision
        decision.transform! decision_order
      end
    end

    def transform_order_decisions
      results = nil
      results = [decision_order]
      decisions['order'].each do |decision|
        new_results = []
        results.each do |intermediate_result|
          transformed = decision.transform!(intermediate_result)
          new_results += transformed.expand
        end
        results = new_results
      end
      results
    end

    def decision_table_root
      Rails.root.join( 'rufus' )
    end

    def decision_table_dir
      decision_table_root.join( *self.class.name.underscore.split('/')[0...-1])
    end

    def construct_item_columns!
      decision_items.each do |item|
        variant = ProductCache.instance[item]
        item_columns.each do |item_column|
          entity, key = item_column.split('.')
          item_column = [entity, key.gsub(entity,'')].join('_')
          case entity
          when 'product'
            if(m = key.match(/^option(\d+)_name$/))
              item_key = key
              option = variant.product.options[m[1].to_i]
              item[key] = option.nil? ? nil : option.name
            else
              item_key = variant.attributes.keys.include?(key) ? item_column : key
              item[item_key] = variant.product.attributes[key]
            end
          when 'variant'
            item_key = variant.product.attributes.keys.include?(key) ? item_column : key
            item[item_key] = variant.attributes[key]
          end
        end
      end
    end

    def construct_aggregate_columns!
      product_types_set = Set.new
      sku_set = Set.new
      product_types_quantities = nil
      total_item_quantity = nil
      decision_items.each do |item|
        aggregate_columns.each do |aggregate|
          case aggregate
          when :product_types_quantities
            product_types_quantities ||= {}
            column_name = "#{item['product_type']} quantity"
            product_types_quantities[column_name] ||= 0
            product_types_quantities[column_name] += item['quantity']
          when :product_types_set
            product_types_set << item['product_type']
            item['product_types_set'] = product_types_set
          when :total_item_quantity
            total_item_quantity ||= 0
            total_item_quantity += item['quantity']
          when :sku_set
            sku_set << item['sku']
            item['sku_set'] = sku_set
          end
        end
      end
      decision_items.each do |item| 
        item.merge!(product_types_quantities) if product_types_quantities
        item['total_item_quantity'] = total_item_quantity if total_item_quantity
      end
      decision_order.merge!(product_types_quantities) if product_types_quantities
      decision_order['product_types_set'] = product_types_set if aggregate_columns.include?(:product_types_set)
      decision_order['sku_set'] = sku_set if aggregate_columns.include?(:sku_set)
    end

    # def collect_service_names
    #   service_names = Set.new(decision_order[service_name_column])
    #   service_names += decision_items.collect{|item| item[service_name_column]}
    #   service_names.flatten
    # end

    def construct_services!
      services = []
      # the decision table will accumulate services 
      # (if option accumulate is on)
      service_names = [decision_order[service_name_column]].flatten
      service_names.each_with_index do |name, ix|
        service = {}
        service_column_map.each do |d_col, s_col|
          service[s_col] = [decision_order[d_col]].flatten[ix]
        end

        price_columns.each do |price_column, op|

        end



        # NOTE:
        #  I think I have to change this so that after running decision
        # tables that have accumulate, I expand the result into an 
        # array of hashes. Because otherwise how will my zone -> price
        # decision table work?
        prices = [service['total_price']]
        # the item decision tables can either override or add
        # to or subtract from the price of a service
        decision_item.each do |item|
          # if the item decision table has commented on an item,
          # it will be in the array of values for "Shipping Method"
          if item.has_key?(service_name_column)
            ix = item[service_name_column].index(name)
            if ix

            end
          end
        end
        services << service
      end
      services
    end

    def calculate_price(row)

    end

    # def rufusize_column_names!
    #   @decision_items.map!{ |item| Hash[ item.map{ |k,v| ["in:#{k}", v] } ] }
    # end

    # def add_service_names!
    #   decision_items.each{|item| item.merge!()}
    # end

    # TODO: add option1_names_set, and also columns for each option name, with subtotal quantities
    def aggregate_columns
      @aggregate_columns ||= [
        :product_types_quantities,
        :total_item_quantity,
        :product_types_set,
        :sku_set
      ]
    end

    def item_columns
      @item_columns ||= [
        'product.product_type',
        'product.option1_name',
        'product.option2_name',
        'product.option3_name',
        'variant.option1',
        'variant.option2',
        'variant.option3'
      ]
    end

    def services
      @services ||= [
        {'STD' => 'Standard'}
      ]
    end

    def service_name_column
      @service_name_column ||= "Shipping Method"
    end

    def item_service_operation
      @item_service_operation ||= :plus
    end

    def service_column_map
      {
        "Shipping Method" => 'service_name',
        # "Service Price" => "total_price",
        "Currency" => "currency",
        "Min Delivery Date" => "min_delivery_date",
        "Max Delivery Date" => "max_delivery_date"
      }
    end

    def service_price_column
      service_column_map.invert['total_price']
    end

    def price_columns
      {
        "Service Price" => :max,
        "Handling" => :add
      }
    end

    # def column_converters
    #   {
    #     "Min Delivery Date" => lambda{|value| Time.now }
    #   }
    # end

    def decision_items 
      @decision_items ||= items.map{ |i| i.to_hash.stringify_keys }
    end

    def decision_order
      @decision_order ||= begin
        order = params[:destination].to_hash.stringify_keys
        order['currency'] = params[:currency]
        order['num_items'] = items.length
        order
      end
    end

    def decisions
      @decisions ||= begin
        decisions = {}
        ['order', 'item'].each do |decision_type|
          decisions[decision_type] =
            Dir["#{decision_table_dir}/#{decision_type}/*.csv"].map do |path|
              table = Rufus::Decision::Table.new(path)
              table.matchers.unshift(Rudelo::Matchers::SetLogic.new)
              table
            end
        end
        decisions
      end
      @decisions
    end
  end
end
