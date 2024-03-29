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

ActiveRecord::Schema.define(version: 20160129150428) do

  create_table "error_log", force: :cascade do |t|
    t.text     "message",    limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "names", force: :cascade do |t|
    t.string   "name",          limit: 255,                 null: false
    t.string   "language_iso",  limit: 3,   default: "und"
    t.string   "country_iso",   limit: 3
    t.integer  "source_id",     limit: 4
    t.integer  "nameable_id",   limit: 4,                   null: false
    t.string   "nameable_type", limit: 255,                 null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "names", ["source_id"], name: "index_names_on_source_id", using: :btree

  create_table "ranks", force: :cascade do |t|
    t.string   "rank",         limit: 255, null: false
    t.string   "language_iso", limit: 255, null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "ranks_taxa", id: false, force: :cascade do |t|
    t.integer "taxon_id", limit: 4
    t.integer "rank_id",  limit: 4
  end

  add_index "ranks_taxa", ["rank_id"], name: "index_ranks_taxa_on_rank_id", using: :btree
  add_index "ranks_taxa", ["taxon_id"], name: "index_ranks_taxa_on_taxon_id", using: :btree

  create_table "source_databases", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.string   "authors_and_editors", limit: 255
    t.string   "uri",                 limit: 255
    t.string   "uri_scheme",          limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "sources", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.string   "slug",       limit: 255, null: false
    t.string   "version",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "taxa", force: :cascade do |t|
    t.string   "taxon_scientific_name", limit: 255,                   null: false
    t.string   "slug",                  limit: 255
    t.integer  "col_taxon_id",          limit: 4,                     null: false
    t.integer  "parent_id",             limit: 4
    t.integer  "source_database_id",    limit: 4
    t.integer  "taxonomy_id",           limit: 4,                     null: false
    t.string   "type",                  limit: 255, default: "Taxon", null: false
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
  end

  add_index "taxa", ["parent_id"], name: "index_taxa_on_parent_id", using: :btree
  add_index "taxa", ["slug"], name: "index_taxa_on_slug", unique: true, using: :btree
  add_index "taxa", ["source_database_id"], name: "index_taxa_on_source_database_id", using: :btree
  add_index "taxa", ["taxonomy_id"], name: "index_taxa_on_taxonomy_id", using: :btree

  create_table "taxonomies", force: :cascade do |t|
    t.string   "slug",         limit: 255, null: false
    t.string   "product_name", limit: 255, null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

end
