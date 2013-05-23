require 'rufus-decision'
require "rudelo/matchers/set_logic"
require 'webify/hash_expand'
require 'csv'

class ::Set
  def to_rudelo
    inspect.chomp.gsub('#<Set: {', '$(').gsub('}>', ')')
  end
end

module Carriers
  class RufusService < ::Carriers::Service
    attr_accessor :item_columns, :aggregate_columns, :service_name_column, :service_columns

    # def default_options
    # end

    def fetch_rates
      rates = nil
      withShopify do
        construct_item_columns!
        construct_aggregate_columns!
        process_decision_order!
        selected_services = transform_order_decisions
        rates = construct_rates(selected_services)
      end
      return rates
    end
 
    def process_decision_order!
      # override in subclasses
    end
    # def transform_decisions!
    #   decisions['item'].each do decision
    #     decision.transform! decision_items
    #   end
    #   decisions['order'].each do decision
    #     decision.transform! decision_order
    #   end
    # end

    def transform_order_decisions
      Rails.logger.info("transform_order_decisions:")
      ppl decision_order
      results = nil
      results = [decision_order]
      decisions['order'].each do |decision|
        new_results = []
        results.each do |intermediate_result|
          ppl decision
          transformed = decision.transform!(intermediate_result)
          Rails.logger.info("after transforming")
          ppl transformed
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
      ProductCache.instance.dirty!
      decision_items.each do |item|
        Rails.logger.info("looking up #{item.inspect}")
        ppl ProductCache.instance.variants
        variant = ProductCache.instance[item]
        Rails.logger.info("  got #{variant}")
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
      decision_order['total_quantity'] = total_item_quantity if total_item_quantity
      decision_order.merge!(product_types_quantities) if product_types_quantities
      decision_order['product_types_set'] = product_types_set.to_rudelo if aggregate_columns.include?(:product_types_set)
      decision_order['sku_set'] = sku_set.to_rudelo if aggregate_columns.include?(:sku_set)
    end


    def service_name(selected_service)
      selected_service[service_name_column]
    end

    def service_code(selected_service)
      selected_service[service_name_column]
    end

    def construct_rates(selected_services)
      rates = []
      selected_services.each do |selected_service|
        rate = {}
        rate['total_price'] = calculate_price(selected_service)
        rate['service_name'] = service_name(selected_service)
        rate['currency'] = selected_service['currency']
        rate['service_code'] = service_code(selected_service)
        rates << rate
      end
      rates
    end

    def calculate_price(row)
      base_price = row[base_price_column(row)].to_f
      fee_price_columns(row).
        inject(base_price){ |total, k| total + row[k].to_f }
    end

    # def rufusize_column_names!
    #   @decision_items.map!{ |item| Hash[ item.map{ |k,v| ["in:#{k}", v] } ] }
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

    def service_name_column
      @service_name_column ||= "Shipping Method"
    end

    def item_service_operation
      @item_service_operation ||= :plus
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

    def base_price_column(out)
      out = out.first if out.is_a?(Array)
      return "total_price" if out.has_key?("total_price")
      return "price" if out.has_key?("price")
      return out.keys.detect{|k| k.include?("price")}
    end

    def fee_price_columns(out)
       out = out.first if out.is_a?(Array)
       out.keys.select{|k| k =~ /fee$/i }
    end

    def decisions
      @decisions ||= begin
        decisions = {}
        ['order', 'item'].each do |decision_type|
          decisions[decision_type] =
            Dir["#{decision_table_dir}/#{decision_type}/*.csv"].map do |path|
              table = Rufus::Decision::Table.new(path)
              table.matchers.unshift(Rudelo::Matchers::SetLogic.new)
              table.matchers.first.force = Rails.env.development?
              table
            end
        end
        decisions
      end
      @decisions
    end
  end
end
