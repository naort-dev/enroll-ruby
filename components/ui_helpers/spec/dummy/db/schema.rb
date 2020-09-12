# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 20_170_419_051_917) do

  create_table "surveys", force: :cascade do |t|
    t.string   "workflow",    default: "{}"
    t.string   "results",     default: "{}"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "smoker"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "address",     default: "{}"
    t.string   "form_params", default: "{}"
  end

end
