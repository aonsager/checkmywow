class AddTalentsToFps < ActiveRecord::Migration
  def change
    add_column :fp_dh_havoc, :talents, :string
    add_column :fp_dh_havoc, :fight_length, :integer
    add_column :fp_dh_veng, :talents, :string
    add_column :fp_dh_veng, :fight_length, :integer
    add_column :fp_dk_blood, :talents, :string
    add_column :fp_dk_blood, :fight_length, :integer
    add_column :fp_dk_frost, :talents, :string
    add_column :fp_dk_frost, :fight_length, :integer
    add_column :fp_dk_unholy, :talents, :string
    add_column :fp_dk_unholy, :fight_length, :integer
    add_column :fp_druid_balance, :talents, :string
    add_column :fp_druid_balance, :fight_length, :integer
    add_column :fp_druid_feral, :talents, :string
    add_column :fp_druid_feral, :fight_length, :integer
    add_column :fp_druid_guardian, :talents, :string
    add_column :fp_druid_guardian, :fight_length, :integer
    add_column :fp_druid_resto, :talents, :string
    add_column :fp_druid_resto, :fight_length, :integer
    add_column :fp_hunter_beast, :talents, :string
    add_column :fp_hunter_beast, :fight_length, :integer
    add_column :fp_hunter_marks, :talents, :string
    add_column :fp_hunter_marks, :fight_length, :integer
    add_column :fp_hunter_survival, :talents, :string
    add_column :fp_hunter_survival, :fight_length, :integer
    add_column :fp_mage_arcane, :talents, :string
    add_column :fp_mage_arcane, :fight_length, :integer
    add_column :fp_mage_fire, :talents, :string
    add_column :fp_mage_fire, :fight_length, :integer
    add_column :fp_mage_frost, :talents, :string
    add_column :fp_mage_frost, :fight_length, :integer
    add_column :fp_monk_brew, :talents, :string
    add_column :fp_monk_brew, :fight_length, :integer
    add_column :fp_monk_mist, :talents, :string
    add_column :fp_monk_mist, :fight_length, :integer
    add_column :fp_monk_wind, :talents, :string
    add_column :fp_monk_wind, :fight_length, :integer
    add_column :fp_paladin_holy, :talents, :string
    add_column :fp_paladin_holy, :fight_length, :integer
    add_column :fp_paladin_prot, :talents, :string
    add_column :fp_paladin_prot, :fight_length, :integer
    add_column :fp_paladin_ret, :talents, :string
    add_column :fp_paladin_ret, :fight_length, :integer
    add_column :fp_priest_disc, :talents, :string
    add_column :fp_priest_disc, :fight_length, :integer
    add_column :fp_priest_holy, :talents, :string
    add_column :fp_priest_holy, :fight_length, :integer
    add_column :fp_priest_shadow, :talents, :string
    add_column :fp_priest_shadow, :fight_length, :integer
    add_column :fp_rogue_sin, :talents, :string
    add_column :fp_rogue_sin, :fight_length, :integer
    add_column :fp_rogue_outlaw, :talents, :string
    add_column :fp_rogue_outlaw, :fight_length, :integer
    add_column :fp_rogue_sub, :talents, :string
    add_column :fp_rogue_sub, :fight_length, :integer
    add_column :fp_shaman_ele, :talents, :string
    add_column :fp_shaman_ele, :fight_length, :integer
    add_column :fp_shaman_enh, :talents, :string
    add_column :fp_shaman_enh, :fight_length, :integer
    add_column :fp_shaman_resto, :talents, :string
    add_column :fp_shaman_resto, :fight_length, :integer
    add_column :fp_warlock_aff, :talents, :string
    add_column :fp_warlock_aff, :fight_length, :integer
    add_column :fp_warlock_demon, :talents, :string
    add_column :fp_warlock_demon, :fight_length, :integer
    add_column :fp_warlock_destr, :talents, :string
    add_column :fp_warlock_destr, :fight_length, :integer
    add_column :fp_warrior_arms, :talents, :string
    add_column :fp_warrior_arms, :fight_length, :integer
    add_column :fp_warrior_fury, :talents, :string
    add_column :fp_warrior_fury, :fight_length, :integer
    add_column :fp_warrior_prot, :talents, :string
    add_column :fp_warrior_prot, :fight_length, :integer
  end
end
