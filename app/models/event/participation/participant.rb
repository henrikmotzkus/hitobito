# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer
#  person_id              :integer          not null
#  type                   :string(255)      not null
#  label                  :string(255)
#  additional_information :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

# Teilnehmer
class Event::Participation::Participant < Event::Participation
  
  self.permissions = [:contact_data]
  
  after_save :update_count
  after_destroy :update_count
  
  
  private
  
  def update_count
    event.refresh_participant_count! if event
  end
  
end
