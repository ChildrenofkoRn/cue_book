require_relative 'rspec_helper'
load_class(__FILE__)

describe CueTrack do
  DIRECTIVES = %w( number title performer composer index ).freeze

  describe ".new" do

    it "create object with directives equal to nil" do
      track = CueTrack.new

      DIRECTIVES.each do |directive|
        expect( track.public_send(directive.to_sym) ).to eq nil
      end
    end
  end

  # as default attr_accessor is used this test is not necessary
  describe "object" do
    let(:text) { FactoryBot.build(:text) }

    it "must have attr_accessor methods for each directive" do
      track = CueTrack.new

      DIRECTIVES.each_with_index do |directive, idx|
        new_value = text + idx.to_s
        expect { track.public_send("#{directive}=".to_sym, new_value) }
          .to change { track.public_send("#{directive}".to_sym) }.from(nil).to(new_value)
      end
    end
  end

  describe ".parse_headers" do
    let(:hash_texts_ext) { FactoryBot.build(:texts_ext) }

    track_arr_lines = [
    '  TRACK 10 AUDIO',
    '    TITLE "We Are The Ruffest [Original Mix]"',
    '    PERFORMER "The Prodigy"',
    '    REM COMPOSER "Liam Howlett"',
    '    INDEX 01 39:37:73',
    ]
    track_values = [
      10,
      'We Are The Ruffest [Original Mix]',
      'The Prodigy',
      'Liam Howlett',
      '39:37:73',
    ]

    it "with empty array create object w directives equal to nil" do
      track = CueTrack.parse_track([])

      DIRECTIVES.each do |directive|
        expect( track.public_send(directive.to_sym) ).to eq nil
      end
    end

    it "if some directive is missing in array, then create object w directives and missing directive equal to nil" do
      track = CueTrack.parse_track([])

      DIRECTIVES.each do |directive|
        expect( track.public_send(directive.to_sym) ).to eq nil
      end
    end

    it "valid parse array" do
      track = CueTrack.parse_track(track_arr_lines)

      DIRECTIVES.each_with_index do |directive, idx|
        expect( track.public_send(directive.to_sym) ).to eq track_values[idx]
      end
    end

    it "valid parse, extended test for text directives: title, performer, composer" do

      directives =  %w( title performer composer )

      directives.each do |directive|

        hash_texts_ext.each_pair do |text, valid_parse|
          prefix = directive == 'composer' ? 'REM ' : ''
          line = "    #{prefix}#{directive.upcase} #{text}"

          expect( CueTrack.parse_track([line])
                    .public_send(directive.to_sym) ).to eq valid_parse
        end
      end
    end

    it "if there is unknown directives, then there should be a message" do
      track_arr_lines = [
        '  TRACK 10 AUDIO',
        '    TITLE "We Are The Ruffest [Original Mix]"',
        '    PERFORMER "The Prodigy"',
        '    REM COMPOSER "Liam Howlett"',
        '    FLAGS DCP',
        '    INDEX 01 39:37:73',
      ]
      msg = "Attention! Some lines were left unprocessed!"
      expect { CueTrack.parse_track(track_arr_lines) }.to output(/#{msg}/).to_stdout
    end


  end

end
