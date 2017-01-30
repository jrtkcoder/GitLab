class Route < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  after_update :rename_descendants, if: :path_changed?

  def rename_descendants
    # We update each row separately because MySQL does not have regexp_replace.
    # rubocop:disable Rails/FindEach
    Route.where('path LIKE ?', "#{path_was}/%").each do |route|
      # Note that update column skips validation and callbacks.
      # We need this to avoid recursive call of rename_descendants method
      route.update_column(:path, route.path.sub(path_was, path))
    end
    # rubocop:enable Rails/FindEach
  end
end
