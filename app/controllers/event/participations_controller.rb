class Event::ParticipationsController < CrudController
  
  self.nesting = Event
  
  FILTER = { all: 'Alle Personen', 
             leaders: 'Leitungsteam', 
             participants: 'Teilnehmende' }
  
  decorates :event, :participation, :participations, :alternatives
  prepend_before_filter :entry, only: [:show, :new, :create, :edit, :update, :destroy, :print]
  
  # load event before authorization
  prepend_before_filter :parent, :set_group
  before_render_form :load_priorities
  before_render_show :load_answers

  after_create :send_confirmation_email
  before_save :set_participant_role
  
  def new
    assign_attributes
    entry.init_answers
    respond_with(entry)
  end

    
  def authorize!(action, *args)
    if [:index].include?(action)
      super(:index_participations, parent)
    else
      super
    end
  end

  def print
    load_answers
    render :print, layout: false
  end

  def destroy
    super(location: event_application_market_index_path(entry.event_id))
  end
  
  private

  def set_participant_role
    if entry.event != Event::Course
      role = entry.event.participant_type.new
      role.participation = entry
      entry.roles << role
    end
  end
    
  def list_entries(action = :index)
    records = parent.participations.
                 where(event_participations: {active: true}).
                 includes(:person, :roles).
                 participating(parent).
                 order_by_role(parent.class).
                 merge(Person.order_by_name).
                 uniq
    Person::PreloadPublicAccounts.for(records.collect(&:person))

    if scope = FILTER.keys.detect {|k| k.to_s == params[:filter] }
      # do not use params[:filter] in send to satisfy brakeman
      records = records.send(scope, parent)
    end
    
    records
  end
  
  
  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles. 
  def build_entry
    participation = parent.participations.new
    participation.person = current_user
    if parent.supports_applications
      appl = participation.build_application
      appl.priority_1 = parent
    end
    participation
  end
  
  def assign_attributes
    super
    # Set these attrs again as a new application instance might have been created by the mass assignment.
    entry.application.priority_1 ||= parent if entry.application
  end
  
  def set_group
    @group = parent.group
  end
    
  def load_priorities
    if entry.application && entry.event.priorization
      @alternatives = Event::Course.application_possible.
                                    where(kind_id: parent.kind_id).
                                    in_hierarchy(current_user).
                                    list
      @priority_2s = @priority_3s = (@alternatives.to_a - [parent]) 
    end
  end
  
  def load_answers
    @answers = entry.answers.includes(:question)
    @application = Event::ApplicationDecorator.decorate(entry.application)
  end
  
  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::ParticipationDecorator.decorate(entry).flash_info}".html_safe
  end

  def send_confirmation_email
    Event::ParticipationMailer.confirmation(current_user, @participation).deliver
  end
  
  class << self
    def model_class
      Event::Participation
    end
  end
end
