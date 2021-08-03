class CueRender
  def initialize(headers:, tracks:)
    @headers = headers
    @tracks = tracks
  end

  def render
    cue = get_headers + get_tracks
    cue.join("\n") + "\n"
  end

  private

  def get_tracks
    @tracks.inject([]) do |tracks_arr, track|
      tracks_arr + track_format(track)
    end
  end

  def get_headers
    @headers.get.each_with_object([]) do |(header, data), memo|
      value = data[:value]
      type  = data[:type]

      line = if type == :REM
               'REM %s "%s"' % [header.upcase, value]
             else
               '%s "%s"' % [header.upcase, value]
             end
      line += " WAVE" if header == 'file'
      memo.push line
    end
  end

  def track_format(track)
    track.class::DIRECTIVES_ALLOW.each_with_object([]) do |directive, memo|
      value = track.public_send(directive.to_sym)
      memo.push self.send("get_#{directive}".to_sym, value)
    end
  end

  def get_number(number)
    spaces = "\s" * 2
    sprintf('%sTRACK %02d AUDIO', spaces, number)
  end

  def get_title(title)
    spaces = "\s" * 4
    sprintf('%sTITLE "%s"', spaces, title )
  end

  def get_performer(performer)
    performer = performer.nil? ? @headers.performer : performer

    spaces = "\s" * 4
    sprintf('%sPERFORMER "%s"', spaces, performer)
  end

  def get_composer(composer)
    composer = composer.nil? ? @headers.composer : composer

    spaces = "\s" * 4
    sprintf('%sPERFORMER "%s"', spaces, composer)
  end

  def get_index(index)
    spaces = "\s" * 4
    sprintf('%sINDEX 01 %s', spaces, index)
  end
end
