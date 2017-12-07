class BrewmasterMonkV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Brewmaster Monk', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage taken and healing received</li><li>Cast Efficiency</li></ul><p>Resources tab:</p><ul><li>Time not Energy-Capped</li><li>Ironskin Brew Effectiveness</li><li>Purifying Brew Effectiveness</li><li>Stagger Graph</li></ul><p>Cooldowns tab</p><ul><li>Dampen Harm Effectiveness</li><li>Diffuse Magic Effectiveness</li><li>Zen Meditation Effectiveness</li><li>Fortifying Brew Effectiveness</li></ul><p>Health Graph</p>');
  end
end
