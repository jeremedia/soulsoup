# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_30_015258) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "event_store_events", force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.binary "data", null: false
    t.datetime "created_at", null: false
    t.datetime "valid_at"
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.string "stream", null: false
    t.integer "position"
    t.uuid "event_id", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "incarnations", force: :cascade do |t|
    t.string "incarnation_id"
    t.bigint "soul_id", null: false
    t.string "forge_type"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "game_session_id"
    t.jsonb "modifiers"
    t.integer "events_count"
    t.float "total_experience"
    t.text "memory_summary"
    t.string "lora_weights_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ended_at"], name: "index_incarnations_on_ended_at"
    t.index ["forge_type"], name: "index_incarnations_on_forge_type"
    t.index ["game_session_id"], name: "index_incarnations_on_game_session_id"
    t.index ["incarnation_id"], name: "index_incarnations_on_incarnation_id", unique: true
    t.index ["soul_id"], name: "index_incarnations_on_soul_id"
  end

  create_table "soul_relationships", force: :cascade do |t|
    t.bigint "soul_id", null: false
    t.bigint "related_soul_id", null: false
    t.string "relationship_type"
    t.float "strength"
    t.datetime "formed_at"
    t.datetime "last_interaction_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["related_soul_id"], name: "index_soul_relationships_on_related_soul_id"
    t.index ["relationship_type"], name: "index_soul_relationships_on_relationship_type"
    t.index ["soul_id"], name: "index_soul_relationships_on_soul_id"
  end

  create_table "souls", force: :cascade do |t|
    t.string "soul_id"
    t.jsonb "genome"
    t.vector "personality_vector", limit: 256
    t.jsonb "base_traits"
    t.integer "total_incarnations"
    t.float "current_grace_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["soul_id"], name: "index_souls_on_soul_id", unique: true
    t.index ["total_incarnations"], name: "index_souls_on_total_incarnations"
  end

  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
  add_foreign_key "incarnations", "souls"
  add_foreign_key "soul_relationships", "souls"
  add_foreign_key "soul_relationships", "souls", column: "related_soul_id"
end
