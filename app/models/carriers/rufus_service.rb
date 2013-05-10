module Carriers
  class RufusService < ::Carriers::Service
    def fetch_rates
      construct_aggregate_columns if preference.aggregate_columns?

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

    def construct_aggregate_columns
      # for lifemap we need "Product Types" which is a set of the product types in the order
      #  Shopify
    end

    def decisions
      @@decisions ||= Dir["#{decision_table_dir}/*.csv"].map do |path|
        Rufus::Decision::Table.new(path)
      end
    end
  end
end
