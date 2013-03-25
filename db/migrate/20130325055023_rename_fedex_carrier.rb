class RenameFedexCarrier < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute("UPDATE preference SET carrier='Private_FABUSA' WHERE carrier='Fedex' ")
  end

  def down
  end
end
