class AddGuilds < ActiveRecord::Migration
  def change
    create_table :guilds do |t|
      t.string   :server, null: false
      t.string   :server_slug, null: false
      t.string   :region, null: false
      t.string   :name, null: false
      t.integer  :status, default: 0
      t.integer  :last_import, limit: 8, default: 0
      t.timestamps
    end

    create_table :guild_reports do |t|
      t.belongs_to :guild, index: true
      t.belongs_to :report, index: true
      t.timestamps
    end

    add_index :guilds, [:region, :server, :name], :unique => true, :name => 'guild_index'
  end
end
