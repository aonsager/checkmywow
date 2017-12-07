class DestructionV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Destruction Warlock', version: 1).update_attributes(content: '<p>Key Metrics</p><ul><li>Eradication Uptime</li><li>Immolate Uptime</li><li>Havoc Uptime</li><li>Havoc Fails</li></ul><p>Cast Efficiency</p><p>Resource Management</p><ul><li>Soul Shards Gained/Wasted</li><li>Always Be Casting (Experimental)</li></ul>');
  end
end
