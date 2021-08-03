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
    headers_arr = []
    @headers.class::HEADERS_FAMOUS.each do |header|

      value = @headers.public_send(header.to_sym)
      type = @headers.public_send("#{header}_type".to_sym)

      line = if type == :REM
               'REM %s "%s"' % [header.upcase, value]
             else
               '%s "%s"' % [header.upcase, value]
             end
      line += " WAVE" if header == 'file'
      line = set_announcer_for_title(line) if header == 'title'
      headers_arr.push line
    end
    headers_arr
  end

  def track_format(track)
    track_lines = []

    track_lines.push get_number_track(track.number)
    track_lines.push get_title(track.title)
    track_lines.push get_performer(track.performer)
    track_lines.push get_composer(track.composer)
    track_lines.push get_index(track.index)
    track_lines
  end

  def get_number_track(number)
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

  def set_announcer_for_title(line)
    return line if line.include?("[читает ")
    announcer = @headers.composer ? " [читает #{@headers.composer}]" : ""
    line.sub(/"$/, announcer + "\"")
  end
end
