include ApplicationHelper

def list_domains
  %w(cnrs irstea ifsttar ined inria inra inserm ird crasc ens ecp ec-lyon.fr ec-lille.fr
    ec-nantes.fr insa ifremer brgm onf andra cea cemagref ineris irsn cnes cirad universcience
    mnhn.fr ehess.fr sorbonne.fr ensam.fr enssib.fr jussieu.fr sciences-po.fr obspm.fr palais-decouverte.fr
    ecp.fr inalco.fr dauphine.fr cnam.fr college-de-france.fr unistra.fr uha.fr u-bordeaux1.fr u-bordeaux3.fr
    u-bordeaux4.fr u-bordeaux2.fr univ-pau.fr lacc.univ-bpclermont.fr u-clermont1.fr univ-rennes1.fr
    univ-rennes2.fr univ-brest.fr univ-ubs.fr univ-orleans.fr univ-tours.fr univ-reims.fr univ-corse.fr
    fcomte.fr univ-paris1.fr u-paris2.fr univ-paris3.fr paris-sorbonne.fr univ-paris5.fr upmc.fr
    univ-paris-diderot.fr icp.fr univ-paris8.fr u-paris10.fr u-pec.fr univ-paris13.fr univ-mlv.fr u-cergy.fr
    uvsq.fr univ-evry.fr u-psud.fr univ-montp1.fr univ-montp2.fr univ-montp3.fr unimes.fr univ-perp.fr im.fr
    univ-metz.fr uhp-nancy.fr univ-nancy2.fr univ-tlse1.fr univ-tlse2.fr ups-tlse.fr ict-toulouse.asso.fr
    univ-jfc.fr univ-artois.fr univ-lille1.fr univ-lille2.fr univ-lille3.fr univ-catholille.fr univ-littoral.fr
    valenciennes.fr unicaen.fr univ-lehavre.fr univ-rouen.fr univ-angers.fr uco.fr univ-lemans.fr univ-nantes.fr
    u-picardie.fr utc univ-larochelle.fr univ-poitiers.fr univ-provence.fr univmed.fr univ-cezanne.fr
    univ-avignon.fr unice.fr univ-tln.fr univ-savoie.fr ujf-grenoble.fr upmf-grenoble.fr u-grenoble3.fr
    univ-lyon1.fr univ-lyon2.fr univ-lyon3.fr univ-catholyon.fr univ-st-etienne.fr univ-ag.fr
    univ-reunion ufp.pf unvi-nc.nc)
end

def seed_domains
  list_domains.each do |domain_name|
    Domain.create(name: domain_name)
  end
end

def seed_users
  users = []
  users << User.new(name:  "T. Latrille",
               email: "thibault.latrille@ens-lyon.fr",
               password:              "password",
               password_confirmation: "password",
               admin: true,
               activated: true,
               activated_at: Time.zone.now)
  30.times do |n|
    first_name  = Faker::Name.first_name
    last_name  = Faker::Name.last_name
    email = "#{first_name}.#{last_name}@ens-lyon.fr"
    password = "password"
    users << User.new(name: "#{first_name[0].upcase}. #{last_name}",
                 email: email,
                 password:              password,
                 password_confirmation: password,
                 activated: true,
                 activated_at: Time.zone.now)
  end
  users.map do |u|
    u.save!
  end
  users
end

def seed_timelines(users, tags)
  timelines = []
  names = []
  names << "Les OGMs sont-ils nocifs pour la santé ?"
  names << "Les crevettes sont elles conscientes"
  names << "Les ondes des portables vont-elles nous griller le cerveau ?"
  names << "Les animaux peuvent-ils être homosexuels ?"
  names << "Les poissons de Fukushima sont-ils fluorescent ?"
  names << "Les poules ont elles des dents ?"
  names << "Sommes nous descendant de Néanderthal ? "
  names << "Le nuage de Tchernobyl s'est il arreté à la frontière "
  names << "La masturbation rend elle sourd ?"
  names << "Les coraux vont-ils disparaîtrent ?"
  names << "Le THC rend il stupide et con ?"
  names << "La café est il mauvais pour la santé ?"
  names << "Le LHC va-t-il créer un trou noir ?"
  names << "Yellowstone va-t-il bientôt sauter ?"
  names.each do |name|
      timeline = Timeline.new(
      user: users[rand(users.length)],
      name:  name,
      score: 4.2)
      timeline.set_tag_list( tags.sample(rand(1..7)) )
      timelines << timeline
  end
  timelines.map do |t|
    t.save!
  end
  timelines
end

def seed_following_new_timelines(users, tags)
  following_new_timelines = []
  users.each do |user|
    s = tags.length
    tag_ids = Array(1..s).sample(1+rand(s/3))
    tag_ids.each do |tag_id|
      following_new_timelines << FollowingNewTimeline.new( user_id: user.id, tag_id: tag_id )
    end
  end
  following_new_timelines.map do |f|
    f.save!
  end
  following_new_timelines
end

def seed_following_timelines(users, timelines)
  following_timelines = []
  users.each do |user|
    user_timelines = timelines.sample(1+rand(timelines.length/3))
    user_timelines.each do |timeline|
      following_timelines << FollowingTimeline.new( user_id: user.id, timeline_id: timeline.id )
    end
  end
  following_timelines.map do |f|
    f.save!
  end
  following_timelines
end


def seed_following_summaries(users, timelines)
  following_summaries = []
  users.each do |user|
    user_timelines = timelines.sample(1+rand(timelines.length/4))
    user_timelines.each do |timeline|
      following_summaries << FollowingSummary.new( user_id: user.id, timeline_id: timeline.id )
    end
  end
  following_summaries.map do |f|
    f.save!
  end
  following_summaries
end

def seed_references(users, timelines)
  references = []
  bibtex = BibTeX.open('./db/seeds.bib')
  timelines.each do |timeline|
    array = Array((0..bibtex.length-1)).sample(5)
    array.each do |rand|
      bib = bibtex[rand]
      ref = Reference.new(
          user: users[rand(users.length)],
          timeline: timeline)
      reference_attributes = [:title, :doi, :year, :url, :journal, :author, :abstract]
      reference_attributes.each do |attr|
        ref[attr] = bib.respond_to?(attr) ? bib[attr].value : ''
      end
      ref.year = ref.year.to_i
      ref.title_fr = Faker::Lorem.sentence(4)
      ref.open_access = rand(2) == 1 ? true : false
      references << ref
    end
  end
  references.map do |r|
    r.save!
  end
  references
end

def seed_following_references(users, timelines)
  references = timelines[0].references
  following_references = []
  users.each do |user|
    user_references = references.sample(1+rand(references.length/2))
    user_references.each do |reference|
      following_references << FollowingReference.new( user_id: user.id, reference_id: reference.id )
    end
  end
  following_references.map do |f|
    f.save!
  end
  following_references
end

def seed_summaries(users, timelines)
  summaries = []
  timeline = timelines[0]
  timeline_url = "0.0.0.0:3000/timelines/"+timeline.id.to_s
  contributors = users[1..-1].sample(1+rand(users.length/2-1))
  references = timeline.references
  reference_ids = references.map{ |ref| ref.id }
  contributors << users[0]
  contributors.each do |user|
    content = Faker::Lorem.sentence(rand(6))+"["+Faker::Lorem.sentence(rand(2))+"]("+
        reference_ids[rand(reference_ids.length)].to_s+")"+Faker::Lorem.sentence(rand(4))
    "\n"+Faker::Lorem.sentence(rand(12))
    summary = Summary.new(
        user: user,
        timeline:  timeline,
        content: content)
    summaries << summary
  end
  summaries.map do |c|
    c.save_with_markdown( timeline_url )
  end
  summaries
end

def seed_credits(users, summaries)
  credits = []
  users.each do |user|
    summaries.group_by{ |c| c.timeline_id }.each do |_, summaries_by_timelines|
      sum = 0
      summaries_user = summaries_by_timelines.sample(rand(summaries_by_timelines.length/2))
      summaries_user.each do |summary|
        value = rand(0..(12-sum))
        if value > 0
          sum += value
          credits << Credit.new(
              user_id: user.id,
              summary_id: summary.id,
              timeline_id:  summary.timeline_id,
              value: value)
          visit = VisiteTimeline.find_by( user_id: user.id, timeline_id: summary.timeline_id )
          if visit
            visit.update( updated_at: Time.zone.now )
          else
            VisiteTimeline.create( user_id: user.id, timeline_id: summary.timeline_id )
          end
        end
      end
    end
  end
  credits.map do |v|
    v.save
  end
  credits
end

def seed_comments(users, timelines)
  comments = []
  timeline = timelines[0]
  timeline_url = "0.0.0.0:3000/timelines/"+timeline.id.to_s
  references = timeline.references
  reference_ids = references.map{ |ref| ref.id }
  references.each do |ref|
    contributors = users[1..-1].sample(1+rand(users.length/2-1))
    contributors << users[0]
    contributors.each do |user|
      f_1_content = Faker::Lorem.sentence(rand(6))+"["+Faker::Lorem.sentence(rand(2))+"]("+
          reference_ids[rand(reference_ids.length)].to_s+")"+Faker::Lorem.sentence(rand(4))
          "\n"+Faker::Lorem.sentence(rand(12))
      f_2_content = Faker::Lorem.sentence(rand(6))+"["+Faker::Lorem.sentence(rand(2))+"]("+
          reference_ids[rand(reference_ids.length)].to_s+")"+Faker::Lorem.sentence(rand(4))
      "\n"+Faker::Lorem.sentence(rand(12))
      f_3_content = Faker::Lorem.sentence(rand(6))+"["+Faker::Lorem.sentence(rand(2))+"]("+
          reference_ids[rand(reference_ids.length)].to_s+")"+Faker::Lorem.sentence(rand(4))
      "\n"+Faker::Lorem.sentence(rand(12))
      f_4_content = Faker::Lorem.sentence(rand(6))+"["+Faker::Lorem.sentence(rand(2))+"]("+
          reference_ids[rand(reference_ids.length)].to_s+")"+Faker::Lorem.sentence(rand(4))
      "\n"+Faker::Lorem.sentence(rand(12))
      f_5_content = Faker::Lorem.sentence(rand(6))+"["+Faker::Lorem.sentence(rand(2))+"]("+
          reference_ids[rand(reference_ids.length)].to_s+")"+Faker::Lorem.sentence(rand(4))
      "\n"+Faker::Lorem.sentence(rand(12))
      comment = Comment.new(
          user: user,
          timeline:  timeline,
          reference: ref,
          f_1_content: f_1_content,
          f_2_content: f_2_content,
          f_3_content: f_3_content,
          f_4_content: f_4_content,
          f_5_content: f_5_content)
      comments << comment
    end
  end
  comments.map do |c|
    c.save_with_markdown( timeline_url )
  end
  comments
end

def seed_votes(users, comments)
  votes = []
  users.each do |user|
    comments.group_by{ |c| c.reference_id }.each do |_, comments_by_reference|
      sum = 0
      comments_user = comments_by_reference.sample(rand(comments_by_reference.length/2))
      comments_user.each do |comment|
        value = rand(0..(12-sum))
        if value > 0
          sum += value
          votes << Vote.new(
              user_id: user.id,
              comment_id: comment.id,
              timeline_id:  comment.timeline_id,
              reference_id: comment.reference_id,
              value: value)
          visit = VisiteReference.find_by( user_id: user.id, reference_id: comment.reference_id )
          if visit
            visit.update( updated_at: Time.zone.now )
          else
            VisiteReference.create( user_id: user.id, reference_id: comment.reference_id )
          end
        end
      end
    end
  end
  votes.map do |v|
    v.save
  end
  votes
end

def seed_ratings(users, timelines)
  timeline = timelines[0]
  references = timeline.references
  ratings = []
  references.each do |ref|
    voters = users.sample(1+rand(users.length-1))
    voters.each do |user|
      value = rand(1..5)
      ratings << Rating.new(
          user: user,
          timeline:  ref.timeline,
          reference: ref,
          value: value)
    end
  end
  ratings.map do |r|
    r.save!
  end
  ratings
end

seed_domains
tags = tags_hash.keys
users = seed_users
seed_following_new_timelines(users, tags)
timelines = seed_timelines(users, tags)
seed_following_timelines(users, timelines)
seed_following_summaries(users, timelines)
references = seed_references(users, timelines)
seed_following_references(users, timelines)
summaries = seed_summaries(users, timelines)
seed_credits(users, summaries)
comments = seed_comments(users, timelines)
seed_votes(users, comments)
seed_ratings(users, timelines)
