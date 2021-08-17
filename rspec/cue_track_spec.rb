require_relative 'rspec_helper'
load_class(__FILE__)

describe CueTrack do
  DIRECTIVES = %w( number title performer composer index ).freeze

  describe ".new" do
    it "#new create object with directives equal to nil" do
      track = CueTrack.new

      DIRECTIVES.each do |directive|
        expect( track.public_send(directive.to_sym) ).to eq nil
      end
    end
  end

  describe "object" do
    it "must have attr_accessor methods for each directive" do
      track = CueTrack.new
      text = 'The Prodigy - Your Love [Original Mix] #'

      DIRECTIVES.each_with_index do |directive, idx|
        new_value = text + idx.to_s
        expect { track.public_send("#{directive}=".to_sym, new_value) }
          .to change { track.public_send("#{directive}".to_sym) }.from(nil).to(new_value)
      end
    end
  end

  describe ".parse_headers" do
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

    it "valid parse, extended test for directives: title, performer, composer" do
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

      directives =  %w( title performer composer )

      directives.each do |directive|

        array_text.each_with_index do |text, idx|
          prefix = directive == 'composer' ? 'REM ' : ''
          line = "    #{prefix}#{directive.upcase} #{text}"
          expect( CueTrack.parse_track([line])
                    .public_send(directive.to_sym) ).to eq valid_parse[idx]
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
