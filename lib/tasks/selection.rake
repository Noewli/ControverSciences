namespace :admin  do
  task :selection => :environment do
    include AssisstantHelper

    update_score_users
    update_score_timelines
    compute_fitness
    selection_events
  end
end