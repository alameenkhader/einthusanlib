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

ActiveRecord::Schema[8.0].define(version: 2025_09_23_000001) do
  create_table "movies", force: :cascade do |t|
    t.string "title", null: false
    t.string "image_url"
    t.string "einthusan_url", null: false
    t.datetime "released_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["einthusan_url"], name: "index_movies_on_einthusan_url", unique: true
    t.index ["released_at"], name: "index_movies_on_released_at"
    t.index ["title"], name: "index_movies_on_title"
  end
end
