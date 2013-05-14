require 'rufus-decision'
module Carriers
  class RufusService < ::Carriers::Service
    def fetch_rates
      withShopify do
        construct_item_columns!
        construct_aggregate_columns!
        decisions.each do decision
          decision.transform! decision_items
        end
      end
      # for each item
      #    optionally: restore option1, option2, option3 & product_type
      #    map item keys
      #    for each decision
      #        transform item
      # apply aggregator
    end

    def decision_table_dir
      Rails.root.join( 'rufus', self.class.name.demodulize.underscore)
    end

    def construct_item_columns!
      decision_items.each do |item|
        variant = ProductCache.instance[item]
        item_columns.each do |ag_col|
          entity, key = ag_col.split('.')
          case entity
          when 'product'
            item_key = variant.attributes.keys.include?(key) ? ag_col : key
            item[item_key] = variant.product.attributes[key]
          when 'variant'
            item_key = variant.product.attributes.keys.include?(key) ? ag_col : key
            item[item_key] = variant.attributes[key]
          end
        end
      end
    end

    def construct_aggregate_columns!
      product_types_set = Set.new
      product_types_quantities = nil
      decision_items.each do |item|
        aggregate_columns.each do |aggregate|
          case aggregate
          when :product_types_quantities
            product_types_quantities ||= {}
            product_types_quantities[item['product_type']] ||= 0
            product_types_quantities[item['product_type']] += 1
          when :product_types_set
            product_types_set << item['product_type']
            item['product_types_set'] = product_types_set
          end
        end
      end
      decision_items.each{ |item| product_types_quantities.each{ |type, qty| item[type] = qty } } if product_types_quantities
      decision_items
    end

    # def rufusize_column_names!
    #   @decision_items.map!{ |item| Hash[ item.map{ |k,v| ["in:#{k}", v] } ] }
    # end

    def aggregate_columns
      [
        :product_types_quantities,
        :product_types_set
      ]
    end

    def item_columns
      [
        'product.product_type',
        'variant.option1',
        'variant.option2',
        'variant.option3',
        'variant.id',
        'product.id'
      ]
    end

    def decision_items 
      @decision_items ||= items.map{ |i| i.to_hash.stringify_keys }
    end

    def decisions
      @@decisions ||= Dir["#{decision_table_dir}/*.csv"].map do |path|
        Rufus::Decision::Table.new(path)
      end
    end
  end
end
