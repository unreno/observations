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

ActiveRecord::Schema.define(version: 20170223213101) do

  create_table "observations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "chirp_id"
    t.integer  "provider_id"
    t.string   "concept"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string   "value"
    t.string   "units",         limit: 20
    t.string   "raw"
    t.datetime "downloaded_at"
    t.string   "source_schema", limit: 50
    t.string   "source_table",  limit: 50
    t.integer  "source_id"
    t.datetime "imported_at"
    t.index ["chirp_id", "started_at"], name: "index_observations_on_chirp_id_and_started_at", using: :btree
    t.index ["chirp_id"], name: "index_observations_on_chirp_id", using: :btree
    t.index ["concept"], name: "index_observations_on_concept", using: :btree
    t.index ["started_at"], name: "index_observations_on_started_at", using: :btree
    t.index ["value"], name: "index_observations_on_value", using: :btree
  end

end
