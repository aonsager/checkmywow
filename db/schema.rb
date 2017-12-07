# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170831020608) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bosses", force: :cascade do |t|
    t.string   "name"
    t.integer  "zone_id"
    t.integer  "order_num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "buff_parses", force: :cascade do |t|
    t.integer  "fight_parse_id",                       null: false
    t.string   "name",                                 null: false
    t.text     "kpi_hash",        default: "--- {}\n"
    t.text     "details_hash",    default: "--- {}\n"
    t.text     "uptimes_array",   default: "--- []\n"
    t.text     "downtimes_array", default: "--- []\n"
    t.text     "stacks_array",    default: "--- []\n"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "buff_parses", ["fight_parse_id"], name: "index_buff_parses_on_fight_parse_id", using: :btree

  create_table "changelogs", force: :cascade do |t|
    t.string   "fp_type",    null: false
    t.integer  "version",    null: false
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "patch"
  end

  add_index "changelogs", ["fp_type", "version"], name: "index_changelogs_on_fp_type_and_version", unique: true, using: :btree

  create_table "cooldown_parses", force: :cascade do |t|
    t.integer  "fight_parse_id",                                null: false
    t.string   "name",                                          null: false
    t.string   "cd_type",                                       null: false
    t.text     "kpi_hash",                 default: "--- {}\n"
    t.text     "details_hash",             default: "--- {}\n"
    t.integer  "started_at",     limit: 8
    t.integer  "ended_at",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cooldown_parses", ["fight_parse_id"], name: "index_cooldown_parses_on_fight_parse_id", using: :btree

  create_table "debuff_parses", force: :cascade do |t|
    t.integer  "fight_parse_id",                       null: false
    t.string   "name",                                 null: false
    t.integer  "target_id"
    t.string   "target_name"
    t.integer  "target_instance"
    t.text     "kpi_hash",        default: "--- {}\n"
    t.text     "details_hash",    default: "--- {}\n"
    t.text     "uptimes_array",   default: "--- []\n"
    t.text     "downtimes_array", default: "--- []\n"
    t.text     "stacks_array",    default: "--- []\n"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "debuff_parses", ["fight_parse_id"], name: "index_debuff_parses_on_fight_parse_id", using: :btree

  create_table "external_buff_parses", force: :cascade do |t|
    t.integer  "fight_parse_id",                       null: false
    t.string   "name",                                 null: false
    t.integer  "target_id"
    t.string   "target_name"
    t.integer  "target_instance"
    t.text     "kpi_hash",        default: "--- {}\n"
    t.text     "details_hash",    default: "--- {}\n"
    t.text     "uptimes_array",   default: "--- []\n"
    t.text     "downtimes_array", default: "--- []\n"
    t.text     "stacks_array",    default: "--- []\n"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_buff_parses", ["fight_parse_id"], name: "index_external_buff_parses_on_fight_parse_id", using: :btree

  create_table "external_cooldown_parses", force: :cascade do |t|
    t.integer  "fight_parse_id",                                null: false
    t.integer  "target_id",                                     null: false
    t.string   "target_name"
    t.string   "name",                                          null: false
    t.string   "cd_type",                                       null: false
    t.text     "kpi_hash",                 default: "--- {}\n"
    t.text     "details_hash",             default: "--- {}\n"
    t.integer  "started_at",     limit: 8
    t.integer  "ended_at",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_cooldown_parses", ["fight_parse_id", "target_id"], name: "index_external_cooldown_parses_on_fight_parse_id_and_target_id", using: :btree

  create_table "fails", force: :cascade do |t|
    t.string   "model_type",   null: false
    t.string   "model_id",     null: false
    t.string   "status"
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fails", ["model_type", "model_id"], name: "index_fails_on_model_type_and_model_id", unique: true, using: :btree

  create_table "fight_parse_records", force: :cascade do |t|
    t.string   "report_id",                   null: false
    t.integer  "fight_id",                    null: false
    t.integer  "fight_guid"
    t.integer  "player_id",                   null: false
    t.integer  "actor_id"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "status",      default: 0
    t.integer  "version",     default: 0
    t.datetime "parsed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "kill",        default: false
  end

  add_index "fight_parse_records", ["report_id", "fight_id", "player_id"], name: "fpr_index", unique: true, using: :btree

  create_table "fight_parses", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.string   "talents"
    t.integer  "fight_length"
    t.integer  "casts_score"
  end

  add_index "fight_parses", ["report_id", "fight_id", "player_id"], name: "index_fight_parses_on_report_id_and_fight_id_and_player_id", unique: true, using: :btree

  create_table "fights", force: :cascade do |t|
    t.string   "report_id",                               null: false
    t.integer  "fight_id",                                null: false
    t.string   "name"
    t.integer  "boss_id"
    t.integer  "size"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.integer  "status",                      default: 0
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "boss_percent",                default: 0
    t.integer  "zone_id"
  end

  add_index "fights", ["report_id", "fight_id"], name: "index_fights_on_report_id_and_fight_id", unique: true, using: :btree

  create_table "fp_dh_havoc", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_dh_havoc", ["report_id", "fight_id", "player_id"], name: "fp_dh_havoc_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_dh_veng", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_dh_veng", ["report_id", "fight_id", "player_id"], name: "fp_dh_veng_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_dk_blood", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_dk_blood", ["report_id", "fight_id", "player_id"], name: "fp_dk_blood_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_dk_frost", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_dk_frost", ["report_id", "fight_id", "player_id"], name: "fp_dk_frost_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_dk_unholy", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_dk_unholy", ["report_id", "fight_id", "player_id"], name: "fp_dk_unholy_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_druid_balance", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_druid_balance", ["report_id", "fight_id", "player_id"], name: "fp_druid_balance_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_druid_feral", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_druid_feral", ["report_id", "fight_id", "player_id"], name: "fp_druid_feral_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_druid_guardian", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_druid_guardian", ["report_id", "fight_id", "player_id"], name: "fp_druid_guardian_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_druid_resto", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_druid_resto", ["report_id", "fight_id", "player_id"], name: "fp_druid_resto_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_hunter_beast", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_hunter_beast", ["report_id", "fight_id", "player_id"], name: "fp_hunter_beast_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_hunter_marks", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_hunter_marks", ["report_id", "fight_id", "player_id"], name: "fp_hunter_marks_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_hunter_survival", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_hunter_survival", ["report_id", "fight_id", "player_id"], name: "fp_hunter_survival_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_mage_arcane", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_mage_arcane", ["report_id", "fight_id", "player_id"], name: "fp_mage_arcane_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_mage_fire", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_mage_fire", ["report_id", "fight_id", "player_id"], name: "fp_mage_fire_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_mage_frost", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_mage_frost", ["report_id", "fight_id", "player_id"], name: "fp_mage_frost_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_monk_brew", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_monk_brew", ["report_id", "fight_id", "player_id"], name: "fp_monk_brew_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_monk_mist", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_monk_mist", ["report_id", "fight_id", "player_id"], name: "fp_monk_mist_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_monk_wind", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_monk_wind", ["report_id", "fight_id", "player_id"], name: "fp_monk_wind_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_paladin_holy", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_paladin_holy", ["report_id", "fight_id", "player_id"], name: "fp_paladin_holy_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_paladin_prot", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_paladin_prot", ["report_id", "fight_id", "player_id"], name: "fp_paladin_prot_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_paladin_ret", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_paladin_ret", ["report_id", "fight_id", "player_id"], name: "fp_paladin_ret_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_priest_disc", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_priest_disc", ["report_id", "fight_id", "player_id"], name: "fp_priest_disc_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_priest_holy", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_priest_holy", ["report_id", "fight_id", "player_id"], name: "fp_priest_holy_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_priest_shadow", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
    t.integer  "voidform_uptime"
  end

  add_index "fp_priest_shadow", ["report_id", "fight_id", "player_id"], name: "fp_priest_shadow_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_rogue_outlaw", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_rogue_outlaw", ["report_id", "fight_id", "player_id"], name: "fp_rogue_outlaw_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_rogue_sin", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_rogue_sin", ["report_id", "fight_id", "player_id"], name: "fp_rogue_sin_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_rogue_sub", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_rogue_sub", ["report_id", "fight_id", "player_id"], name: "fp_rogue_sub_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_shaman_ele", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_shaman_ele", ["report_id", "fight_id", "player_id"], name: "fp_shaman_ele_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_shaman_enh", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_shaman_enh", ["report_id", "fight_id", "player_id"], name: "fp_shaman_enh_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_shaman_resto", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_shaman_resto", ["report_id", "fight_id", "player_id"], name: "fp_shaman_resto_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_warlock_aff", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_warlock_aff", ["report_id", "fight_id", "player_id"], name: "fp_warlock_aff_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_warlock_demon", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_warlock_demon", ["report_id", "fight_id", "player_id"], name: "fp_warlock_demon_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_warlock_destr", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_warlock_destr", ["report_id", "fight_id", "player_id"], name: "fp_warlock_destr_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_warrior_arms", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_warrior_arms", ["report_id", "fight_id", "player_id"], name: "fp_warrior_arms_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_warrior_fury", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.integer  "cooldowns_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_warrior_fury", ["report_id", "fight_id", "player_id"], name: "fp_warrior_fury_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "fp_warrior_prot", force: :cascade do |t|
    t.string   "report_id",                                        null: false
    t.integer  "fight_id",                                         null: false
    t.integer  "player_id",         limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.string   "spec"
    t.integer  "boss_id"
    t.integer  "difficulty"
    t.boolean  "kill"
    t.boolean  "processed"
    t.integer  "version",                     default: 1
    t.text     "kpi_hash",                    default: "--- {}\n"
    t.text     "resources_hash",              default: "--- {}\n"
    t.text     "cooldowns_hash",              default: "--- {}\n"
    t.datetime "report_started_at"
    t.integer  "started_at",        limit: 8
    t.integer  "ended_at",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0
    t.string   "boss_name"
    t.integer  "boss_percent"
    t.text     "casts_hash",                  default: "--- {}\n"
    t.float    "expansion",                   default: 6.2
    t.text     "combatant_info",              default: "--- {}\n"
    t.integer  "actor_id"
    t.integer  "zone_id"
    t.integer  "hotfix",                      default: 0
    t.integer  "casts_score"
    t.string   "talents"
    t.integer  "fight_length"
  end

  add_index "fp_warrior_prot", ["report_id", "fight_id", "player_id"], name: "fp_warrior_prot_report_id_fight_id_player_id_idx", unique: true, using: :btree

  create_table "guild_reports", force: :cascade do |t|
    t.integer  "guild_id"
    t.integer  "report_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "guild_reports", ["guild_id"], name: "index_guild_reports_on_guild_id", using: :btree
  add_index "guild_reports", ["report_id"], name: "index_guild_reports_on_report_id", using: :btree

  create_table "guilds", force: :cascade do |t|
    t.string   "server",                            null: false
    t.string   "server_slug",                       null: false
    t.string   "region",                            null: false
    t.string   "name",                              null: false
    t.integer  "status",                default: 0
    t.integer  "last_import", limit: 8, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "guilds", ["region", "server", "name"], name: "guild_index", unique: true, using: :btree

  create_table "healing_parses", force: :cascade do |t|
    t.string   "report_id",                                   null: false
    t.integer  "fight_id",                                    null: false
    t.integer  "target_id",                                   null: false
    t.string   "target_name"
    t.text     "kpi_hash",               default: "--- {}\n"
    t.text     "details_hash",           default: "--- {}\n"
    t.integer  "started_at",   limit: 8
    t.integer  "ended_at",     limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "healing_parses", ["report_id", "fight_id"], name: "index_healing_parses_on_report_id_and_fight_id", using: :btree

  create_table "kpi_parses", force: :cascade do |t|
    t.integer  "fight_parse_id",                      null: false
    t.string   "name",                                null: false
    t.text     "kpi_hash",       default: "--- {}\n"
    t.text     "details_hash",   default: "--- {}\n"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kpi_parses", ["fight_parse_id"], name: "index_kpi_parses_on_fight_parse_id", using: :btree

  create_table "players", force: :cascade do |t|
    t.integer  "player_id",   limit: 8,                      null: false
    t.string   "player_name"
    t.string   "class_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "specs",                 default: [],                      array: true
    t.string   "boss_counts",           default: "--- {}\n"
    t.integer  "processed",             default: 0
  end

  add_index "players", ["player_id"], name: "index_players_on_player_id", unique: true, using: :btree

  create_table "progresses", force: :cascade do |t|
    t.string   "model_type",                         null: false
    t.string   "model_id",                           null: false
    t.integer  "current",      limit: 8, default: 0
    t.integer  "finish",       limit: 8, default: 1
    t.string   "message"
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "progresses", ["model_type", "model_id"], name: "index_progresses_on_model_type_and_model_id", unique: true, using: :btree

  create_table "report_players", force: :cascade do |t|
    t.string   "report_id",  null: false
    t.string   "player_id",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_players", ["report_id", "player_id"], name: "index_report_players_on_report_id_and_player_id", unique: true, using: :btree

  create_table "reports", force: :cascade do |t|
    t.string   "report_id",                  null: false
    t.string   "title"
    t.integer  "zone"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.boolean  "imported",   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",     default: 0
  end

  add_index "reports", ["report_id"], name: "index_reports_on_report_id", unique: true, using: :btree

  create_table "spell_names", force: :cascade do |t|
    t.string   "class_type", null: false
    t.string   "spec",       null: false
    t.integer  "guid"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spell_names", ["class_type", "spec", "guid"], name: "index_spell_names_on_class_type_and_spec_and_guid", unique: true, using: :btree

  create_table "zones", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",    default: false
    t.integer  "order_id"
  end

end
