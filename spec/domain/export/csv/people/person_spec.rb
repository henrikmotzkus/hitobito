# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Csv::People::Person do

  let(:person) { people(:top_leader) }

  subject { Export::Csv::People::Person.new(person) }

  context 'standard attributes' do
    its([:id]) { should eq person.id }
    its([:first_name]) { should eq 'Top' }
  end

  context 'roles' do
    its([:roles]) { should eq 'Leader TopGroup' }

    context 'multiple roles' do
      let(:group) { groups(:bottom_group_one_one) }
      before { Fabricate(Group::BottomGroup::Member.name.to_s, group: group, person: person) }

      its([:roles]) { should eq 'Member Group 11, Leader TopGroup' }
    end
  end

  context 'phone numbers' do
    before { person.phone_numbers << PhoneNumber.new(label: 'foobar', number: 321) }
    its([:phone_number_foobar]) { should eq '321' }
  end

  context 'social accounts ' do
    before { person.social_accounts << SocialAccount.new(label: 'foobar', name: 'asdf') }
    its([:social_account_foobar]) { should eq 'asdf' }
  end
end