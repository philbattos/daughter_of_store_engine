class Category < ActiveRecord::Base
  attr_accessible :name, :description

  validates :name,        presence: true, uniqueness: true
  validates :description, presence: true

  has_many  :products
end