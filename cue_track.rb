class CueTrack
  DIRECTIVES_ALLOW = %w( number title performer composer index ).freeze

  attr_accessor *DIRECTIVES_ALLOW.map(&:to_sym)

  # TODO to realize
  # ISRC USEE10240418
  # FLAGS DCP

  def initialize(index: nil, title: nil, performer: nil,  number: nil, composer: nil)
    @index  = index
    @title  = title
    @performer = performer
    @composer = composer
    @number = number
  end

  def self.parse_track(track_array_lines)
    object = self.new

    DIRECTIVES_ALLOW.each do |directive|
      data = self.send("get_#{directive}".to_sym, track_array_lines)
      object.instance_variable_set("@#{directive}".to_sym, data)
    end

    #REFACTOR
    directives = DIRECTIVES_ALLOW.dup
    directives[0] = 'track'
    track_array_lines.each do |line|
      check = directives.any? { |directive| line.include?(directive.upcase) }
      unless check
        puts "Attention! Some lines were left unprocessed!"
        puts track_array_lines
        break
      end
    end
    object
  end

  private

  def self.get_number(arr_lines)
    prefix = /^\s+TRACK\s+/
    index = nil
    arr_lines.each do |line|
      if line =~ /#{prefix}.*/i
        index = line.match(/(?:#{prefix})([0-9]{1,3})(?:\sAUDIO)/)[1].to_i
        break
      end
    end
    index
  end

  def self.get_index(arr_lines)
    prefix = /\s+INDEX\s01\s+/
    index = nil
    arr_lines.each do |line|
      if line =~ /^#{prefix}.*/i
        index = line.match(/[0-9]+:[0-9]+:[0-9]+/)[0]
        break
      end
    end
    index
  end

  def self.get_title(arr_lines)
    prefix = /\s*TITLE\s+/
    title = nil
    arr_lines.each do |line|
      if line =~ /^#{prefix}.*/i
        title = line[/(?:#{prefix})(.*)/, 1].gsub(/^['"]|['"]$/,'')
        break
      end
    end
    title
  end

  def self.get_performer(arr_lines)
    prefix = /\s*PERFORMER\s+/
    performer = nil
    arr_lines.each do |line|
      if line =~ /^#{prefix}.*/i
        performer = line[/(?:#{prefix})(.*)/, 1].gsub(/^['"]|['"]$/,'')
        break
      end
    end
    performer
  end

  def self.get_composer(arr_lines)
    prefix = /\s*REM\s+COMPOSER\s+/
    composer = nil
    arr_lines.each do |line|
      if line =~ /^#{prefix}.*/i
        composer = line[/(?:#{prefix})(.*)/, 1].gsub(/^['"]|['"]$/,'')
        break
      end
    end
    composer
  end
end
