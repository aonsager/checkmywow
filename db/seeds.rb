# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Zone.delete_all
Boss.delete_all

Zone.find_or_create_by(id: 8).update_attributes(name: 'Hellfire Citadel')

Boss.find_or_create_by(id: 1777).update_attributes(name: "Fel Lord Zakuun", zone_id: 8, order_num: 10)
Boss.find_or_create_by(id: 1778).update_attributes(name: "Hellfire Assault ", zone_id: 8, order_num: 1)
Boss.find_or_create_by(id: 1783).update_attributes(name: "Gorefiend", zone_id: 8, order_num: 6)
Boss.find_or_create_by(id: 1784).update_attributes(name: "Tyrant Velhari ", zone_id: 8, order_num: 9)
Boss.find_or_create_by(id: 1785).update_attributes(name: "Iron Reaver", zone_id: 8, order_num: 2)
Boss.find_or_create_by(id: 1786).update_attributes(name: "Kilrogg Deadeye", zone_id: 8, order_num: 5)
Boss.find_or_create_by(id: 1787).update_attributes(name: "Kormrok", zone_id: 8, order_num: 3)
Boss.find_or_create_by(id: 1788).update_attributes(name: "Shadow-Lord Iskar", zone_id: 8, order_num: 7)
Boss.find_or_create_by(id: 1794).update_attributes(name: "Socrethar the Eternal", zone_id: 8, order_num: 8)
Boss.find_or_create_by(id: 1795).update_attributes(name: "Mannoroth", zone_id: 8, order_num: 12)
Boss.find_or_create_by(id: 1798).update_attributes(name: "Hellfire High Council", zone_id: 8, order_num: 4)
Boss.find_or_create_by(id: 1799).update_attributes(name: "Archimonde ", zone_id: 8, order_num: 13)
Boss.find_or_create_by(id: 1800).update_attributes(name: "Xhul'horac ", zone_id: 8, order_num: 11)