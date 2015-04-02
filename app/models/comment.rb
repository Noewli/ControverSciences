class Comment < ActiveRecord::Base
  require 'HTMLlinks'

  attr_accessor :parent_id, :delete_picture, :has_picture

  belongs_to :user
  belongs_to :timeline
  belongs_to :reference

  has_many :votes, dependent: :destroy
  has_many :links, dependent: :destroy

  has_many :notification_comments, dependent: :destroy
  has_many :notification_selection_losses, dependent: :destroy
  has_many :notification_selection_wins, dependent: :destroy
  has_many :notification_selections, foreign_key: "new_comment_id", dependent: :destroy
  has_many :comment_types, dependent: :destroy
  has_many :comment_joins, dependent: :destroy

  after_create :cascading_create_comment

  around_update :updating_with_public

  validates :user_id, presence: true
  validates :timeline_id, presence: true
  validates :reference_id, presence: true
  validates :f_0_content, length: {maximum: 1001}
  validates :f_1_content, length: {maximum: 1001}
  validates :f_2_content, length: {maximum: 1001}
  validates :f_3_content, length: {maximum: 1001}
  validates :f_4_content, length: {maximum: 1001}
  validates :f_5_content, length: {maximum: 1001}
  validates :caption, length: {maximum: 1001}
  validates :title, length: {maximum: 180}
  validates_uniqueness_of :user_id, :scope => :reference_id

  def user_name
    User.select( :name ).find( self.user_id ).name
  end

  def reference_title
    Reference.select( :title ).find( self.reference_id ).title
  end

  def timeline_name
    Timeline.select( :name ).find( self.timeline_id ).name
  end

  def picture?
    self.figure_id ? true : false
  end

  def empty_field?( field )
    case field
      when 6
        self.title.blank?
      when 7
        !self.figure_id
      else
        self["f_#{field}_content"].blank?
    end
  end

  def picture_url
    if self.figure_id
      Figure.select( :id, :picture, :user_id ).find( self.figure_id ).picture_url
    else
      nil
    end
  end

  def balance
    self.f_0_balance + self.f_1_balance + self.f_2_balance +
        self.f_3_balance + self.f_4_balance + self.f_5_balance + self.f_6_balance + self.f_7_balance
  end

  def my_vote( user_id, field )
    vote = Vote.select( :value ).find_by( user_id: user_id, comment_id: self.id, field: field )
    if vote
      vote.value
    else
      0
    end
  end

  def get_best_comment( field )
    ids = CommentJoin.where( reference_id: self.reference_id, field: field ).pluck( :comment_id )
    if field == 6
      most = Comment.select( :id, :reference_id, :title_markdown, :user_id ).where( id: ids ).order(:f_6_score => :desc).first
    else
      most = Comment.select( :id, :reference_id, :user_id ).where( id: ids ).order( "f_#{field}_score".to_sym => :desc).first
    end
    most
  end

  def markdown( timeline_url)
    render_options = {
        # will remove from the output HTML tags inputted by user
        filter_html:     true,
        # will insert <br /> tags in paragraphs where are newlines
        # (ignored by default)
        hard_wrap:       true,
        # hash for extra link options, for example 'nofollow'
        link_attributes: { rel: 'nofollow' },
        # more
        # will remove <img> tags from output
        no_images: true,
        # will remove <a> tags from output
        # no_links: true
        # will remove <style> tags from output
        no_styles: true,
        # generate links for only safe protocols
        safe_links_only: true
        # and more ... (prettify, with_toc_data, xhtml)
    }

    renderer = HTMLlinks.new(render_options)
    renderer.links = []
    if Rails.env.production?
      renderer.ref_url = "http://www.controversciences.org/references/"
    else
      renderer.ref_url = "http://127.0.0.1:3000/references/"
    end

    extensions = {
        #will parse links without need of enclosing them
        autolink:           true,
        # blocks delimited with 3 ` or ~ will be considered as code block.
        # No need to indent.  You can provide language name too.
        # ```ruby
        # block of code
        # ```
        #fenced_code_blocks: true,
        # will ignore standard require for empty lines surrounding HTML blocks
        lax_spacing:        true,
        # will not generate emphasis inside of words, for example no_emph_no
        no_intra_emphasis:  true,
        # will parse strikethrough from ~~, for example: ~~bad~~
        strikethrough:      true,
        # will parse superscript after ^, you can wrap superscript in ()
        superscript:        true
        # will require a space after # in defining headers
        # space_after_headers: true
    }
    redcarpet = Redcarpet::Markdown.new(renderer, extensions)
    for fi in 0..5
      unless self.empty_field?( fi )
        self["markdown_#{fi}".to_sym ] = redcarpet.render(self["f_#{fi}_content".to_sym ])
      end
    end
    unless self.empty_field?( 7 )
      self.caption_markdown = redcarpet.render(self.caption)
    end
    unless self.empty_field?( 6 )
      self.title_markdown = redcarpet.render(self.title)
    end
    renderer.links
  end

  def save_with_markdown( timeline_url )
    links = self.markdown( timeline_url)
    if self.save
      reference_ids = Reference.where(timeline_id: self.timeline_id).pluck(:id)
      links.each do |link|
        if reference_ids.include? link
          Link.create({comment_id: self.id, user_id: self.user_id,
                       reference_id: link, timeline_id: self.timeline_id})
        end
      end
      FollowingReference.create( user_id: self.user_id,
                                 reference_id: self.reference_id)
      true
    else
      false
    end
  end

  def update_with_markdown( timeline_url )
    Link.where( user_id: user_id, comment_id: id ).destroy_all
    save_with_markdown( timeline_url )
  end


  def selection_update( best_comment = nil , comment_id = nil, user_id = nil, field = nil, only_win = false )
    if user_id
      unless only_win
        NotificationSelectionLoss.create( user_id: user_id,
                                          comment_id: comment_id, field: field )
      end
      NotificationSelectionWin.create( user_id: self.user_id, comment_id: self.id, field: field)
      NewCommentSelection.create( old_comment_id: comment_id, new_comment_id: self.id, field: field)
    end
    if field == 6
      Reference.update( self.reference_id, title_fr: self.title_markdown )
    end
    best_comment["f_#{field}_user_id".to_sym] = self.user_id
    best_comment["f_#{field}_comment_id".to_sym] = self.id
    best_comment
  end

  def empty_best_comment
    best_comment = BestComment.find_by(reference_id: self.reference_id )
    if best_comment
      for field in 0..7 do
        if best_comment["f_#{field}_comment_id"] == self.id
          best_comment["f_#{field}_user_id"] = nil
          best_comment["f_#{field}_comment_id"] = nil
        end
      end
      best_comment.save
    end
  end

  def fill_best_comment
    best_comment = BestComment.find_by(reference_id: self.reference_id )
    unless best_comment
      best_comment = BestComment.new(reference_id: self.reference_id)
    end
    for field in 0..7 do
      if not best_comment["f_#{field}_user_id"]
        unless self.empty_field?( field )
          best_comment["f_#{field}_user_id"] = self.user_id
          best_comment["f_#{field}_comment_id"] = self.id
          if field == 6
            Reference.update( self.reference_id, title_fr: self.title_markdown )
          end
        end
      elsif best_comment["f_#{field}_user_id"] == self.user_id
        if self.empty_field?( field )
          most = get_best_comment( field )
          if most
            most.selection_update( best_comment, self.id, self.user_id, field )
          else
            best_comment["f_#{field}_user_id"] = nil
            best_comment["f_#{field}_comment_id"] = nil
          end
        end
      end
    end
    best_comment.save
  end

  def refill_best_comment
    best_comment = BestComment.find_by(reference_id: self.reference_id )
    for field in 0..7 do
      unless best_comment["f_#{field}_user_id"]
        most = get_best_comment( field )
        if most
          best_comment = most.selection_update( best_comment, self.id, self.user_id, field, true )
        end
      end
    end
    best_comment.save
  end

  def update_comment_join
    CommentJoin.where(comment_id: self.id).destroy_all
    joins = []
    for fi in 0..7 do
      unless self.empty_field?( fi )
        joins << CommentJoin.new( comment_id: self.id,
                                  reference_id: self.reference_id, field: fi)
      end
    end
    CommentJoin.import joins
  end

  def destroy_with_counters
    empty_best_comment
    nb_votes = self.votes.sum( :value )
    Timeline.decrement_counter( :nb_comments , self.timeline_id )
    Reference.update_counters( self.reference_id, nb_edits: -1 )
    Reference.update_counters( self.reference_id, nb_votes: -nb_votes )
    self.destroy
    refill_best_comment
  end

  private

  def updating_with_public
    public = self.public_was
    yield
    if self.public
      update_comment_join
      fill_best_comment
    else
      if public != self.public
        CommentJoin.where(comment_id: self.id).destroy_all
        Vote.where( comment_id: self.id).destroy_all
        empty_best_comment
        refill_best_comment
      end
    end
  end

  def cascading_create_comment
    if self.public
      NewComment.create( comment_id: self.id )
      update_comment_join
      fill_best_comment
    end
    Reference.increment_counter(:nb_edits, self.reference_id)
    Timeline.increment_counter(:nb_comments, self.timeline_id)
    unless TimelineContributor.find_by({user_id: self.user_id, timeline_id: self.timeline_id})
      timrelation=TimelineContributor.new({user_id: self.user_id, timeline_id: self.timeline_id, bool: true})
      timrelation.save
      Timeline.increment_counter(:nb_contributors, self.timeline_id)
    end
    unless ReferenceContributor.find_by({user_id: self.user_id, reference_id: self.reference_id})
      refrelation=ReferenceContributor.new({user_id: self.user_id, reference_id: self.reference_id, bool: true})
      refrelation.save
      Reference.increment_counter(:nb_contributors, self.reference_id)
    end
  end

end