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

ActiveRecord::Schema[8.0].define(version: 2025_06_30_052557) do
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

  create_table "forge_sessions", force: :cascade do |t|
    t.bigint "forge_id", null: false
    t.string "session_id", null: false
    t.string "status", default: "waiting"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.jsonb "teams", default: {}
    t.jsonb "session_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["forge_id"], name: "index_forge_sessions_on_forge_id"
    t.index ["session_id"], name: "index_forge_sessions_on_session_id", unique: true
    t.index ["started_at"], name: "index_forge_sessions_on_started_at"
    t.index ["status"], name: "index_forge_sessions_on_status"
  end

  create_table "forges", force: :cascade do |t|
    t.string "type", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "max_participants", default: 10
    t.boolean "active", default: true
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_forges_on_active"
    t.index ["type"], name: "index_forges_on_type"
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
    t.datetime "last_heartbeat_at"
    t.bigint "forge_session_id"
    t.string "team"
    t.index ["ended_at"], name: "index_incarnations_on_ended_at"
    t.index ["forge_session_id", "team"], name: "index_incarnations_on_forge_session_id_and_team"
    t.index ["forge_session_id"], name: "index_incarnations_on_forge_session_id"
    t.index ["forge_type"], name: "index_incarnations_on_forge_type"
    t.index ["game_session_id", "ended_at"], name: "index_incarnations_on_session_and_ended"
    t.index ["game_session_id"], name: "index_incarnations_on_game_session_id"
    t.index ["incarnation_id"], name: "index_incarnations_on_incarnation_id", unique: true
    t.index ["soul_id", "ended_at"], name: "index_incarnations_on_soul_and_ended"
    t.index ["soul_id"], name: "index_incarnations_on_soul_id"
    t.index ["team"], name: "index_incarnations_on_team"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.index ["soul_id", "related_soul_id"], name: "index_soul_relationships_unique", unique: true
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
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "chosen_name"
    t.string "title"
    t.string "portrait_seed"
    t.jsonb "appearance_traits"
    t.jsonb "voice_characteristics"
    t.text "origin_story"
    t.jsonb "core_memories"
    t.jsonb "aspirations"
    t.jsonb "fears"
    t.integer "generation", default: 1
    t.string "birth_forge"
    t.jsonb "notable_achievements"
    t.datetime "born_at"
    t.index ["chosen_name"], name: "index_souls_on_chosen_name"
    t.index ["current_grace_level"], name: "index_souls_on_current_grace_level"
    t.index ["first_name"], name: "index_souls_on_first_name"
    t.index ["generation"], name: "index_souls_on_generation"
    t.index ["last_name"], name: "index_souls_on_last_name"
    t.index ["soul_id"], name: "index_souls_on_soul_id", unique: true
    t.index ["total_incarnations"], name: "index_souls_on_total_incarnations"
  end

  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
  add_foreign_key "forge_sessions", "forges"
  add_foreign_key "incarnations", "forge_sessions"
  add_foreign_key "incarnations", "souls"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "soul_relationships", "souls"
  add_foreign_key "soul_relationships", "souls", column: "related_soul_id"
end
