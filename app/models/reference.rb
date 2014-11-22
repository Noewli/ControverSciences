class Reference < ActiveRecord::Base
  belongs_to :user
  belongs_to :timeline
  has_many :links, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :reference_contributors, dependent: :destroy

  after_create  :cascading_save_ref

  validates :user_id, presence: true
  validates :timeline_id, presence: true

  attr_writer :current_step

  validates_presence_of :title, :title_fr, :author, :year, :doi, :url, :journal, :if => lambda { |o| o.current_step == "metadata" }
  validates_uniqueness_of :timeline_id, :scope => [:doi], :if => lambda { |o| o.current_step == "metadata" }

  def current_step
    @current_step || steps.first
  end

  def steps
    %w[doi_name metadata confirmation]
  end

  def next_step
    self.current_step = steps[steps.index(current_step)+1]
  end

  def previous_step
    self.current_step = steps[steps.index(current_step)-1]
  end

  def first_step?
    current_step == steps.first
  end

  def last_step?
    current_step == steps.last
  end

  def all_valid?
    steps.all? do |step|
      self.current_step = step
      valid?
    end
  end

  def create_notifications
    user_ids = FollowingTimeline.where( timeline_id: self.timeline_id ).pluck( :user_id )
    notifications = []
    user_ids.each do |user_id|
      notifications << NotificationReference.new( user_id: user_id, reference_id: self.id )
    end
    NotificationReference.import notifications
    User.increment_counter( :notifications_reference, user_ids)
  end

  private

  def cascading_save_ref
    self.create_notifications
    Timeline.increment_counter(:nb_references, self.timeline_id)
    refrelation = ReferenceContributor.new({user_id: self.user_id, reference_id: self.id, bool: true})
    refrelation.save()
    Reference.increment_counter(:nb_contributors, self.id)
    if not TimelineContributor.where({user_id: self.user_id, timeline_id: self.timeline_id}).any?
      timrelation = TimelineContributor.new({user_id: self.user_id, timeline_id: self.timeline_id, bool: true})
      timrelation.save()
      Timeline.increment_counter(:nb_contributors, self.timeline_id)
    end
  end

end
