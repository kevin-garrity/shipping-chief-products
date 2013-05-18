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
            item_key = variant.attributes.keys.include?(key) ? item_column : key
            item[item_key] = variant.product.attributes[key]
          when 'variant'
            item_key = variant.product.attributes.keys.include?(key) ? item_column : key
            item[item_key] = variant.attributes[key]
          end
        end
      end
    end

    def construct_aggregate_columns!
      product_types_set = Set.new
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
          end
        end
      end
      decision_items.each do |item| 
        product_types_quantities.each{ |type, qty| item[type] = qty } if product_types_quantities
        item[:total_item_quantity] = total_item_quantity if total_item_quantity
      end

      decision_items
    end

    # def rufusize_column_names!
    #   @decision_items.map!{ |item| Hash[ item.map{ |k,v| ["in:#{k}", v] } ] }
    # end

    def aggregate_columns
      [
        :product_types_quantities,
        :total_item_quantity,
        :product_types_set
      ]
    end

    def item_columns
      [
        'product.product_type',
        'variant.option1',
        'variant.option2',
        'variant.option3'
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
