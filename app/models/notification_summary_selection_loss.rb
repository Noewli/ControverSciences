class NotificationSummarySelectionLoss < ActiveRecord::Base
  belongs_to :user
  belongs_to :summary
end
