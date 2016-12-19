class Secret < ApplicationRecord
  default_scope -> { order(time: :desc) }
  validates :tx, presence: true, length: { is: 64 }
  validates :file_mime, presence: true, unless: -> (secret){not secret.file_path.present?}
  validates :time, presence: true
  validates :text, presence: true, unless: -> (secret){secret.file_path.present?}
  validates :file_path, presence: true, unless: -> (secret){secret.text.present?}
  validates :file_size, presence: true, unless: -> (secret){not secret.file_path.present?}
end

