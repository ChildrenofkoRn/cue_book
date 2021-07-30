class CueTrack
  DIRECTIVES_ALLOW = %w( number index title author ).freeze

  attr_accessor *DIRECTIVES_ALLOW.map(&:to_sym)

  # ISRC USEE10240418
  # FLAGS DCP

  def initialize(index: nil, title: nil, author: nil,  number: nil)
    @index  = index
    @title  = title
    @author = author
    @number = number
  end

  def parse_track(track_array_lines)
    DIRECTIVES_ALLOW.each do |directive|
      data = self.class.send("get_#{directive}".to_sym, track_array_lines)
      instance_variable_set("@#{directive}".to_sym, data)
    end

    if track_array_lines.size > DIRECTIVES_ALLOW.size
      p "Attention! Some lines were left unprocessed!"
      pp track_array_lines
    end
  end

  def render
    track = []
    DIRECTIVES_ALLOW.each do |directive|
      track.push '\s\s'
    end
  end

  def self.get_number(arr_lines)
    index = nil
    arr_lines.each do |line|
      if line =~ /^\s+TRACK\s.*/i
        index = line.match(/(?:TRACK\s)([0-9]{2})(?:\sAUDIO)/)[1].to_i
        break
      end
    end
    index
  end

  def self.get_index(arr_lines)
    index = nil
    arr_lines.each do |line|
      if line =~ /^\s+INDEX\s01\s.*/i
        index = line.match(/[0-9]+:[0-9]+:[0-9]+/)[0]
        break
      end
    end
    index
  end

  def self.get_title(arr_lines)
    title = nil
    arr_lines.each do |line|
      if line =~ /^\s+TITLE\s.*/i
        title = line[/(?:")(.*)(?:")/,1]
        break
      end
    end
    title
  end

  def self.get_author(arr_lines)
    author = nil
    arr_lines.each do |line|
      if line =~ /^\s+PERFORMER\s.*/i
        author = line[/(?:")(.*)(?:")/,1]
        break
      end
    end
    author
  end
end
