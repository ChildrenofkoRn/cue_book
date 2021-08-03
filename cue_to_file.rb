class Cue2File
  def initialize(headers:, path2save: nil, cue_string: nil)
    @headers = headers
    @path2save = path2save
    @cue_string = cue_string
  end

  def get_filename
    template = '%<performer>s - %<title>s%<date>s%<timestamp>s.cue'

    date = @headers.date ? " [#{@headers.date}]" : ''
    time = Time.now.strftime("%Y%m%d_%H%M")
    timestamp = " #{time}"
    format(template, performer: @headers.performer,
                             title: @headers.title,
                             date: date,
                             timestamp: timestamp )
  end

end
