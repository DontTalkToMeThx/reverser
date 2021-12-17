class Artist < ApplicationRecord
  belongs_to_creator
  has_many :artist_urls
  has_many :submissions, through: :artist_urls

  validates :name, uniqueness: { case_sensitive: false }
  validates :name, printable_string: true
  validates :name, length: { in: 1..64 }
end
