# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoice::Qrcode do

  let(:invoice) do
    Invoice.new(
      sequence_number: '1-1',
      payment_slip: :qr,
      total: 1500,
      iban: 'CH93 0076 2011 6238 5295 7',
      payee: "Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing\nCH",
      recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland\nCH"
    )
  end

  describe :generate do
    it 'generates image' do
      invoice.qrcode.generate do |file|
        image = ChunkyPNG::Image.from_file(file)
        expect(image.dimension.height).to eq 390
        expect(image.dimension.width).to eq 390
      end
    end
  end

  describe :payload do
    subject { invoice.qrcode.payload.split("\r\n") }

    it 'has 31 distinct parts' do
      expect(subject).to have(31).items
    end

    it 'has header part with type, version and coding' do
      expect(subject[0]).to eq 'SPC'
      expect(subject[1]).to eq '0200'
      expect(subject[2]).to eq '1'
    end

    it 'has iban' do
      expect(subject[3]).to eq 'CH93 0076 2011 6238 5295 7'
    end

    it 'has recipient info of combined type' do
      expect(subject[4]).to eq 'K'
      expect(subject[5]).to eq 'Acme Corp'
      expect(subject[6]).to eq 'Hallesche Str. 37'
      expect(subject[7]).to be_blank # 2nd address line, n/a for combined type
      expect(subject[8]).to eq '3007'
      expect(subject[9]).to eq 'Hinterdupfing'
      expect(subject[10]).to eq 'CH'
    end

    it 'has blank final recipient info' do
      11.upto(17).each do |field|
        expect(subject[field]).to be_blank
      end
    end

    it 'has payment information' do
      expect(subject[18]).to eq '1500.00'
      expect(subject[19]).to eq 'CHF'
    end

    it 'has final payment recipient of combined type' do
      expect(subject[20]).to eq 'K'
      expect(subject[21]).to eq 'Max Mustermann'
      expect(subject[22]).to eq 'Musterweg 2'
      expect(subject[23]).to be_blank
      expect(subject[24]).to eq '8000'
      expect(subject[25]).to eq 'Alt Tylerland'
      expect(subject[26]).to eq 'CH'
    end

    it 'has blank reference' do
      expect(subject[27]).to eq 'NON'
      expect(subject[28]).to be_blank
    end

    it 'has blank additional information ' do
      expect(subject[29]).to be_blank
      expect(subject[30]).to eq 'EPD'
      expect(subject[31]).to be_blank
    end

    it 'has blank alternative payment method' do
      expect(subject[32]).to be_blank
    end
  end

end

