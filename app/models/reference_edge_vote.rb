class ReferenceEdgeVote < ActiveRecord::Base
  belongs_to :user
  belongs_to :reference_edge
  belongs_to :timeline

  validates :timeline_id, presence: true
  validates :user_id, presence: true
  validates :reference_edge_id, presence: true
  validates_uniqueness_of :user_id, :scope => [:reference_edge_id]

  after_create :cascading_create_vote
  after_destroy :cascading_destroy_vote

  private

  def cascading_create_vote
    ref_edge = self.reference_edge
    if ref_edge.category == self.category
      if self.value
        ReferenceEdge.increment_counter(:plus, self.reference_edge_id)
        ReferenceEdge.increment_counter(:balance, self.reference_edge_id)
      else
        ReferenceEdge.increment_counter(:minus, self.reference_edge_id)
        ReferenceEdge.decrement_counter(:balance, self.reference_edge_id)
      end
    else
      plus = ReferenceEdgeVote.where(reference_edge_id: self.id,
                                     value: true, category: self.category).count
      minus = ReferenceEdgeVote.where(reference_edge_id: self.id,
                                      value: false, category: self.category).count
      balance = plus - minus
      if balance > ref_edge.balance
        ref_edge.plus = plus
        ref_edge.minus = minus
        ref_edge.balance = balance
        ref_edge.category = self.category
        ref_edge.save!
      end
    end
  end

  def cascading_destroy_vote
    ref_edge = self.reference_edge
    if ref_edge.category == self.category
      if self.value
        ReferenceEdge.decrement_counter(:plus, self.reference_edge_id)
        ReferenceEdge.decrement_counter(:balance, self.reference_edge_id)
      else
        ReferenceEdge.decrement_counter(:minus, self.reference_edge_id)
        ReferenceEdge.increment_counter(:balance, self.reference_edge_id)
      end
    else
      plus = ReferenceEdgeVote.where(reference_edge_id: self.id,
                                     value: true, category: self.category).count
      minus = ReferenceEdgeVote.where(reference_edge_id: self.id,
                                      value: false, category: self.category).count
      balance = plus - minus
      if balance > ref_edge.balance
        ref_edge.plus = plus
        ref_edge.minus = minus
        ref_edge.balance = balance
        ref_edge.category = self.category
        ref_edge.save!
      end
    end
  end

end
