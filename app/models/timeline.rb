class Timeline < ActiveRecord::Base

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  include ApplicationHelper
  include PgSearch
  pg_search_scope :search_by_name,
                  :against => [:name, :frame],
                  :ignoring => :accents,
                  :using => {
                      :tsearch => {:prefix => true,
                                   :dictionary => "french"},
                      :trigram => {}
                  }

  attr_accessor :delete_picture, :has_picture, :frame_timeline_id,
                :tag_list, :binary_left, :binary_right, :source
  belongs_to :user
  has_many :timeline_contributors, dependent: :destroy
  has_many :references, dependent: :destroy
  has_many :summaries, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :links, dependent: :destroy
  has_many :summary_links, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :edges, dependent: :destroy
  has_many :edges_from, class_name: "Edge",
           foreign_key: "target",
           dependent: :destroy

  has_many :reference_edges, dependent: :destroy
  has_many :reference_edge_votes, dependent: :destroy

  has_many :frames, dependent: :destroy

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  has_many :notifications, dependent: :destroy

  has_many :figures, dependent: :destroy
  has_many :header_figures, class_name: "Figure", foreign_key: "img_timeline_id", dependent: :destroy
  belongs_to :figure

  after_create :cascading_save_timeline

  around_update :updating_with_params

  validates :user_id, presence: true
  validates :private, :inclusion => {:in => [true, false]}
  validates :name, presence: true, length: { maximum: 180 }
  validates :frame, length: {minimum: 180, maximum: 2500}
  validate :binary_valid

  def user_name
    User.select( :name ).find( self.user_id ).name
  end

  def picture?
    self.figure_id ? true : false
  end

  def picture_url
    if self.figure_id
      Figure.select(:id, :picture, :user_id).find(self.figure_id).picture_url
    else
      nil
    end
  end

  def nb_edits
    self.nb_summaries + self.nb_comments
  end

  def total_binary
    self.binary_1+self.binary_2+self.binary_3+self.binary_4+self.binary_5
  end

  def nb_suggestions
    nb = self.suggestion.children
    if nb == 0
      ""
    elsif nb == 1
      " (#{nb} réponse)"
    else
      " (#{nb} réponses)"
    end
  end

  def binary_font_size( value )
    if self.nb_references > 0
      12+56.0*self["binary_#{value}"]/self.nb_references
    else
      25.0
    end
  end

  def binary_explanation( value )
    text = "Les références qui sont "
    case value
      when 1
        return text + "très fermement du coté " + self.binary.split('&&')[0].downcase
      when 2
        return text + "du coté " + self.binary.split('&&')[0].downcase
      when 3
        return text + "neutres"
      when 4
        return text + "du coté " + self.binary.split('&&')[1].downcase
      when 5
        return text + "très fermement du coté " + self.binary.split('&&')[1].downcase
    end
  end

  def self.tagged_with(name)
    Tag.find_by_name!(name).timelines
  end

  def self.tag_counts
    Tag.select("tags.*, count(taggings.tag_id) as count").
        joins(:taggings).group("taggings.tag_id")
  end

  def get_tag_list
    tags.map(&:name)
  end

  def set_tag_list(names)
    if !names.nil?
      list = tags_hash.keys
      self.tags = names.map do |n|
        if list.include? n
          Tag.where(name: n.strip).first_or_create!
        end
      end
    end
  end

  def get_tag_hash
    hash = {}
    self.references.each do |ref|
      ref.tags.map(&:name).each do |name|
        hash[name] ? hash[name] += 1 : hash[name] = 1
      end
    end
    hash
  end

  def compute_score( nb_contributors, nb_references, nb_comments, nb_summaries )
    4.0/(1.0/(1+Math.log(1+nb_contributors))+1.0/(1+Math.log(1+10*nb_references))+1.0/(1+Math.log(1+5*nb_comments))+1.0/(1+Math.log(1+20*nb_summaries)))
  end

  private

  def binary_valid
    if self.binary != ""
      if self.binary.split('&&')[0].blank?
        errors.add(:base, "Un des antagoniste est vide")
      elsif self.binary.split('&&')[0].length > 20
        errors.add(:base, "Un des antagoniste est trop long (>20 caractères)")
      end
      if self.binary.split('&&')[1].blank?
        errors.add(:base, "Un des antagoniste est vide")
      elsif self.binary.split('&&')[1].length > 20
        errors.add(:base, "Un des antagoniste est trop long (>20 caractères)")
      end
    end
  end

  def cascading_save_timeline
    Frame.create( user_id: self.user_id, best: true,
                   content: self.frame, name: self.name, timeline_id: self.id, binary: self.binary )
    unless self.private
      notifications = []
      User.all.pluck(:id).each do |user_id|
        unless self.user_id == user_id
          notifications << Notification.new( user_id: user_id, timeline_id: self.id, category: 1 )
        end
      end
      Notification.import notifications
    end
    TimelineContributor.create({user_id: self.user_id, timeline_id: self.id, bool: true})
  end

  def updating_with_params
    binary = self.binary_was
    yield
    if binary != self.binary
      Reference.where( timeline_id: self.id ).update_all(:binary => self.binary )
      if self.binary == ""
        Reference.where( timeline_id: self.id ).update_all(binary_most: 0,
                                                           binary_1: 0, binary_2: 0,
                                                           binary_3: 0, binary_4: 0, binary_5: 0)
        Timeline.where( id: self.id ).update_all(binary_0: self.nb_references,
                                                           binary_1: 0, binary_2: 0,
                                                           binary_3: 0, binary_4: 0, binary_5: 0)
        Binary.where( timeline_id: self.id ).delete_all
      end
    end
  end

end
