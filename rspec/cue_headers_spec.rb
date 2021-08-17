require_relative 'rspec_helper'
load_class(__FILE__)

describe CueHeaders do

  HEADERS_REM = %w( genre date comment composer )
  HEADERS = HEADERS_REM + %w( performer title file )


  describe ".new" do
    it "#new create object with headers equal to nil" do
      headers = CueHeaders.new

      HEADERS.each do |header|
        expect( headers.public_send(header.to_sym) ).to eq nil
      end
    end
  end

  describe "object" do
    it "must have attr_accessor methods for value for each header" do
      headers = CueHeaders.new
      text = 'Jóhann Jóhannsson - Sicario: Original Motion Picture Soundtrack '

      HEADERS.each_with_index do |header, idx|
        new_value = text + idx.to_s
        expect { headers.public_send("#{header}=".to_sym, new_value) }
          .to change { headers.public_send("#{header}".to_sym) }.from(nil).to(new_value)
      end
    end

    it "must have attr_reader methods for type for each header" do
      headers = CueHeaders.new

      HEADERS.each_with_index do |header, _idx|
        type = HEADERS_REM.include?(header) ? :REM : :SIMPLE
        expect( headers.public_send("#{header}_type".to_sym) ).to eq type
      end
    end
  end

  describe ".parse_headers" do
    it "with empty array create object w headers equal to nil" do
      headers = CueHeaders.parse_headers([])

      HEADERS.each do |header|
        expect( headers.public_send(header.to_sym) ).to eq nil
      end
    end

    it "if some header is missing in array, then create object w headers and missing header equal to nil" do
      headers = CueHeaders.parse_headers([])

      HEADERS.each do |header|
        expect( headers.public_send(header.to_sym) ).to eq nil
      end
    end

    it "valid parse text for each header [\"']?TEXT[\"']?" do
      array_text = [
        '',
        '1965',
        '\'Ф"антасти"ка\'',
        '\'Sur"veilla"nce\'',
        '"Ф"антаст\'и"ка"',
        '"Sur"veill\'a"nce"',
        'Ф"антаст\'и\'"ка',
        'Sur"veill\'a\'"nce',
        '"Sur"vei;ll.\'a:\'(")n\/ce*"',
        '"Target"',
        'Alejandro\'s Song',
        'Jóhann Jóhannsson',
        '"Лавкрафт - Сомнамбулический поиск неведомого Кадата.wav"',
      ]
      valid_parse = [
        '',
        '1965',
        'Ф"антасти"ка',
        'Sur"veilla"nce',
        'Ф"антаст\'и"ка',
        'Sur"veill\'a"nce',
        'Ф"антаст\'и\'"ка',
        'Sur"veill\'a\'"nce',
        'Sur"vei;ll.\'a:\'(")n\/ce*',
        'Target',
        'Alejandro\'s Song',
        'Jóhann Jóhannsson',
        'Лавкрафт - Сомнамбулический поиск неведомого Кадата.wav',
      ]

      HEADERS.each do |header|
        head = if HEADERS_REM.include?(header)
                "REM #{header.upcase}"
               else
                 "#{header.upcase}"
               end

        array_text.each_with_index do |text, idx|
          line = "#{head} #{text}"
          line += ' WAVE' if header == 'file'
          expect( CueHeaders.parse_headers([line])
                    .public_send(header.to_sym) ).to eq valid_parse[idx]
        end
      end
    end
  end

  describe ".get" do
    it "returns all headers as hash with value & type for each" do
      headers = CueHeaders.new
      text = 'Nobuo Uematsu - Sairin: Kata Tsubasa no Tenshi / Advent: One-Winged Angel '

      HEADERS.each_with_index do |header, idx|
        new_value = text + idx.to_s
        headers.public_send("#{header}=".to_sym, new_value)
      end

      headers.get.each_with_index do |(header, hash), _idx|
        expect( headers.public_send(header) ).to eq hash[:value]
        expect( headers.public_send("#{header}_type".to_sym) ).to eq hash[:type]
      end
    end
  end

  describe ".set_announcer_for_title" do
    let(:headers) { CueHeaders.new }

    it "if composer is set, then adding to title" do
      headers.title = 'Duna'
      headers.composer = 'Peter Markin'
      expect { headers.set_announcer_for_title }
        .to change { headers.title }.from('Duna').to('Duna [читает Peter Markin]')
    end

    it "if composer is not set, then title not change" do
      headers.title = 'Duna'
      expect { headers.set_announcer_for_title }.not_to change { headers.title }
    end

    it "if composer already added to title, then title not change" do
      headers.title = 'Duna [читает Peter Markin]'
      headers.composer = 'Peter Markin'
      expect { headers.set_announcer_for_title }.not_to change { headers.title }
    end

  end
end
