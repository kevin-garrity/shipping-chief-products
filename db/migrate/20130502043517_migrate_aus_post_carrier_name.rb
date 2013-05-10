class MigrateAusPostCarrierName < ActiveRecord::Migration
  def up
    Preference.all.each do |p|
      if (p.carrier =='AusPost')
        p.carrier='aus_post'
        p.save!
      end
    end
    
  end

  def down
  end
end
