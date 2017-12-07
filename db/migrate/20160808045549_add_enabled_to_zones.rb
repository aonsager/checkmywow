class AddEnabledToZones < ActiveRecord::Migration
  def change
    add_column :zones, :enabled, :boolean, default: false
    add_column :fight_parses, :zone_id, :integer
    add_column :fights, :zone_id, :integer

    Zone.find(8).update_attributes(enabled: true)
    Zone.where(id: (9..11)).destroy_all
    Zone.new.update_attributes(id: 9, name: "Mythic+ Dungeons", enabled: false)
    Zone.new.update_attributes(id: 10, name: "Emerald Nightmare", enabled: false)
    Zone.new.update_attributes(id: 11, name: "The Nighthold", enabled: false)

    Boss.new.update_attributes(id: 1841, name: 'Ursoc', zone_id: 10, order_num: 1)
    Boss.new.update_attributes(id: 1842, name: 'Krosus', zone_id: 11, order_num: 7)
    Boss.new.update_attributes(id: 1849, name: 'Skorpyron', zone_id: 11, order_num: 1)
    Boss.new.update_attributes(id: 1853, name: 'Nythendra', zone_id: 10, order_num: 2)
    Boss.new.update_attributes(id: 1854, name: 'Dragons of Nightmare', zone_id: 10, order_num: 3)
    Boss.new.update_attributes(id: 1862, name: 'Tichondrius', zone_id: 11, order_num: 5)
    Boss.new.update_attributes(id: 1863, name: 'Star Augur Etraeus', zone_id: 11, order_num: 6)
    Boss.new.update_attributes(id: 1864, name: 'Xavius', zone_id: 10, order_num: 4)
    Boss.new.update_attributes(id: 1865, name: 'Chronomatic Anomaly', zone_id: 11, order_num: 2)
    Boss.new.update_attributes(id: 1866, name: "Gul'dan", zone_id: 11, order_num: 10)
    Boss.new.update_attributes(id: 1867, name: 'Trilliax', zone_id: 11, order_num: 3)
    Boss.new.update_attributes(id: 1871, name: 'Spellblade Aluriel', zone_id: 11, order_num: 4)
    Boss.new.update_attributes(id: 1872, name: 'Grand Magistrix Elisande', zone_id: 11, order_num: 9)
    Boss.new.update_attributes(id: 1873, name: "Il'gynoth, Heart of Corruption", zone_id: 10, order_num: 5)
    Boss.new.update_attributes(id: 1876, name: 'Elerethe Renferal', zone_id: 10, order_num: 6)
    Boss.new.update_attributes(id: 1877, name: 'Cenarius', zone_id: 10, order_num: 7)
    Boss.new.update_attributes(id: 1886, name: "High Botanist Tel'arn", zone_id: 11, order_num: 8)
    Boss.new.update_attributes(id: 11456, name: 'Eye of Azshara', zone_id: 9, order_num: 5)
    Boss.new.update_attributes(id: 11458, name: "Neltharion's Lair", zone_id: 9, order_num: 8)
    Boss.new.update_attributes(id: 11466, name: 'Darkheart Thicket', zone_id: 9, order_num: 4)
    Boss.new.update_attributes(id: 11477, name: 'Halls of Valor', zone_id: 9, order_num: 6)
    Boss.new.update_attributes(id: 11492, name: 'Maw of Souls', zone_id: 9, order_num: 7)
    Boss.new.update_attributes(id: 11493, name: 'Vault of the Wardens', zone_id: 9, order_num: 9)
    Boss.new.update_attributes(id: 11501, name: 'Black Rook Hold', zone_id: 9, order_num: 2)
    Boss.new.update_attributes(id: 11516, name: 'The Arcway', zone_id: 9, order_num: 1)
    Boss.new.update_attributes(id: 11571, name: 'Court of Stars', zone_id: 9, order_num: 3)

  end
end


