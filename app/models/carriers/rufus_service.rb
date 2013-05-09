module Carriers
  class RufusService < ::Carriers::Service
    def fetch_rates
      # 
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

    def decisions
      @@decisions ||= Dir["#{decision_table_dir}/*.csv"].map do |path|
        Rufus::Decision::Table.new(path)
      end
    end
  end
end
