require 'rufus-decision'
require "rudelo/matchers/set_logic"
require 'webify/hash_expand'
require 'csv'

class ::Set
  def to_rudelo
    inspect.chomp.gsub('#<Set: {', '$(').gsub('}>', ')')
  end

  def self.from_rudelo(str)
    @value_parser ||= Rudelo::Parsers::SetValueParser.new
    @value_transform ||= Rudelo::Parsers::SetLogicTransform.new
    @value_transform.apply(@value_parser.parse(str))
  end

  def self.empty
    Set.new
  end
end

class String
  def to_f_or_i_or_s
    ((float = Float(self)) && (float % 1.0 == 0) ? float.to_i : float) rescue self
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
        item_decision_results = transform_item_decisions
        item_decision_results = extract_services_from_item_decision_results(item_decision_results)
        # puts "item_decision_results:"
        # pp item_decision_results
        construct_aggregate_columns!
        decision_order.merge!(item_decision_results[:all]) if item_decision_results.has_key?(:all)
        # puts "\n\n########################################################"
        process_decision_order!
        selected_services = transform_order_decisions
        add_item_decision_results(selected_services, item_decision_results)
        rates = construct_rates(selected_services)
      end
      return rates
    end
 
    def add_item_decision_results(selected_services, item_decision_results)
      return if item_decision_results.empty?
      selected_services.each do |selected_service|
        name = service_name(selected_service)
        if item_decision_results.has_key?(name)
          selected_service.merge!(item_decision_results[name])
        elsif item_decision_results.has_key?(:all)
          selected_service.merge!(item_decision_results[:all])
        end
      end
    end

    def process_decision_order!
      # override in subclasses
    end

    def transform_item_decisions
      # puts '####### transform_item_decisions #########'
      results = []

      # on each line item
      decision_items.each do | item|
        # puts "---item: #{item.inspect}"
        item_results = [item]
        # run each decision, expanding results that have array items due to
        # accumulate setting
        decisions['item'].each do |decision|
          # puts "------decision: #{decision.inspect}"
          new_results = []
          item_results.each do |intermediate_result|
            # puts "---------intermediate_result: #{intermediate_result}"
            transformed = decision.transform(intermediate_result)
            # puts "---------transformed:"
             # pp transformed
            new_results += transformed.expand
          end
          item_results = new_results
          # puts "------item_results: #{item_results.inspect}"
        end
        # puts "---"
        item_results.each do |result|
          # puts "------result: #{result.inspect}"
          result.keys.each do |key|
            result.delete(key) if item.has_key?(key) && (result[key] == item[key])
          end
          # puts "------now result: #{result.inspect}"
        end
        results += item_results
      end
      # puts "---returning: #{results.inspect}"
      results
    end

    def extract_services_from_item_decision_results(results)
      services = {}
      results.each do |result|
        service_name = result.delete(service_name_column)
        service_name = :all if service_name.nil?
        services[service_name] ||= {}
        service = services[service_name]
        result.each do |column, new_value|
          column_type, column_name = column.split(':')
          if column_name.nil?
            column_name = column_type
            column_type = :set
          end
          value = service[column_name]
          case column_type.to_sym
          when :set
            value ||= Set.empty
            value = value.union( Set.from_rudelo(new_value) )
          when :sum
            value ||= 0
            num = new_value.to_f_or_i_or_s
            value += num if num.is_a?(Numeric)
          when :max
            num = new_value.to_f_or_i_or_s
            value = value.nil? ? num : [value, num].max
          when :min
            num = new_value.to_f_or_i_or_s
            value = value.nil? ? num : [value, num].min
          end
          service[column_name] = value
        end
      end
      services
    end

    def transform_order_decisions
      Rails.logger.info("transform_order_decisions:")

      results = nil
      results = [decision_order]
        decisions['order'].each do |decision|
        new_results = []
        Rails.logger.info '####### decision is #########'
        Rails.logger.info decision.inspect
        
        results.each do |intermediate_result|
          
          Rails.logger.info '####### transform_order_decisions #########'
          Rails.logger.info "---decision_order:"
          Rails.logger.info intermediate_result.to_s
                    
          # ppl decision
          transformed = decision.transform!(intermediate_result)
          Rails.logger.info("after transforming")
          # ppl transformed
          new_results += transformed.expand
        end
        results = new_results
      end
      # puts "-------> transform_order_decisions results:"
      # pp results
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
        Rails.logger.info("looking up #{item.inspect}")
        variant = ProductCache.instance[item]
        Rails.logger.info("  got #{variant}")
        item_columns.each do |item_column|
          entity, key = item_column.split('.')
          item_column = [entity, key.gsub(entity,'')].join('_')
          case entity
          when 'metafields'
            variant.product.metafields_cached.each do |metafield|
              item[column_name_for_metafield(metafield)] = metafield.value
            end
            variant.metafields_cached.each do |metafield|
              item[column_name_for_metafield(metafield)] = metafield.value
            end
          when 'product'
            if(m = key.match(/^option(\d+)_name$/))
              option = variant.product.options[m[1].to_i]
              item[key] = option.nil? ? nil : option.name
            else
              item[key] = variant.product.attributes[key]
            end
          when 'variant'
            item[key] = variant.attributes[key]
          end
        end
      end
    end

    def column_name_for_metafield(metafield)
      "#{metafield.namespace}:#{metafield.key}"
    end
    def construct_aggregate_columns!
      product_types_set = Set.new
      sku_set = Set.new
      total_order_price = nil
      vendor_set = Set.new
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
          when :vendor_set
            vendor_set << item['vendor']
            item['vendor_set'] = vendor_set
          when :total_order_price
            total_order_price ||= 0
            total_order_price += item['quantity'].to_f * item['price'].to_f
          end
        end
      end
      decision_items.each do |item| 
        item.merge!(product_types_quantities) if product_types_quantities
        item['total_quantity'] = total_item_quantity if total_item_quantity
        item['total_order_price'] = total_order_price if total_order_price
      end
      decision_order['total_quantity'] = total_item_quantity if total_item_quantity
      decision_order['total_order_price'] = total_order_price if total_order_price
      decision_order.merge!(product_types_quantities) if product_types_quantities
      decision_order['product_types_set'] = product_types_set.to_rudelo if aggregate_columns.include?(:product_types_set)
      decision_order['sku_set'] = sku_set.to_rudelo if aggregate_columns.include?(:sku_set)
      decision_order['vendor_set'] = vendor_set.to_rudelo if aggregate_columns.include?(:vendor_set)
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
        price = calculate_price(selected_service)
        unless price == :na
          rate['total_price'] = calculate_price(selected_service)
          rate['service_name'] = service_name(selected_service)
          rate['currency'] = selected_service['currency']
          rate['service_code'] = service_code(selected_service)
          rates << rate
        end
      end
      rates
    end

    def calculate_price(row)
      base_price = row[base_price_column(row)]
      # puts "calculate_price. base_price: #{base_price.inspect}"
      return :na if ["na", 'n/a', 'skip', '-'].include?(base_price.downcase)
      base_price = base_price.to_f
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
        :sku_set,
        :vendor_set,
        :total_order_price
      ]
    end

    def item_columns
      @item_columns ||= [
        'product.product_type',
        # 'product.vendor',
        'product.option1_name',
        'product.option2_name',
        'product.option3_name',
        'product.metafields',
        'variant.option1',
        'variant.option2',
        'variant.option3',
        'variant.metafields'
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
              # puts "loading #{path}"
              table = Rufus::Decision::Table.new(path)
              table.matchers.unshift(Rudelo::Matchers::SetLogic.new)
              # table.matchers.first.force = Rails.env.development? || Rails.env.test?
              table
            end
        end
        decisions
      end
      @decisions
    end
  end
end
